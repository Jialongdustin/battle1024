defmodule BattleTest.RoomSupervisorTest do
  use ExUnit.Case
  use Plug.Test
  doctest Battle.Service.BattleService.RoomSupervisor

  import Mock
  require Logger

  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Service.BattleService.RoomServer
  alias Battle.Utils.Token
  alias Battle.Web.Router

  @opts Router.init([])

  test "init game" do
    user_id_1 = "123"
    user_id_2 = "456"
    game_id = "aa"

    {:ok,contest_id} = RoomSupervisor.init_game(user_id_1,user_id_2,game_id,"a","b","c")

    [{pid,_}] = Registry.lookup(Battle.RoomRegistry,contest_id)

    # 验证 contest_id 对应的进程已经存在

    assert is_pid(pid)

  end

  test "receive do" do
    user_id_1 = "123"
    user_id_2 = "456"
    game_id = "aa"
    {:ok,contest_id} = RoomSupervisor.init_game(user_id_1,user_id_2,game_id,"a","b","c")

    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token_battle: fn _ ->
        {:ok, %{user_id: user_id_2, ext: %{account_id: game_id}}}
      end
    ] do
      request_body = %{"token" => "aslkfgasg"}
      conn =
        :post
        |> conn("/play/query", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

    end

    with_mock Battle.Utils.Token, [:passthrough], [
      verify_token_battle: fn _ ->
        {:ok, %{user_id: user_id_1, ext: %{account_id: game_id}}}
      end
    ] do
      request_body = %{"token" => "aslkfgasg"}
      conn =
        :post
        |> conn("/play/query", Ejoy.Jiffy.encode!(request_body))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)
    end

    RoomSupervisor.movement(Battle.Utils.Convert.convert_integer_into_string([[2, 0], [3, 0]]), "123", game_id)

  end


end