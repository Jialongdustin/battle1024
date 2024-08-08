defmodule Battle.Plug.Session do
  @cookie_opts [:domain, :max_age, :path, :secure, :http_only, :extra, :same_site, :partitioned]
  @expires_key "_session_expires"
  @behaviour Plug

  @impl true
  def init(opts) do
    store = Plug.Session.Store.get(Keyword.fetch!(opts, :store))  # RedisSessionStore
    key = Keyword.fetch!(opts, :key)  # []
    cookie_opts = Keyword.take(opts, @cookie_opts)  # []
    store_opts = Keyword.drop(opts, [:store, :key] ++ @cookie_opts)  # []
    store_config = store.init(store_opts)   # [ex: 24 * 3600]

    %{
      store: store,
      store_config: store_config,
      key: key,
      cookie_opts: cookie_opts
    }
  end

  @impl true
  def call(conn, config) do
    %{cookie_opts: cookie_opts} = config
    cookie_opts = fix_cookie_opts(conn, cookie_opts)
    Plug.Session.call(conn, %{config | cookie_opts: cookie_opts})
  end

  defp fix_cookie_opts(conn, opts) do
    ua =
      conn
      |> Plug.Conn.get_req_header("user-agent")
      |> List.first()
      |> Ejoy.UserAgent.parse()

    {same_site, opts} = Keyword.pop(opts, :same_site)
    {partitioned, opts} = Keyword.pop(opts, :partitioned)

    opts =
      if same_site && Ejoy.UserAgent.is_support_same_site(ua) do
        Keyword.put(opts, :same_site, same_site)
      else
        opts
      end

    if partitioned && Ejoy.UserAgent.is_support_cookie_partitioned(ua) do
      extra =
        case Keyword.get(opts, :extra)  do
          nil -> "Partitioned"
          extra -> extra <> "; Partitioned"
        end
      Keyword.put(opts, :extra, extra)
    else
      opts
    end
  end

  def set_expires_in(conn, ex) do
    expires_at = System.os_time(:second) + ex
    set_expires_at(conn, expires_at)
  end

  def set_expires_at(conn, at_ts) do
    Plug.Conn.put_session(conn, @expires_key, at_ts)
  end

  def get_expires_key() do
    @expires_key
  end
end
