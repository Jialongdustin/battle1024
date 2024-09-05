defmodule BattleResultTestGit do
  use ExUnit.Case
  #  doctest Battle.BattleDfs
  doctest Battle.BattleHandler

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Mongo.BattleResultTest

  test "get battle results within 24 hour" do
    {:ok, res} = BattleResultTest.get_battle_results_within_24_hour()

    res_info = Enum.reduce(res, [], fn message, acc ->
      acc ++ [%{ai_name: message.ai_name}]
    end)

    assert Enum.all?([%{ai_name: "fuck"}, %{ai_name: "牛逼"}], fn user_info -> user_info in res_info end)
  end

  test "get battle res" do
    BattleResultTest.save_battle_result("2","aaa","niubi","c.com","main")
    {:ok,code} = BattleResultTest.get_result_by_user_id("2")
    BattleResultTest.remove_all_battle("2")
    assert code == 2001
  end

  test "count submit" do
    {:ok,count} = BattleResultTest.count_submit("2")
    BattleResultTest.save_battle_result("2","aaa","niubi","c.com","main")
    BattleResultTest.update_battle_result("aaa","10","10",[10,20],["20","30"],[10,11])
    {:ok,after_count} = BattleResultTest.count_submit("2")
    BattleResultTest.remove_all_battle("2")
    assert after_count == count+1
  end


end