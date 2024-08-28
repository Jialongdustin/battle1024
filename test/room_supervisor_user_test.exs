defmodule BattleTest.RoomSupervisorUserTest do
  use ExUnit.Case
  doctest Battle.Service.BattleService.RoomSupervisorTest

  require Logger

  alias Battle.Service.BattleService.RoomSupervisorTest
  alias Battle.Service.BattleService.RoomServer
  alias Battle.Utils.Token

  test "battle test for user" do

    #    Logger.configure(level: :none)
    contest_id =Battle.Service.BattleService.RoomSupervisorTest.init_game()
    #token_black: "66c8088b4d783922fa779fd0"
    #token_white: "66c8088b4d783922fa779fcf"

    # "66c8028b65cfd1d344393780"
    {:ok, moment_token_123} = Battle.Utils.Token.generate_token(123, contest_id)
    # "66c8029065cfd1d344393781"
    {:ok, moment_token_456} = Battle.Utils.Token.generate_token(456, contest_id)
    #    RoomSupervisor.query(123, contest_id)
    #    RoomSupervisor.query(456, contest_id)

    RoomSupervisorTest.movement([[2, 0], [3, 0]], 123, contest_id)
    RoomSupervisorTest.movement([[5, 0], [4, 0]], 456, contest_id)
    RoomSupervisorTest.movement([[3, 0], [5, 0], [7, 0]], 123, contest_id)
    RoomSupervisorTest.movement([[5, 1], [4, 1]], 456, contest_id)
    RoomSupervisorTest.movement([[2, 1], [3, 1]], 123, contest_id)
  end

end