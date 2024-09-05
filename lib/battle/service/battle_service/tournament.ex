defmodule Battle.Service.BattleService.Tournament do
   use GenServer

  alias Battle.Service.BattleService.ThreadPool
  alias Battle.Service.WebService.Kun

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_args) do
    ThreadPool.start_link()  # 启动一个大小为10的线程池
    ref = schedule_tournament()
    {:ok, %{ref: ref}}
  end

  def handle_info(:start_tournament, state) do
    initiate_tournament_logic()
    IO.inspect("start arrange next game")
    schedule_tournament()
    {:noreply, state}
  end

  defp schedule_tournament do
    now = DateTime.utc_now()
    noon = "#{Date.to_string(now)} 06:45:00"
    {:ok, twelve_noon, _offset} = DateTime.from_iso8601("#{noon}Z")
    now_ms = DateTime.to_unix(now, :millisecond)
    twelve_noon_ms = DateTime.to_unix(twelve_noon, :millisecond)
    cond do
      now_ms < twelve_noon_ms ->
        wait_time = twelve_noon_ms - now_ms
        IO.inspect("need to wait #{wait_time} ms to start tournament")
        Process.send_after(self(), :start_tournament, wait_time)
      true ->
        tomorrow_noon = DateTime.add(twelve_noon, 86400)
        tomorrow_noon_ms = DateTime.to_unix(tomorrow_noon, :millisecond)
        wait_time = tomorrow_noon_ms - now_ms
        IO.inspect("the next game will start after #{wait_time} ms")
        Process.send_after(self(), :start_tournament, wait_time)
    end
  end

  defp initiate_tournament_logic() do
    IO.inspect("start tournament")
    case Kun.start_build() do
      {:error, reason} ->
        {:error, reason}
      package_info ->
        players =
          package_info
          |> Enum.reduce(%{}, fn %{user_id: user_id, package_name: package_name}, acc ->
            Map.put(acc, user_id, package_name)
          end)
        user_ids = Map.keys(players)
        if length(user_ids) > 1 do
          Enum.each(user_ids, fn user_id1 ->
            Enum.each(user_ids -- [user_id1], fn user_id2 ->
              contest_id = UUID.uuid4()
              ThreadPool.add_task({user_id1, user_id2, contest_id, players})
            end)
          end)
        end
        {:ok, "start tournament"}
    end
  end
end
