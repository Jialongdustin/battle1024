defmodule BattleTest.RoomSupervisorUserTest do
  use ExUnit.Case
  doctest Battle.Service.BattleService.RoomSupervisorTest

  require Logger

  alias Battle.Service.BattleService.RoomSupervisorTest
  alias Battle.Service.BattleService.RoomServer
  alias Battle.Utils.Token

  test "battle test for user" do

    #    Logger.configure(level: :none)
    {:ok,contest_info} =Battle.Service.BattleService.RoomSupervisorTest.init_game("656599a4-65b4-11ef-bdb1-b2a3d4b2d740",true)
    #token_black: "66c8088b4d783922fa779fd0"
    #token_white: "66c8088b4d783922fa779fcf"

    # "66c8028b65cfd1d344393780"
#    {:ok, moment_token_123} = Battle.Utils.Token.generate_token(123, contest_id)
    # "66c8029065cfd1d344393781"
#    {:ok, moment_token_456} = Battle.Utils.Token.generate_token(456, contest_id)
    #    RoomSupervisor.query(123, contest_id)
    #    RoomSupervisor.query(456, contest_id)

    RoomSupervisorTest.movement(Battle.Utils.Convert.convert_integer_into_string([[2, 0], [3, 0]]), "10", contest_info.game_id)
    RoomSupervisorTest.movement(Battle.Utils.Convert.convert_integer_into_string([[5, 0], [4, 0]]), "24", contest_info.game_id)
    RoomSupervisorTest.movement(Battle.Utils.Convert.convert_integer_into_string([[3, 0], [5, 0], [7, 0]]), "10", contest_info.game_id)
    RoomSupervisorTest.movement(Battle.Utils.Convert.convert_integer_into_string([[5, 1], [4, 1]]), "24", contest_info.game_id)
    RoomSupervisorTest.movement(Battle.Utils.Convert.convert_integer_into_string([[2, 1], [3, 1]]), "10", contest_info.game_id)
  end

end