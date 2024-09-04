defmodule BattleTest.UserTest do
  use ExUnit.Case
  use Plug.Test
  doctest Battle.Mongo.User

  alias Battle.Mongo.User


  test "save user and query" do
    user_id = UUID.uuid1()
    account = "woc"
    user_name = "ljl"
    User.save_user(user_id,account,user_name)
    {:ok,res} = User.query_user_by_account(account)
    assert res.user_id == user_id && user_name == user_name
  end

  test "query user name" do
    user_id = UUID.uuid1()
    account = "woccow"
    user_name = "ljljl"
    User.save_user(user_id,account,user_name)
    {:ok,db_user_name} = User.get_user_name(user_id)
    assert db_user_name == user_name
  end

end