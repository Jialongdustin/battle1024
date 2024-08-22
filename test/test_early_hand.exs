test "battle_early_hand" do

  #    Logger.configure(level: :none)
  {:ok, contest_id} =
    Battle.Service.BattleService.RoomSupervisor.init_game(111, 222, "10000")

  {:ok, %{token_white: token_white, token_black: token_black}} = Battle.Service.BattleService.RoomSupervisorTest.init_game(111)

  # "66c5979e77853a94a1367a5d"
  # Battle.Utils.Token.verify_token_battle("66c555a9dd7201a8aa7d36fa")
  {:ok, moment_token_123} = Battle.Utils.Token.generate_token(111, contest_id)
  # "66c58a276a8c27278ff18b9e"
  {:ok, moment_token_456} = Battle.Utils.Token.generate_token(222, contest_id)
  RoomSupervisor.query(123, contest_id)
  RoomSupervisor.query(456, contest_id)

  RoomSupervisor.movement([[1, 0], [2, 0]], 123, contest_id)

  RoomSupervisor.movement([[2, 0], [3, 0]], 123, contest_id)
  RoomSupervisor.movement([[5, 0], [4, 0]], 456, contest_id)
  RoomSupervisor.movement([[3, 0], [5, 0], [7, 0]], 123, contest_id)
  RoomSupervisor.movement([[5, 1], [4, 1]], 456, contest_id)
  RoomSupervisor.movement([[2, 1], [3, 1]], 123, contest_id)
end
