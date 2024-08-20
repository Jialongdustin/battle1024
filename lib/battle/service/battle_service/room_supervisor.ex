defmodule Battle.Service.BattleService.RoomSupervisor do
  use DynamicSupervisor

  require Logger

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Service.BattleService.ConnectionStore
  alias Battle.Utils.Token


  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    opts = [strategy: :one_for_one]
    DynamicSupervisor.init(opts)
  end

  def init_game(white, black,contest_id) do
    child_spec_server = {RoomServer, white: white, black: black, contest_id: contest_id}
    DynamicSupervisor.start_child(__MODULE__, child_spec_server)
    {:ok, contest_id}
  end

#  def join(moment_token) do
  def query(user_id,contest_id) do

    case Registry.lookup(Battle.RoomRegistry,contest_id) do
      [{pid,_}] ->
        case RoomServer.query(pid, user_id) do
          {:ok, detail} ->
            # 当前询问回合，写回成功
            {:ok, detail}
          {:error, reason} ->
            # 不是当前询问回合，写回错误
            {:error,reason}
          end
      [] ->
        {:error, "room not found"}
    end
  end

  def movement(moves,user_id,contest_id) do

    case Registry.lookup(Battle.RoomRegistry,contest_id) do
      [{pid,_}] ->
        case RoomServer.movement(pid,user_id,moves) do
          {:ok,success_detail} ->
            {:ok,success_detail}
          {:error,error_detail} ->
            {:error,error_detail}
        end
      [] ->
        {:error, "room not found"}
    end
  end
end


