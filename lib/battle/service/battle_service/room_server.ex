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
    {init_move,_} = Battle.BattleHandler.move_list(@board_init,true)
    initial_state = %{
      white: white,
      black: black,
      contest_id: contest_id,
      board: @board_init,
      early_hand: true,
      can_move: init_move,
      steps: [],
      time_ref: nil,
      white_joined: false,
      black_joined: false,
      count_white: 0,
      count_black: 0

    }

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
  def query(pid, user_id) do
    GenServer.call(pid, {:query, user_id})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:start_countdown, timeout}, _from, state) do
    if state.time_ref do
      Process.cancel_timer(state.time_ref)
    end

    new_ref = Process.send_after(self(), :execute_task, timeout)
    new_state = %{state | time_ref: new_ref}
    {:reply, :ok, new_state}
  end
  def handle_call({:query, user_id}, from, state) do
    winner =
      case{count_piece([1,2],state.board),count_piece([3,4],state.board)} do
        {0,_} -> state.black
        {_,0} -> state.white
        _ -> nil
      end

    if (user_id == state.white and state.early_hand == true) or
    (user_id == state.black and state.early_hand == false) do
      detail = %{
        code: Map.get(@code_info, 100),
        winner: winner,
        board: state.board,
        available_step: state.can_move
      }

      {:reply, {:ok, detail}, state}
    else
      detail = %{
        code: Map.get(@code_info, 300),
        winner: winner,
        board: state.board,
        available_step: nil
      }
      {:reply, {:ok, detail}, state}
    end
  end

  # 具体战斗逻辑
  def movement(pid, moves,user_id) do
    GenServer.call(pid, {:movement, moves, user_id})
  end

  def handle_call({:movement,user_id, moves}, _from, state) do
    white = state.early_hand
    board = state.board
    move_list = state.can_move

    is_match =
      Enum.any?(move_list, fn path ->
        Enum.take(path, 2) == moves
      end)

    # 如果路径正确需要更新棋盘
    case is_match do
      true ->

        [[x0, y0], [x1, y1]] = moves
        # 判断有没有吃子
        # 确保 x0..x1 和 y0..y1 的范围是从小到大
        x_range = Enum.sort([x0, x1])
        y_range = Enum.sort([y0, y1])

        capture =
          for x <- Enum.at(x_range,0)..Enum.at(x_range,1), y <- Enum.at(y_range,0)..Enum.at(y_range,1), reduce: nil do
            acc ->
              # 确保不在起点位置
              if x != x0 or y != y0 do
                case Enum.at(Enum.at(state.board, x), y) do
                  0 -> acc  # 如果是 0，保持现有的 acc，不改变
                  value when acc == nil -> [x, y]  # 如果是第一个非零值，记录该坐标
                  _ -> acc  # 如果已经有非零值，保持原样
                end
              else
                acc  # 如果在起点位置，则继续累积原值
              end
          end
        [cx,cy] =
          case capture do
            nil ->
              [nil,nil]
            _ -> capture
          end


        {node_value,white_king,black_king} =
          case {Enum.at(Enum.at(board, x0), y0), x1} do
            {2, _} -> {2,nil,nil}
            {4, _} -> {4,nil,nil}
            {1, x} when x == length(board) - 1 -> {2,[x,y1],nil}
            {1, _} -> {1,nil,nil}
            {3, 0} -> {4,nil,[0,y1]}
            {3, _} -> {3,nil,nil}
          end

        update =
          case [cx, cy] do
            [nil, nil] ->
              [
                {x0, y0, 0},
                {x1, y1, node_value}
              ]
            _ ->
              [
                {x0, y0, 0},
                {cx, cy, 0},
                {x1, y1, node_value}
              ]
          end

        new_board = Enum.reduce(update,board, fn {row, col, new_value}, acc ->
          update_row = List.replace_at(Enum.at(acc, row), col, new_value)
          List.replace_at(acc, row, update_row)
        end)
        {can_move,flag} = Battle.BattleHandler.move_list(new_board, white)

        new_state =
          case state.early_hand do
            true -> # white
              case {capture,flag} do
                # 当前棋子没有吃子,只是普通移动
                {nil,_} ->
                  {can_move,_} = Battle.BattleHandler.move_list(new_board, !white)
                  %{
                    state |
                    board: new_board,
                    early_hand: !white,
                    can_move: can_move,
                    steps: [moves | state.steps],
                    count_white: state.count_white+1
                  }
                {_,false} ->
                  # 当前棋子吃了子,下一步不能吃了
                  {can_move,_} = Battle.BattleHandler.move_list(new_board, !white)
                  %{
                    state |
                    board: new_board,
                    early_hand: !white,
                    can_move: can_move,
                    steps: [moves | state.steps],
                    white_joined: true,
                    count_white: state.count_white+1
                  }
                _ ->
                  # 吃了子还能继续吃，还是当前棋子的回合
                  %{
                    state |
                    board: new_board,
                    early_hand: white,
                    can_move: can_move,
                    steps: [moves | state.steps],
                    white_joined: true,
                    count_white: state.count_white+1
                  }
              end
            false -> # black
              case {capture,flag} do
                # 当前棋子没有吃子,只是普通移动
                {nil,_} ->
                  {can_move,_} = Battle.BattleHandler.move_list(new_board, !white)
                  %{
                    state |
                    board: new_board,
                    early_hand: !white,
                    can_move: can_move,
                    steps: [moves | state.steps],
                    count_white: state.count_black+1
                  }
                {_,false} ->
                  {can_move,_} = Battle.BattleHandler.move_list(new_board, !white)
                  # 当前棋子吃了子,下一步不能吃了
                  %{
                    state |
                    board: new_board,
                    early_hand: !white,
                    can_move: can_move,
                    steps: [moves | state.steps],
                    white_joined: true,
                    count_white: state.count_black+1
                  }
                _ ->
                  # 吃了子还能继续吃，还是当前棋子的回合
                  %{
                    state |
                    board: new_board,
                    early_hand: white,
                    can_move: can_move,
                    steps: [moves | state.steps],
                    white_joined: true,
                    count_white: state.count_black+1
                  }
              end
          end

        # 如果有一方的棋子为零，另外一方获胜
        winner = case{count_piece([1,2],new_board),count_piece([3,4],new_board)} do
          {0,_} -> state.black
          {_,0} -> state.white
          _ -> nil
        end

        # 返回可移动路径给机器人
        available_step =
          Enum.map(can_move, fn list ->
            Enum.map(list, fn inner_list ->
              Enum.take(inner_list, 2)
            end)
        end)

        detail = %{
          code: Map.get(@code_info,100),
          winner: winner,
          white_king: white_king,
          black_king: black_king,
          opponent_step: moves,
          captured: [cx, cy],
          board: new_board,
          available_step: available_step
        }
        IO.inspect(new_state)
        {:reply, {:ok, detail}, new_state}

      false ->
        available_step =
          Enum.map(state.can_move, fn list ->
            Enum.map(list, fn inner_list ->
              Enum.take(inner_list, 2)
            end)
          end)
        detail = %{
          code: Map.get(@code_info,200),
          winner: nil,
          white_king: nil,
          black_king: nil,
          opponent_step: nil,
          captured: nil,
          board: nil,
          available_step: available_step
        }
        {:reply, {:error, detail}, state}
    end
  end

  def handle_info({:wait_opponent_move,user_id,capture,node_value,white_king,black_king},state) do
    if (user_id == state.white and state.early_hand == true)
       or (user_id == state.black and state.early_hand == false) do
      available_step =
        Enum.map(state.can_move, fn list ->
          Enum.map(list, fn inner_list ->
            Enum.take(inner_list, 2)
          end)
        end)

      winner = case{count_piece([1,2],state.board),count_piece([3,4],state.board)} do
        {0,_} -> state.black
        {_,0} -> state.white
        _ -> nil
      end

      detail = %{
        code: Map.get(@code_info,100),
        winner: winner,
        white_king: white_king,
        black_king: black_king,
        opponent_step: List.first(state.steps),
        captured: capture,
        board: state.board,
        available_step: available_step
      }
       end
  end

  defp count_piece(piece_value,board) do
    count =
      board
      |> Enum.flat_map(& &1)  # 将二维数组扁平化为一维
      |> Enum.count(fn piece -> piece in piece_value end) # 检查每种颜色棋子的个数
  end

end
