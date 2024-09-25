defmodule Battle.Service.BattleService.RoomSupervisorTest do
  use DynamicSupervisor

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Service.WebService.Kun
  alias Battle.Utils.Token
  alias Battle.Utils.Convert
  alias Battle.Ai.Simple

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ets.new(:pid_info_test, [:named_table, :public, read_concurrency: true])
    :ets.new(:user_id_test, [:named_table, :public, read_concurrency: true])
    opts = [strategy: :one_for_one]
    DynamicSupervisor.init(opts)
  end

  # Battle.Service.BattleService.RoomSupervisorTest.init_game("111", false)
  def init_game(user_id, white) do
    game_id = UUID.uuid4()
    {:ok, token_user} = Token.generate_token(user_id, game_id)
    child_spec_server = %{
      id: RoomServer,
      start: {RoomServer, :start_link, [%{white: if(white, do: user_id, else: "1024"), black: if(white, do: "1024", else: user_id), game_id: game_id}]},
      restart: :transient,
      type: :worker
    }
    DynamicSupervisor.start_child(__MODULE__, child_spec_server)
    [{pid, _}] = Registry.lookup(Battle.RoomRegistry, game_id)
    :ets.insert(:user_id_test, {user_id, game_id})
    RoomServer.start_countdown_test(pid)
    if white do
      {:ok, %{token: token_user, game_id: game_id}}
    else
      battle_state = RoomServer.get_state(pid)
      movement = Simple.move(battle_state.board, true)
      RoomServer.query(pid, "1024")
      RoomServer.movement(pid, "1024", movement)
      {:ok, %{token: token_user, game_id: game_id}}
    end
  end

  def query(caller, user_id, game_id) do
    case Registry.lookup(Battle.RoomRegistry, game_id) do
      [{pid, _}] ->
        case RoomServer.query(pid, user_id) do
          {:ok, detail} ->
            # 当前询问回合，写回成功
            {:ok, detail}
          {:error, detail} ->
            :ets.insert(:pid_info_test, {game_id, caller})
            # 不是当前询问回合，写回错误
            {:error, detail}
        end
      [] ->
        {:room_error, "game is over, do not query again"}
    end
  end

  def movement(moves, user_id, game_id) do
    IO.inspect(moves)
    case Registry.lookup(Battle.RoomRegistry, game_id) do
      [{pid, _}] ->
        if user_id != "1024" do
          RoomServer.start_countdown_test(pid)
        end
        case RoomServer.movement(pid, user_id, Convert.convert_index_into_integer(moves)) do
          {:ok, success_detail} ->
            battle_state = RoomServer.get_state(pid)
            if success_detail.winner do
              RoomServer.terminate_game_test(pid)
            else
              movement = Simple.move(battle_state.board, user_id == battle_state.black)
              RoomServer.query(pid, "1024")
              RoomServer.movement(pid, "1024", movement)
            end
            {:ok, success_detail}
          {:error, error_detail} ->
            {:error, error_detail}
        end
      [] ->
        {:error, "room not found"}
    end
  end

  def delete_room(user_id) do
    case :ets.lookup(:user_id_test, user_id) do
      [] -> # 对方没有查询
        {:error, "no test of current user"}
      [{_, game_id}] -> # 对方查询棋盘状态
        :ets.delete(:user_id_test, game_id)
        [{pid, _}] = Registry.lookup(Battle.RoomRegistry, game_id)
        RoomServer.terminate_game(pid)
        {:ok, "delete success"}
    end
  end
end
