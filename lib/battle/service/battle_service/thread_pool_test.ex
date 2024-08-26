defmodule Battle.Service.BattleService.ThreadPoolTest do
  use GenServer

  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Utils.Token
  alias Battle.Service.WebService.Kun

  @appNames %{"battle-player-python" =>"battle-player-lua", "battle-player-java" => "battle-player-c"}

  # alias Battle.Service.BattleService.ThreadPoolTest
  # game_id = UUID.uuid4()
  # ThreadPoolTest.add_task({"git@gitlab.alibaba-inc.com:Test_elixir/battle1024_jdk8.git", "dustin", game_id})
  # ThreadPoolTest.terminate_service("plat1024-test1", "battle-player-python")
  # send(Battle.Service.BattleService.ThreadPoolTest, {game_id, "battle-test1", "plat1024-test1", "battle-player-python"})
  def start_link(size) do
    GenServer.start_link(__MODULE__, size, name: __MODULE__)
  end

  def init(size) do
    {:ok, %{users: [], workers: [], size: size, queue: :queue.new(), busy: %{}}}
  end

  def add_task(task) do
    GenServer.cast(__MODULE__, {:add_task, task})
  end

  def handle_cast({:add_task, task}, state) do
    if length(state.workers) < state.size do
      # 如果有空闲的 worker，直接执行任务
      worker = Task.async(fn -> execute_task(task) end)
      game_id = Tuple.to_list(task) |> Enum.at(2)
      {:noreply, %{state | workers: [worker | state.workers], busy: Map.put(state.busy, game_id, worker)}}
    else
      # 否则，将任务加入队列
      {:noreply, %{state | queue: :queue.in(task, state.queue)}}
    end
  end

  def handle_info({:terminate, game_id, group_name, group_key, app_name}, state) do
    # 从 busy 列表中移除已完成的任务
    {worker, busy} = Map.pop(state.busy, game_id)
    workers = List.delete(state.workers, worker)

    # 创建卸载任务单
    terminate_service(group_key, app_name)

    # 如果队列中有任务，将其分配给空闲的 worker
    case :queue.out(state.queue) do
      {{:value, next_task}, new_queue} ->
        next_game_id = Tuple.to_list(next_task) |> Enum.at(2)
        new_worker = Task.async(fn -> reuse_group_for_task(next_task, {group_name, group_key, app_name}) end)
        {:noreply, %{state | workers: [new_worker | workers], busy: Map.put(busy, next_game_id, new_worker), queue: new_queue}}
      {:empty, _} ->
        {:noreply, %{state | workers: workers, busy: busy}}
    end
  end

  defp reuse_group_for_task({git, tag, game_id}, {groupName, groupKey, appName}) do
    package_name = Kun.change_config(%{user_id: 1024, git_url: git, tag: tag})[:package_name]
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
    RoomSupervisor.init_game(10, 24, game_id, groupName, groupKey, appName)
  end

  # players建立user_id和每个用户的构建包的映射
  defp execute_task({git, tag, game_id}) do
    package_name = Kun.change_config(%{user_id: 1024, git_url: git, tag: tag})[:package_name]
    {groupName, appName} = Kun.get_idle_service(true)
    groupKey =
      Regex.run(~r/test\d+/, groupName)
      |> List.first()
      |> (fn name -> "plat1024-#{name}" end).()
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
    RoomSupervisor.init_game(10, 24, game_id, groupName, groupKey, appName)
  end

  defp update_services(groupName, groupKey, appName, game_id) do
    update_service(appName, 10, game_id) ++
    update_service(appName, 24, game_id)
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

  defp terminate_service(groupKey, appName) do
    result = create_uninstalls(groupKey, appName)
    :timer.sleep(3000)
    result
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
