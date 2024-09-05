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
              {:ok, user_info}  ->
                %{user_id: user_id, rate: win_rate, ai_name: user_info.ai_name}
              {:error, _} ->
                %{user_id: user_id, rate: win_rate, ai_name: "not register yet"}
            end
          end)
          {:ok, win_rates}

      {:error, reason} ->
        {:error, []}
    end
  end
  def insert_win_rate(user_infos) do
    Enum.map(user_infos, fn user_info -> RankList.save_rank(user_info.user_id, user_info.ai_name, user_info.rate) end)
  end
end
