defmodule BattleTest.UserTest do
  use ExUnit.Case
  use Plug.Test
  doctest Battle.Mongo.User

  alias Battle.Mongo.User


  test "save user" do
    User.save_user(1,123132)
  end

  test "query user info" do
    {:ok, res} = User.query_user(1)
  end

end