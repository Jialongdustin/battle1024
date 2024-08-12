defmodule Battle.Service.BattleService.RoomServer do
  use GenServer

  require Logger

  @timeout 3000
  @board_init [
                [0, 0, 0, 0, 0, 0, 0, 0],
                [1, 1, 1, 1, 1, 1, 1, 1],
                [1, 1, 1, 1, 1, 1, 1, 1],
                [0, 0, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 0, 0],
                [2, 2, 2, 2, 2, 2, 2, 2],
                [2, 2, 2, 2, 2, 2, 2, 2],
                [0, 0, 0, 0, 0, 0, 0, 0]
              ]

  @can_move_init ["3a", "3b", "3c", "3d", "3e", "3f", "3g", "3h"]

  def start_link(opts) do
    white = opts[:white]
    black = opts[:black]
    contest_id = opts[:contest_id]
    initial_state = %{
      white: white,
      black: black,
      board: @board_init,
      early_hand: true,
      can_move: @can_move_init,
      steps: [],
      time_ref: nil
    }
    GenServer.start_link(__MODULE__, initial_state, name: :"#{contest_id}")
  end

  def init(state) do
    {:ok, state}
  end

  def start_countdown(timeout \\ @timeout) do
    GenServer.call(__MODULE__, {:start_countdown, timeout})
  end

  def handle_call({:start_countdown, timeout}, _from, state) do
    if state.time_ref do
      Process.cancel_timer(state.time_ref)
    end
    new_ref = Process.send_after(self(), :execute_task, timeout)
    new_state = %{state | time_ref: new_ref}
    {:reply, :ok, new_state}
  end

  def handle_info(:execute_task, state) do
    Logger.info("overtime operation")
    {:noreply, state}
  end
end
