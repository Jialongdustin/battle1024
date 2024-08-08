defmodule Battle.Utils.RedisStore do
  @cluster_name :redis_store

  defmodule Key do
    def auto_cache_prefix(), do: format_key "auto_cache{}"
    def sid_prefix(), do: format_key "sid"
    def auth_key_prefix(), do: format_key "auth_key"
    def account_last_login_prefix, do: format_key "a_last_login"
    def user_opts_prefix, do: format_key "user_opts"
    def products_info, do: format_key "products_info"
    def format_key(key) do
      "#{UnionConfig.product()}:admin_center:#{key}"
    end
  end

  def child_spec() do
    redis_opts = UnionConfig.product_get(:redis) |> Enum.to_list()
    RedixPool.child_spec(pool_name: @cluster_name, redix_param: redis_opts)
  end

  def q([_ | _] = command) do
    RedixPool.command(@cluster_name, command, [])
  end
end
