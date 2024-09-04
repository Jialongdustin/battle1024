defmodule RankListTest do
  use ExUnit.Case
  #  doctest Battle.BattleDfs
  doctest Battle.BattleHandler

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Mongo.BattleResult
  alias Battle.Service.WebService.RankList


  test "get rank list" do
    Battle.Mongo.RankList.save_rank("aaa","jahaja",1)
    Battle.Mongo.RankList.save_rank("acac","haha",0.2)
    {:ok,rank_info} = Battle.Mongo.RankList.get_rank_list(0,2)
    rank_rate = Enum.reduce(rank_info,[],fn message,acc ->
    acc++[message.rate]
    end)
    Battle.Mongo.RankList.remove_rank("aaa")
    Battle.Mongo.RankList.remove_rank("acac")
    assert Enum.all?([1,0.2],fn user_info -> user_info in rank_rate end)
  end

  test "rank self without game" do
    user_id = "acac"
    ai_name = "jajaja"
    Battle.Mongo.User.save_user(user_id,"12312","niu")
    Battle.Mongo.UserAi.insert_ai(user_id,ai_name)
    {:error, single_info} = Battle.Mongo.RankList.get_rank_by_user_id(user_id)
    Battle.Mongo.User.remove_user(user_id)
    Battle.Mongo.UserAi.clean_message(user_id)
    assert single_info.ai_name == ai_name
  end

  test "rank self without commit" do
    user_id = "aaa"
    Battle.Mongo.User.save_user(user_id,"12sds312","niu11")
    {:error, single_info} = Battle.Mongo.RankList.get_rank_by_user_id(user_id)
    Battle.Mongo.User.remove_user(user_id)
    assert single_info.last_submit_date == nil
  end

end