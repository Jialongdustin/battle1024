defmodule Battle.Service.BattleService.ThreadPoolTest do
  use GenServer

  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Utils.Token
  alias Battle.Service.WebService.Kun
  alias Battle.Mongo.BattleResultTest

  @service_groups ["battle-test1", "battle-test2", "battle-test3", "battle-test4", "battle-test5"]
  @appNames %{"battle-player-python" =>"battle-player-lua", "battle-player-java" => "battle-player-c"}

  # alias Battle.Service.BattleService.ThreadPoolTest
  # alias Battle.Service.BattleService.RoomServer
  # game_id = UUID.uuid4()
  # ThreadPoolTest.add_task({"git@gitlab.alibaba-inc.com:Test_elixir/battle1024_python_3.12.5.git", "main", game_id})
  # ThreadPoolTest.terminate_service("plat1024-test1", "battle-player-python")
  # send(Battle.Service.BattleService.ThreadPoolTest, {game_id, "battle-test1", "plat1024-test1", "battle-player-python"})
  # [{pid, _}] = Registry.lookup(Battle.RoomRegistry, game_id)
  # RoomServer.get_state(pid)
  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_args) do
    :ets.new(:services_info_test, [:named_table, :public, read_concurrency: true])
    Enum.each(@service_groups, fn group_name ->
      Enum.each(Map.keys(@appNames), fn app_name ->
        case :ets.lookup(:services_info_test, group_name) do
          [] ->
            :ets.insert(:services_info_test, {group_name, app_name})
          [{group_name, app_name_old}] ->
            :ets.insert(:services_info_test, {group_name, [app_name | app_name_old]})
        end
      end)
    end)
    {:ok, %{workers: [], queue: :queue.new(), busy: %{}}}
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

  def handle_cast({:add_task, task}, state) do
    case get_first_and_pop() do
      {:ok, service} ->
        worker = Task.async(fn -> execute_task(task, service) end)
        contest_id = Tuple.to_list(task) |> Enum.at(2)
        {:noreply, %{state | workers: [worker | state.workers], busy: Map.put(state.busy, contest_id, worker)}}
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
        case :ets.lookup(:services_info_test, group_name) do
          [] ->
            :ets.insert(:services_info_test, {group_name, app_name})
          [{group_name, app_name_old}] ->
            :ets.insert(:services_info_test, {group_name, [app_name | app_name_old]})
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
    case :ets.first(:services_info_test) do
      :"$end_of_table" ->
        {:error, "ETS is empty"}
      key ->
        [{groupName, appName_lists}] = :ets.lookup(:services_info_test, key)
        [head | tail] = case is_list(appName_lists) do
          true ->
            appName_lists
          false ->
            [appName_lists]
        end
        if tail == [] do
          :ets.delete(:services_info_test, key)
        else
          :ets.insert(:services_info_test, {groupName, tail})
        end
        {:ok, {groupName, head}}
    end
  end

  defp reuse_group_for_task({git, tag, game_id}, {groupName, groupKey, appName}) do
    package_name = Kun.change_config(%{user_id: "1024", git_url: git, tag: tag})[:package_name]
    RoomSupervisor.init_game("10", "24", game_id, groupName, groupKey, appName,package_name)
    update_services(groupName, groupKey, appName, game_id)
    [
      %{
        "serviceGroup": groupKey,
        "service": appName,
        "appConfBuildName": package_name
      },
      %{
        "serviceGroup": groupKey,
        "service": Map.get(@appNames, appName),
        "appConfBuildName": package_name
      },
    ] |> Kun.create_deploy_task()
  end

  # players建立user_id和每个用户的构建包的映射
  defp execute_task({git, tag, game_id}, {groupName, appName}) do
    case Kun.change_config(%{user_id: "1024", git_url: git, tag: tag}) do
      {:error, reason} ->
        BattleResultTest.update_battle_result_failed(game_id, reason)
      %{package_name: package_name, user_id: _} ->
        groupKey =
          Regex.run(~r/test\d+/, groupName)
          |> List.first()
          |> (fn name -> "plat1024-#{name}" end).()
        RoomSupervisor.init_game("10", "24", game_id, groupName, groupKey, appName, true)
        update_services(groupName, groupKey, appName, game_id)
        [
          %{
            "serviceGroup": groupKey,
            "service": appName,
            "appConfBuildName": package_name
          },
          %{
            "serviceGroup": groupKey,
            "service": Map.get(@appNames, appName),
            "appConfBuildName": package_name
          },
        ] |> Kun.create_deploy_task()
    end


  end

  defp terminate_service(groupKey, appName) do
    result = create_uninstalls(groupKey, appName)
    :timer.sleep(3000)
    result
  end

  defp update_services(groupName, groupKey, appName, game_id) do
    update_service(appName, "10", game_id, true) ++
    update_service(Map.get(@appNames, appName), "24", game_id, false)
    |> Kun.update_service_group(groupName, groupKey)
  end

  defp update_service(appName, user_id, game_id, white) do
    {:ok, token} = Token.generate_token(user_id, game_id)
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
            "white" => to_string(white),
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

end
