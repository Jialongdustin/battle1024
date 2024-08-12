defmodule Battle.Service.BattleService.RoomSupervisor do
  use DynamicSupervisor

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Token
  alias Battle.Service.BattleService.RoomRegistry

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
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
    {:ok,user_info} = Token.verify_token(moment_token)
    user_id = user_info.user_id
    contest_id = user_info.contest_id

    case Registry.lookup(RoomRegistry,contest_id) do
      [{pid,_}] ->
        RoomServer.add_player(pid,user_id)
      [] ->
        {:error, "room not found"}
    end

  end
end

# alias Battle.Service.BattleService.RoomSupervisor
# RoomSupervisor.join_game("A", "B")
# Logger.configure(level: :none)
