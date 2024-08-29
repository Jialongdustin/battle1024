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
  alias Battle.Mongo.User
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
  @redirect_uri "https://battle1024.ejoy.com/login/redirect"

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, File.read!("priv/static/index.html"))
  end

  ## web
  # 登录验证, 重定向授权网址
  get "/login/one_code" do
    uri = "http://one.ejoy.com/oauth_v3?client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&response_type=code&scope=acl&state=123"
    # uri = "https://one.ejoy.com/oauth?product_code=P11387&redirect_uri=#{@redirect_uri}&client_id=#{@client_id}&scope=acl&state=login&nonce=84680"
    conn
    |> Conn.put_resp_header("location",  uri)
    |> Conn.send_resp(302, "")
    |> Conn.halt()
  end

  get "/login/redirect" do
    access_token = conn.params["code"]
    front_end_url = "https://ieu-battle1024.alibaba.net/login"
    case Auth.verify_code(access_token) do
      {:ok, moment_token} ->
        # 将 code 和 moment_token 作为查询参数添加到 URL
        redirect_url = front_end_url <> "?code=200&moment_token=" <> moment_token
        conn
        |> Conn.put_resp_header("location", redirect_url)
        |> Conn.send_resp(302, "")
        |> Conn.halt()

      {:error, _reason} ->
        # 如果失败，将 code 设为 400，并重定向到前端
        redirect_url = front_end_url <> "?code=403"
        conn
        |> Conn.put_resp_header("location", redirect_url)
        |> Conn.send_resp(302, "")
        |> Conn.halt()
    end
  end

  # 获取某个用户所有对局信息
  get "/user/all" do
    token = conn.params["moment_token"]

    case Token.verify_token(token) do
      {:ok, user_id} ->
        case BattleResult.get_battle_result_by_user_id(user_id) do
          {:ok, game} ->
            body = Ejoy.Jiffy.encode!(%{code: 200, data: game, success: true})
            conn
            |> Conn.put_resp_content_type("application/json")
            |> Conn.send_resp(200, body)
            |> Conn.halt()
          {:error, reason} ->
            body = Ejoy.Jiffy.encode!(%{code: 2003, data: reason, success: false})
            conn
            |> Conn.put_resp_content_type("application/json")
            |> Conn.send_resp(200, body)
            |> Conn.halt()
        end

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
    IO.inspect(moment_token)
    case Token.verify_token(moment_token) do
      {:ok, user_id} ->
        body = case RankList.get_rank_by_user_id(user_id) do
          {:ok, info} ->
            Ejoy.Jiffy.encode!(%{code: 200, data: info, success: true})
          {:error, reason} ->
            Ejoy.Jiffy.encode!(%{code: 2004, data: reason, success: false})
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
    page = conn.params["page"]
    limit = conn.params["limit"]
    case Token.verify_token(moment_token) do
      {:ok, _} ->
        message =
          case RankList.get_rank_list(String.to_integer(page), String.to_integer(limit)) do
            {:ok, rank_list} ->
              %{code: 200, data: rank_list, success: true}
            {:error, message} ->
              %{code: 2004, data: message, success: false}
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

      _ ->
        body = Ejoy.Jiffy.encode!(%{error: "Internal Server Error"})
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(500, body)
        |> Conn.halt()
    end
  end

  # 获取所有用户参赛信息
  get "/game/statistic_info" do
    moment_token = conn.params["moment_token"]
    case Token.verify_token(moment_token) do
      {:ok, _} ->
        message =
          case BattleStatistics.query_statistics_info() do
            {:ok, battle_statistics} ->
              %{
                code: 200,
                data: %{
                  average_step: battle_statistics.average_step,
                  average_time_cost: battle_statistics.average_time_cost,
                  submit_count: battle_statistics.submit_count,
                  user_count: battle_statistics.user_count,
                  last_submit_time: battle_statistics.last_submit_time.ms
                    },
                success: true
              }
            {:error, message} ->
              %{code: 2005, data: message, success: false}
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

      _ ->
        body = Ejoy.Jiffy.encode!(%{error: "Internal Server Error"})
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(500, body)
        |> Conn.halt()
    end
  end

  json_rpc "/user/update_avatar", "schema/user/update_avatar" do
    token = conn.params["moment_token"]
    avatar = conn.params["avatar"]
    case Token.verify_token(token) do
      {:ok, user_id} ->
        User.update_avatar(user_id, avatar)
        body = Ejoy.Jiffy.encode!(%{code: 200, data: "update success", success: true})
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

  get "user/get_avatar" do
    token = conn.params["moment_token"]
    case Token.verify_token(token) do
      {:ok, user_id} ->
        case User.query_user(String.to_integer(user_id)) do
          {:ok, message} ->
            body = Ejoy.Jiffy.encode!(%{code: 200, data: message.avatar, success: true})
            conn
            |> Conn.put_resp_content_type("application/json")
            |> Conn.send_resp(200, body)
            |> Conn.halt()

          {:error, reason} ->
            body = Ejoy.Jiffy.encode!(%{code: 2006, data: reason, success: false})
            conn
            |> Conn.put_resp_content_type("application/json")
            |> Conn.send_resp(200, body)
            |> Conn.halt()
        end

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

  # 复盘
  get "/game/detail" do
    moment_token = conn.params["moment_token"]
    game_id = conn.params["game_id"]
    IO.inspect(game_id)
    case Token.verify_token(moment_token) do
      {:ok, _} ->
        message = case BattleInfo.get_battle_by_game_id(game_id) do
          {:ok, battle_info} ->
            message = %{
            detail: battle_info.detail,
            game_id: battle_info.game_id,
            steps: battle_info.steps
            }
            %{code: 200, data: message, success: true}
          {:error, _} ->
            %{code: 2007, error: "game not exists", success: false}
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
      _ ->
        Logger.error("Unexpected result from verify_code")
        body = Ejoy.Jiffy.encode!(%{error: "Internal Server Error"})
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(500, body)
        |> Conn.halt()
    end
  end

  # 创建ai_name
  json_rpc "/user/create_ai", "schema/user/create_ai" do
    ai_name = conn.params["ai_name"]
    token = conn.params["moment_token"]
    case Token.verify_token(token) do
      {:ok, user_id} ->
        UserAi.insert_ai(user_id, ai_name)
        body = Ejoy.Jiffy.encode!(%{code: 200, data: "ok", success: true})
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

  # 提交git
  json_rpc "/user/submit_git", "schema/user/submit_git" do
    git_url = conn.params["git_url"]
    tag = conn.params["tag"]
    token = conn.params["moment_token"]
    case Token.verify_token(token) do
      {:ok, user_id} ->
        game_id = UUID.uuid4()
        {:ok, user_info} = UserAi.get_newest_ai_by_userId(user_id)
        BattleResultTest.save_battle_result(user_id, game_id, user_info.ai_name, git_url, tag)
        Task.start(fn -> ThreadPoolTest.add_task({git_url, tag, game_id}) end)
        body = Ejoy.Jiffy.encode!(%{code: 200, data: "ok", success: true})
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

  # 检查git的测试结果
  get "/user/check_update" do
    moment_token = conn.params["moment_token"]
    case Token.verify_token(moment_token) do
      {:ok, user_id} ->
        case BattleResultTest.get_result_by_user_id(user_id) do
          {:ok, info} ->
            message = case info.white.winner == nil do
              true ->
                %{"code" => 200, "data" => "failure", "success" => false}
              false ->
                %{"code" => 200, "data" => "success", "success" => true}
            end
            conn
            |> Conn.put_resp_content_type("application/json")
            |> Conn.send_resp(200, Ejoy.Jiffy.encode!(message))
            |> Conn.halt()
          {:processing, _} ->
            conn
            |> Conn.put_resp_content_type("application/json")
            |> Conn.send_resp(200, Ejoy.Jiffy.encode!(%{"code" => 200, "data" => "processing", "success" => true}))
            |> Conn.halt()

          {:error, _} ->
            conn
            |> Conn.put_resp_content_type("application/json")
            |> Conn.send_resp(403, Ejoy.Jiffy.encode!("do not submit git before"))
            |> Conn.halt()
        end

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

  # 查看用户所有测试比赛接口
  get "/test/all" do
    moment_token = conn.params["moment_token"]
    case Token.verify_token(moment_token) do
      {:ok, user_id} ->
        message = case BattleResultTest.get_all_results_by_user_id(user_id) do
          {:error, _} ->
            %{"code" => 200, "data" => [], "success" => true}
          {:ok, info} ->
            %{"code" => 200, "data" => info, "success" => true}
        end
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(200, Ejoy.Jiffy.encode!(message))
        |> Conn.halt()

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

  # 更新git仓库
  json_rpc "/user/update_git", "schema/user/update_git" do
    moment_token = conn.params["moment_token"]
    git_url = conn.params["git_url"]
    tag = conn.params["tag"]
    case Token.verify_token(moment_token) do
      {:ok, user_id} ->
        {:ok, ai_name} = UserAi.get_ai_name(user_id)
        game_id = UUID.uuid4()
        BattleResultTest.save_battle_result(user_id, game_id, ai_name, git_url, tag)
        Task.start(fn -> ThreadPoolTest.add_task({git_url, tag, game_id}) end)
        body = Ejoy.Jiffy.encode!(%{code: 200, data: "ok", success: true})
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
        Logger.error("Unexpected result from verify_code")
        body = Ejoy.Jiffy.encode!(%{error: "Internal Server Error"})
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(500, body)
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

      {:room_error, reason} ->
        body = Ejoy.Jiffy.encode!(reason)
        conn
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(404, body)
        |> Conn.halt()
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
    user_id = user_info.user_id
    game_id = user_info.ext.account_id

    # 检查是否是白棋, 因为对局总是白棋先行
    case RoomSupervisor.query(self(), user_id, game_id) do
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

      {:room_error, reason} ->
          body = Ejoy.Jiffy.encode!(reason)
          conn
          |> Conn.put_resp_content_type("application/json")
          |> Conn.send_resp(404, body)
          |> Conn.halt()
    end
  end

  # 下棋
  json_rpc "/play/move", "schema/play/move" do
    token = conn.params["token"]
    move = conn.params["move"]
    {:ok, user_info} = Token.verify_token_battle(token)
    user_id = user_info.user_id
    game_id = user_info.ext.account_id
    # 处理棋步
    case RoomSupervisor.movement(move, user_id, game_id) do
      {:ok, response} ->
        [{pid, _}] = Registry.lookup(Battle.RoomRegistry, game_id)
        RoomServer.record_time_step(pid, user_id)
        RoomServer.start_cpuntdown(pid)
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
end
