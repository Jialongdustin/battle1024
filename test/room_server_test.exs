defmodule BattleTest.RoomServerTest do
  use ExUnit.Case
  doctest Battle.Service.BattleService.RoomServer

  require Logger

  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Service.BattleService.RoomServer
  alias Battle.Utils.Token
  alias Battle.Mongo.BattleStatistics
  alias Battle.Mongo.BattleResult

  test "battle_early_hand" do
    BattleStatistics.delete_message()
    BattleStatistics.save_init()
    #    Logger.configure(level: :none)
    {:ok, contest_id} =
      Battle.Service.BattleService.RoomSupervisor.init_game("123", "456", "11", "groupName", "groupKey", "appName")

    # "66cd6eadeee7d7224be32a91"
    {:ok, moment_token_123} = Battle.Utils.Token.generate_token("123", contest_id)
    # "66cd6eadeee7d7224be32a90"
    {:ok, moment_token_456} = Battle.Utils.Token.generate_token("456", contest_id)
    #    RoomSupervisor.query(123, contest_id)
    #    RoomSupervisor.query(456, contest_id)
    RoomSupervisor.query(nil,"123",contest_id)
    RoomSupervisor.movement(Battle.Utils.Convert.convert_integer_into_string([[2, 0], [3, 0]]), "123", contest_id)
    RoomSupervisor.query(nil,"456",contest_id)
    RoomSupervisor.movement(Battle.Utils.Convert.convert_integer_into_string([[5, 4], [4, 4]]), "456", contest_id)
    RoomSupervisor.query(nil,"123",contest_id)
    RoomSupervisor.movement(Battle.Utils.Convert.convert_integer_into_string([[3, 0], [3, 1]]), "123", contest_id)
    RoomSupervisor.query(nil,"456",contest_id)
    RoomSupervisor.movement(Battle.Utils.Convert.convert_integer_into_string([[4, 4], [4, 3]]), "456", contest_id)
    RoomSupervisor.query(nil,"123",contest_id)
    RoomSupervisor.movement(Battle.Utils.Convert.convert_integer_into_string([[3, 1], [3, 0]]), "123", contest_id)
    RoomSupervisor.query(nil,"456",contest_id)
    RoomSupervisor.movement(Battle.Utils.Convert.convert_integer_into_string([[4, 3], [4, 4]]), "456", contest_id)
    # 重复移动会结束游戏
    RoomSupervisor.query(nil,"123",contest_id)
    RoomSupervisor.movement(Battle.Utils.Convert.convert_integer_into_string([[3, 0], [3, 1]]), "123", contest_id)

    {:ok,battle_info} = Battle.Mongo.BattleInfo.get_battle_by_game_id(contest_id)
    Battle.Mongo.BattleInfo.remove_battle(contest_id)
    BattleResult.remove_battle("123")
    assert battle_info.steps == 7
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

  test "move before query" do
    BattleStatistics.delete_message()
    BattleStatistics.save_init()
    #    Logger.configure(level: :none)
    {:ok, contest_id} =
      Battle.Service.BattleService.RoomSupervisor.init_game("123", "456", "11", "groupName", "groupKey", "appName")

    # "66cd6eadeee7d7224be32a91"
    {:ok, moment_token_123} = Battle.Utils.Token.generate_token("123", contest_id)
    # "66cd6eadeee7d7224be32a90"
    {:ok, moment_token_456} = Battle.Utils.Token.generate_token("456", contest_id)
    #    RoomSupervisor.query(123, contest_id)
    #    RoomSupervisor.query(456, contest_id)
#    RoomSupervisor.query(nil,"123",contest_id)
    RoomSupervisor.movement(Battle.Utils.Convert.convert_integer_into_string([[2, 0], [3, 0]]), "123", contest_id)
    {:ok,battle_info} = Battle.Mongo.BattleInfo.get_battle_by_game_id(contest_id)
    Battle.Mongo.BattleInfo.remove_battle(contest_id)
    BattleResult.remove_battle("123")
    assert battle_info.steps == 0
#    RoomSupervisor.query(nil,"456",contest_id)
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
      %{captured: ["a", "4"], moves: [["a", "5"], ["a", "3"]]},
      %{captured: ["a", "2"], moves: [["a", "3"], ["a", "1"]]}
    ]

    update = RoomServer.get_update(capture, 2, 3, 0, 7, 0)

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
             [2, 0, 0, 0, 0, 0, 0, 0]
           ]
  end


  test "count total pieces" do

    board = [
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 1, 0, 1, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 2, 0, 0, 0, 0, 0, 0]
    ]

#    board = [
#      [0, 0, 0, 0, 0, 0, 0, 0],
#      [0, 0, 0, 0, 0, 0, 0, 0],
#      [0, 0, 0, 0, 0, 0, 0, 0],
#      [0, 0, 0, 0, 0, 0, 0, 0],
#      [0, 0, 0, 0, 0, 0, 0, 0],
#      [0, 0, 0, 0, 0, 0, 0, 0],
#      [0, 0, 0, 0, 0, 0, 0, 0],
#      [0, 0, 4, 0, 0, 0, 0, 0]
#    ]
    state = %{
      white: "11",
      black: "22",
      contest_id: 33,
      winner: nil,
      board: board,
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
    capture = [%{captured: [6, 1], moves: [[4, 1], [7, 1]]}]

    res = RoomServer.count_total_piece(state,capture)
    assert res == "11"
  end

  test "record time step" do
    BattleStatistics.delete_message()
    BattleStatistics.save_init()
    game_id = "11111"
    {:ok, game_id} =
      Battle.Service.BattleService.RoomSupervisor.init_game("123", "456", game_id, "groupName", "groupKey", "appName")

      RoomSupervisor.query(nil,"123",game_id)
      RoomSupervisor.movement(Battle.Utils.Convert.convert_integer_into_string([[2, 0], [3, 0]]), "123", game_id)

      RoomSupervisor.query(nil,"456",game_id)
      RoomSupervisor.movement(Battle.Utils.Convert.convert_integer_into_string([[5, 0], [4, 0]]), "456", game_id)

      #违规会结束游戏
      RoomSupervisor.query(nil,"123",game_id)
      RoomSupervisor.movement(Battle.Utils.Convert.convert_integer_into_string([[2, 0], [3, 0]]), "123", game_id)

      {:ok,battle_info} = Battle.Mongo.BattleInfo.get_battle_by_game_id(game_id)
      Battle.Mongo.BattleInfo.remove_battle(game_id)
      BattleResult.remove_battle("123")
      assert battle_info.steps == 2

  end

end
