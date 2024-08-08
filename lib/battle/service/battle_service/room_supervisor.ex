defmodule Battle.RoomSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    opts = [strategy: :one_for_one]
    DynamicSupervisor.init(opts)
  end
end
