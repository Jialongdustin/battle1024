defmodule Battle.Web.Router do
  use Plug.Router
  use Ejoy.Plug.ErrorHandler
  use Ejoy.Plug.JsonResp2 , return_code_module: Battle.Utils.ReturnCode

  alias Plug.Conn
  require Logger

  plug(:match)
  # plug Battle.Plug.Session,
  # [store: Battle.Plug.RedisSessionStore]
  # |> Keyword.merge(Const.session_opts())

  plug(Ejoy.Plug.Prometheus, ignore_http_count: true, source: "admin_center")
  plug(Plug.Parsers, parsers: [:urlencoded, :multipart, Plug.Parsers.Jiffy], length: 20_000_000)
  use Ejoy.Plug.JsonRPC
  plug(Ejoy.Plug.Logger)

  plug(:dispatch)

  # def send_json_resp(ret, conn) do
  #   case ret do
  #     {:error, err, resp} -> send_json(conn, err, resp)
  #     _ -> send_json(conn, ret)
  #   end
  # end

  # def set_auth_state(conn) do
  #   state = :crypto.strong_rand_bytes(10) |> Base.encode64()
  #   conn =
  #     conn
  #     |> Conn.fetch_session()
  #     |> Conn.put_session(@one_auth_state_key, state)
  #   {conn, state}
  # end

  # json_rpc "/login/one_prepare", "schema/login/one_prepare" do
  #   {conn, state} = set_auth_state(conn)
  #   send_json_resp(%{state: state}, conn)
  # end

  # 下棋
  json_rpc "/play/one_step_chess", "schema/play/one_step_chess" do
    move = params["move"]
    body = Ejoy.Jiffy.encode!(%{code: 0, message: "ok"})
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(200, body)
    |> Conn.halt()   #  用于结束连接的处理, 防止后续的Plug继续对该连接进行处理
  end

  # 创建AI
  json_rpc "/user/create_AI", "schema/user/create_AI" do
    user_id = params["user_id"]
    ai_name = params["ai_name"]
    body = Ejoy.Jiffy.encode!(%{code: 0, message: "ok", state: "create AI done"})
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(200, body)
    |> Conn.halt()
  end

  # 测试AI
  json_rpc "/contest/test_AI", "schema/play/test_AI" do
    body = Ejoy.Jiffy.encode!(%{code: 0, message: "ok", state: "test successful"})
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(200, body)
    |> Conn.halt()
  end

  # 获取某个用户所有对局信息
  get "/user/all_contests_info" do

  end

  # 获取战斗力排行榜
  get "/contest/ranking_list" do
      code = conn.params["code"]
      body = Ejoy.Jiffy.encode!(%{code: 0, message: "ok", state: "test successful"})
      conn
      |> Conn.put_resp_content_type("application/json")
      |> Conn.send_resp(200, body)
      |> Conn.halt()
  end

  # 获取所有用户参赛信息
  get "/contest/all_user_info" do

  end

  # 更新git仓库
  json_rpc "/user/update_git", "schema/user/update_git" do
    git_url = params["git"]
    body = Ejoy.Jiffy.encode!(%{code: 0, message: "ok"})
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(200, body)
    |> Conn.halt()
  end

  复盘
  get "/user/one_contest_details" do

  end
end
