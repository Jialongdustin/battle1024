defmodule Battle.Web.Supervisor do
  use Supervisor
  require Logger

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Battle.Web.Router,
        options: http_options()
      )
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end

  def http_options() do
    [
      port: 4000
    ]
  end
end
