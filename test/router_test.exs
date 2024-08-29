defmodule BattleTest.RouterTest do
  use ExUnit.Case
  use Plug.Test
  import Mock
  doctest Battle.Web.Router

  alias Battle.Web.Router
  alias Battle.Mongo.UserAi
  alias Battle.Mongo.BattleInfo
  alias Battle.Mongo.User
  alias Battle.Mongo.BattleStatistics
  alias Battle.Mongo.RankList
  alias Battle.Mongo.BattleResult
  alias Battle.Mongo.BattleResultTest

  @opts Router.init([])

  test "return html on /" do
    conn =
      :get
      |> conn("/", "")
      |> Router.call(@opts)
    assert conn.state == :sent
    assert conn.status == 200
  end

  test "redirects to the correct URL on /login/one_code" do
    expected_url = "http://one.ejoy.com/oauth_v3?client_id=10052&redirect_uri=http://battle1024.ejoy.com/login/redirect&response_type=code&scope=acl&state=123"
    conn =
      :get
      |> conn("/login/one_code", "")
      |> Router.call(@opts)
    assert conn.state == :sent
    assert conn.status == 302
    assert get_resp_header(conn, "location") == [expected_url]
  end

  test "return 200 with user info on /login/redirect with valid code" do
    with_mock Battle.Service.WebService.Auth, [:passthrough], [
      verify_code: fn
        _ ->
          {:ok, "abc"}
      end
    ] do
      conn =
        :get
        |> conn("/login/redirect", %{"code" => "asgkasgag"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["https://ieu-battle1024.alibaba.net/login?code=200&moment_token=abc"]
    end
  end

  test "return 302 with error message on /login/redirect with invalid code" do
    with_mock Battle.Service.WebService.Auth, [:passthrough], [
      verify_code: fn _ -> {:error, "one_code_error"} end
    ] do
      conn =
        :get
        |> conn("/login/redirect", %{"code" => "asgkasgag"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["https://ieu-battle1024.alibaba.net/login?code=403"]
    end
  end

  test "/user/all, return 200" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      BattleResult.save_battle_result(["111", "222"], "333", "111", [11, 22], ["11","22"], "111", [20, 30])
      conn =
        :get
        |> conn("/user/all", %{"moment_token" => "asgkasgag"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      BattleResult.remove_battle("111")
    end
  end

  test "/user/all, return 200 with code 2003 when no any game of this user" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "1"}
      end
    ] do
      conn =
        :get
        |> conn("/user/all", %{"moment_token" => "asgkasgag"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 2003, "data" => "no games of user", "success" => false}
    end
  end

  test "/user/all, return 302 when token is invalid" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "invalid token"}
      end
    ] do
      conn =
        :get
        |> conn("/user/all", %{"moment_token" => "asgkasgag"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
    end
  end

  test "/user/all, return 500 when server error" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:server_error, "server error"}
      end
    ] do
      conn =
        :get
        |> conn("/user/all", %{"moment_token" => "asgkasgag"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
    end
  end

  test "/user/ranking_list, return 200" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "1"}
      end
    ] do
      RankList.save_rank("1", "fuck", 0.8)
      conn =
        :get
        |> conn("/user/ranking_list")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      RankList.remove_rank("1")
    end
  end

  test "/user/ranking_list, return 200 with code 2004 when no game of user_id" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "1"}
      end
    ] do
      conn =
        :get
        |> conn("/user/ranking_list", %{"moment_token" => "asgkasgag"})
        |> Router.call(@opts)
      IO.inspect(conn.resp_body)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 2004, "data" => "user_id error", "success" => false}
    end
  end

  test "/user/ranking_list, return 302 when token is invalid" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "invalid token"}
      end
    ] do
      conn =
        :get
        |> conn("/user/ranking_list", %{"moment_token" => "asgkasgag"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
    end
  end

  test "/user/ranking_list, return 500 when server error" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:server_error, "server error"}
      end
    ] do
      conn =
        :get
        |> conn("/user/ranking_list", %{"moment_token" => "asgkasgag"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
    end
  end

  test "GET /game/ranking_list with pagination, return 200" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      RankList.save_rank("111", "fuck", 0.98)
      conn =
        :get
        |> conn("/game/ranking_list", %{"page" => "0", "limit" => "2", "moment_token" => "dummy_token"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      RankList.remove_rank("111")
    end
  end

  test "GET /game/ranking_list with pagination, return 200 with code 2004 when no games" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      conn =
        :get
        |> conn("/game/ranking_list", %{"page" => "0", "limit" => "2", "moment_token" => "dummy_token"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 2004, "data" => "empty rank list", "success" => false}
    end
  end

  test "GET /game/ranking_list with pagination, return 302 when token is invalid" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "invalid token"}
      end
    ] do
      conn =
        :get
        |> conn("/game/ranking_list", %{"page" => "0", "limit" => "2", "moment_token" => "dummy_token"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
    end
  end

  test "GET /game/ranking_list with pagination, return 500 when server error" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:server_rror, "server error"}
      end
    ] do
      conn =
        :get
        |> conn("/game/ranking_list", %{"page" => "0", "limit" => "2", "moment_token" => "dummy_token"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
    end
  end

  test " /game/statistic_info, return 200 with code 2005 when no any game" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, ""}
      end
    ] do
      query_params = %{
        "moment_token" => "sfakjflasfla"
      }
      url_with_query = "/game/statistic_info?#{URI.encode_query(query_params)}"
      conn =
        :get
        |> conn(url_with_query)
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 2005, "data" => "no info in battle_statistics", "success" => false}
    end
  end

  test " /game/statistic_info, return 200 " do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, ""}
      end
    ] do
      BattleStatistics.save_init()
      query_params = %{
        "moment_token" => "sfakjflasfla"
      }
      url_with_query = "/game/statistic_info?#{URI.encode_query(query_params)}"
      conn =
        :get
        |> conn(url_with_query)
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
    end
  end

  test " /game/statistic_info, return 302 when token is invalid " do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "invalid token"}
      end
    ] do
      query_params = %{
        "moment_token" => "sfakjflasfla"
      }
      url_with_query = "/game/statistic_info?#{URI.encode_query(query_params)}"
      conn =
        :get
        |> conn(url_with_query)
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
    end
  end

  test " /game/statistic_info, return 500 when server is error" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:server_error, "server error"}
      end
    ] do
      query_params = %{
        "moment_token" => "sfakjflasfla"
      }
      url_with_query = "/game/statistic_info?#{URI.encode_query(query_params)}"
      conn =
        :get
        |> conn(url_with_query)
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
    end
  end

  test "/user/update_avatar, return 200" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      User.save_user("111", "415500")
      json_data = %{"avatar" => "aaccbb",
                  "moment_token" => "dummy token"} |> Ejoy.Jiffy.encode!()
      conn =
        :post
        |> conn("/user/update_avatar", json_data)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      User.remove_user("111")
    end
  end

  test "/user/update_avatar, return 302 when token is invalid" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "invalid token"}
      end
    ] do
      User.save_user("111", "415500")
      json_data = %{"avatar" => "aaccbb",
                  "moment_token" => "dummy token"} |> Ejoy.Jiffy.encode!()
      conn =
        :post
        |> conn("/user/update_avatar", json_data)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
      User.remove_user("111")
    end
  end

  test "/user/update_avatar, return 500 when server is wrong" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:server_error, "server error"}
      end
    ] do
      User.save_user("111", "415500")
      json_data = %{"avatar" => "aaccbb",
                  "moment_token" => "dummy token"} |> Ejoy.Jiffy.encode!()
      conn =
        :post
        |> conn("/user/update_avatar", json_data)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
      User.remove_user("111")
    end
  end

  test " /user/get_avatar, return 200" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      User.save_user("111", "415500")
      query_params = %{
        "moment_token" => "sfakjflasfla"
      }
      url_with_query = "/user/get_avatar?#{URI.encode_query(query_params)}"
      conn =
        :get
        |> conn(url_with_query)
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      User.remove_user("111")
    end
  end

  test " /user/get_avatar, return 200 with code 2006 when user not exists" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "222"}
      end
    ] do
      User.save_user("111", "415500")
      query_params = %{
        "moment_token" => "sfakjflasfla"
      }
      url_with_query = "/user/get_avatar?#{URI.encode_query(query_params)}"
      conn =
        :get
        |> conn(url_with_query)
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 2006, "data" => "user_id error", "success" => false}
      User.remove_user("111")
    end
  end

  test " /user/get_avatar, return 302 when token is invalid" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "invalid token"}
      end
    ] do
      query_params = %{
        "moment_token" => "sfakjflasfla"
      }
      url_with_query = "/user/get_avatar?#{URI.encode_query(query_params)}"
      conn =
        :get
        |> conn(url_with_query)
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
    end
  end

  test " /user/get_avatar, return 500 when server is wrong" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:server_error, "server error"}
      end
    ] do
      query_params = %{
        "moment_token" => "sfakjflasfla"
      }
      url_with_query = "/user/get_avatar?#{URI.encode_query(query_params)}"
      conn =
        :get
        |> conn(url_with_query)
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
    end
  end

  test " /game/detail, return 200 when game exists" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "1"}
      end
    ] do
      BattleInfo.insert_battle("10002", 20, [%{}, %{}])
      query_params = %{
        "game_id" => Integer.to_string(10002),
        "moment_token" => "sfakjflasfla"
      }
      url_with_query = "/game/detail?#{URI.encode_query(query_params)}"
      conn =
        :get
        |> conn(url_with_query)
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      BattleInfo.remove_battle("10002")
    end
  end

  test " /game/detail, return 200 with code 2007 when game not exist" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "1"}
      end
    ] do
      BattleInfo.insert_battle("10002", 20, [%{}, %{}])
      query_params = %{
        "game_id" => Integer.to_string(10003),
        "moment_token" => "sfakjflasfla"
      }
      url_with_query = "/game/detail?#{URI.encode_query(query_params)}"
      conn =
        :get
        |> conn(url_with_query)
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 2007, "error" => "game not exists", "success" => false}
      BattleInfo.remove_battle("10002")
    end
  end

  test " /game/detail, return 302 when token is invalid" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "token invalid"}
      end
    ] do
      BattleInfo.insert_battle("10002", 20, [%{}, %{}])
      query_params = %{
        "game_id" => Integer.to_string(10003),
        "moment_token" => "sfakjflasfla"
      }
      url_with_query = "/game/detail?#{URI.encode_query(query_params)}"
      conn =
        :get
        |> conn(url_with_query)
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
      BattleInfo.remove_battle("10002")
    end
  end

  test " /game/detail, return 500 when server error" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:server_error, "server error"}
      end
    ] do
      BattleInfo.insert_battle("10002", 20, [%{}, %{}])
      query_params = %{
        "game_id" => Integer.to_string(10003),
        "moment_token" => "sfakjflasfla"
      }
      url_with_query = "/game/detail?#{URI.encode_query(query_params)}"
      conn =
        :get
        |> conn(url_with_query)
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
      BattleInfo.remove_battle("10002")
    end
  end

  test "return 200 with insert ai_name on /user/create_ai" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
          {:ok, "1"}
      end
    ] do
      request_body = %{
        "ai_name" => "fuck the world",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/user/create_ai", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => "ok", "success" => true}
    end
  end

  test "return 403 with error message info on /user/create_ai" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
          {:error, "invalid token"}
      end
    ] do
      request_body = %{
        "ai_name" => "fuck the world",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/user/create_ai", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
    end
  end

  test "return 500 with internal error on /user/create_ai" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
          {:server_error, "internal error"}
      end
    ] do
      request_body = %{
        "ai_name" => "fuck the world",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/user/create_ai", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
    end
  end

  test "return 200 with test git on /user/submit_git" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "1"}
      end
    ] do
      request_body = %{
        "git_url" => "git@alibaba-inc.com:battlenet.git",
        "tag" => "1.0",
        "moment_token" => "sfakjflasfla"
      }
      UserAi.insert_ai("1", "牛逼")
      conn =
        :post
        |> conn("/user/submit_git", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => "ok", "success" => true}
      UserAi.clean_message("1")
    end
  end

  test "return 302 code with invalid token on /user/submit_git" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "invalid token"}
      end
    ] do
      request_body = %{
        "git_url" => "git@alibaba-inc.com:battlenet.git",
        "tag" => "1.0",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/user/submit_git", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
    end
  end

  test "return 500 code with internal server error on /user/submit_git" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:internal_error, "server error"}
      end
    ] do
      request_body = %{
        "git_url" => "git@alibaba-inc.com:battlenet.git",
        "tag" => "1.0",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/user/submit_git", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
    end
  end

  test "return 200 code with success when updata git on /user/update_git" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "1"}
      end
    ] do
      UserAi.insert_ai("1", "牛逼")
      request_body = %{
        "git_url" => "git@alibaba-inc.com:battlenet.git",
        "tag" => "1.0",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/user/update_git", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => "ok", "success" => true}
      UserAi.clean_message("1")
    end
  end

  test "return 302 code with invalid token when updata git on /user/update_git" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "invalid token"}
      end
    ] do
      request_body = %{
        "git_url" => "git@alibaba-inc.com:battlenet.git",
        "tag" => "1.0",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/user/update_git", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
    end
  end

  test "return 500 code with internal server error when updata git on /user/update_git" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:server_error, "server error"}
      end
    ] do
      request_body = %{
        "git_url" => "git@alibaba-inc.com:battlenet.git",
        "tag" => "1.0",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/user/update_git", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
    end
  end

  test "return 200 when check processing on /user/check_update" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      BattleResultTest.save_battle_result("111", "first", "牛逼", "git@alibaba-inc.com", "main")
      conn =
        :get
        |> conn("/user/check_update", %{"moment_token" => "sfakjflasfla"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => "processing", "success" => true}
      BattleResultTest.remove_all_battle("111")
    end
  end

  test "return 200 when check success on /user/check_update" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      UserAi.insert_ai("111", "牛逼")
      BattleResultTest.save_battle_result("111", "first", "牛逼", "git@alibaba-inc.com", "main")
      BattleResultTest.update_battle_result("first", "111", "111", [1, 2], ["1g", "2g"], [30, 31])
      conn =
        :get
        |> conn("/user/check_update", %{"moment_token" => "sfakjflasfla"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => "success", "success" => true}
      BattleResultTest.remove_all_battle("111")
      UserAi.clean_message("111")
    end
  end

  test "return 200 when check failed on /user/check_update" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      BattleResultTest.remove_all_battle("111")
      UserAi.insert_ai("111", "牛逼")
      BattleResultTest.save_battle_result("111", "first", "牛逼", "git@alibaba-inc.com", "main")
      BattleResultTest.update_battle_result("first", "111", nil, [1, 2], ["1g", "2g"], [30, 31])
      conn =
        :get
        |> conn("/user/check_update", %{"moment_token" => "sfakjflasfla"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => "failure", "success" => false}
      BattleResultTest.remove_all_battle("111")
      UserAi.clean_message("111")
    end
  end

  test "return 302 when token invalid on /user/check_update" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "invalid token"}
      end
    ] do
      conn =
        :get
        |> conn("/user/check_update", %{"moment_token" => "sfakjflasfla"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
    end
  end

  test "return 500 when server error on /user/check_update" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:server_error, "server error"}
      end
    ] do
      conn =
        :get
        |> conn("/user/check_update", %{"moment_token" => "sfakjflasfla"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
    end
  end

  test "return 200 when no test games on /test/all" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      BattleResultTest.save_battle_result("111", "666", "牛逼", "git@fuckyourselr.com", "maybe")
      conn =
        :get
        |> conn("/test/all", %{"moment_token" => "sgkjaags"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => [], "success" => true}
      BattleResultTest.remove_all_battle("111")
    end
  end

  test "return 200 when test game finish on /test/all" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      BattleResultTest.save_battle_result("111", "666", "牛逼", "git@fuckyourselr.com", "maybe")
      BattleResultTest.update_battle_result("666", "111", nil, [1, 2], ["1g", "2g"], [30, 31])
      conn =
        :get
        |> conn("/test/all", %{"moment_token" => "sgkjaags"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => [%{"black" => %{"game_id" => "666", "memory_cost_black" => "2g", "time_cost_black" => 2, "total_step_black" => 31, "winner" => nil}, "tag" => "maybe", "white" => %{"game_id" => "666", "memory_cost_white" => "1g", "time_cost_white" => 1, "total_step_white" => 30, "winner" => nil}}], "success" => true}
      BattleResultTest.remove_all_battle("111")
    end
  end

  test "return 200 with token info when create test game on /user/create_test" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      request_body = %{"token" => "abcdefghijklmn"}
      conn =
        :post
        |> conn("/user/create_test")
    end
  end
end
