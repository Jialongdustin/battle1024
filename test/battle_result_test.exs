defmodule BattleTest do
  use ExUnit.Case
  #  doctest Battle.BattleDfs
  doctest Battle.BattleHandler

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Mongo.BattleResult

  test "insert_battle_res" do
    state =%{app_name: "33",
      black: 456,
      board: [[0, 0, 0, 0, 0, 0, 0, 0], [1, 1, 1, 1, 1, 1, 1, 1], [0, 1, 1, 1, 1, 1, 1, 1], [0, 1, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 3, 0, 0], [3, 3, 3, 3, 3, 0, 3, 3], [3, 3, 3, 3, 3, 3, 3, 3], [0, 0, 0, 0, 0, 0, 0, 0]],
      can_move: [[[4, 5], [4, 4]], [[4, 5], [4, 6]], [[4, 5], [3, 5]], [[5, 0], [4, 0]], [[5, 1], [4, 1]], [[5, 2], [4, 2]], [[5, 3], [4, 3]], [[5, 4], [5, 5]], [[5, 4], [4, 4]], [[5, 6], [5, 5]], [[5, 6], [4, 6]], [[5, 7], [4, 7]], [[6, 5], [5, 5]]],
      contest_id: "10003",
      early_hand: false,
      group_key: "22",
      group_name: "11",
      illegal_times: [0, 0],
      pre_step_black: %{cnt: 2, move: [[4, 5], [4, 6]]},
      pre_step_white: %{cnt: 2, move: [[3, 0], [3, 1]]},
      steps: [%{captured: [%{captured: nil, moves: [[2, 0], [3, 0]]}], user_id: 123}, %{captured: [%{captured: nil, moves: [[5, 5], [4, 5]]}], user_id: 456}, %{captured: [%{captured: nil, moves: [[3, 0], [3, 1]]}], user_id: 123}, %{captured: [%{captured: nil, moves: [[4, 5], [4, 6]]}], user_id: 456}, %{captured: [%{captured: nil, moves: [[3, 1], [3, 0]]}], user_id: 123}, %{captured: [%{captured: nil, moves: [[4, 6], [4, 5]]}], user_id: 456}, %{captured: [%{captured: nil, moves: [[3, 0], [3, 1]]}], user_id: 123}],
      steps_black: 10,
      steps_white: 11,
      time_cost_black: 0,
      time_cost_white: 0,
      time_counter_black: 0,
      time_counter_white: 0,
      time_ref: nil,
      white: 123,
      winner: 123}
    Battle.Mongo.BattleResult.save_battle_result(
      [state.white, state.black],
      state.contest_id,
      state.winner,
      [state.time_cost_white, state.time_cost_black],
      ["1G", "2G"],
      state.white,
      [state.steps_white, state.steps_black]
    )

  end


  test "get_all_battle" do
    winner = 1
    {_,res} = case BattleResult.get_battle_results() do
      {:ok,res} -> {:ok,res}
      {:error,reason} ->{:error,reason}
    end
    IO.inspect(res)
    assert Enum.any?(res, fn element -> element == winner end)
  end

  test "get_battle_by user id" do
    res = BattleResult.get_battle_result_by_user_id(123)

    IO.inspect(res)
  end
end