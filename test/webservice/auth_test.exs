defmodule BattleTest.AuthTest do
  use ExUnit.Case
  import Mock
  #  doctest Battle.BattleDfs
  doctest Battle.Service.WebService.Auth
  alias Battle.Service.WebService.Auth
  alias Battle.Utils.Token


  test "verify code success"do
    with_mock Ejoy.HttpRPC, [:passthrough], [
      application_json_post: fn _, _ ->
        {:ok, %{"account" => "11456","name" => "bommoe"}}
      end
    ] do
      # Mock UUID generation to return a predictable UUID
      with_mock UUID, [:passthrough], [
        uuid1: fn -> "test-uuid-1234" end
      ] do
        {:ok,user_info} = Auth.verify_code("123")
        {:ok,moment_token} = Battle.Utils.Token.generate_token("test-uuid-1234")
        assert Token.verify_token(user_info) == Token.verify_token(moment_token)
      end
    end
  end

  test "verify code error " do
    with_mock Ejoy.HttpRPC, [:passthrough], [
      application_json_post: fn _, _ ->
        {:ok, %{"code" => 10040,"message" => "permission deny"}}
      end
    ] do
      # Mock UUID generation to return a predictable UUID
      {:error,error_info} = Auth.verify_code(123)
      assert error_info == 10040
    end
  end

  Battle.Service.WebService.Auth.verify_code("AQZQMTEzODdHqdz1EzRG0mzK2wu5Fl2m8XrzPR0o2WZm19adL2aMyXGtXTbcDqTau2FlHGOlf6zh57aA")

end