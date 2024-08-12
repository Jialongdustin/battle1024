defmodule Battle.Service.BattleService.RoomSupervisor do
  use DynamicSupervisor

  alias Battle.Service.BattleService.RoomServer

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    opts = [strategy: :one_for_one]
    DynamicSupervisor.init(opts)
  end

  def join_game(white, black) do
    contest_id = UUID.uuid4()
    child_spec = {RoomServer, white: white, black: black, contest_id: contest_id}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
    {:ok, contest_id}
  end

  def join(user_id) do

  end
end

# alias Battle.Service.BattleService.RoomSupervisor
# RoomSupervisor.join_game("A", "B")
# Logger.configure(level: :none)
