# 这部分是调度的线程池代码
defmodule ThreadPool do
  use GenServer

  def start_link(size) do
    GenServer.start_link(__MODULE__, size, name: :thread_pool)
  end

  def init(size) do
    {:ok, %{workers: [], size: size, queue: :queue.new(), busy: %{}}}
  end

  def add_task(pid, task) do
    GenServer.cast(pid, {:add_task, task})
  end

  def handle_cast({:add_task, task}, state) do
    if length(state.workers) < state.size do
      # 如果有空闲的 worker，直接执行任务
      worker = Task.async(fn -> execute_task(task) end)
      {:noreply, %{state | workers: [worker | state.workers], busy: Map.put(state.busy, worker.ref, worker)}}
    else
      # 否则，将任务加入队列
      {:noreply, %{state | queue: :queue.in(task, state.queue)}}
    end
  end

  def handle_info({ref, _result}, state) do
    # 从 busy 列表中移除已完成的任务
    {worker, busy} = Map.pop(state.busy, ref)
    workers = List.delete(state.workers, worker)

    # 如果队列中有任务，将其分配给空闲的 worker
    case :queue.out(state.queue) do
      {{:value, next_task}, new_queue} ->
        new_worker = Task.async(fn -> execute_task(next_task) end)
        {:noreply, %{state | workers: [new_worker | workers], busy: Map.put(busy, new_worker.ref, new_worker), queue: new_queue}}

      {:empty, _} ->
        {:noreply, %{state | workers: workers, busy: busy}}
    end
  end

  defp execute_task({user_id1, user_id2}) do
    Battle.start(user_id1, user_id2)
  end
end

defmodule Tournament do
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
