defmodule BattleTest.RoomServerTest do
  use ExUnit.Case
  doctest Battle.Service.BattleService.RoomSupervisor

  require Logger

  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Service.BattleService.RoomServer
  alias Battle.Utils.Token

  test "init game" do
    user_id_1 = "123"
    user_id_2 = "456"
    {:ok,contest_id} = RoomSupervisor.init_game(user_id_1,user_id_2)

    [{pid,_}] = Registry.lookup(Battle.RoomRegistry,contest_id)

    # 验证 contest_id 对应的进程已经存在
    moves = [[5,0],[4,0]]
#    moves = [[2,0],[3,0]]
    capture = [0,0]
    res = RoomServer.movement(pid,moves,capture)
    IO.inspect(res)

    assert is_pid(pid)

  end

end