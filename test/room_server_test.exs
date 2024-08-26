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
      Battle.Service.BattleService.RoomSupervisor.init_game(123, 456, "10008", "11", "22", "33")

    # "66cbf00f45826e234382f9b9"
    {:ok, moment_token_123} = Battle.Utils.Token.generate_token(123, contest_id)
    # "66cbf01245826e234382f9ba"
    {:ok, moment_token_456} = Battle.Utils.Token.generate_token(456, contest_id)
    #    RoomSupervisor.query(123, contest_id)
    #    RoomSupervisor.query(456, contest_id)

    RoomSupervisor.movement([[2, 0], [3, 0]], 123, contest_id)
    RoomSupervisor.movement([[5, 4], [4, 4]], 456, contest_id)
    RoomSupervisor.movement([[3, 0], [3, 1]], 123, contest_id)
    RoomSupervisor.movement([[4, 4], [4, 3]], 456, contest_id)
    RoomSupervisor.movement([[3, 1], [3, 0]], 123, contest_id)
    RoomSupervisor.movement([[4, 3], [4, 4]], 456, contest_id)
    RoomSupervisor.movement([[3, 0], [3, 1]], 123, contest_id)
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
    moves = [[2, 1], [3, 1]]
    res = RoomServer.get_captures(moves, board)
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
    res = RoomServer.cal_black_white_and_node_value(moves, board)
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

    capture = [
      %{captured: [4, 0], moves: [[3, 0], [5, 0]]},
      %{captured: [6, 0], moves: [[5, 0], [7, 0]]}
    ]

    update = RoomServer.get_update(capture, 1, 3, 0, 7, 0)

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

  test "check repeat remove" do
    state = %{
      white: 11,
      black: 22,
      contest_id: 33,
      winner: nil,
      board: @board_init,
      early_hand: true,
      steps: [],
      illegal_times: [0, 0],
      time_ref: nil,
      steps_white: 0,
      steps_black: 0,
      pre_step_white: %{move: [], cnt: 0},
      pre_step_black: %{move: [], cnt: 0},
      time_cost_white: 0,
      time_cost_black: 0,
      time_counter_white: 0,
      time_counter_black: 0
    }

    {_, state} = RoomServer.check_repeat_move(state, [[2, 0], [3, 0]], [])
    {_, state} = RoomServer.check_repeat_move(state, [[3, 0], [2, 0]], [])
    RoomServer.check_repeat_move(state, [[2, 0], [3, 0]], [])
  end

  test "count total pieces" do
    new_state = %{
      board: [
        [0, 0, 0, 0, 0, 0, 0, 0],
        [1, 0, 0, 0, 1, 0, 1, 0],
        [0, 1, 1, 1, 2, 1, 2, 1],
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 3, 3, 3, 3, 3, 4, 4],
        [0, 3, 3, 3, 3, 3, 4, 4],
        [1, 0, 0, 0, 0, 0, 0, 0]
      ]
    }

    count_diff_pieces = {
      RoomServer.count_piece([1], new_state.board),
      RoomServer.count_piece([2], new_state.board),
      RoomServer.count_piece([3], new_state.board),
      RoomServer.count_piece([4], new_state.board)
    }

    IO.inspect(count_diff_pieces)
  end
end
