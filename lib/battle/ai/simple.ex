defmodule Battle.Ai.Simple do
  use GenServer

  alias Battle.BattleHandler

  def start_link(opts) do
    initial_state = %{}
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_args) do
    {:ok, %{}}
  end

  def move(board,white) do
    {move_list,_} = BattleHandler.move_list(board,white)
    Enum.random(move_list)
  end


end
