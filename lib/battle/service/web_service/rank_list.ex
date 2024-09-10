defmodule Battle.Service.WebService.RankList do
  alias Battle.Mongo.BattleResult
  alias Battle.Mongo.UserAi
  alias Battle.Mongo.RankList

  # 这里计算的胜率的是当天的对局
  def get_battle_info() do
    {_, res} = case BattleResult.get_battle_results_within_24_hour() do
      {:ok, results} ->
        # 统计每个玩家的胜利次数
        win_counts =
          results
          |> Enum.map(fn %{:winner => winner} -> winner end)
          |> Enum.frequencies()

        # 统计每个玩家参与的总场次
        total_counts =
          results
          |> Enum.flat_map(fn %{:user_id_2 => players} -> players end)
          |> Enum.frequencies()

        # 计算每个玩家的胜率
        win_rates =
          Enum.map(total_counts, fn {user_id, total_games} ->
            wins = Map.get(win_counts, user_id, 0)
            win_rate = wins / total_games
            case UserAi.get_newest_ai_by_userId(user_id) do
              {:ok, user_info} ->
                %{user_id: user_id, rate: win_rate, ai_name: user_info.ai_name}
              {:error, _} ->
                %{user_id: user_id, rate: win_rate, ai_name: "not register yet"}
            end
          end)

        # 根据胜率排序，并分配排名（相同胜率相同排名）
        ranked_win_rates =
          win_rates
          |> Enum.sort_by(& &1.rate, :desc)  # 按胜率降序排序
          |> Enum.reduce({[], nil, 0, 1}, fn player_info, {acc, prev_rate, prev_rank, rank} ->
            if player_info.rate == prev_rate do
              # 如果胜率相同，保持相同排名
              {[Map.put(player_info, :rank, prev_rank) | acc], prev_rate, prev_rank, rank + 1}
            else
              # 如果胜率不同，分配新的排名
              {[Map.put(player_info, :rank, rank) | acc], player_info.rate, rank, rank + 1}
            end
          end)
          |> elem(0)
          |> Enum.reverse()  # 最终将列表反转回来

        {:ok, ranked_win_rates}

      {:error, reason} ->
        {:error, []}
    end
  end

  def insert_win_rate(user_infos) do
    Enum.map(user_infos, fn user_info -> RankList.save_rank(user_info.user_id, user_info.ai_name, user_info.rate, user_info.rank) end)
  end
end
