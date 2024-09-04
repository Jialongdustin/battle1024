test "battle_early_hand" do

  #    Logger.configure(level: :none)
  {:ok, contest_id} =
    Battle.Service.BattleService.RoomSupervisor.init_game("82844bf6-6385-11ef-890d-b2a3d4b2d740", "9927b3de-6385-11ef-aca7-b2a3d4b2d740", "10000", "battle-players1", "plat1024-playes1", "battle-player-c")

  {:ok, %{token_white: token_white, token_black: token_black}} = Battle.Service.BattleService.RoomSupervisorTest.init_game(111)

  # "66d01511320915e5de6e9b56"
  # Battle.Utils.Token.verify_token_battle("66c555a9dd7201a8aa7d36fa")
  {:ok, moment_token_123} = Battle.Utils.Token.generate_token("82844bf6-6385-11ef-890d-b2a3d4b2d740", contest_id)
  # "66d01516320915e5de6e9b57"
  {:ok, moment_token_456} = Battle.Utils.Token.generate_token("9927b3de-6385-11ef-aca7-b2a3d4b2d740", contest_id)
  RoomSupervisor.query(123, contest_id)
  RoomSupervisor.query(456, contest_id)
  is_binary("9927b3de-6385-11ef-aca7-b2a3d4b2d740")
  Battle.Service.WebService.Auth.verify_code("AQZQMTEzODdESJnAWL4/09+g5Cia5hgVoZDRWgIN2GZm1ruCu4M0FOSI5uZY05YR2iAAzcbaVFjMA7Sp")

  RoomSupervisor.movement([[1, 0], [2, 0]], 123, contest_id)

  RoomSupervisor.movement([[2, 0], [3, 0]], 123, contest_id)
  RoomSupervisor.movement([[5, 0], [4, 0]], 456, contest_id)
  RoomSupervisor.movement([[3, 0], [5, 0], [7, 0]], 123, contest_id)
  RoomSupervisor.movement([[5, 1], [4, 1]], 456, contest_id)
  RoomSupervisor.movement([[2, 1], [3, 1]], 123, contest_id)
end
