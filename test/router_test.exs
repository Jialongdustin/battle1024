defmodule BattleTest.RouterTest do
  use ExUnit.Case
  use Plug.Test
  import Mock
  doctest Battle.Web.Router

  alias Battle.Web.Router

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

  test "return 403 with error message on /login/redirect with invalid code" do
    with_mock Battle.Service.WebService.Auth, [:passthrough], [
      verify_code: fn _ -> {:error, "one_code_error"} end
    ] do
      conn =
        :get
        |> conn("/login/redirect", "")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 403
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "one_code_error"}
    end
  end

  test "return 500 with internal error on /login/redirect with server error" do
    with_mock Battle.Service.WebService.Auth, [:passthrough], [
      verify_code: fn _ ->
        {:server_error, "internal server error"}
      end
    ] do
      conn =
        :get
        |> conn("/login/redirect", "")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
    end
  end

  test "return 200 with insert AI info on /user/create_AI" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
          {:ok, 1}
      end
    ] do
      request_body = %{
        "ai_name" => "fuck the world",
        "git_url" => "git@alibaba-inc.com:battlenet.git",
        "tag" => "1.0",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/user/create_AI", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 0, "message" => "ok", "state" => "create successful"}
      Battle.UserAi.clean_message(1)
    end
  end

  test "return 403 with error message info on /user/create_AI" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
          {:error, "invalid token"}
      end
    ] do
      request_body = %{
        "ai_name" => "fuck the world",
        "git_url" => "git@alibaba-inc.com:battlenet.git",
        "tag" => "1.0",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/user/create_AI", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 403
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "invalid token"}
    end
  end

  test "return 500 with internal error on /user/create_AI" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
          {:server_error, "internal error"}
      end
    ] do
      request_body = %{
        "ai_name" => "fuck the world",
        "git_url" => "git@alibaba-inc.com:battlenet.git",
        "tag" => "1.0",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/user/create_AI", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
    end
  end

  test "return 200 code with create AI testing game on /contest/test_AI" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, 1}
      end
    ] do
      request_body = %{
        "ai_name" => "fuck the world",
        "git_url" => "git@alibaba-inc.com:battlenet.git",
        "tag" => "1.0",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/contest/test_AI", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 0, "message" => "ok", "state" => "test successful"}
    end
  end

  test "return 403 code with invalid token when create test game on /contest/test_AI" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:error, "invalid token"}
      end
    ] do
      request_body = %{
        "ai_name" => "fuck the world",
        "git_url" => "git@alibaba-inc.com:battlenet.git",
        "tag" => "1.0",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/contest/test_AI", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 403
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "invalid token"}
    end
  end

  test "return 500 code with internal error when create AI testing game on /contest/test_AI" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:internal_error, "server error"}
      end
    ] do
      request_body = %{
        "ai_name" => "fuck the world",
        "git_url" => "git@alibaba-inc.com:battlenet.git",
        "tag" => "1.0",
        "moment_token" => "sfakjflasfla"
      }
      conn =
        :post
        |> conn("/contest/test_AI", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 500
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"error" => "Internal Server Error"}
    end
  end

  test "get all info of one user on /user/all_contests_info" do
    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token: fn _ ->
        {:ok, 1}
      end
    ] do
      conn =
        :get
        |> conn("/user/all_contests_info", "")
        |> Router.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
      assert Ejoy.Jiffy.decode!(conn.resp_body) == %{"code" => 0, "message" => "ok", "state" => []}
    end
  end
end
