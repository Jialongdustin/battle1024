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
  def join(user_id,contest_id) do

#    Logger.info(moment_token)
#    {:ok,user_info} = Token.verify_token_battle(moment_token)
#    user_id = user_info.user_id
#    contest_id = user_info.ext.account_id

    case Registry.lookup(Battle.RoomRegistry,contest_id) do
      [{pid,_}] ->
        case RoomServer.add_player(pid, user_id) do
          {:ok, detail} ->
            {:ok, detail}
          {:error, reason} ->
            {:error, reason}
          end
      [] ->
        {:error, "room not found"}
    end


  end

  def battle_handler(moves,capture,user_id,contest_id) do

    case Registry.lookup(Battle.RoomRegistry,contest_id) do
      [{pid,_}] ->
#        case RoomServer.movement(pid,user_id,moves,capture) do
#          {}
#        end
        RoomServer.movement(pid,user_id,moves,capture)
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
