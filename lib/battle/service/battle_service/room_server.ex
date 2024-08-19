defmodule Battle.Service.BattleService.RoomServer do
  use GenServer

  require Logger
  @code_info %{100 => "your turn to move",
  200 => "illegal movement, please try again",
  300 => "not your turn, please try again"
  }

  alias Battle.Mongo.BattleResult
  alias Battle.Mongo.BattleInfo
  @timeout 3000
  @board_init [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [3, 3, 3, 3, 3, 3, 3, 3],
    [3, 3, 3, 3, 3, 3, 3, 3],
    [0, 0, 0, 0, 0, 0, 0, 0]
  ]

  def start_link(opts) do
    white = opts[:white]
    black = opts[:black]
    contest_id = opts[:contest_id]
    groupName = opts[:groupName]
    groupKey = opts[:groupKey]
    appName = opts[:appName]
    initial_state = %{
      white: white,
      black: black,
      contest_id: contest_id,
      board: @board_init,
      early_hand: true,
      can_move: [],
      steps: [],
      illegal_times: [0, 0],
      time_ref: nil,
      white_joined: false,
      black_joined: false,
      count_white: 0,
      count_black: 0,
      group_name: groupName,
      group_key: groupKey,
      app_name: appName
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

  def terminate_game(contest_id) do
    GenServer.call(via_tuple(contest_id), :terminate_game)
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

  def handle_call({:terminate_game,}, _from, state) do
    # 持久化存储对局信息
    Process.send(Battle.Service.BattleService.ThreadPool, {state.contest_id, state.group_name, state.group_key, state.app_name})
    {:stop, :game_over, state}
  end

  def handle_info(:execute_task, %{illegal_times: illegal_times, early_hand: early_hand} = state) do
    Logger.info("overtime operation")
    case early_hand do
      true ->
        illegal_times_white = Enum.at(illegal_times, 0) + 1
        if(illegal_times_white == 3) do
          :terminate_game
        end
      false ->
        illegal_times_black = Enum.at(illegal_times, 1) + 1
        if(illegal_times_black == 3) do
          :terminate_game
        end
    end
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
    {:reply, {:ok, detail}, state}
  end

  defp via_tuple(contest_id) do
    {:via, Registry, {Battle.RoomRegistry, contest_id}}
  end
end
