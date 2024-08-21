defmodule Battle.RoomServer do
  use ExUnit.Case
  doctest Battle.Service.BattleService.RoomSupervisor

  require Logger

  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Service.BattleService.RoomServer
  alias Battle.Utils.Token


  test "init game" do
    user_id_1 = "123"
    user_id_2 = "456"
    {:ok,contest_id} = RoomSupervisor.init_game(user_id_1,user_id_2)

    [{pid,_}] = Registry.lookup(Battle.RoomRegistry,contest_id)

    # 验证 contest_id 对应的进程已经存在
    Logger.info(inspect(pid))
    assert is_pid(pid)

  end


  test "join game" do
    user_id_1 = "123"
    user_id_2 = "456"
    {:ok,contest_id} = RoomSupervisor.init_game(user_id_1,user_id_2)
    Logger.info(contest_id)

    info = %{
      code: 100,
      black: "user_id_1",
      white: "user_id_2"
    }

    {:ok,moment_token} = Token.generate_token(user_id_1,contest_id)
    assert RoomSupervisor.join(moment_token) == {:ok,info}

  end

end