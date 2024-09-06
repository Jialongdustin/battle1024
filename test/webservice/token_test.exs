defmodule BattleTest.TokenTest do
  use ExUnit.Case
  use Plug.Test
  doctest Battle.Utils.Token
  alias Battle.Utils.Token

  test "game token" do
    user_id = "aaa"
    game_id = "dds"
    {:ok,token} = Token.generate_token(user_id,game_id)
    {:ok,user_info} = Token.verify_token_battle(token)
    assert %{ext: %{game_id: game_id}, user_id: user_id}
 == %{ext: %{game_id: user_info.ext.game_id},user_id: user_info.user_id}
  end

  test "moment_token" do
    user_id = "acsd"
    {:ok,token} = Token.generate_token(user_id)
    {:ok,user_info} = Token.verify_token(token)
    assert user_info == user_id
  end

  test "ejoy token" do
    {:ok,token,token_info} = Ejoy.MomentToken.new_token_info(1,1,"123123",%{game_id: "1111"})
    {:ok,db_info} = Ejoy.MomentToken.Service.auth_token(token)
  end
end