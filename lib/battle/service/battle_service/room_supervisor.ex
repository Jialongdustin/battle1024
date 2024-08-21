defmodule Battle.Service.BattleService.RoomSupervisor do
  use DynamicSupervisor

  require Logger

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Utils.Token


  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ets.new(:pid_info, [:named_table, :public, read_concurrency: true])
    opts = [strategy: :one_for_one]
    DynamicSupervisor.init(opts)
  end

  def init_game(white, black) do
    contest_id = UUID.uuid4()
    child_spec = {RoomServer, white: white, black: black, contest_id: contest_id}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
    {:ok, contest_id}
  end

  def join(moment_token) do
    Logger.info(moment_token)
#    {:ok,user_info} = Token.verify_token_battle(moment_token)
#    user_id = user_info.user_id
#    contest_id = user_info.ext.account_id

#    case Registry.lookup(Battle.RoomRegistry,contest_id) do
#      [{pid,_}] ->
#        RoomServer.add_player(pid,user_id)
#      [] ->
#        {:error, "room not found"}
#    end

    detail = %{
      code: 100,
      black: "user_id_1",
      white: "user_id_2"
    }

    {:ok,detail}
  end

  def battle_handler(handle_detail,moment_token) do
    [[x0, y0], [x1, y1]] = Jason.decode!(handle_detail)
    Logger.info("#{x0}<>   <>#{y0}<>   <>#{x1}<>   <>#{y1}")
    Logger.info(moment_token)

#    {:ok,user_info} = Token.verify_token_battle(moment_token)
##    user_id = user_info.user_id
#    contest_id = user_info.ext.account_id
#
##    case Registry.lookup(Battle.RoomRegistry,contest_id) do
##      [{pid,_}] ->
##        RoomServer.movement(pid,x0,y0,x1,y1)
##      [] ->
##        {:error, "room not found"}
##    end

    detail = %{
      code: "init",
      winner: "",
      white_king: "user_id_2",
      black_king: "user_id_1",
      opponent_step: [[1,1],[1,3]],
      captured: [[1,2]]
    }
    {:ok,detail}
  end
end
