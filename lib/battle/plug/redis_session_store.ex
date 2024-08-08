defmodule Battle.Plug.RedisSessionStore do
  @behaviour Plug.Session.Store
  @max_tries 3

  alias Battle.Utils.RedisStore

  @impl true
  def init(opts) do
    opts = Keyword.take(opts, [:ex])
    [ex: 24 * 3600] |> Keyword.merge(opts)
  end

  @impl true
  def get(_conn, sid, _) do
    sid_key = "#{RedisStore.Key.sid_prefix()}:#{sid}"
    case RedisStore.q(["GET", sid_key]) do
      {:ok, nil} -> {nil, %{}}
      {:ok, value} ->
        value = value |> Ejoy.Jiffy.decode!()
        expire_ts = Map.get(value, AdminCenter.Plug.Session.get_expires_key())
        if expire_ts && expire_ts < System.os_time(:second) do
          {nil, %{}}
        else
          {sid, value}
        end
    end
  end

  @impl true
  def put(_conn, nil, data, opts) do
    put_new(data, opts)
  end

  def put(_conn, sid, data, opts) do
    RedisStore.q(["SET", sid_key(sid), Ejoy.Jiffy.encode!(data), "EX", opts[:ex]])
    sid
  end

  @impl true
  def delete(_conn, sid, _) do
    RedisStore.q(["DEL", sid_key(sid)])
    :ok
  end

  defp put_new(data, opts, counter \\ 0)
       when counter < @max_tries do
    sid = Base.encode64(:crypto.strong_rand_bytes(48))
    case RedisStore.q(["SET", sid_key(sid), Ejoy.Jiffy.encode!(data), "NX", "EX", opts[:ex]]) do
      {:ok, "OK"} -> sid
      _ -> put_new(data, opts, counter + 1)
    end
  end

  def sid_key(sid) do
    "#{RedisStore.Key.sid_prefix()}:#{sid}"
  end
end
