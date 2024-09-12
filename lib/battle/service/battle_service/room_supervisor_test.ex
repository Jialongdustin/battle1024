defmodule Battle.Service.BattleService.RoomSupervisorTest do
  use DynamicSupervisor

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Service.WebService.Kun
  alias Battle.Utils.Token
  alias Battle.Utils.Convert

  @service_groups ["battle-test6", "battle-test7", "battle-test8", "battle-test9", "battle-test10", "battle-test11", "battle-test12", "battle-test13", "battle-test14", "battle-test15",
                  "battle-test16", "battle-test17", "battle-test18", "battle-test19", "battle-test20"]
  @appNames ["battle-player-python", "battle-player-lua", "battle-player-java", "battle-player-c"]
  @package_name "plat1024-lingxigou:20240911142041"

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ets.new(:pid_info_test, [:named_table, :public, read_concurrency: true])
    :ets.new(:services_ai, [:named_table, :public, read_concurrency: true])
    Enum.each(@service_groups, fn group_name ->
      Enum.each(@appNames, fn app_name ->
        case :ets.lookup(:services_ai, group_name) do
          [] ->
            :ets.insert(:services_ai, {group_name, [app_name]})
          [{group_name, app_name_old}] ->
            :ets.insert(:services_ai, {group_name, [app_name | app_name_old]})
        end
      end)
    end)
    opts = [strategy: :one_for_one]
    DynamicSupervisor.init(opts)
  end

  # game_id = "d9279888-1962-494c-aed9-1058dfd2805a"
  def init_game(user_id, white) do
    case get_first_and_pop() do
      {:ok, {groupName, appName}} ->
        game_id = UUID.uuid4()
        IO.inspect(game_id)
        {:ok, token_user} = Token.generate_token(user_id, game_id)
        {:ok, token_ai} = Token.generate_token("1024", game_id)
        child_spec_server = %{
          id: RoomServer,
          start: {RoomServer, :start_link, [%{white: if(white, do: user_id, else: "1024"), black: if(white, do: "1024", else: user_id), game_id: game_id, groupName: groupName, groupKey: groupName, appName: appName}]},
          restart: :transient,
          type: :worker
        }
        DynamicSupervisor.start_child(__MODULE__, child_spec_server)
        [{pid, _}] = Registry.lookup(Battle.RoomRegistry, game_id)
        RoomServer.start_countdown(pid, true)
        start_ai_service(groupName, appName, token_ai, white)
        {:ok, %{
          token: token_user,
          game_id: game_id
        }}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def query(caller, user_id, game_id) do
    case Registry.lookup(Battle.RoomRegistry, game_id) do
      [{pid, _}] ->
        if user_id != "1024" do
          RoomServer.start_countdown(pid, true)
        end
        case RoomServer.query(pid, user_id) do
          {:ok, detail} ->
            # 当前询问回合，写回成功
            {:ok, detail}
          {:error, detail} ->
            :ets.insert(:pid_info_test, {game_id, caller})
            # 不是当前询问回合，写回错误
            {:error, detail}
        end
      [] ->
        {:room_error, "game is over, do not query again"}
    end
  end

  def movement(moves, user_id, game_id) do
    case Registry.lookup(Battle.RoomRegistry, game_id) do
      [{pid, _}] ->
        if user_id != "1024" do
          RoomServer.start_countdown(pid, true)
        end
        case RoomServer.movement(pid, user_id, Convert.convert_index_into_integer(moves)) do
          {:ok, success_detail} ->
            # 将your_step改为opponent_step
            if success_detail.winner do
              RoomServer.terminate_game_test(pid)
            end
            case :ets.lookup(:pid_info_test, game_id) do
              [] -> # 对方没有查询
                {:ok, success_detail}
              [{_, dest}] -> # 对方查询棋盘状态
                :ets.delete(:pid_info_test, game_id)
                send(dest, {:query, success_detail})
                {:ok, success_detail}
            end

          {:error, error_detail} ->
            {:error, error_detail}
        end
      [] ->
        {:error, "room not found"}
    end
  end

  def get_first_and_pop() do
    case :ets.first(:services_ai) do
      :"$end_of_table" ->
        {:error, "ETS is empty"}
      key ->
        [{groupName, appName_lists}] = :ets.lookup(:services_ai, key)
        [head | tail] = appName_lists
        if tail == [] do
          :ets.delete(:services_ai, key)
        else
          :ets.insert(:services_ai, {groupName, tail})
        end
        {:ok, {groupName, head}}
    end
  end

  def start_ai_service(groupName, appName, token_ai, white) do
    update_service(appName, token_ai, white)
    |> Kun.update_service_group(groupName, groupName)
    create_deploy(groupName, appName, @package_name)
    |> Kun.create_deploy_task()
    {:ok, "deploy done"}
  end

  def end_ai_service(groupName, appName) do
    create_uninstall(groupName, appName)
    |> Kun.create_uninstall_task()
    case :ets.lookup(:services_ai, groupName) do
      [] ->
        :ets.insert(:services_ai, {groupName, appName})
      [{groupName, app_name_old}] ->
        :ets.insert(:services_ai, {groupName, [appName | app_name_old]})
    end
    {:ok, "uninstall done"}
  end

  defp create_deploy(groupKey, appName, configName) do
    [
      %{
        "serviceGroup": groupKey,
        "service": appName,
        "appConfBuildName": configName,
      }
    ]
  end

  defp create_uninstall(groupKey, appName) do
    [
      %{
        "serviceGroup": groupKey,
        "service": appName,
        "deleteExclusivePvc": true
      }
    ]
  end

  defp update_service(appName, token, white) do
    [%{
          "name" => appName,
          "version" => appName,
          "replicas" => 1,
          "cpu" => 12,
          "mem" => 96,
          "capacity" => 20,
          "svcCapacity" => 0,
          "nodepoolId" => "np0f3c8a13074143ff90da1f198a756367",
          "params" => %{
            "token" => token,
            "white" => to_string(!white)
          },
          "resources" => %{
            "kun-run" => %{
              "requests" => %{
                "cpu" => 2.0,
                "mem" => 4.0
              },
              "limits" => %{
                "cpu" => 0.5,
                "mem" => 2.0
              }
            }
          }
        }]
  end
end
