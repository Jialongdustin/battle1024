defmodule BattleTest.RoomServerTest do
  use ExUnit.Case
  doctest Battle.Service.BattleService.RoomSupervisor

  require Logger

  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Service.BattleService.RoomServer
  alias Battle.Utils.Token

  test "battle_early_hand" do

    #    Logger.configure(level: :none)
    {:ok, contest_id} =
      Battle.Service.BattleService.RoomSupervisor.init_game("123", "456", "10000")

    # "66c2eab984da5b380c71d90c"
    {:ok, moment_token_123} = Battle.Utils.Token.generate_token("123", contest_id)
    # "66c2eabe84da5b380c71d90d"
    {:ok, moment_token_456} = Battle.Utils.Token.generate_token("456", contest_id)
    RoomSupervisor.query(123, contest_id)
    RoomSupervisor.query(456, contest_id)

    RoomSupervisor.movement([[2, 0], [3, 0]], 123, contest_id)
    RoomSupervisor.movement([[5, 0], [4, 0]], 456, contest_id)
    RoomSupervisor.movement([[3, 0], [5, 0], [7, 0]], 123, contest_id)
    RoomSupervisor.movement([[5, 1], [4, 1]], 456, contest_id)
    RoomSupervisor.movement([[2, 1], [3, 1]], 123, contest_id)
  end

  test "calculate capture" do
    board = [
      [0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [0, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 0, 0, 0, 0, 0, 0],
      [3, 0, 0, 0, 0, 0, 0, 0],
      [0, 3, 3, 3, 3, 3, 3, 3],
      [3, 3, 3, 3, 3, 3, 3, 3],
      [0, 0, 0, 0, 0, 0, 0, 0]
    ]
    moves = [[3, 0], [5, 0], [7, 0]]
    res = RoomServer.get_captures(moves,board)
    IO.inspect(res)
  end

  test "cal_black_white_and_node_value" do
    board = [
      [0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [0, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 0, 0, 0, 0, 0, 0],
      [3, 0, 0, 0, 0, 0, 0, 0],
      [0, 3, 3, 3, 3, 3, 3, 3],
      [3, 3, 3, 3, 3, 3, 3, 3],
      [0, 0, 0, 0, 0, 0, 0, 0]
    ]
    moves = [[3, 0], [5, 0], [7, 0]]
    res = RoomServer.cal_black_white_and_node_value(moves,board)
    IO.inspect(res)
  end

end
