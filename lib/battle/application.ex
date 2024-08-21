defmodule Battle.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [

      %{
        id: Battle.Web.Supervisor,
        start: {Battle.Web.Supervisor, :start_link, []},
        type: :supervisor
      },
        {Registry, keys: :unique, name: Battle.RoomRegistry},
      Battle.Service.BattleService.RoomSupervisor
      # Starts a worker by calling: Battle.Worker.start_link(arg)
      # {Battle.Worker, arg}
    ]
    opts = [strategy: :one_for_one, name: Battle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def http_options() do
    [
      port: 4000
    ]
  end
end
