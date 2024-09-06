defmodule BattleTest.AuthTest do
  use ExUnit.Case
  import Mock
  #  doctest Battle.BattleDfs
  doctest Battle.Service.WebService.Auth
  alias Battle.Service.WebService.Auth
  alias Battle.Utils.Token
  alias Battle.Mongo.User


  test "verify code success old user "do
    User.save_user("test-uuid-1234","11456","bommoe")

    with_mock Ejoy.HttpRPC, [:passthrough], [
      application_json_post: fn _, _ ->
        {:ok, %{"account" => "11456","name" => "bommoe"}}
      end
    ] do
        {:ok,user_info} = Auth.verify_code("123")
        {:ok,moment_token} = Battle.Utils.Token.generate_token("test-uuid-1234")
        User.remove_user("test-uuid-1234")
        assert Token.verify_token(user_info) == Token.verify_token(moment_token)
    end
  end

  test "verify code success new user"do
    with_mock Ejoy.HttpRPC, [:passthrough], [
      application_json_post: fn _, _ ->
        {:ok, %{"account" => "123324","name" => "ben"}}
      end
    ] do
      # Mock UUID generation to return a predictable UUID
      with_mock UUID, [:passthrough], [
        uuid1: fn -> "test-uuid-4567" end
      ] do
        {:ok,user_info} = Auth.verify_code("123")
        {:ok,moment_token} = Battle.Utils.Token.generate_token("test-uuid-4567")
        User.remove_user("test-uuid-4567")
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
end
