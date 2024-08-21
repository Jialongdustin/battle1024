defmodule BattleTest.RoomServerTest do
  use ExUnit.Case
  doctest Battle.Mongo.BattleStatistics

  require Logger

  alias Battle.Mongo.BattleStatistics
  alias Battle.Mongo.BattleResult

  test "count" do
    res = BattleStatistics.count()
    IO.inspect(res)
  end

  test "save_init" do
    BattleStatistics.save_init()
  end

  test "add_user" do
    {:ok,pre_res} = BattleStatistics.query_statistics_info()

    BattleStatistics.user_increment()

    {:ok,after_res} = BattleStatistics.query_statistics_info()
    assert pre_res.user_count == after_res.user_count-1
  end

  test "add_submit" do
    {:ok,pre_res} = BattleStatistics.query_statistics_info()

    BattleStatistics.submit_increment()

    {:ok,after_res} = BattleStatistics.query_statistics_info()
    assert pre_res.submit_count == after_res.submit_count-1
  end
  test "calculate average" do
    {:ok,pre_res} = BattleStatistics.query_statistics_info()

    steps = 40
    BattleStatistics.update_average_step(1,steps)

    {:ok,after_res} = BattleStatistics.query_statistics_info()
    assert pre_res.average_step*(BattleResult.count_battle()-1) ==
             after_res.submit_count*BattleResult.count_battle()-steps
  end
end