defmodule Battle.Service.WebService.WebSocketHandler do
  require Logger
  
  def handle_info({:update_board, message}, state) do
    {:reply, :ok, {:text, Jason.encode!(message)}, state}
  end
end
