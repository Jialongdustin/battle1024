defmodule Battle.Service.BattleService.Tournament do
  alias Battle.Service.BattleService.ThreadPool
  alias Battle.Service.WebService.Kun

  def start_tournament() do
    {:ok, pool} = ThreadPool.start_link(10)  # 启动一个大小为10的线程池

    players =
      Kun.start_build()
      |> Enum.reduce(%{}, fn %{user_id: user_id, package_name: package_name}, acc ->
        Map.put(acc, user_id, package_name)
      end)
    user_ids = Map.keys(players)
    Enum.each(user_ids, fn user_id1 ->
      Enum.each(user_ids -- [user_id1], fn user_id2 ->
        contest_id = UUID.uuid4()
        ThreadPool.add_task({user_id1, user_id2, contest_id, players})
      end)
    end)
  end
end

players = %{
  111 => "plat1024-battle-players:20240826154603",
  222 => "plat1024-battle-players:20240826154542"
}
#   333 => "plat1024-battle-players:20240826154521",
#   444 => "plat1024-battle-players:20240826154500"
# }
