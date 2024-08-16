defmodule Battle.Service.BattleService.ConnectionStore do
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def store_connection(moment_token, conn) do
    GenServer.call(__MODULE__, {:store_connection, moment_token, conn})
  end

  def fetch_connection(moment_token) do
    GenServer.call(__MODULE__, {:fetch_connection, moment_token})
  end

  def handle_call({:store_connection, moment_token, conn}, _from, state) do
    {:reply, :ok, Map.put(state, moment_token, conn)}
  end

  def handle_call({:fetch_connection, moment_token}, _from, state) do
    conn = Map.get(state, moment_token)
    {:reply, conn, state}
  end

  def handle_info({:remove_connection, moment_token}, state) do
    {:noreply, Map.delete(state, moment_token)}
  end

end
