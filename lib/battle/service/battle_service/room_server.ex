defmodule Battle.Service.BattleService.RoomServer do
  use GenServer

  require Logger

  @code_info %{
    100 => "your turn to move",
    101 => "move success, please wait until your opponent move",
    102 => "winner occurred!!! no need to move",
    200 => "illegal movement, please try again",
    300 => "not your turn, please try again"
  }

  alias Battle.Mongo.BattleResult
  alias Battle.Mongo.BattleInfo

  @timeout 10_000
  # @board_init [
  #   [0, 0, 0, 0, 0, 0, 0, 0],
  #   [1, 1, 1, 1, 1, 1, 1, 1],
  #   [1, 1, 1, 1, 1, 1, 1, 1],
  #   [0, 0, 0, 0, 0, 0, 0, 0],
  #   [0, 0, 0, 0, 0, 0, 0, 0],
  #   [3, 3, 3, 3, 3, 3, 3, 3],
  #   [3, 3, 3, 3, 3, 3, 3, 3],
  #   [0, 0, 0, 0, 0, 0, 0, 0]
  # ]
  @board_init [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [1, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0]
  ]

  def start_link(opts) do
    white = opts[:white]
    black = opts[:black]
    contest_id = opts[:contest_id]
    groupName = opts[:groupName]
    groupKey = opts[:groupKey]
    appName = opts[:appName]
    {init_move, _} = Battle.BattleHandler.move_list(@board_init, true)
    initial_state = %{
      white: white,
      black: black,
      contest_id: contest_id,
      winner: nil,
      board: @board_init,
      early_hand: true,
      can_move: init_move,
      steps: [],
      illegal_times: [0, 0],
      time_ref: nil,
      steps_white: 0,
      steps_black: 0,
      group_name: groupName,
      group_key: groupKey,
      app_name: appName,
      time_cost_white: 0,
      time_cost_black: 0,
      time_counter_white: 0,
      time_counter_black: 0,
    }
#    GenServer.start_link(__MODULE__, initial_state, name: :"#{contest_id}")
    GenServer.start_link(__MODULE__, initial_state, name: via_tuple(contest_id))
  end

  defp via_tuple(contest_id) do
    {:via, Registry, {Battle.RoomRegistry, contest_id}}
  end

  def init(state) do
    {:ok, state}
  end

  def start_countdown(pid,timeout \\ @timeout) do
    GenServer.call(pid, {:start_countdown, timeout})
  end
  # 玩家加入战斗
  def add_player(pid,user_id) do
    GenServer.call(pid,{:add_player, user_id})
  end


  def handle_call({:start_countdown, timeout}, _from, state) do
    if state.time_ref do
      Process.cancel_timer(state.time_ref)
    end
    new_ref = Process.send_after(self(), :execute_task, timeout)
    {:reply, :ok, %{state | time_ref: new_ref}}
  end

  def handle_call({:add_player,user_id},_from,state) do
    #    new_state = Map.put(state.players,user_id,%{joined: true})
    #    {:reply, :ok, new_state}
    detail = %{
      code: 100,
      black: "user_id_1",
      white: "user_id_2"
    }

    {:reply,{:ok,detail},state}
  end

  def handle_info(:execute_task, state) do
    Logger.info("overtime operation")
    {:noreply, state}
  end

  # 具体战斗逻辑
  def movement(pid,x0,y0,x1,y1) do
    GenServer.call(pid,{:movement,x0,y0,x1,y1})
  end

  def handle_call({:movement,x0,y0,x1,y1},_from,state) do
    Logger.info("#{x0}   #{y0}   #{x1}   #{y1}")
    detail = %{
      code: "init",
      winner: "",
      white_king: "user_id_2",
      black_king: "user_id_1",
      opponent_step: [[1,1],[1,3]],
      captured: [[1,2]]
    }
    {:reply,{:ok,detail},state}
  end
end
