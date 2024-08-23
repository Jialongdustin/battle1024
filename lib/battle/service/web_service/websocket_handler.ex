defmodule Battle.Service.WebService.WebSocketHandler do
  require Logger

  def init(opts) do
    Battle.Service.BattleService.RoomSupervisorTest.init_game(self())
    {:ok, opts}
  end

  def handle_info({:init_message, detail}, state) do

    {:reply, :ok, {:text, Ejoy.Jiffy.encode!(%{type: "init",detail: detail})}, state}
  end

  def handle_info({:reply_move, moves,captured}, state) do

    {:reply,:ok, {:text, Ejoy.Jiffy.encode!(%{type: "move", moves: moves, captured: captured})}, state}
  end
end
