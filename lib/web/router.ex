defmodule Battle.Router do
  use Plug.Router
  use Ejoy.Plug.ErrorHandler

  alias Plug.Conn
  require Logger

  plug(:match)

  plug(Plug.Parsers, parsers: [:urlencoded, :multipart, Plug.Parsers.Jiffy], length: 20_000_000)
  use Ejoy.Plug.JsonRPC

  plug(:dispatch)

  @client_id 10052
  @redirect_uri "http://localhost:8080/login/redirect"



  get "/login/one_code" do
    uri = "http://one.ejoy.com/oauth_v3?client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&response_type=code&scope=acl&state=123"
    conn
    |> Plug.Conn.put_resp_header("Location",  uri)
    |> Plug.Conn.send_resp(302, "")
    |> Plug.Conn.halt()
  end


  get "/login/redirect" do
    code = conn.params["code"]
    Logger.info("Received code: #{code}")

    case OneDemo2.Auth.verify_code(code) do
      {:ok, user} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(user))

      {:error, reason} ->  # 假设 `verify_code` 中的错误返回格式为 {:error, reason}
        Logger.error("Verification failed: #{inspect(reason)}")
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{error: "Permission refused"}))

      _ ->
        Logger.error("Unexpected result from verify_code")
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{error: "Internal Server Error"}))
    end
  end
end
