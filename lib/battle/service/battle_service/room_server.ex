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
    [3, 3, 3, 3, 3, 3, 3, 3],
    [3, 3, 3, 3, 3, 3, 3, 3],
    [0, 0, 0, 0, 0, 0, 0, 0]
  ]

  def start_link(opts) do
    white = opts[:white]
    black = opts[:black]
    contest_id = opts[:contest_id]

    initial_state = %{
      white: white,
      black: black,
      board: @board_init,
      early_hand: true,
      can_move: Battle.BattleHandler.move_list(@board_init,true),
      steps: [],
      time_ref: nil
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

  def start_countdown(pid, timeout \\ @timeout) do
    GenServer.call(pid, {:start_countdown, timeout})
  end

  # 玩家加入战斗
  def add_player(pid, user_id) do
    GenServer.call(pid, {:add_player, user_id})
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
  def movement(pid, moves,capture) do
    GenServer.call(pid, {:movement, moves, capture})
  end

  def handle_call({:movement, moves, capture}, _from, state) do

    IO.inspect(state)
    white = state.early_hand
    board = state.board
    move_list = state.can_move

    is_match =
      Enum.any?(move_list, fn path ->
        Enum.take(path, 2) == moves
      end)

    [[x0, y0], [x1, y1]] = moves
    [cx, cy] = capture

    {node_value,white_king,black_king} =
      case {Enum.at(Enum.at(board, x0), y0), x1} do
        {2, _} -> {2,nil,nil}
        {4, _} -> {4,nil,nil}
        {1, x} when x == length(board) - 1 -> {2,[x,y1],nil}
        {1, _} -> {1,nil,nil}
        {3, 0} -> {4,nil,[0,y1]}
        {3, _} -> {3,nil,nil}
      end

    code_info = %{100 => "good choice", 200 => "illegal movement, please try again"}
    # 如果路径正确需要更新棋盘
    case is_match do
      true ->
        update = [
          {x0, y0, 0},
          {cx, cy, 0},
          {x1, y1, node_value}
        ]
        new_board = Enum.reduce(update,board, fn {row, col, new_value}, acc ->
          update_row = List.replace_at(Enum.at(acc, row), col, new_value)
          List.replace_at(acc, row, update_row)
        end)
        can_move = Battle.BattleHandler.move_list(new_board, !white)
        new_state = %{
          white: state.white,
          black: state.black,
          board: new_board,
          early_hand: !white,
          can_move: can_move,
          steps: [moves | state.steps],
          time_res: nil
        }

        IO.inspect(new_state)

        winner = case{count_piece([1,2],new_board),count_piece([3,4],new_board)} do
          {0,_} -> state.black
          {_,0} -> state.white
          _ -> nil
        end
        available_step =
          Enum.map(can_move, fn list ->
            Enum.map(list, fn inner_list ->
              Enum.take(inner_list, 2)
            end)
        end)
        detail = %{
          code: Map.get(code_info,100),
          winner: winner,
          white_king: white_king,
          black_king: black_king,
          opponent_step: moves,
          captured: capture,
          board: new_board,
          available_step: available_step
        }

        {:reply, {:ok, detail}, new_state}

      false ->
        available_step =
          Enum.map(state.can_move, fn list ->
            Enum.map(list, fn inner_list ->
              Enum.take(inner_list, 2)
            end)
          end)
        detail = %{
          code: Map.get(code_info,200),
          winner: nil,
          white_king: nil,
          black_king: nil,
          opponent_step: nil,
          captured: nil,
          board: nil,
          available_step: available_step
        }
        {:reply, {:ok, detail}, state}
    end


  end
  defp count_piece(piece_value,board) do
    count =
      board
      |> Enum.flat_map(& &1)  # 将二维数组扁平化为一维
      |> Enum.count(fn piece -> piece in piece_value end)
  end
end
