defmodule Battle.Service.BattleService.RoomServer do
  use GenServer

  require Logger

  @code_info %{
    100 => "your turn to move",
    101 => "move success as well as your ",
    102 => "winner occurred!!! no need to move",
    200 => "illegal movement, please try again",
    300 => "not your turn, please wait for your opponent move"
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
    GenServer.start_link(__MODULE__, initial_state, name: via_tuple(contest_id))
  end

  def init(state) do
    {:ok, state}
  end

  def start_countdown(pid, timeout \\ @timeout) do
    GenServer.call(pid, {:start_countdown, timeout})
  end

  # 玩家加入战斗
  def query(pid, user_id) do
    GenServer.call(pid, {:query, user_id})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def start_time_step(pid, user_id) do
    GenServer.call(pid, {:start_time_step, user_id})
  end

  def record_time_step(pid, user_id) do
    GenServer.call(pid, {:record_time_step, user_id})
  end

   # 具体战斗逻辑
   def movement(pid, user_id, moves) do
    GenServer.call(pid, {:movement, user_id, moves})
  end

  def terminate_game(pid) do
    GenServer.call(pid, :terminate_game)
  end

  def terminate_game_test(pid) do
    GenServer.stop(pid)
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:start_time_step, user_id}, _from, state) do
    case user_id == state.white do
      true ->
        {:reply, :ok, %{state | time_counter_white: DateTime.utc_now()}}
      false ->
        {:reply, :ok, %{state | time_counter_black: DateTime.utc_now()}}
    end
  end

  def handle_call({:record_time_step, user_id}, _from, state) do
    case user_id == state.white do
      true ->
        step_cost = DateTime.utc_now()
        |> DateTime.diff(state.time_counter_white, :millisecond)
        new_time_cost = state.time_cost_white + step_cost
        {:reply, step_cost, %{state | time_cost_white: new_time_cost}}
      false ->
        step_cost = DateTime.utc_now()
        |> DateTime.diff(state.time_counter_black, :millisecond)
        new_time_cost = state.time_cost_black + step_cost
        {:reply, step_cost, %{state | time_cost_white: new_time_cost}}
    end
  end

  def handle_call(:terminate_game, _from, state) do
    # 每一局的信息
    Battle.Mongo.BattleStatistics.update_average_step(state.steps_white + state.steps_black)
    Battle.Mongo.BattleStatistics.update_average_time_cost(state.time_cost_white+state.time_cost_black)
    BattleInfo.insert_battle(state.contest_id, state.steps_white + state.steps_black, state.steps)
    BattleResult.save_battle_result([state.white, state.black], state.contest_id, state.winner, [state.time_cost_white, state.time_cost_black], ["1G", "2G"], state.white, [state.steps_white, state.steps_black])
    # Process.send(Battle.Service.BattleService.ThreadPool, {state.contest_id, state.group_name, state.group_key, state.app_name})
    {:stop, :normal, :ok, state}
  end

  def handle_call({:start_countdown, timeout}, _from, state) do
    if state.time_ref do
      Process.cancel_timer(state.time_ref)
    end
    new_ref = Process.send_after(self(), :execute_task, timeout)
    {:reply, :ok, %{state | time_ref: new_ref}}
  end

  def handle_call({:query, user_id}, _from, state) do
    if (user_id == state.white and state.early_hand == true) or
    (user_id == state.black and state.early_hand == false) do
      detail = %{
        code: 10002,
        board: state.board,
        winner: nil,
      }
      {:reply, {:ok, detail}, state}
    else
      {:reply, {:error, Map.get(@code_info, 300)}, state}
    end
  end

  def handle_call({:movement, user_id, moves}, _from, state) do
    white = state.early_hand
    board = state.board
    move_list = state.can_move
    winner =
      case {count_piece([1, 2], board), count_piece([3, 4], board)} do
        {0, _} -> state.black
        {_, 0} -> state.white
        _ -> nil
      end
    is_match =
      Enum.any?(move_list, fn path ->
        path == moves
      end)

    # 如果路径正确需要更新棋盘
    case is_match do
      true ->
        capture = case get_captures(moves, state.board) do
          [] ->
            [
              %{captured: nil, moves: moves}
            ]
          res -> res
        end

        # 最终被吃掉的所有棋子的位置
        [[x0, y0] | _] = moves
        [x1, y1] = List.last(moves)

        {node_value, white_king, black_king} = cal_black_white_and_node_value(moves, state.board)

        # 获取所有的捕获位置，并将它们更新为 0
        update = get_update(capture, node_value, x0, y0, x1, y1)

        new_board =
          Enum.reduce(update, board, fn {row, col, new_value}, acc ->
            update_row = List.replace_at(Enum.at(acc, row), col, new_value)
            List.replace_at(acc, row, update_row)
          end)

        {can_move, flag} = Battle.BattleHandler.move_list(new_board, !white)

        move_detail = %{
          user_id: user_id,
          captured: capture
        }
        code = case winner do
          nil ->
            Map.get(@code_info, 101)
          _ ->
            Map.get(@code_info, 102)
        end
        {new_state, detail} =
          case state.early_hand do
            # white
            true ->
                # 当前棋子没有吃子, 只是普通移动
              {
                %{
                  state |
                  board: new_board,
                  winner: winner,
                  early_hand: !white,
                  can_move: can_move,
                  steps: state.steps ++ [move_detail],
                  steps_white: state.steps_white + 1
                },
                %{
                  code: 10000,
                  winner: winner,
                  king: white_king,
                  move_detail: move_detail,
                  board: new_board
                }
              }

            # black
            false ->
              {
                %{
                  state |
                  board: new_board,
                  winner: winner,
                  early_hand: !white,
                  can_move: can_move,
                  steps: state.steps ++ [move_detail],
                  steps_black: state.steps_black + 1
                },
                %{
                  code: 10000,
                  winner: winner,
                  king: white_king,
                  move_detail: move_detail,
                  board: new_board
                }
              }
          end
        IO.inspect(detail)
        {:reply, {:ok, detail}, new_state}

      false ->
        available_step =
          Enum.map(state.can_move, fn list ->
            Enum.map(list, fn inner_list ->
              Enum.take(inner_list, 2)
            end)
          end)
        detail = %{
          code: 20000,
          winner: nil,
          king: nil,
          move_detail: nil,
          board: state.board,
          # available_step: available_step
        }
        {illegal_times_white, illegal_times_black} =
          state.illegal_times
          |> case do
            [white, black] ->
              if state.white == user_id do
                {white + 1, black}
              else
                {white, black + 1}
              end
          end
        new_winner =
          case {illegal_times_white, illegal_times_black} do
            {3, _} ->
              state.black
            {_, 3} ->
              state.white
            _ ->
              state.winner
          end
        {:reply, {:error, %{detail | winner: new_winner}}, %{state | illegal_times: [illegal_times_white, illegal_times_black], winner: new_winner}}
    end
  end

  def handle_info(:execute_task, %{illegal_times: illegal_times, early_hand: early_hand} = state) do
    IO.puts "overtime operation"
    case early_hand do
      true ->
        illegal_times_white = Enum.at(illegal_times, 0) + 1
        illegal_times_black = Enum.at(illegal_times, 1)
        if(illegal_times_white == 3) do
          {:noreply, %{state | winner: state.white}}
        else
          {:noreply, %{state | illegal_times: [illegal_times_white, illegal_times_black]}}
        end
      false ->
        illegal_times_white = Enum.at(illegal_times, 0)
        illegal_times_black = Enum.at(illegal_times, 1) + 1
        if(illegal_times_black == 3) do
          {:noreply, %{state | winner: state.black}}
        else
          {:noreply, %{state | illegal_times: [illegal_times_white, illegal_times_black]}}
        end
    end
  end

  defp via_tuple(contest_id) do
    {:via, Registry, {Battle.RoomRegistry, contest_id}}
  end

  defp count_piece(piece_value,board) do
    count =
      board
      |> Enum.flat_map(& &1)  # 将二维数组扁平化为一维
      |> Enum.count(fn piece -> piece in piece_value end) # 检查每种颜色棋子的个数
  end

  def get_captures(moves,board) do
    captures =
      moves
      |> Enum.chunk_every(2, 1, :discard)  # 将路径分段，每段包含两个连续的点
      |> Enum.reduce([], fn [[x0, y0], [x1, y1]], acc ->
        # 确保 x0..x1 和 y0..y1 的范围是从小到大
        x_range = Enum.sort([x0, x1])
        y_range = Enum.sort([y0, y1])

        # 找出当前路径中被吃掉的棋子
        capture =
          for x <- Enum.at(x_range, 0)..Enum.at(x_range, 1),
              y <- Enum.at(y_range, 0)..Enum.at(y_range, 1),
              reduce: nil do
            acc_inner ->
              # 确保不在起点和终点位置
              if (x != x0 or y != y0) and (x != x1 or y != y1) do
                case Enum.at(Enum.at(board, x), y) do
                  # 如果是 0，保持现有的 acc_inner，不改变
                  0 -> acc_inner
                  # 如果是第一个非零值，记录该坐标
                  value when acc_inner == nil -> %{moves: [[x0,y0],[x1,y1]],captured: [x,y]}
                  # 如果已经有非零值，保持原样
                  _ -> acc_inner
                end
              else
                # 如果在起点或终点位置，则继续累积原值
                acc_inner
              end
          end
        # 将捕获的棋子位置加入到最终的捕获列表中
        case capture do
          nil -> acc
          _ -> acc ++ [capture]
        end
      end)
  end

  defp cal_black_white_and_node_value(moves,board) do
    [[x0, y0] | _] = moves
    [x1, y1] = List.last(moves)
    case Enum.at(Enum.at(board, x0), y0) do
      1 ->
        # 查找符合条件的 [x, y]
        case Enum.find(moves, fn [x, _y] -> x == length(board) - 1 end) do
          nil -> {1, nil, nil}  # 没有符合条件的，保持为普通白子
          [_x, y] -> {2, [length(board) - 1, y], nil}  # 找到符合条件的，白子变成白子王
        end

      2 -> {2, nil, nil}  # 已经是白子王，保持不变

      3 ->
        # 查找符合条件的 [x, y]
        case Enum.find(moves, fn [x, _y] -> x == 0 end) do
          nil -> {3, nil, nil}  # 没有符合条件的，保持为普通黑子
          [_x, y] -> {4, nil, [0, y]}  # 找到符合条件的，黑子变成黑子王
        end

      4 -> {4, nil, nil}  # 已经是黑子王，保持不变
    end
  end

  def get_update(capture, node_value,x0,y0,x1,y1) do
    res = Enum.reduce(capture, [{x0, y0, 0}], fn
      %{captured: nil, moves: [[x0, y0], [x1, y1]]}, acc ->
        acc ++ [{x1, y1, node_value}]

      %{captured: captures, moves: [[x0, y0], [x1, y1]]}, acc ->
        [cx,cy] = captures
        capture_updates =  [{cx, cy, 0}]
        acc ++ capture_updates
    end)
    res ++ [{x1, y1, node_value}]
  end

end
