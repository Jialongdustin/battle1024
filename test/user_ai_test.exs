defmodule Mongo.UserAi do
  use ExUnit.Case
  doctest Battle.Mongo.UserAi
  alias Battle.Mongo.UserAi



  test "get ai name " do
    user_id = "453912"
    ai_name = "AI_biubiubiu"
    UserAi.insert_ai(user_id,ai_name)
    {:ok,name} = UserAi.get_ai_name(user_id)
    UserAi.clean_message(user_id)
    assert name == ai_name
  end

  test "get all git" do

    user_id = "453912"
    ai_name = "AI_biubiubiu"
    git_url = "http://example.com/repo1.git"
    tag = "1.0"

    user_id_2 = "1212312"
    ai_name_2 = "biubibui"
    git_url_2 = "csca.com"
    tag_2 = "main"

    UserAi.insert_ai(user_id,ai_name)
    UserAi.update_git(user_id,git_url,tag)

    UserAi.insert_ai(user_id_2,ai_name_2)
    UserAi.update_git(user_id_2,git_url_2,tag_2)

    {:ok,user_info} = UserAi.get_all_gits()

    UserAi.clean_message(user_id)
    UserAi.clean_message(user_id_2)
    insert_info = [%{
      user_id: user_id,
      git_url: git_url,
      tag: tag
    },
    %{
      user_id: user_id_2,
      git_url: git_url_2,
      tag: tag_2
    }
    ]

    assert insert_info == user_info
  end

  test "get gits and user_infos"do

    user_id = "453912"
    ai_name = "AI_biubiubiu"
    git_url = "http://example.com/repo1.git"
    tag = "1.0"

    UserAi.insert_ai(user_id,ai_name)
    UserAi.update_git(user_id,git_url,tag)
    {:ok,user_info} = UserAi.get_newest_ai_by_userId(user_id)
    UserAi.clean_message(user_id)
    assert user_info.user_id == user_id && user_info.git_url == git_url && user_info.tag == tag

  end

  test "get all package_name distinct" do
#    UserAi.insert_ai("11","hahaha")
#    UserAi.update_git("11","ben.com","main","111")
#    UserAi.update_git("11","ljl.com","master","aa11")
#    UserAi.update_git("11","ljl.com","ben","aa11222")
#    UserAi.insert_ai("22","biubiubiu")
#    UserAi.update_git("22","ben.com","main","111")
    UserAi.update_git("22","ljl.com","mainnnn","111111")
    info = UserAi.get_all_gits()
    IO.inspect(info)
  end
end
