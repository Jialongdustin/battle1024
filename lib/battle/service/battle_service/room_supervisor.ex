defmodule Battle.Service.BattleService.RoomSupervisor do
  use DynamicSupervisor

  require Logger

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Utils.Token
  alias Battle.Utils.Convert

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ets.new(:pid_info, [:named_table, :public, read_concurrency: true])
    opts = [strategy: :one_for_one]
    DynamicSupervisor.init(opts)
  end

  def init_game(white, black, game_id, groupName, groupKey, appName, test \\ false) do
    # child_spec_server = {RoomServer, white: white, black: black, game_id: game_id}
    child_spec_server = %{
      id: RoomServer,
      start: {RoomServer, :start_link, [%{white: white, black: black, game_id: game_id, groupName: groupName, groupKey: groupKey, appName: appName}]},
      restart: :transient,
      type: :worker
    }
    DynamicSupervisor.start_child(__MODULE__, child_spec_server)
    if test do
      [{pid, _}] = Registry.lookup(Battle.RoomRegistry, game_id)
      RoomServer.time_counter(pid)
    end
    {:ok, game_id}
  end

  def query(caller, user_id, game_id) do
    case Registry.lookup(Battle.RoomRegistry, game_id) do
      [{pid, _}] ->
        case RoomServer.query(pid, user_id) do
          {:ok, detail} ->
            # 当前询问回合，写回成功
            RoomServer.start_countdown(pid)
            RoomServer.start_time_step(pid)
            {:ok, detail}
          {:error, detail} ->
            :ets.insert(:pid_info, {game_id, caller})
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
        case RoomServer.movement(pid, user_id, Convert.convert_index_into_integer(moves)) do
          {:ok, success_detail} ->
            RoomServer.start_countdown(pid)
            RoomServer.record_time_step(pid, user_id)
            if success_detail.winner do
              RoomServer.terminate_game(pid)
            end
            case :ets.lookup(:pid_info, game_id) do
              [] -> # 对方没有查询
                {:ok, success_detail}
              [{_, dest}] -> # 对方查询棋盘状态
                :ets.delete(:pid_info, game_id)
                send(dest, {:query, success_detail})
                if success_detail.winner == nil do
                  RoomServer.start_time_step(pid)
                  RoomServer.start_countdown(pid)
                end
                {:ok, success_detail}
            end
          {:error, error_detail} ->
            RoomServer.terminate_game(pid)
            {:error, error_detail}
        end
      [] ->
        {:error, "room not found"}
      end
  end
end
