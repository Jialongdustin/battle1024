defmodule Battle.Web.Router do
  use Plug.Router
  use Ejoy.Plug.ErrorHandler
  use Ejoy.Plug.JsonResp2, return_code_module: Battle.Utils.ReturnCode

  alias Plug.Conn
  alias Battle.Service.WebService.Auth
  alias Battle.Utils.Token
  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Service.BattleService.RoomSupervisorTest
  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Service.BattleService.RoomServer
  alias Battle.Mongo.BattleInfo
  alias Battle.Mongo.BattleStatistics
  alias Battle.Mongo.RankList
  alias Battle.Mongo.UserAi
  alias Battle.Mongo.BattleResult
  alias Battle.Mongo.BattleResultTest
  alias Battle.Service.WebService.WebSocketHandler
  alias Battle.Service.BattleService.ThreadPoolTest
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
  @redirect_uri "http://battle1024.ejoy.com/login/redirect"

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, File.read!("priv/static/index.html"))
  end

  ## web
  # 登录验证, 重定向授权网址
  get "/login/one_code" do
    uri = "http://one.ejoy.com/oauth_v3?client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&response_type=code&scope=acl&state=123"
    conn
    |> Conn.put_resp_header("location",  uri)
    |> Conn.send_resp(302, "")
    |> Conn.halt()
  end

  # 根据生成moment_token
  get "/login/redirect" do
    code = conn.params["code"]

    case Auth.verify_code(code) do
      {:ok, user} ->
        body = Ejoy.Jiffy.encode!(user)
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()

      # 假设 `verify_code` 中的错误返回格式为 {:error, reason}
      {:error, _} ->
        uri = "http://one.ejoy.com/oauth_v3?client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&response_type=code&scope=acl&state=123"
        conn
        |> Conn.put_resp_header("location",  uri)
        |> Conn.send_resp(302, "")
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

  # 获取某个用户所有对局信息
  get "/user/all_games_info" do
    token = conn.params["moment_token"]

    case Token.verify_token(token) do
      {:ok, user_id} ->
        {:ok, game} = BattleResult.get_battle_result_by_user_id(String.to_integer(user_id))
        body = Ejoy.Jiffy.encode!(%{code: 200, state: game})
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()

      {:error, _} ->
        uri = "http://one.ejoy.com/oauth_v3?client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&response_type=code&scope=acl&state=123"
        conn
        |> Conn.put_resp_header("location",  uri)
        |> Conn.send_resp(302, "")
        |> Conn.halt()

      _ ->
        body = Ejoy.Jiffy.encode!(%{error: "Internal Server Error"})
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(500, body)
        |> Conn.halt()
    end
  end

  # 获取某个用户的排名信息
  get "/user/ranking_list" do
    moment_token = conn.params["moment_token"]
    case Token.verify_token(moment_token) do
      {:ok, user_id} ->

        body = case RankList.get_rank_by_user_id(String.to_integer(user_id)) do
          {:ok, info} ->
            Ejoy.Jiffy.encode!(%{code: 200, state: info})
          {:error, message} ->
            Ejoy.Jiffy.encode!(%{error: message})
        end
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()

        {:error, _} ->
          uri = "http://one.ejoy.com/oauth_v3?client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&response_type=code&scope=acl&state=123"
          conn
          |> Conn.put_resp_header("location",  uri)
          |> Conn.send_resp(302, "")
          |> Conn.halt()

      _ ->
        body = Ejoy.Jiffy.encode!(%{error: "Internal Server Error"})
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(500, body)
        |> Conn.halt()
    end
  end

  # 获取胜率排行榜
  get "/game/ranking_list" do
    moment_token = conn.params["moment_token"]
    case Token.verify_token(moment_token) do
      {:ok, _} ->
        message =
          case RankList.get_rank_list() do
            {:ok, rank_list} ->
              %{code: 200, rank_list: rank_list}
            {:error, message} ->
              %{code: 403, error: message}
          end
        body = Ejoy.Jiffy.encode!(message)
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()

      {:error, _} ->
        uri = "http://one.ejoy.com/oauth_v3?client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&response_type=code&scope=acl&state=123"
        conn
        |> Conn.put_resp_header("location",  uri)
        |> Conn.send_resp(302, "")
        |> Conn.halt()
    end
  end

  # 获取所有用户参赛信息
  get "/game/all_users_info" do
    moment_token = conn.params["moment_token"]
    case Token.verify_token(moment_token) do
      {:ok, _} ->
        message =
          case BattleStatistics.query_statistics_info() do
            {:ok, battle_statistics} ->
              %{
                code: 200,
                average_step: battle_statistics.average_step,
                average_time_cost: battle_statistics.average_time_cost,
                submit_count: battle_statistics.submit_count,
                user_count: battle_statistics.user_count
              }

            {:error, message} ->
              %{error: message}
          end
        body = Ejoy.Jiffy.encode!(message)
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()

      {:error, _} ->
        uri = "http://one.ejoy.com/oauth_v3?client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&response_type=code&scope=acl&state=123"
        conn
        |> Conn.put_resp_header("location",  uri)
        |> Conn.send_resp(302, "")
        |> Conn.halt()
    end
  end

  json_rpc "/user/update_avatar", "schema/user/create_AI" do
    token = conn.params["moment_token"]


  end

  # 复盘
  get "/game/detail" do
    moment_token = conn.params["moment_token"]
    game_id = conn.params["game_id"]
    case Token.verify_token(moment_token) do
      {:ok, user_id} ->
        message = case BattleInfo.get_battle_by_game_id(game_id) do
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

      {:error, _} ->
        uri = "http://one.ejoy.com/oauth_v3?client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&response_type=code&scope=acl&state=123"
        conn
        |> Conn.put_resp_header("location",  uri)
        |> Conn.send_resp(302, "")
        |> Conn.halt()
    end
  end

  # 创建AI
  json_rpc "/user/create_AI", "schema/user/create_AI" do
    ai_name = conn.params["ai_name"]
    git_url = conn.params["git_url"]
    tag = conn.params["tag"]
    token = conn.params["moment_token"]
    case Token.verify_token(token) do
      {:ok, user_id} ->
        game_id = UUID.uuid4()
        BattleResultTest.save_battle_result(user_id, game_id, ai_name, git_url, tag)
        Task.start(fn -> ThreadPoolTest.add_task({git_url, tag, game_id}) end)
        # BattleStatistics.submit_increment()
        # UserAi.insert_ai(user_id, ai_name, git_url, tag)
        body = Ejoy.Jiffy.encode!(%{code: 0, message: "ok", state: "testing now"})
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()

      {:error, _} ->  # 假设 `verify_code` 中的错误返回格式为 {:error, reason}
        uri = "http://one.ejoy.com/oauth_v3?client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&response_type=code&scope=acl&state=123"
        conn
        |> Conn.put_resp_header("location",  uri)
        |> Conn.send_resp(302, "")
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

  # 更新git仓库
  json_rpc "/user/update_git", "schema/user/update_git" do
    moment_token = conn.params["moment_token"]
    git_url = conn.params["git"]
    ai_name = conn.params["ai_name"]
    tag = conn.params["tag"]
    case Token.verify_token(moment_token) do
      {:ok, user_id} ->
        game_id = UUID.uuid4()
        BattleResultTest.save_battle_result(user_id, game_id, ai_name, git_url, tag)
        Task.start(fn -> ThreadPoolTest.add_task({git_url, tag, game_id}) end)
        body = Ejoy.Jiffy.encode!(%{code: 0, message: "ok", state: "testing now"})
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()

      {:error, _} ->
        uri = "http://one.ejoy.com/oauth_v3?client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&response_type=code&scope=acl&state=123"
        conn
        |> Conn.put_resp_header("location",  uri)
        |> Conn.send_resp(302, "")
        |> Conn.halt()
    end
end

  # 创建测试比赛
  json_rpc "/user/create_test", "schema/user/create_test" do
    token = conn.params["moment_token"]
    case Token.verify_token(token) do
      {:ok, _} ->
        # 初始化测试对局, 返回黑棋和白棋的token
        {:ok, info} = RoomSupervisorTest.init_game()
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, Ejoy.Jiffy.encode!(info))
        |> Conn.halt()

      {:error, _} ->  # 假设 `verify_code` 中的错误返回格式为 {:error, reason}
        uri = "http://one.ejoy.com/oauth_v3?client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&response_type=code&scope=acl&state=123"
        conn
        |> Conn.put_resp_header("location",  uri)
        |> Conn.send_resp(302, "")
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

  # 创建测试比赛后 用户的两个机器人分别初始化拿到棋盘信息
  json_rpc "/test/query", "schema/test/query" do
    token = conn.params["token"]
    {:ok, user_info} = Token.verify_token_battle(token)
    user_id = String.to_integer(user_info.user_id)
    game_id = user_info.ext.account_id

    # 检查是否是白棋, 因为对局总是白棋先行
    case RoomSupervisorTest.query(self(), user_id, game_id) do
      {:ok, detail} ->
        body = Ejoy.Jiffy.encode!(detail)
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()
      {:error, _} ->
        receive do
          {:query, detail} ->
            body = Ejoy.Jiffy.encode!(detail)
            conn
            |> Conn.put_resp_content_type("application/json")
            |> Conn.send_resp(200, body)
            |> Conn.halt()
        end
    end
  end

  # 用户测试比赛时的下棋移动接口
  json_rpc "/test/move", "schema/test/move" do
    token = conn.params["token"]
    moves = conn.params["move"]
    {:ok, user_info} = Token.verify_token_battle(token)
    user_id = String.to_integer(user_info.user_id)
    game_id = user_info.ext.account_id

    case RoomSupervisorTest.movement(moves, user_id, game_id) do
      {:ok, response} ->
        body = Ejoy.Jiffy.encode!(response)
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()

      {:error, reason} ->
        body = Ejoy.Jiffy.encode!(reason)
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(400, body)
        |> Conn.halt()
    end
  end

  # kun上发布机器人应用后会发这个请求初始化接口
  json_rpc "/play/query", "schema/play/query" do
    token = conn.params["token"]
    {:ok, user_info} = Token.verify_token_battle(token)
    user_id = String.to_integer(user_info.user_id)
    game_id = user_info.ext.account_id

    # 检查是否是白棋, 因为对局总是白棋先行
    case RoomSupervisor.query(self(), user_id, game_id) do
      {:ok, detail} ->
        [{pid, _}] = Registry.lookup(Battle.RoomRegistry, game_id)
        RoomServer.start_countdown(pid)
        RoomServer.start_time_step(pid, user_id)
        body = Ejoy.Jiffy.encode!(detail)
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()
      {:error, _} ->
        receive do
          {:query, detail} ->
            if detail.winner == nil do
              [{pid, _}] = Registry.lookup(Battle.RoomRegistry, game_id)
              RoomServer.start_countdown(pid)
              RoomServer.start_time_step(pid, user_id)
            end
            body = Ejoy.Jiffy.encode!(detail)
            conn
            |> Conn.put_resp_content_type("application/json")
            |> Conn.send_resp(200, body)
            |> Conn.halt()
        end
    end
  end

  # 下棋
  json_rpc "/play/move", "schema/play/move" do
    token = conn.params["token"]
    move = conn.params["move"]
    {:ok, user_info} = Token.verify_token_battle(token)
    user_id = String.to_integer(user_info.user_id)
    game_id = user_info.ext.account_id
    # 处理棋步
    case RoomSupervisor.movement(move, user_id, game_id) do
      {:ok, response} ->
        [{pid, _}] = Registry.lookup(Battle.RoomRegistry, game_id)
        RoomServer.record_time_step(pid, user_id)
        body = Ejoy.Jiffy.encode!(response)
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, body)
        |> Conn.halt()

      {:error, reason} ->
        body = Ejoy.Jiffy.encode!(reason)
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(400, body)
        |> Conn.halt()
    end
  end

  # 将用户创建测试比赛的http请求升级为websocket
  get "/test/websocket" do
    conn
    |> WebSockAdapter.upgrade(WebSocketHandler, [self()], timeout: :infinity)
    |> halt()
  end
end
