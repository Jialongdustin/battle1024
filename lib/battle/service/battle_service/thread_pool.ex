defmodule Battle.Service.BattleService.ThreadPool do
  use GenServer

  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Utils.Token
  alias Battle.Service.WebService.Kun
  # @service_groups ["battle-players1", "battle-players2", "battle-players3", "battle-players4", "battle-players5", "battle-players6", "battle-players7", "battle-players8", "battle-players9", "battle-players10",
  #                 "battle-players11", "battle-players12", "battle-players13", "battle-players14"]
  @service_groups ["battle-players1", "battle-players2", "battle-players3", "battle-players4", "battle-players5"]
  @appNames %{"battle-player-python" =>"battle-player-lua", "battle-player-java" => "battle-player-c"}

  def start_link(size) do
    GenServer.start_link(__MODULE__, size, name: __MODULE__)
  end

  def init(size) do
    :ets.new(:services_info, [:named_table, :public, read_concurrency: true])
    Enum.each(@service_groups, fn group_name ->
      Enum.each(Map.keys(@appNames), fn app_name ->
        case :ets.lookup(:services_info, group_name) do
          [] ->
            :ets.insert(:services_info, {group_name, app_name})
          [{group_name, app_name_old}] ->
            :ets.insert(:services_info, {group_name, [app_name | app_name_old]})
        end
      end)
    end)
    {:ok, %{users: [], workers: [], size: size, queue: :queue.new(), busy: %{}}}
  end

  def get_users(info) do
    GenServer.call(__MODULE__, {:get_users, info})
  end

  def add_task(task) do
    GenServer.cast(__MODULE__, {:add_task, task})
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_users, info}, _from, state) do
    case length(state.users) do
      0 ->
        new_users = [info]
        {:reply, :push, %{state | users: new_users}}
      1 ->
        {:reply, state.users, %{state | users: []}}
    end
  end

  def handle_cast({:add_task, task}, state) do
    case get_first_and_pop() do
      {:ok, service} ->
        worker = Task.async(fn -> execute_task(task, service) end)
        game_id = Tuple.to_list(task) |> Enum.at(2)
        {:noreply, %{state | workers: [worker | state.workers], busy: Map.put(state.busy, game_id, worker)}}
      {:error, _} ->
        {:noreply, %{state | queue: :queue.in(task, state.queue)}}
    end
  end

  def handle_info({:terminate, game_id, group_name, group_key, app_name}, state) do
    # 从 busy 列表中移除已完成的任务
    {worker, busy} = Map.pop(state.busy, game_id)
    workers = List.delete(state.workers, worker)

    # 如果队列中有任务，将其分配给空闲的 worker
    case :queue.out(state.queue) do
      {{:value, next_task}, new_queue} ->
        next_game_id = Tuple.to_list(next_task) |> Enum.at(2)
        new_worker = Task.async(fn -> reuse_group_for_task(next_task, {group_name, group_key, app_name}) end)
        {:noreply, %{state | workers: [new_worker | workers], busy: Map.put(busy, next_game_id, new_worker), queue: new_queue}}
      {:empty, _} ->
        terminate_service(group_key, app_name)
        case :ets.lookup(:services_info, group_name) do
          [] ->
            :ets.insert(:services_info, {group_name, app_name})
          [{group_name, app_name_old}] ->
            :ets.insert(:services_info, {group_name, [app_name | app_name_old]})
        end
        {:noreply, %{state | workers: workers, busy: busy}}
    end
  end

  def handle_info({ref, result}, state) when is_reference(ref) do
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, state) do
    {:noreply, state}
  end

  defp get_first_and_pop() do
    case :ets.first(:services_info) do
      :"$end_of_table" ->
        {:error, "ETS is empty"}
      key ->
        [{groupName, appName_lists}] = :ets.lookup(:services_info, key)
        [head | tail] = case is_list(appName_lists) do
          true ->
            appName_lists
          false ->
            [appName_lists]
        end
        if tail == [] do
          :ets.delete(:services_info, key)
        else
          :ets.insert(:services_info, {groupName, tail})
        end
        {:ok, {groupName, head}}
    end
  end

  # 对局结束后, 直接把当前服务组信息复用给下一个worker, 省去了调kun的接口去查询空闲的服务组
  defp reuse_group_for_task({user_id1, user_id2, game_id, players}, {groupName, groupKey, appName}) do
    update_services(groupName, groupKey, appName, user_id1, user_id2, game_id)
    create_deploys(groupKey, appName, user_id1, user_id2, players)
    RoomSupervisor.init_game(user_id1, user_id2, game_id, groupName, groupKey, appName)
  end

  # players建立user_id和每个用户的构建包的映射
  defp execute_task({user_id1, user_id2, game_id, players}, {groupName, appName}) do
    # {groupName, appName} = Kun.get_idle_service()
    groupKey =
      Regex.run(~r/players\d+/, groupName)
      |> List.first()
      |> (fn name -> "plat1024-#{name}" end).()
    update_services(groupName, groupKey, appName, user_id1, user_id2, game_id)
    create_deploys(groupKey, appName, user_id1, user_id2, players)
    RoomSupervisor.init_game(user_id1, user_id2, game_id, groupName, groupKey, appName)
  end

  defp terminate_service(groupKey, appName) do
    result = create_uninstalls(groupKey, appName)
    :timer.sleep(3000)
    result
  end

  defp create_deploys(groupKey, appName, user_id1, user_id2, players) do
    create_deploy(groupKey, appName, Map.get(players, user_id1)) ++
    create_deploy(groupKey, Map.get(@appNames, appName), Map.get(players, user_id2))
    |> Kun.create_deploy_task()
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

  defp create_uninstalls(groupKey, appName) do
    create_uninstall(groupKey, appName) ++
    create_uninstall(groupKey, Map.get(@appNames, appName))
    |> Kun.create_uninstall_task()
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

  defp update_services(groupName, groupKey, appName, user_id1, user_id2, game_id) do
    update_service(appName, user_id1, game_id) ++
    update_service(appName, user_id2, game_id)
    |> Kun.update_service_group(groupName, groupKey)
  end

  defp update_service(appName, user_id, game_id) do
    {:ok, token} = Token.generate_token(user_id, game_id)
    [%{
          "name" => appName,
          "version" => appName,
          "replicas" => 1,
          "cpu" => 12,
          "mem" => 96,
          "capacity" => 20,
          "svcCapacity" => 0,
          "nodepoolId" => "npeba0ac67afb34e028c66e0ba0ece482f", # np0f3c8a13074143ff90da1f198a756367
          "params" => %{
            "token" => token
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
# services = [
#   %{
#     "serviceGroup": "plat1024-players1",
#     "service": "battle-player-python",
#     "appConfBuildName": "plat1024-battle-players:20240827143548",
#   }
# ]
