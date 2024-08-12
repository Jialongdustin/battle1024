defmodule Battle.Web.Router do
  use Plug.Router
  use Ejoy.Plug.ErrorHandler
  use Ejoy.Plug.JsonResp2 , return_code_module: Battle.Utils.ReturnCode

  alias Plug.Conn
  alias Battle.Service.WebService.Auth
  alias Battle.Utils.Token
  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Service.BattleService.RoomServer
  alias Battle.Mongo.BattleInfo
  alias Battle.Mongo.BattleStatistics
  alias Battle.Mongo.RankList
  alias Battle.Mongo.UserAi
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

  @client_id 10052
  @redirect_uri "http://localhost:4000/login/redirect"

  ## web
  # 登录验证, 重定向授权网址
  get "/login/one_code" do
    uri = "http://one.ejoy.com/oauth_v3?client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&response_type=code&scope=acl&state=123"
    conn
    |> Conn.put_resp_header("Location",  uri)
    |> Conn.send_resp(302, "")
    |> Conn.halt()
  end

  # 根据生成moment_token
  get "/login/redirect" do
    code = conn.params["code"]

    case Auth.verify_code(code) do
      {:ok, user} ->
        Logger.info(user)
        body = Ejoy.Jiffy.encode!(user)
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()

      {:error, reason} ->  # 假设 `verify_code` 中的错误返回格式为 {:error, reason}
        Logger.error("Verification failed: #{inspect(reason)}")
        body = Ejoy.Jiffy.encode!(%{error: "Permission refused"})
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(403, body)
        |> Conn.halt()

      _ ->
        Logger.error("Unexpected result from verify_code")
        body = Ejoy.Jiffy.encode!(%{error: "Internal Server Error"})
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(500, body)
        |> Conn.halt()
    end
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
    body = Ejoy.Jiffy.encode!(%{code: 0, message: "ok", state: "test successful"})
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(200, body)
    |> Conn.halt()
  end

  # 获取战斗力排行榜
  get "/contest/ranking_list" do
    moment_token = conn.params["moment_token"]
    case Token.verify_token(moment_token) do
      {:ok, _} ->
        message = case RankList.get_rank_list() do
          {:ok, rank_list} ->
            %{rank_list: rank_list}
          {:error, message} ->
            %{error: message}
        end
        body = Ejoy.Jiffy.encode!(message)
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()
      {:error, message} ->
        body = Ejoy.Jiffy.encode!(%{error: message})
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(403, body)
        |> Conn.halt()
    end
  end

  # 获取所有用户参赛信息
  get "/contest/all_user_info" do
    moment_token = conn.params["moment_token"]
    case Token.verify_token(moment_token) do
      {:ok, _} ->
        message =  case BattleStatistics.query_statistics_info() do
          {:ok, battle_statistics} ->
            %{battle_statistics: battle_statistics}
          {:error, message} ->
            %{error: message}
        end
        body = Ejoy.Jiffy.encode!(message)
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()
      {:error, message} ->
        body = Ejoy.Jiffy.encode!(%{error: message})
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(403, body)
        |> Conn.halt()
    end
  end

  # 更新git仓库
  json_rpc "/user/update_git", "schema/user/update_git" do
    moment_token = conn.params["moment_token"]
    git_url = conn.params["git"]
    body = Ejoy.Jiffy.encode!(%{code: 0, message: "ok"})
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(200, body)
    |> Conn.halt()
  end

  # 复盘
  get "/contest/one_contest_details" do
    moment_token = conn.params["moment_token"]
    contest_id = conn.params["contest_id"]
    case Token.verify_token(moment_token) do
      {:ok, user_id} ->
        message = case BattleInfo.get_battle_by_contest_id(contest_id) do
            {:ok, battle_info} ->
              %{battle_info: battle_info}
            {:error, _} ->
              %{error: "contest not exists"}
        end
        body = Ejoy.Jiffy.encode!(message)
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()
      {:error, message} ->
        body = Ejoy.Jiffy.encode!(%{error: message})
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(403, body)
        |> Conn.halt()
    end
  end


  ## battle
  # 加入棋局, 棋局初始化
  json_rpc "/play/init", "schema/play/init" do
    moment_token = params["moment_token"]
    {:ok,response} = RoomSupervisor.join(moment_token)
    body = Ejoy.Jiffy.encode!(response)
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(200, body)
    |> Conn.halt()
  end

  # 下棋
  json_rpc "/play/one_step_chess", "schema/play/one_step_chess" do
    moment_token = params["moment_token"]
    move = params["move"]
#    resp = RoomSupervisor
    {:ok,response} = RoomSupervisor.battle_handler(move,moment_token)
    body = Ejoy.Jiffy.encode!(response)
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(200, body)
    |> Conn.halt()   #  用于结束连接的处理, 防止后续的Plug继续对该连接进行处理
  end

end
