defmodule BattleTest.ThreadPoolTest do
  use ExUnit.Case
  import Mock

  alias Battle.Service.BattleService.ThreadPool
  alias Battle.Service.BattleService.RoomServer

  setup do
    {:ok, pid} = ThreadPool.start_link(10)
    :ok
  end

  test "starts with an initial state" do
    state = ThreadPool.get_state()
    assert state.size == 10
    assert state.workers == []
    assert state.queue == :queue.new()
    assert state.busy == %{}
  end

  test "add tasks" do
    task = {"user_id1", "user_id2", "game_id", %{"user_id1" => "plat1024-battle-players:20240904160251", "user_id2" => "plat1024-battle-players:20240904160251"}}
    state = ThreadPool.get_state()
    assert :ok = ThreadPool.add_task(task)
    :timer.sleep(5000)
    [{pid, _}] = Registry.lookup(Battle.RoomRegistry, "game_id")
    server_state = RoomServer.get_state(pid)
    send(ThreadPool, {:terminate, "game_id", server_state.group_name, server_state.group_key, server_state.app_name})
    :timer.sleep(2000)
    assert state.workers == []
  end

  test "add task when there is no services " do
    task = {"user_id1", "user_id2", "game_id", %{"user_id1" => "plat1024-battle-players:20240904160251", "user_id2" => "plat1024-battle-players:20240904160251"}}
    :ets.delete_all_objects(:services_info)
    assert :ok = ThreadPool.add_task(task)
    :timer.sleep(1000)
    state = ThreadPool.get_state()
    assert :queue.len(state.queue) == 1

    :ets.insert(:services_info, {"battle-players1", "battle-player-python"})
    assert :ok = ThreadPool.add_task(task)
    :timer.sleep(5000)
    send(ThreadPool, {:terminate, "game_id", "battle-players1", "plat1024-players1", "battle-player-python"})
    :timer.sleep(2000)
    send(ThreadPool, {:terminate, "game_id", "battle-players1", "plat1024-players1", "battle-player-python"})
    :timer.sleep(2000)
    state = ThreadPool.get_state()
    assert :queue.len(state.queue) == 0
    assert state.workers == []
  end

  test "handle_info/2 {ref, result}" do
    ref = make_ref()
    result = :some_result
    send(self(), {ref, result})
    assert ThreadPool.handle_info({ref, result}, %{some_state: true}) == {:noreply, %{some_state: true}}
  end

  test "handle_info/2 handles DOWN messages" do
    ref = make_ref()
    pid = self()
    reason = :normal

    send(self(), {:DOWN, ref, :process, pid, reason})

    # Call the handle_info function directly
    assert ThreadPool.handle_info({:DOWN, ref, :process, pid, reason}, %{some_state: true}) == {:noreply, %{some_state: true}}
  end

end
