use Mix.Config

config :union_config_app,
  config_db: [
    host: 'localhost',
    port: 27017
    # db: "config",
    # collection: "config"
  ],
  product: :TEST,
  static_config: [
    product_business_log: %{
      TEST: %{
        db: "TEST_business_log",
        host: "localhost",
        port: 27017
      }
    },
    product_db: %{
      TEST: %{
        host: "localhost",
        port: 27017
      }
    },
    holo: %{
      TEST: %{
        AliOSS: %{}
      }
    }]

config :ejoy_utils, db_pool: 10
config :ejoy_utils, send_vortex_heartbeat: false

config :ejoy_etcd, lib_prefix: "test"

config :ex_json_schema,
       :remote_schema_resolver,
       {Ejoy.Plug.SchamaResolver, :remote_schema_resolver}
