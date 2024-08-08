defmodule Battle.RoomServer do
  use GenServer

  def start_link(opts) do
    white = opts[:white]
    black = opts[:black]
    board = [[]]
    initial_state = %{
      white: white,
      black: black,
      board: board,
      early_hand: true,
      can_move: [[]],
      steps: [[[]]]
    }
    GenServer.start_link(__MODULE__, initial_state, name: white)
  end

  def init(state) do
    {:ok, state}
  end
end
