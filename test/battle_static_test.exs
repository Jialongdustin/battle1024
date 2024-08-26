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

  test "save static info" do
    update_info = %{
      user_count: 1,
      submit_count: 1,
      average_step: 20,
      average_time_cost: 30
    }
    BattleStatistics.update_statistics_info(update_info.user_count,update_info.submit_count,update_info.average_step,update_info.average_time_cost)
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

    {:ok,moment_token} = Battle.Utils.Token.generate_token("1")
    {:ok,pre_res} = BattleStatistics.query_statistics_info()

    steps = 40
    BattleStatistics.update_average_step(1,steps)

    {:ok,after_res} = BattleStatistics.query_statistics_info()
    assert pre_res.average_step*(BattleResult.count_battle()-1) ==
             after_res.submit_count*BattleResult.count_battle()-steps
  end
end