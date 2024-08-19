defmodule BattleTest do
  use ExUnit.Case
#  doctest Battle.BattleDfs
  doctest Battle.BattleHandler

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Service.BattleService.RoomSupervisor

  test "battle_early_hand" do
    Battle.Service.BattleService.ConnectionStore.get_state()
#    Logger.configure(level: :none)
    {:ok,contest_id} = Battle.Service.BattleService.RoomSupervisor.init_game("123","456", "10000")
    # "66c2eab984da5b380c71d90c"
    {:ok,moment_token_123} = Battle.Utils.Token.generate_token("123",contest_id)
    # "66c2eabe84da5b380c71d90d"
    {:ok,moment_token_456} = Battle.Utils.Token.generate_token("456",contest_id)
    RoomSupervisor.query(123,contest_id)
    RoomSupervisor.query(456,contest_id)

    RoomSupervisor.movement([[2,0],[3,0]],123,contest_id)
    RoomSupervisor.movement([[5,0],[4,0]],456,contest_id)
    RoomSupervisor.movement([[3,0],[5,0]],123,contest_id)
    RoomSupervisor.movement([[5,0],[7,0]],123,contest_id)
    RoomSupervisor.movement([[5,1],[4,1]],456,contest_id)



  end


#  test "dfs" do
#    turkish_flag = [
#      [0, 0, 0, 0, 0, 0, 0, 0],
#      [1, 1, 1, 1, 1, 1, 1, 1],
#      [1, 1, 1, 1, 1, 1, 1, 1],
#      [0, 0, 0, 0, 0, 0, 0, 0],
#      [0, 0, 0, 0, 0, 0, 0, 0],
#      [3, 3, 3, 3, 3, 3, 3, 3],
#      [3, 3, 3, 3, 3, 3, 3, 3],
#      [0, 0, 0, 0, 0, 0, 0, 0]
#    ]
##     turkish_flag =  [
##         [0, 0, 0, 0, 0, 0, 0, 0],
##         [0, 0, 0, 1, 0, 1, 0, 0],
##         [0, 1, 0, 0, 2, 0, 0, 0],
##         [0, 3, 0, 0, 0, 0, 0, 0],
##         [0, 0, 0, 3, 0, 0, 0, 0],
##         [0, 3, 0, 0, 0, 0, 0, 0],
##         [0, 0, 3, 0, 3, 0, 0, 0],
##         [0, 0, 0, 0, 4, 0, 0, 0],
##     ]
#
##     turkish_flag = [
##         [0, 0, 0, 0, 0, 0, 0, 0],
##         [0, 1, 0, 1, 0, 1, 0, 0],
##         [0, 3, 0, 0, 2, 0, 0, 0],
##         [0, 0, 0, 0, 0, 0, 0, 0],
##         [0, 3, 0, 3, 0, 3, 0, 0],
##         [0, 0, 3, 0, 3, 0, 0, 0],
##         [0, 0, 0, 3, 0, 0, 0, 0],
##         [0, 0, 4, 0, 4, 0, 0, 0],
##     ]
#
##    IO.inspect(Battle.BattleHandler.pairwise([-1, 0, 1, 0, -1]))
#    res = Battle.BattleHandler.move_list(turkish_flag,true)
##    res = Battle.BattleHandler.dfs(turkish_flag,1,1,false,"white",8,8)
#    expect = [
#      [[1,1],[3,1],[5,1],[5,3],[5,5]],
#      [[1,1],[3,1],[5,1],[5,3],[7,3],[7,0]],
#      [[1,1],[3,1],[5,1],[5,3],[7,3],[7,1]],
#      [[1,1],[3,1],[5,1],[5,3],[7,3],[7,5],[2, 5]],
#      [[1,1],[3,1],[5,1],[5,3],[7,3],[7,5],[3, 5]],
#      [[1,1],[3,1],[5,1],[5,3],[7,3],[7,6]],
#      [[1,1],[3,1],[5,1],[5,3],[7,3],[7,7]]
#    ]
#
#    assert expect == res
#  end



end
