defmodule Battle.Service.BattleService.ThreadPool do
  use GenServer

  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Utils.Token
  alias Battle.Service.WebService.Kun
  @appNames %{"battle-player-python" =>"battle-player-lua", "battle-player-java" => "battle-player-c"}

  def start_link(size) do
    GenServer.start_link(__MODULE__, size, name: __MODULE__)
  end

  def init(size) do
    {:ok, %{users: [], workers: [], size: size, queue: :queue.new(), busy: %{}}}
  end

  def get_users(info) do
    GenServer.call(__MODULE__, {:get_users, info})
  end

  def add_task(task) do
    GenServer.cast(__MODULE__, {:add_task, task})
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
    if length(state.workers) < state.size do
      # 如果有空闲的 worker，直接执行任务
      worker = Task.async(fn -> execute_task(task) end)
      contest_id = Tuple.to_list(task) |> Enum.at(2)
      {:noreply, %{state | workers: [worker | state.workers], busy: Map.put(state.busy, contest_id, worker)}}
    else
      # 否则，将任务加入队列
      {:noreply, %{state | queue: :queue.in(task, state.queue)}}
    end
  end

  def handle_info({contest_id, group_name, group_key, app_name}, state) do
    # 从 busy 列表中移除已完成的任务
    {worker, busy} = Map.pop(state.busy, contest_id)
    workers = List.delete(state.workers, worker)

    # 创建卸载任务单
    terminate_service(group_key, app_name)

    # 如果队列中有任务，将其分配给空闲的 worker
    case :queue.out(state.queue) do
      {{:value, next_task}, new_queue} ->
        next_contest_id = Tuple.to_list(next_task) |> Enum.at(2)
        new_worker = Task.async(fn -> reuse_group_for_task(next_task, {group_name, group_key, app_name}) end)
        {:noreply, %{state | workers: [new_worker | workers], busy: Map.put(busy, next_contest_id, new_worker), queue: new_queue}}
      {:empty, _} ->
        {:noreply, %{state | workers: workers, busy: busy}}
    end
  end

  # 对局结束后, 直接把当前服务组信息复用给下一个worker, 省去了调kun的接口去查询空闲的服务组
  defp reuse_group_for_task({user_id1, user_id2, contest_id, players}, {groupName, groupKey, appName}) do
    update_services(groupName, groupKey, appName, user_id1, user_id2, contest_id)
    create_deploys(groupKey, appName, user_id1, user_id2, players)
    RoomSupervisor.init_game(user_id1, user_id2, contest_id, groupName, groupKey, appName)
  end

  # players建立user_id和每个用户的构建包的映射
  defp execute_task({user_id1, user_id2, contest_id, players}) do
    {groupName, appName} = Kun.get_idle_service()
    groupKey =
      Regex.run(~r/players\d+/, groupName)
      |> List.first()
      |> (fn name -> "plat1024-#{name}" end).()
    update_services(groupName, groupKey, appName, user_id1, user_id2, contest_id)
    create_deploys(groupKey, appName, user_id1, user_id2, players)
    RoomSupervisor.init_game(user_id1, user_id2, contest_id, groupName, groupKey, appName)
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
        "appConfBuildName": configName
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

  defp update_services(groupName, groupKey, appName, user_id1, user_id2, contest_id) do
    update_service(appName, user_id1, contest_id) ++
    update_service(appName, user_id2, contest_id)
    |> Kun.update_service_group(groupName, groupKey)
  end

  defp update_service(appName, user_id, contest_id) do
    {:ok, token} = Token.generate_token(user_id, contest_id)
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
