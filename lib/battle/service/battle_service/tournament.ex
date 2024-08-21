defmodule Battle.BattleService.Tournament do
  def start_tournament() do
    {:ok, pool} = ThreadPool.start_link(10)  # 启动一个大小为10的线程池

    for user_id1 <- 1..100 do
      for user_id2 <- (user_id1 + 1)..100 do
        ThreadPool.add_task(pool, {user_id1, user_id2})
      end
    end

    # 等待所有对战完成
    Process.sleep(:infinity)
  end


end