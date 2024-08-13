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
    GenServer.start_link(__MODULE__, initial_state, name: via_tuple(contest_id))
  end

  def init(state) do
    {:ok, state}
  end

  def start_countdown(contest_id, timeout \\ @timeout) do
    GenServer.call(via_tuple(contest_id), {:start_countdown, timeout})
  end
  # 玩家加入战斗
  def add_player(contest_id, user_id) do
    GenServer.call(via_tuple(contest_id), {:add_player, user_id})
  end


  def handle_call({:start_countdown, timeout}, _from, state) do
    if state.time_ref do
      Process.cancel_timer(state.time_ref)
    end
    new_ref = Process.send_after(self(), :execute_task, timeout)
    new_state = %{state | time_ref: new_ref}
    {:reply, :ok, new_state}
  end

  def handle_call({:add_player, user_id}, _from, state) do
    #    new_state = Map.put(state.players,user_id,%{joined: true})
    #    {:reply, :ok, new_state}
    detail = %{
      code: 100,
      black: "user_id_1",
      white: "user_id_2"
    }

    {:reply, {:ok, detail}, state}
  end

  def handle_info(:execute_task, state) do
    Logger.info("overtime operation")
    {:noreply, state}
  end

  # 具体战斗逻辑
  def movement(contest_id, x0, y0,x1,y1) do
    GenServer.call(via_tuple(contest_id), {:movement,x0,y0,x1,y1})
  end

  def handle_call({:movement, x0,y0,x1,y1}, _from, state) do
    Logger.info("#{x0}   #{y0}   #{x1}   #{y1}")
    detail = %{
      code: "init",
      winner: "",
      white_king: "user_id_2",
      black_king: "user_id_1",
      opponent_step: [[1,1],[1,3]],
      captured: [[1,2]]
    }
    {:reply, {:ok,detail}, state}
  end

  defp via_tuple(contest_id) do
    {:via, Registry, {Battle.RoomRegistry, contest_id}}
  end
end
