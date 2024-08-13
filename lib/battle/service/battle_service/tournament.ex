defmodule Battle.Service.BattleService.Tournament do
  alias Battle.Service.BattleService.ThreadPool
  alias Battle.Service.WebService.Kun

  def start_tournament() do
    {:ok, pool} = ThreadPool.start_link(10)  # 启动一个大小为10的线程池

    players = Kun.start_build()
    user_ids = Enum.map(players, fn player -> player.user_id end)
    Enum.each(user_ids, fn user_id1 ->
      Enum.each(user_ids -- [user_id1], fn user_id2 ->
        ThreadPool.add_task(pool, {user_id1, user_id2})
      end)
    end)

    # 等待所有对战完成
    Process.sleep(:infinity)
  end
end
