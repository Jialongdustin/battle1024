defmodule Battle.Service.BattleService.ConnectionStore do
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def store_connection(contest_id, conn) do
    GenServer.call(__MODULE__, {:store_connection, contest_id, conn})
  end

  def fetch_connection(contest_id) do
    GenServer.call(__MODULE__, {:fetch_connection, contest_id})
  end

  def get_state() do
    GenServer.call(__MODULE__, {:get_state})
  end

  def handle_call({:store_connection, contest_id, conn}, _from, state) do
    {:reply, :ok, Map.put(state, contest_id, conn)}
  end


  def handle_call({:fetch_connection, contest_id}, _from, state) do

    conn = Map.get(state, contest_id)
    {:reply, conn, state}
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  def handle_info({:remove_connection, contest_id}, state) do
    {:noreply, Map.delete(state, contest_id)}
  end
end