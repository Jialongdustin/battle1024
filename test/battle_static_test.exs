defmodule BattleTest.BattleStatisticsTest do
  use ExUnit.Case
  doctest Battle.Mongo.BattleStatistics

  require Logger

  alias Battle.Mongo.BattleStatistics
  alias Battle.Mongo.BattleResult


  test "save init" do
    BattleStatistics.save_init()
  end

  test "update static info" do
    BattleStatistics.delete_message()
    BattleStatistics.save_init()
    update_info = %{
      user_count: 1,
      submit_count: 1,
      average_step: 20,
      average_time_cost: 30
    }
    BattleStatistics.update_statistics_info(update_info.user_count,update_info.submit_count,update_info.average_step,update_info.average_time_cost)
    {:ok,after_res} = BattleStatistics.query_statistics_info()
    assert update_info.user_count == after_res.user_count && update_info.submit_count == after_res.submit_count

  end

  test "add_user" do
    BattleStatistics.delete_message()
    BattleStatistics.save_init()
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
    BattleStatistics.delete_message()
    BattleStatistics.save_init()

    {:ok,moment_token} = Battle.Utils.Token.generate_token("656599a4-65b4-11ef-bdb1-b2a3d4b2d740")
    {:ok,pre_res} = BattleStatistics.query_statistics_info()

    steps = 40
    times = 10000
    BattleStatistics.update_average_step(40)
    BattleStatistics.update_average_time_cost(times)
    {:ok,after_res} = BattleStatistics.query_statistics_info()
    IO.inspect(after_res)
    assert steps/2 == after_res.average_step && times/1000/2 == after_res.average_time_cost

  end

  test "update submit time" do
    update_time = Ejoy.Bson.utc_now()
    BattleStatistics.update_last_commit_time(update_time)
    {:ok,user_info} = BattleStatistics.query_statistics_info()
    assert user_info.last_submit_time == update_time
  end
end