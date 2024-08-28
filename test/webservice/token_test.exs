defmodule BattleTest.TokenTest do
  use ExUnit.Case
  use Plug.Test
  doctest Battle.Utils.Token
  alias Battle.Utils.Token

  test "game token" do
    user_id = "aaa"
    contest_id = "dds"
    {:ok,token} = Token.generate_token(user_id,contest_id)
    {:ok,user_info} = Token.verify_token_battle(token)
    assert %{ext: %{account_id: contest_id}, user_id: user_id, user_type: 2}
 == user_info
  end
end