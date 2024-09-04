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
    :timer.sleep(1000)
    [{pid, _}] = Registry.lookup(Battle.RoomRegistry, "game_id")
    server_state = RoomServer.get_state(pid)
    send(ThreadPool, {:terminate, "game_id", state.group_name, state.group_key, state.app_name})
    assert state.workers == []
  end

end
