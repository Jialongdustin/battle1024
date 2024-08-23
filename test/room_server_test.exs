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
      Battle.Service.BattleService.RoomSupervisor.init_game(123, 456, "10002","11","22","33")

    # "66c8028b65cfd1d344393780"
    {:ok, moment_token_123} = Battle.Utils.Token.generate_token(123, contest_id)
    # "66c8029065cfd1d344393781"
    {:ok, moment_token_456} = Battle.Utils.Token.generate_token(456, contest_id)
#    RoomSupervisor.query(123, contest_id)
#    RoomSupervisor.query(456, contest_id)

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
#    moves = [[3, 0], [5, 0], [7, 0]]
    moves = [[2,1],[3,1]]
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

  test "update capture" do
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
    capture =[
      %{captured: [4, 0], moves: [[3, 0], [5, 0]]},
      %{captured: [6, 0], moves: [[5, 0], [7, 0]]}
    ]
    update = RoomServer.get_update(capture,1,3,0,7,0)

    new_board =
      Enum.reduce(update, board, fn {row, col, new_value}, acc ->
        update_row = List.replace_at(Enum.at(acc, row), col, new_value)
        List.replace_at(acc, row, update_row)
      end)

    assert new_board == [
             [0, 0, 0, 0, 0, 0, 0, 0],
             [1, 1, 1, 1, 1, 1, 1, 1],
             [0, 1, 1, 1, 1, 1, 1, 1],
             [0, 0, 0, 0, 0, 0, 0, 0],
             [0, 0, 0, 0, 0, 0, 0, 0],
             [0, 3, 3, 3, 3, 3, 3, 3],
             [0, 3, 3, 3, 3, 3, 3, 3],
             [1, 0, 0, 0, 0, 0, 0, 0]
           ]

  end
end
