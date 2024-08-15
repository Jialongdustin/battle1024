defmodule Battle.BattleDfs do
  require Logger

  def dfs_lady(chess,i,j,color,n,m,pre_i,pre_j) do
    best_paths =
      Enum.reduce(pairwise([-1, 0, 1, 0, -1]), [], fn [qx, qy], acc ->
      check_lady_direction(chess, i, j, qx, qy, pre_i, pre_j, color, n, m, acc)
    end)
    if best_paths == [], do: [[[i, j]]], else: best_paths
  end

  def dfs(chess, i, j, lady, color, n, m) do
    #    Battle.BattleHandler.dfs(turkish_flag,2,0,false,"white",8,8)
    best_paths =
        Enum.reduce(pairwise([-1, 0, 1, 0, -1]), [], fn [qx, qy], acc ->
          check_normal_direction(chess, i, j, qx, qy, lady, color, n, m, acc)
        end)
    if best_paths == [], do: [[[i, j]]], else: best_paths
  end

  defp check_lady_direction(chess, i, j, qx, qy, pre_x, pre_y, color, n, m, best_paths) do
    if [qx*(-1), qy*(-1)] == [pre_x, pre_y] do
      best_paths
    else
      {nx, ny} = {i + qx, j + qy}
      explore_direction(chess, i, j, qx, qy, color, n, m, best_paths, nx, ny)
    end
  end

  def explore_direction(chess, i, j, qx, qy, color, n, m, best_paths, nx, ny) do
    if nx >= 0 and nx < n and ny >= 0 and ny < m do
      opponent_piece = Enum.at(Enum.at(chess, nx), ny)

      if (color == "white" and opponent_piece in [3, 4]) or
           (color == "black" and opponent_piece in [1, 2]) do
        explore_capture(chess, i, j, qx, qy, color, n, m, best_paths, nx, ny, nx + qx, ny + qy)
      else
        if opponent_piece == 0 do
          explore_direction(chess, i, j, qx, qy, color, n, m, best_paths, nx + qx, ny + qy)
        else
          best_paths
        end
      end
    else
      best_paths
    end
  end

  def explore_capture(chess, i, j, qx, qy, color, n, m, best_paths, nx, ny, rx, ry) do
    if rx >= 0 and rx < n and ry >= 0 and ry < m and Enum.at(Enum.at(chess, rx), ry) == 0 do
      temp = Enum.at(Enum.at(chess, nx), ny)

      updates = [
        # 修改初始位置值为0
        {i, j, 0},
        # 修改对手位置的值为0
        {nx, ny, 0},
        # 修改落点位置的值为初始位置的值
        {rx, ry, Enum.at(Enum.at(chess, i), j)}
      ]

      new_chess =
        Enum.reduce(updates, chess, fn {row, col, new_value}, acc ->
          updated_row = List.replace_at(Enum.at(acc, row), col, new_value)
          List.replace_at(acc, row, updated_row)
        end)

      current_paths = dfs_lady(new_chess, rx, ry, color, n, m, nx, ny)

      best_paths =
        Enum.map(current_paths, fn path ->
          [[i, j] | path]
        end)

      further_paths =
        explore_capture(chess, i, j, qx, qy, color, n, m, [], nx, ny, rx + qx, ry + qy)

      # 将进一步捕获的路径追加到 best_paths 中
      best_paths =
        Enum.reduce(further_paths, best_paths, fn path, acc ->
          [path | acc]
        end)
    else
      best_paths
    end
  end

  defp check_normal_direction(chess, i, j, qx, qy, lady, color, n, m, best_paths) do
    if (color == "white" and qx == -1) or (color == "black" and qx == 1) do
      best_paths
    else
      {nx, ny} = {i + qx, j + qy}

      if 0 <= nx and nx < n and 0 <= ny and ny < m and
           ((Enum.at(Enum.at(chess, nx), ny) in [1, 2] and Enum.at(Enum.at(chess, i), j) == 3) or
              (Enum.at(Enum.at(chess, nx), ny) in [3, 4] and Enum.at(Enum.at(chess, i), j) == 1)) do

        {rx, ry} = {nx + qx, ny + qy}

        if 0 <= rx and rx < n and 0 <= ry and ry < m and Enum.at(Enum.at(chess, rx), ry) == 0 do
          updates = [
            # 修改初始位置值为0
            {i, j, 0},
            # 修改对手位置的值为0
            {nx, ny, 0},
            # 修改落点位置的值为初始位置的值
            {rx, ry, Enum.at(Enum.at(chess, i), j)}
          ]

          new_chess =
            Enum.reduce(updates, chess, fn {row, col, new_value}, acc ->
              updated_row = List.replace_at(Enum.at(acc, row), col, new_value)
              List.replace_at(acc, row, updated_row)
            end)

          current_paths =
            if rx == n-1 or rx == 0 do
              dfs_lady(chess,rx,ry,color,n,m,qx,qy)
            else
              dfs(new_chess, rx, ry, lady, color, n, m)
            end

          best_paths =
            Enum.map(current_paths, fn path ->
              [[i, j] | path]
            end)
          best_paths
        else
          best_paths
        end
      else
        #        IO.puts("no path for #{i} #{j}")
        best_paths
      end
    end
  end

  defp check_normal_direction_2(chess, i, j, qx, qy, lady, color, n, m, best_paths) do
    if qx == 1 or qx == -1 do
      best_paths
    else
      {nx, ny} = {i + qx, j + qy}

      if 0 <= nx and nx < n and 0 <= ny and ny < m and
           ((Enum.at(Enum.at(chess, nx), ny) in [1, 2] and Enum.at(Enum.at(chess, i), j) == 3) or
              (Enum.at(Enum.at(chess, nx), ny) in [3, 4] and Enum.at(Enum.at(chess, i), j) == 1)) do

        {rx, ry} = {nx + qx, ny + qy}

        if 0 <= rx and rx < n and 0 <= ry and ry < m and Enum.at(Enum.at(chess, rx), ry) == 0 do
          updates = [
            # 修改初始位置值为0
            {i, j, 0},
            # 修改对手位置的值为0
            {nx, ny, 0},
            # 修改落点位置的值为初始位置的值
            {rx, ry, Enum.at(Enum.at(chess, i), j)}
          ]

          new_chess =
            Enum.reduce(updates, chess, fn {row, col, new_value}, acc ->
              updated_row = List.replace_at(Enum.at(acc, row), col, new_value)
              List.replace_at(acc, row, updated_row)
            end)

          current_paths = dfs(new_chess, rx, ry, lady, color, n, m)

          best_paths =
            Enum.map(current_paths, fn path ->
              [[i, j] | path]
            end)

          best_paths
        else
          best_paths
        end
      else
        best_paths
      end
    end
  end

  def move_list(turkish_flag, white) do
    n = length(turkish_flag)
    m = length(List.first(turkish_flag))

    best_paths_overall =
      for i <- 0..(n - 1), j <- 0..(m - 1), reduce: [] do
        acc ->
          if white do
            case Enum.at(Enum.at(turkish_flag, i), j) do
              1 ->
                paths = dfs(turkish_flag, i, j, false, "white", n, m)
                if paths != [[[i, j]]], do: update_best_paths(paths, [{i, j}], acc), else: acc

              2 ->
                paths = dfs_lady(turkish_flag, i, j, "white", n , m, 0, 0)
                if paths != [[[i, j]]], do: update_best_paths(paths, [{i, j}], acc), else: acc

              _ ->
                acc
            end
          else
            case Enum.at(Enum.at(turkish_flag, i), j) do
              3 ->
                paths = dfs(turkish_flag, i, j, false, "black", n, m)
                if paths != [[[i, j]]], do: update_best_paths(paths, [{i, j}], acc), else: acc

              4 ->
                paths = dfs_lady(turkish_flag, i, j, "black", n, m, 0, 0)
                if paths != [[[i, j]]], do: update_best_paths(paths, [{i, j}], acc), else: acc

              _ ->
                acc
            end
          end
      end

    if best_paths_overall == [] do


      for i <- 0..(n - 1), j <- 0..(m - 1), reduce: [] do
        acc ->
          current_piece = Enum.at(Enum.at(turkish_flag, i), j)

          cond do
            current_piece == 1 and white ->
              acc ++ get_free_list(turkish_flag, i, j, 1)

            current_piece == 2 and white ->
              acc ++ get_free_list(turkish_flag, i, j, 2)

            current_piece == 3 and not white ->
              acc ++ get_free_list(turkish_flag, i, j, 3)

            current_piece == 4 and not white ->
              acc ++ get_free_list(turkish_flag, i, j, 4)

            true ->
              acc
          end
      end
    else
      best_paths_overall
    end
  end

  def get_free_list(turkish_flag, i, j, chess_type) do
    n = length(turkish_flag)
    m = length(List.first(turkish_flag))

    for [dx, dy] <- pairwise([-1, 0, 1, 0, -1]), reduce: [] do
      acc ->
        case chess_type do
          1 -> if dx != -1 and valid_move?(turkish_flag, i + dx, j + dy, n, m), do: [[[i, j], [i + dx, j + dy]] | acc], else: acc
          3 -> if dx != 1 and valid_move?(turkish_flag, i + dx, j + dy, n, m), do: [[[i, j], [i + dx, j + dy]] | acc], else: acc
          2 -> explore_free_list(turkish_flag, i, j, dx, dy, i+dx, j+dy, acc, n, m)
          4 -> explore_free_list(turkish_flag, i, j, dx, dy, i+dx, j+dy, acc, n, m)
          _ -> acc
        end
    end
  end

  def explore_free_list(turkish_flag, i, j, dx, dy, nx, ny, res, n, m) do

    if valid_move?(turkish_flag, nx, ny, n, m) do
      explore_free_list(turkish_flag, i, j, dx, dy, nx+dx, ny+dy, [[[i, j], [nx, ny]] | res], n, m)
    else
      res
    end
  end

  defp valid_move?(turkish_flag, nx, ny, n, m) do
    res = nx >= 0 and nx < n and ny >= 0 and ny < m and Enum.at(Enum.at(turkish_flag, nx), ny) == 0
    IO.puts(res)
    res
  end

  defp update_best_paths(paths, initial_pos, acc) do
    cond do
      paths == [[initial_pos]] -> acc
      acc == [] or length(hd(paths)) > length(hd(acc)) -> paths
      length(hd(paths)) == length(hd(acc)) -> paths ++ acc
      true -> acc
    end
  end

  def pairwise(list) do
    Enum.chunk_every(list, 2, 1, :discard)
  end
end
