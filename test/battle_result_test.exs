defmodule BattleResultTest do
  use ExUnit.Case
  #  doctest Battle.BattleDfs
  doctest Battle.BattleHandler

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Mongo.BattleResult

  test "get battle in 24 hours" do
    BattleResult.save_battle_result(["1","2"],"1","1",[11,22],["11","22"],"1",[20,30])
    winner = "1"
    {:ok,res} = BattleResult.get_battle_results_within_24_hour()
    BattleResult.remove_battle("1")
    assert Enum.any?(res, fn element -> element.winner == winner end)

  end

  test "get_all_battle" do
    BattleResult.save_battle_result(["1","2"],"1","1",[11,22],["11","22"],"1",[20,30])
    winner = "1"
    {_,res} = case BattleResult.get_battle_results() do
      {:ok,res} -> {:ok,res}
      {:error,reason} ->{:error,reason}
    end
    BattleResult.remove_battle("1")
    assert Enum.any?(res, fn element -> winner in element end)
  end

  test "get_battle_by user id" do
    Battle.Mongo.BattleResult.save_battle_result(["1","2"],"1","1",[11,22],["11","22"],"1",[20,30])
    winner = "1"

    {:ok,user_info} = BattleResult.get_battle_result_by_user_id(winner)
    BattleResult.remove_battle(winner)
    assert List.first(user_info).self.winner == winner
  end
end
