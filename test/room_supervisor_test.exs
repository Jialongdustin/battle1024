defmodule BattleTest.RoomSupervisorTest do
  use ExUnit.Case
  doctest Battle.Service.BattleService.RoomSupervisor

  require Logger

  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Service.BattleService.RoomServer
  alias Battle.Utils.Token


  test "init game" do
    user_id_1 = "123"
    user_id_2 = "456"
    game_id = "aa"

    {:ok,contest_id} = RoomSupervisor.init_game(user_id_1,user_id_2,game_id,"a","b","c")

    [{pid,_}] = Registry.lookup(Battle.RoomRegistry,contest_id)

    # 验证 contest_id 对应的进程已经存在

    assert is_pid(pid)

  end



end