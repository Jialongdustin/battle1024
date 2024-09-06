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
  alias Battle.Service.BattleService.RoomSupervisorTest
  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Service.BattleService.RoomServer

  @opts Router.init([])

  test "return 200 with code 200 on /login/get_token" do
    with_mock Battle.Service.WebService.Auth, [:passthrough], [
      verify_code: fn
        _ ->
          {:ok, "abc"}
      end
    ] do
      conn =
        :get
        |> conn("/login/get_token", %{"code" => "asgkasgag"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => "abc", "success" => true}
    end
  end

  test "return 200 with code 2005 on /login/get_token" do
    with_mock Battle.Service.WebService.Auth, [:passthrough], [
      verify_code: fn
        _ ->
          {:error, "token invalid"}
      end
    ] do
      conn =
        :get
        |> conn("/login/get_token", %{"code" => "asgkasgag"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 2005, "data" => "token invalid", "success" => false}
    end
  end

  test "/user/all, return 200" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      UserAi.insert_ai("111","wawawa")
      UserAi.insert_ai("222","wawawa")
      BattleResult.save_battle_result(["111", "222"], "333", "111", [11, 22], ["11","22"], "111", [20, 30])
      conn =
        :get
        |> conn("/user/all", %{"moment_token" => "asgkasgag"})
        |> Router.call(@opts)
      BattleResult.remove_battle("111")
      UserAi.clean_message("111")
      UserAi.clean_message("222")

      assert conn.state == :sent
      assert conn.status == 200
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
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => [], "success" => true}
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
      UserAi.insert_ai("1", "fuck")
      RankList.save_rank("1", "fuck", 0.8)
      User.save_user("1", "2", "lijialong")
      conn =
        :get
        |> conn("/user/ranking_list")
        |> Router.call(@opts)
      RankList.remove_rank("1")
      UserAi.clean_message("1")
      User.remove_user("1")
      assert conn.state == :sent
      assert conn.status == 200
    end
  end

  test "/user/ranking_list, return 200 with code 2004 when no game of user_id" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "1"}
      end
    ] do
      User.save_user("1", "666", "lijialong")
      UserAi.insert_ai("1", "牛逼")
      conn =
        :get
        |> conn("/user/ranking_list", %{"moment_token" => "asgkasgag"})
        |> Router.call(@opts)
      User.remove_user("1")
      UserAi.clean_message("1")
      assert conn.state == :sent
      assert conn.status == 200
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
      User.save_user("111", "666", "lijialong")
      RankList.save_rank("111", "fuck", 0.98)
      conn =
        :get
        |> conn("/game/ranking_list", %{"page" => "0", "limit" => "2", "moment_token" => "dummy_token"})
        |> Router.call(@opts)
      RankList.remove_rank("111")
      User.remove_user("111")
      assert conn.state == :sent
      assert conn.status == 200
    end
  end

  test "GET /game/ranking_list with pagination, return 200 with code 2004 when no games" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      User.save_user("111", "nibi", "lijialong")
      UserAi.insert_ai("111", "niubi")
      conn =
        :get
        |> conn("/game/ranking_list", %{"page" => "0", "limit" => "2", "moment_token" => "dummy_token"})
        |> Router.call(@opts)
      User.remove_user("111")
      UserAi.clean_message("111")
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => [], "success" => true}
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
      BattleStatistics.delete_message()
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
      User.save_user("111", "415500", "lijialong")
      json_data = %{"avatar" => "aaccbb",
                  "moment_token" => "dummy token"} |> Ejoy.Jiffy.encode!()
      conn =
        :post
        |> conn("/user/update_avatar", json_data)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      User.remove_user("111")
      assert conn.state == :sent
      assert conn.status == 200
    end
  end

  test "/user/update_avatar, return 302 when token is invalid" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "invalid token"}
      end
    ] do
      User.save_user("111", "415500", "lijialong")
      json_data = %{"avatar" => "aaccbb",
                  "moment_token" => "dummy token"} |> Ejoy.Jiffy.encode!()
      conn =
        :post
        |> conn("/user/update_avatar", json_data)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      User.remove_user("111")
      assert conn.state == :sent
      assert conn.status == 302
    end
  end

  test "/user/update_avatar, return 500 when server is wrong" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:server_error, "server error"}
      end
    ] do
      User.save_user("111", "415500", "lijialong")
      json_data = %{"avatar" => "aaccbb",
                  "moment_token" => "dummy token"} |> Ejoy.Jiffy.encode!()
      conn =
        :post
        |> conn("/user/update_avatar", json_data)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      User.remove_user("111")
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
    end
  end

  test " /user/get_avatar, return 200" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      User.save_user("111", "415500", "lijialong")
      query_params = %{
        "moment_token" => "sfakjflasfla"
      }
      url_with_query = "/user/get_avatar?#{URI.encode_query(query_params)}"
      conn =
        :get
        |> conn(url_with_query)
        |> Router.call(@opts)
      User.remove_user("111")
      assert conn.state == :sent
      assert conn.status == 200
    end
  end

  test " /user/get_avatar, return 200 with code 2006 when user not exists" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "222"}
      end
    ] do
      User.save_user("111", "415500", "lijialong")
      query_params = %{
        "moment_token" => "sfakjflasfla"
      }
      url_with_query = "/user/get_avatar?#{URI.encode_query(query_params)}"
      conn =
        :get
        |> conn(url_with_query)
        |> Router.call(@opts)
      User.remove_user("111")
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 2006, "data" => "user_id error", "success" => false}
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
      BattleInfo.remove_battle("10002")
      assert conn.state == :sent
      assert conn.status == 200
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
      BattleInfo.remove_battle("10002")
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => "game not exists", "success" => true}
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
      BattleInfo.remove_battle("10002")
      assert conn.state == :sent
      assert conn.status == 302
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
      BattleInfo.remove_battle("10002")
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
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
      UserAi.clean_message("1")
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
      UserAi.clean_message("1")
      BattleResultTest.remove_all_battle("1")
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => "ok", "success" => true}
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
        "git_url" => "git@gitlab.alibaba-inc.com:Test_elixir/battle1024_python_3.12.5.git",
        "tag" => "dustin",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/user/update_git", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      BattleResultTest.remove_all_battle("1")
      UserAi.clean_message("1")
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => "ok", "success" => true}
    end
  end

  test "return 302 code with invalid token when updata git on /user/update_git" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "invalid token"}
      end
    ] do
      request_body = %{
        "git_url" => "git@gitlab.alibaba-inc.com:Test_elixir/battle1024_python_3.12.5.git",
        "tag" => "dustin",
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
        "git_url" => "git@gitlab.alibaba-inc.com:Test_elixir/battle1024_python_3.12.5.git",
        "tag" => "dustin",
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
      BattleResultTest.remove_all_battle("111")
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => "processing", "success" => true}
    end
  end

  test "return 200 when check success on /user/check_update" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      BattleStatistics.save_init()
      UserAi.insert_ai("111", "牛逼")
      BattleResultTest.save_battle_result("111", "first", "牛逼", "git@alibaba-inc.com", "main")
      BattleResultTest.update_battle_result("first", "false", "111", [1, 2], ["1g", "2g"], [30, 31])
      {:ok, info} = BattleResultTest.get_result_by_user_id("111")
      IO.inspect(info)
      conn =
        :get
        |> conn("/user/check_update", %{"moment_token" => "sfakjflasfla"})
        |> Router.call(@opts)
      BattleResultTest.remove_all_battle("111")
      UserAi.clean_message("111")
      BattleStatistics.delete_message()
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => "success", "success" => true}
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
      BattleResultTest.update_battle_result("first", nil, nil, [1, 2], ["1g", "2g"], [30, 31], 2002)
      conn =
        :get
        |> conn("/user/check_update", %{"moment_token" => "sfakjflasfla"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 200, "data" => "failure", "success" => true}
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

  test "return 302 when token invalid on /test/all" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "invalid token"}
      end
    ] do
      conn =
        :get
        |> conn("/test/all", %{"moment_token" => "sgkjaags"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
    end
  end

  test "return 500 when server error on /test/all" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:server_error, "server error"}
      end
    ] do
      conn =
        :get
        |> conn("/test/all", %{"moment_token" => "sgkjaags"})
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
    end
  end

  test "return 200 with token info when create test game on /user/create_test" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, "111"}
      end
    ] do
      request_body = %{"moment_token" => "abcdefghijklmn"}
      conn =
        :post
        |> conn("/user/create_test", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Map.keys(Ejoy.Jiffy.decode!(conn.resp_body)) == ["code", "data", "success"]
    end
  end

  test "return 302 with invalid token when create test game on /user/create_test" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "invalid token"}
      end
    ] do
      request_body = %{"moment_token" => "abcdefghijklmn"}
      conn =
        :post
        |> conn("/user/create_test", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 302
    end
  end

  test "return 500 with internal server error when create test game on /user/create_test" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:server_error, "internal server error"}
      end
    ] do
      request_body = %{"moment_token" => "abcdefghijklmn"}
      conn =
        :post
        |> conn("/user/create_test", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
    end
  end

  test "return 200 with token info when white query test game on /test/query" do
    {:ok, info} = RoomSupervisorTest.init_game()
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token_battle: fn _ ->
        {:ok, %{user_id: "10", ext: %{game_id: info.game_id}}}
      end
    ] do
      request_body = %{"token" => info.token_white}
      conn =
        :post
        |> conn("/test/query", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Map.keys(Ejoy.Jiffy.decode!(conn.resp_body)) == ["board", "code", "winner"]
    end
  end

  test "return 404 with token info when black query test game on /test/query" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token_battle: fn _ ->
        {:ok, %{user_id: "24", ext: %{game_id: "111"}}}
      end
    ] do
      request_body = %{"token" => "abcsdaslfg"}
      conn =
        :post
        |> conn("/test/query", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 404
      assert Ejoy.Jiffy.decode!(conn.resp_body) == "game is over, do not query again"
    end
  end

  test "return 200 with game info when white move in test game on /test/move" do
    {:ok, info} = RoomSupervisorTest.init_game()
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token_battle: fn _ ->
        {:ok, %{user_id: "10", ext: %{game_id: info.game_id}}}
      end
    ] do
      request_body = %{"token" => info.token_white, "move" => [["a", "6"], ["a", "5"]]}
      conn =
        :post
        |> conn("/test/move", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Map.keys(Ejoy.Jiffy.decode!(conn.resp_body)) == ["board", "code", "king", "move_detail", "winner"]
    end
  end

  test "return 400 with illegal move when white move in test game on /test/move" do
    {:ok, info} = RoomSupervisorTest.init_game()
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token_battle: fn _ ->
        {:ok, %{user_id: "10", ext: %{game_id: info.game_id}}}
      end
    ] do
      request_body = %{"token" => info.token_white, "move" => [["a", "3"], ["a", "4"]]}
      conn =
        :post
        |> conn("/test/move", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 400
      assert Map.keys(Ejoy.Jiffy.decode!(conn.resp_body)) == ["board", "code", "king", "move_detail", "winner"]
    end
  end

  test "return 200 with game info when white query formal game on /play/query" do
    {:ok, info} = RoomSupervisor.init_game("10", "24", "saklgaks", "1", "2", "3")
    [{pid, _}] = Registry.lookup(Battle.RoomRegistry, "saklgaks")
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token_battle: fn _ ->
        {:ok, %{user_id: "10", ext: %{game_id: "saklgaks"}}}
      end
    ] do
      request_body = %{"token" => "aslkfgasg"}
      conn =
        :post
        |> conn("/play/query", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Map.keys(Ejoy.Jiffy.decode!(conn.resp_body)) == ["board", "code", "winner"]
      RoomServer.terminate_game_test(pid)
    end
  end

  test "return 404 with game info when white query formal game on /play/query" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token_battle: fn _ ->
        {:ok, %{user_id: "10", ext: %{game_id: "saklgaks"}}}
      end
    ] do
      request_body = %{"token" => "aslkfgasg"}
      conn =
        :post
        |> conn("/play/query", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 404
      assert Ejoy.Jiffy.decode!(conn.resp_body) == "game is over, do not query again"
    end
  end

  test "return 200 with game info when white move in formal game on /play/move" do
    {:ok, info} = RoomSupervisor.init_game("10", "24", "saklgaks", "1", "2", "3")
    [{pid, _}] = Registry.lookup(Battle.RoomRegistry, "saklgaks")
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token_battle: fn _ ->
        {:ok, %{user_id: "10", ext: %{game_id: "saklgaks"}}}
      end
    ] do
      RoomServer.start_time_step(pid)
      request_body = %{"token" => "askfasfkasf", "move" => [["a", "6"], ["a", "5"]]}
      conn =
        :post
        |> conn("/play/move", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Map.keys(Ejoy.Jiffy.decode!(conn.resp_body)) == ["board", "code", "king", "move_detail", "winner"]
      RoomServer.terminate_game_test(pid)
    end
  end

  test "return 400 with game info when white move illegal or room not exists in formal game on /play/move" do
    {:ok, info} = RoomSupervisor.init_game("10", "24", "saklgaks", "1", "2", "3")
    [{pid, _}] = Registry.lookup(Battle.RoomRegistry, "saklgaks")
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token_battle: fn _ ->
        {:ok, %{user_id: "10", ext: %{game_id: "666"}}}
      end
    ] do
      RoomServer.start_time_step(pid)
      request_body = %{"token" => "askfasfkasf", "move" => [["a", "3"], ["a", "4"]]}
      conn =
        :post
        |> conn("/play/move", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 400
      assert Ejoy.Jiffy.decode!(conn.resp_body) == "room not found"
      RoomServer.terminate_game_test(pid)
    end
  end

end
