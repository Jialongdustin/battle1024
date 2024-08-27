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

  @opts Router.init([])

  test "redirects to the correct URL on /login/one_code" do
    expected_url = "http://one.ejoy.com/oauth_v3?client_id=10052&redirect_uri=http://localhost:4000/login/redirect&response_type=code&scope=acl&state=123"
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
          {:ok, %{user_id: 1, name: "ljl"}}
      end
    ] do
      conn =
        :get
        |> conn("/login/redirect", "")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"user_id" => 1, "name" => "ljl"}
      assert conn.status == 200
    end
  end

  test "return 302 with error message on /login/redirect with invalid code" do
    with_mock Battle.Service.WebService.Auth, [:passthrough], [
      verify_code: fn _ -> {:error, "one_code_error"} end
    ] do
      conn =
        :get
        |> conn("/login/redirect", "")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
    end
  end

  test "/user/all, return 200" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "123"}
      end
    ] do
      conn =
        :get
        |> conn("/user/all", "")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      IO.inspect(Ejoy.Jiffy.decode!(conn.resp_body))
    end
  end

  test "/user/ranking_list, return 200" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "1"}
      end
    ] do
      conn =
        :get
        |> conn("/user/ranking_list", "")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      IO.inspect(Ejoy.Jiffy.decode!(conn.resp_body))
    end
  end

  test "GET /game/ranking_list with pagination, return 200" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "1"}
      end
    ] do
      RankList.save_rank()
      conn =
        :get
        |> conn("/game/ranking_list", %{"page" => "0", "limit" => "2", "moment_token" => "dummy_token"})
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200

      response = Ejoy.Jiffy.decode!(conn.resp_body)
      IO.inspect(response)
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
          {:ok, 1}
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
end
