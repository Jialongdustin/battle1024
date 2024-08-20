defmodule BattleTest do
  use ExUnit.Case
  #  doctest Battle.BattleDfs
  doctest Battle.BattleHandler

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Mongo.BattleResult

  test "insert_battle_res" do
    Battle.Mongo.BattleResult.save_battle_result([1,2],2,2,[11,22],["11","22"],2,[20,30])
    Battle.Mongo.BattleResult.save_battle_result([3,4],3,3,[11,22],["11","22"],3,[20,30])
    {_,res} = BattleResult.get_battle_results()
    winner = 3
    assert Enum.any?(res, fn element -> element == winner end)
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
end