defmodule Battle.Service.BattleService.RoomSupervisorTest do
  use DynamicSupervisor

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Service.WebService.WebSocketHandler
  alias Battle.Utils.Token

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ets.new(:pid_info_test, [:named_table, :public, read_concurrency: true])
    opts = [strategy: :one_for_one]
    DynamicSupervisor.init(opts)
  end

  def init_game() do
    contest_id = UUID.uuid4()
    token_white = Token.generate_token(10, contest_id)
    token_black = Token.generate_token(24, contest_id)
    child_spec_server = %{
      id: RoomServer,
      start: {RoomServer, :start_link, [%{white: 10, black: 24, contest_id: contest_id}]},
      restart: :transient,
      type: :worker
    }
    DynamicSupervisor.start_child(__MODULE__, child_spec_server)
    {:ok, %{token_white: token_white, token_black: token_black}}
  end

  def query(caller, user_id, contest_id) do
    [{pid, _}] = Registry.lookup(Battle.RoomRegistry, contest_id)
    case RoomServer.query(pid, user_id) do
        {:ok, detail} ->
          # 当前询问回合，写回成功
          {:ok, detail}
        {:error, detail} ->
          :ets.insert(:pid_info_test, {contest_id, caller})
          # 不是当前询问回合，写回错误
          {:error, detail}
    end
  end

  def movement(caller, moves, user_id, contest_id) do
    case Registry.lookup(Battle.RoomRegistry, contest_id) do
      [{pid, _}] ->
        case RoomServer.movement(pid, user_id, moves) do
          {:ok, success_detail} ->
            move_detail = Map.get(success_detail, :your_step)
            new_detail = success_detail
            |> Map.put(:opponent_step, move_detail)
            |> Map.delete(:your_step)
            if success_detail.winner do
              RoomServer.terminate_game_test(pid)
            end
            [{_, dest}] = :ets.lookup(:pid_info_test, contest_id)
            :ets.insert(:pid_info_test, {contest_id, caller})
            send(WebSocketHandler, {:update_board, success_detail})
            send(dest, {:new_detail, new_detail})
            {:ok, success_detail}
          {:error, error_detail} ->
            {:error, error_detail}
        end

      [] ->
        {:error, "room not found"}
      end
  end
end
