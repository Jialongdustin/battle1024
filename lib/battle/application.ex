defmodule Battle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

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
      Battle.Service.BattleService.RoomSupervisor,
      Battle.Service.BattleService.RoomSupervisorTest,
      {Battle.Service.BattleService.ThreadPoolTest, []},
      {Battle.Service.BattleService.Tournament, []}
      # Starts a worker by calling: Battle.Worker.start_link(arg)
      # {Battle.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Battle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def http_options() do
    [
      port: 4000
    ]
  end
end
