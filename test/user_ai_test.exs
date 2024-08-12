defmodule Mongo.UserAi do
  use ExUnit.Case
  doctest Battle.UserAi


    test "get ai by user id" do
      user_id = 1
      ai_name = "B22"
      {:ok,user_info_list} = Battle.UserAi.get_ai_list_by_userId(user_id)

      assert Enum.all?(user_info_list, fn user_info ->
        user_info.ai_name == ai_name && user_info.user_id == user_id
      end)

    end

    test "insert ai" do
      user_id = 1
      ai_name = "B22"
      git_url = "ccc.com"
      tag = "3.0"

      {:ok,user_info_list_before} = Battle.UserAi.get_ai_list_by_userId(user_id)
      initial_length = length(user_info_list_before)
      Battle.UserAi.insert_ai(user_id,ai_name,git_url,tag)
      {:ok,user_info_list_after} = Battle.UserAi.get_ai_list_by_userId(user_id)

      assert length(user_info_list_after) == initial_length+1

      assert Enum.any?(user_info_list_after, fn user_info ->
        user_info.ai_name == ai_name && user_info.user_id == user_id
      end)
    end

    test "delete ai info" do
      user_id = 2
      ai_name = "Biubiubiu"
      git_url = "ab.com"
      tag = "1.0"

      Battle.UserAi.insert_ai(user_id,ai_name,git_url,tag)
      {:ok,user_info_before} = Battle.UserAi.get_ai_list_by_userId(user_id)
      initial_size = length(user_info_before)
      assert initial_size >0
      assert Enum.any?(user_info_before, fn user_info ->
        user_info.ai_name == ai_name && user_info.user_id == user_id
      end)

      Battle.UserAi.clean_message(user_id)
      {:ok,user_info_after} = Battle.UserAi.get_ai_list_by_userId(user_id)

      assert length(user_info_after) == 0
    end

    test "get newest ai info" do
    user_id = 1
    ai_name = "Biu biu biu~~!!"
    git_url = "biu.com"
    tag = "4.0"
    Battle.UserAi.insert_ai(user_id,ai_name,git_url,tag)
    {:ok,user_info} = Battle.UserAi.get_newest_ai_by_userId(user_id)

    assert user_info.user_id == user_id && user_info.ai_name == ai_name && user_info.git_url == git_url && user_info.tag == tag
    end

    test "get gits and user_infos"do

    user_id = 3
    ai_name = "AI_One"
    git_url = "http://example.com/repo1.git"
    tag = "1.0"

    Battle.UserAi.insert_ai(user_id,ai_name,git_url,tag)

    {:ok,user_infos} = Battle.UserAi.get_all_gits()
    assert Enum.any?(user_infos, fn message ->
      message.user_id == user_id && message.git_url == git_url && message.tag == tag
    end)
    end




end