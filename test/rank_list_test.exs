defmodule BattleTest do
  use ExUnit.Case
  #  doctest Battle.BattleDfs
  doctest Battle.BattleHandler

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Mongo.BattleResult
  alias Battle.Service.WebService.RankList

  test "calculate rate" do
    res = RankList.get_battle_info()
    IO.inspect(res)
  end

  test "insert into rank list db" do
    {:ok,user_infos} = Battle.Service.WebService.RankList.get_battle_info()
    Battle.Service.WebService.RankList.insert_win_rate(user_infos)
    {:ok,get_infos} = Battle.Mongo.RankList.get_rank_list(0,6)
    IO.inspect(get_infos)
    IO.inspect(user_infos)
    # 忽略 `date` 和 `_id` 字段

    # 检查所有的 sanitized_user_infos 是否都在 sanitized_get_infos 中
    assert Enum.all?(user_infos, fn user_info -> user_info in get_infos end)
  end

  test "get rank list" do
    res = Battle.Mongo.RankList.get_rank_list(1,2)
    IO.inspect(res)
  end

  test "rank self" do
    {:ok, single_info} = Battle.Mongo.RankList.get_rank_by_user_id(2)
    IO.inspect(single_info)
  end

end