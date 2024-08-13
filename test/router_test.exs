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

  test "return 200 with user info on /login/redirect with valid cade" do
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
      assert Jason.decode!(conn.resp_body) == %{"user_id" => 1, "name" => "ljl"}
      assert conn.status == 200
    end
  end
end
