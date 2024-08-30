defmodule Battle.Service.BattleService.RoomSupervisorTest do
  use DynamicSupervisor

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Utils.Token

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ets.new(:pid_info_test, [:named_table, :public, read_concurrency: true])
    opts = [strategy: :one_for_one]
    DynamicSupervisor.init(opts)
  end

  # game_id = "d9279888-1962-494c-aed9-1058dfd2805a"
  def init_game() do
    game_id = UUID.uuid4()
    {:ok, token_black} = Token.generate_token(24, game_id)
    {:ok, token_white} = Token.generate_token(10, game_id)
    child_spec_server = %{
      id: RoomServer,
      start: {RoomServer, :start_link, [%{white: 10, black: 24, game_id: game_id}]},
      restart: :transient,
      type: :worker
    }
    DynamicSupervisor.start_child(__MODULE__, child_spec_server)
    [{pid, _}] = Registry.lookup(Battle.RoomRegistry, game_id)
    RoomServer.start_countdown(pid, true)
    {:ok, %{
      token_white: token_white,
      token_black: token_black,
      game_id: game_id
    }}
  end

  def query(caller, user_id, game_id) do
    case Registry.lookup(Battle.RoomRegistry, game_id) do
      [{pid, _}] ->
        RoomServer.start_countdown(pid, true)
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
    case Registry.lookup(Battle.RoomRegistry, game_id) do
      [{pid, _}] ->
        RoomServer.start_countdown(pid, true)
        case RoomServer.movement(pid, user_id, moves) do
          {:ok, success_detail} ->
            # 将your_step改为opponent_step
            if success_detail.winner do
              RoomServer.terminate_game_test(pid)
            end
            case :ets.lookup(:pid_info_test, game_id) do
              [] -> # 对方没有查询
                {:ok, success_detail}
              [{_, dest}] -> # 对方查询棋盘状态
                :ets.delete(:pid_info_test, game_id)
                send(dest, {:query, success_detail})
                {:ok, success_detail}
            end

          {:error, error_detail} ->
            {:error, error_detail}
        end
      [] ->
        {:error, "room not found"}
    end
  end
end
