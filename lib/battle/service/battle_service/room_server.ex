defmodule Battle.Service.BattleService.RoomServer do
  use GenServer

  require Logger

  alias Battle.Mongo.BattleResult
  alias Battle.Mongo.BattleInfo
  alias Battle.Mongo.BattleStatistics
  alias Battle.Mongo.BattleResultTest
  alias Battle.Mongo.UserAi
  alias Battle.Utils.Convert
  alias Battle.Service.BattleService.RoomSupervisorTest

  @timeout 3000
  @timeout_test 180_000
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
    game_id = opts[:game_id]
    groupName = opts[:groupName]
    groupKey = opts[:groupKey]
    appName = opts[:appName]
    package_name = opts[:package_name]
    {init_move, _} = Battle.BattleHandler.move_list(@board_init, true)
    initial_state = %{
      code: 10002,
      white: white,
      black: black,
      game_id: game_id,
      winner: nil,
      board: @board_init,
      early_hand: true,
      can_move: init_move,
      steps: [],
      illegal_times: [0, 0],
      time_ref: nil,
      time_ref_test: nil,
      time_ref_verify: nil,
      steps_white: 0,
      steps_black: 0,
      group_name: groupName,
      group_key: groupKey,
      app_name: appName,
      query_white: false,
      query_black: false,
      pre_step_white: %{move: [],cnt: 0},
      pre_step_black: %{move: [],cnt: 0},
      time_cost_white: 0,
      time_cost_black: 0,
      time_counter_white: 0,
      time_counter_black: 0,
      package_name: package_name
    }
    GenServer.start_link(__MODULE__, initial_state, name: via_tuple(game_id))
  end

  def init(state) do
    {:ok, state}
  end

  def start_countdown(pid, query \\ false) do
    GenServer.call(pid, {:start_countdown, @timeout, query})
  end

  def start_countdown_test(pid) do
    GenServer.call(pid, {:start_countdown_test, @timeout_test})
  end

  # 玩家加入战斗
  def query(pid, user_id) do
    GenServer.call(pid, {:query, user_id})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def start_time_step(pid) do
    GenServer.call(pid, :start_time_step)
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
    GenServer.call(pid, :terminate_game_test)
  end

  def time_counter(pid) do
    GenServer.call(pid, :time_counter)
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:time_counter, _from, state) do
    if state.time_ref_verify do
      Process.cancel_timer(state.time_ref_verify)
      {:reply, :ok, %{state | time_ref_verify: nil}}
    else
      new_ref_test = Process.send_after(self(), :execute_task_verify, @timeout_test)
      {:reply, :ok, %{state | time_ref_verify: new_ref_test}}
    end
  end

  def handle_call(:start_time_step, _from, state) do
    case state.early_hand do
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
        {:reply, step_cost, %{state | time_cost_black: new_time_cost}}
    end
  end

  def handle_call(:terminate_game, _from, state) do
    if state.white == "10" and state.black == "24" do
      BattleResultTest.update_battle_result(state.game_id, state.white, state.winner,
        [state.time_cost_white, state.time_cost_black], ["1G", "2G"], [state.steps_white, state.steps_black], state.package_name)
      BattleInfo.insert_battle(state.game_id, state.steps_white + state.steps_black, state.steps)
      send(Battle.Service.BattleService.ThreadPoolTest, {:terminate, state.game_id, state.group_name, state.group_key, state.app_name})
    else if state.white == "1024" or state.black == "1024" do
      :ok
    else
      # 每一局的信息
      BattleStatistics.update_average_step(state.steps_white + state.steps_black)
      BattleStatistics.update_average_time_cost(state.time_cost_white + state.time_cost_black)
      BattleInfo.insert_battle(state.game_id, state.steps_white + state.steps_black, state.steps)
      BattleResult.update_battle_result_success(state.game_id, state.winner, [state.time_cost_white, state.time_cost_black], ["1G", "2G"], state.white, [state.steps_white, state.steps_black])
      send(Battle.Service.BattleService.ThreadPool, {:terminate, state.game_id, state.group_name, state.group_key, state.app_name})
    end
    {:stop, :normal, :ok, state}
    end
  end

  def handle_call(:terminate_game_test, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_call({:start_countdown, timeout, query}, _from, state) do
    case query do
      ## 如果是query请求
      true ->
        new_ref = if state.time_ref, do: state.time_ref, else: Process.send_after(self(), :execute_task, timeout)
        {:reply, :ok, %{state | time_ref: new_ref}}

      ## 如果是move请求
      false ->
        if state.time_ref do
          Process.cancel_timer(state.time_ref)
        end
        {:reply, :ok, %{state | time_ref: nil}}
    end
  end

  def handle_call({:start_countdown_test, timeout}, _from, state) do
    if state.time_ref_test do
      Process.cancel_timer(state.time_ref_test)
    end
    new_ref_test = Process.send_after(self(), :execute_task_test, timeout)
    {:reply, :ok, %{state | time_ref_test: new_ref_test}}
  end

  def handle_call({:query, user_id}, _from, state) do
    if (user_id == state.white and state.early_hand == true) or
    (user_id == state.black and state.early_hand == false) do
      detail = %{
        code: state.code,
        board: Convert.convert_array_list(state.board),
        winner: state.winner,
      }
      if user_id == state.white do
        {:reply, {:ok, detail}, %{state | query_white: true}}
      else
        {:reply, {:ok, detail}, %{state | query_black: true}}
      end

    else
      if user_id == state.white do
        {:reply, {:error, "not your turn, please wait for your opponent move"}, %{state | query_white: true}}
      else
        {:reply, {:error, "not your turn, please wait for your opponent move"}, %{state | query_black: true}}
      end
    end
  end

  def handle_call({:movement, user_id, moves}, _from, state) do
    if (user_id == state.white && state.query_white == false) or
       (user_id == state.black && state.query_black == false) do
      if user_id == state.white do
        {:reply,{:error, "send query request before move"},%{state| winner: state.black}}
      else
        {:reply,{:error, "send query request before move"},%{state| winner: state.white}}
      end

    else


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

          # 确定 capture 的值
          capture =
            case get_captures(moves, state.board) do
              [] ->
                # 如果没有捕获的棋子
                [
                  %{captured: nil, moves: Convert.convert_integer_into_string(moves)}
                ]
              res ->
                # 如果有捕获的棋子，直接使用返回值
                res
            end

          # 提取初始位置和最终位置
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
            movement: capture
          }

          {new_state, detail} =
            case state.early_hand do
              # white
              true ->
                case check_repeat_move(state, moves, capture) do
                  {:continue, new_detail} ->
                    {
                      %{
                        state |
                        code: 10003,
                        board: new_board,
                        winner: winner,
                        early_hand: !white,
                        pre_step_white: new_detail.pre_step_white,
                        pre_step_black: new_detail.pre_step_black,
                        can_move: can_move,
                        steps: state.steps ++ [move_detail],
                        steps_white: state.steps_white + 1,
                        query_white: false
                      },
                      %{
                        code: 10000,
                        winner: winner,
                        king: white_king,
                        move_detail: move_detail,
                        board: Convert.convert_array_list(new_board)
                      }
                    }
                  {:game_over, winner} ->
                      {
                        %{
                          state |
                          code: 10001,
                          board: new_board,
                          winner: winner,
                          early_hand: !white,
                          can_move: can_move,
                          steps: state.steps ++ [move_detail],
                          steps_white: state.steps_white + 1
                        },
                        %{
                          code: 30001,
                          winner: winner,
                          king: nil,
                          move_detail: nil,
                          board: nil
                        }
                      }
                end

              # black
              false ->
                case check_repeat_move(state,moves,capture) do
                  {:continue, new_detail} ->
                    {
                      %{
                        state |
                        code: 10003,
                        board: new_board,
                        winner: winner,
                        early_hand: !white,
                        pre_step_white: new_detail.pre_step_white,
                        pre_step_black: new_detail.pre_step_black,
                        can_move: can_move,
                        steps: state.steps ++ [move_detail],
                        steps_black: state.steps_black + 1,
                        query_black: false
                      },
                      %{
                        code: 10000,
                        winner: winner,
                        king: black_king,
                        move_detail: move_detail,
                        board: Convert.convert_array_list(new_board)
                      }
                    }
                  {:game_over, winner} ->
                    {
                      %{
                        state |
                        code: 10001,
                        board: new_board,
                        winner: winner,
                        early_hand: !white,
                        can_move: can_move,
                        steps: state.steps ++ [move_detail],
                        steps_black: state.steps_black + 1
                      },
                      %{
                        code: 30001,
                        winner: winner,
                        king: nil,
                        move_detail: nil,
                        board: nil
                      }
                    }
                end
            end
          case new_state.winner do
            nil ->
              winner = count_total_piece(new_state, capture)
              {new_state, detail} =
                case winner do
                  0 -> # 平局
                    {%{new_state | winner: 0, code: 10001}, %{detail | winner: 0,code: 10001}}

                  winner when is_integer(winner) or is_binary(winner) -> # 已经有赢家且 winner 是整数或二进制（字符串）
                    {%{new_state | winner: winner, code: 10001}, %{detail | winner: winner,code: 10001}}

                  nil -> # 还没有赢家，继续
                    {new_state, detail}
                end
                {:reply, {:ok, detail}, new_state}
            _ ->
              {:reply, {:ok, %{detail | code: 10001}}, new_state}
          end

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
            board: Convert.convert_array_list(state.board),
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
            cond do
              state.white == "10" && state.black == "24" && state.app_name == nil -> state.winner
              state.early_hand == true -> state.black
              true -> state.white
            end

          {:reply, {:error, %{detail | winner: new_winner}}, %{state | illegal_times: [illegal_times_white, illegal_times_black], winner: new_winner}}
      end
    end
  end

  def handle_info(:execute_task, state) do
    IO.puts "overtime operation"
    case state.early_hand do
      true ->
        {:noreply, %{state | winner: state.black}}
      false ->
        {:noreply, %{state | winner: state.white}}
    end
  end

  def handle_info(:execute_task_test, state) do
    IO.puts "overtime operation of testing"
    {:stop, :normal, state}
  end

  def handle_info(:execute_task_verify, state) do
    IO.puts "overtime operation of verify"
    BattleResultTest.update_battle_result_failed(state.game_id, "overtime")
    send(Battle.Service.BattleService.ThreadPoolTest, {:terminate, state.game_id, state.group_name, state.group_key, state.app_name})
    {:stop, :normal, state}
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Battle.RoomRegistry, game_id}}
  end

  def count_total_piece(new_state, get_captures) do
    # 获取各类棋子的数量
    count_diff_pieces = {
      count_piece([1], new_state.board),
      count_piece([2], new_state.board),
      count_piece([3], new_state.board),
      count_piece([4], new_state.board)
    }

    # 根据棋子数量判断胜者
    winner = case {count_diff_pieces,List.first(get_captures)} do
      # 一方有一个普通棋子和一个王棋，另一方有一个普通棋子
      {{_, 1, 1, 0}, %{captured: nil, moves: _}} ->
        new_state.white  # 白方胜
      {{1, 0, _, 1}, %{captured: nil, moves: _}} ->
        new_state.black  # 黑方胜
      # 双方各有一个普通棋子
      {{1, 0, 1, 0}, %{captured: nil, moves: _}} ->
        0  # 平局
      # 双方各有一个王棋
      {{0, 1, 0, 1}, %{captured: nil, moves: _}} ->
        0  # 平局
      # 如果有其他情况，暂时设置为没有赢家
      {{0, 0, _, _}, _} ->
        new_state.black
      {{_, _, 0, 0}, _} ->
        new_state.white
      _ ->
        nil
    end
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
                  value when acc_inner == nil -> %{moves: Convert.convert_integer_into_string([[x0, y0], [x1, y1]]), captured: Convert.convert_capture([x, y])}
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

  def get_update(capture, node_value, x0, y0, x1, y1) do
    update_info = Enum.reduce(capture, [], fn message, acc ->
      if message.captured == nil do
        acc ++ [%{captured: nil, moves: Convert.convert_index_into_integer(message.moves)}]
      else
        acc ++ [%{captured: Convert.convert_capture_s_to_i(message.captured), moves: Convert.convert_index_into_integer(message.moves)}]
      end
    end)
    res = Enum.reduce(update_info, [{x0, y0, 0}], fn
      %{captured: nil, moves: [[x0, y0], [x1, y1]]}, acc ->
        acc ++ [{x1, y1, node_value}]

      %{captured: captures, moves: [[x0, y0], [x1, y1]]}, acc ->
        [cx, cy] = captures
        capture_updates =  [{cx, cy, 0}]
        acc ++ capture_updates
    end)
    res ++ [{x1, y1, node_value}]
  end

  def check_repeat_move(state, moves, capture) do
    # 提取初始位置和最终位置
    [[x0, y0] | _] = moves
    [x1, y1] = List.last(moves)

    new_state =
      case List.first(capture) do
        %{captured: nil, moves: _} ->
        if state.early_hand do
          if [[x0, y0], [x1, y1]] == state.pre_step_white.move do
            if state.pre_step_white.cnt >= 2 do
              # 重复下子超过3次
              if state.pre_step_black.cnt >2 do
                new_state = %{state | winner: 0}
              else
                new_state = %{state | pre_step_white: %{move: [[x1, y1], [x0, y0]], cnt: state.pre_step_white.cnt + 1}}
              end
            else
              new_state = %{state | pre_step_white: %{move: [[x1, y1], [x0, y0]], cnt: state.pre_step_white.cnt + 1}}
            end
          else
            new_state = %{state | pre_step_white: %{move: [[x1, y1], [x0, y0]], cnt: 1}}
          end
        else
          if [[x0, y0], [x1, y1]] == state.pre_step_black.move do
            if state.pre_step_black.cnt >= 2 do
              # 重复下子超过3次
              if state.pre_step_white.cnt >2 do
                new_state = %{state | winner: 0}
              else
                new_state = %{state | pre_step_black: %{move: [[x1, y1], [x0, y0]], cnt: state.pre_step_black.cnt + 1}}
              end

            else
              new_state = %{state | pre_step_black: %{move: [[x1, y1], [x0, y0]], cnt: state.pre_step_black.cnt + 1}}
            end
          else
            new_state = %{state | pre_step_black: %{move: [[x1, y1], [x0, y0]], cnt: 1}}
          end
        end
      _res ->
        if state.white do
          %{state | pre_step_white: %{move: nil, cnt: 0}}
        else
          %{state | pre_step_black: %{move: nil, cnt: 0}}
        end
    end
    new_detail = %{
      winner: new_state.winner,
      pre_step_white: new_state.pre_step_white,
      pre_step_black: new_state.pre_step_black,
    }
    case new_state.winner do
      nil ->
        {:continue, new_detail}
      res ->
        {:game_over, new_state.winner}
    end
  end
end
