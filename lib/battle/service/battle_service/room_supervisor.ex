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

  def init_game(white, black) do
    contest_id = UUID.uuid4()
    child_spec_server = {RoomServer, white: white, black: black, contest_id: contest_id}
    child_spec_connection = {ConnectionStore}
    DynamicSupervisor.start_child(__MODULE__, child_spec_server)
    DynamicSupervisor.start_child(__MODULE__, child_spec_server)
    {:ok, contest_id}
  end

#  def join(moment_token) do
  def join(user_id,contest_id,conn) do

    case Registry.lookup(Battle.RoomRegistry,contest_id) do
      [{pid,_}] ->
        case RoomServer.add_player(pid, user_id) do
          {:ok, detail} ->
            # 白子先手直接写回，白子已经下完到黑子也直接写回
            {:ok, detail, conn}
          {:error, reason} ->
            # 存起来黑子的conn，白子下棋后调用
            ConnectionStore.store_connection(contest_id,conn)
            {:error,"not your turn"}
          end
      [] ->
        {:error, "room not found"}
    end


  end

  def battle_handler(moves,capture,user_id,contest_id) do

    case Registry.lookup(Battle.RoomRegistry,contest_id) do
      [{pid,_}] ->
        case RoomServer.movement(pid,user_id,moves,capture) do
          {:ok,success_detail} ->
            {:ok,success_detail}
          {:error,error_detail} ->
            {:error,error_detail}
        end
      [] ->
        {:error, "room not found"}
    end

#    detail = %{
#      code: "init",
#      winner: "",
#      white_king: "user_id_2",
#      black_king: "user_id_1",
#      opponent_step: [[1,1],[1,3]],
#      captured: [[1,2]]
#    }
#    {:ok,detail}
  end
end

# alias Battle.Service.BattleService.RoomSupervisor
# RoomSupervisor.join_game("A", "B")
# Logger.configure(level: :none)
