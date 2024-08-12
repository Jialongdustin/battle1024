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
    },
    battle_cfg: %{
      TEST: %{
        ansible_products: %{
        },
        require_admin_gate_version: "202404181500",
        kun_key: %{
          id: "2ca6e222d92a45a2",
          secret: "0d4d7549ed654f629dabea93c7f8534f"
        }
      }
    }
  ]

config :ejoy_utils, db_pool: 10
config :ejoy_utils, send_vortex_heartbeat: false

config :ejoy_etcd, lib_prefix: "test"

config :ex_json_schema,
       :remote_schema_resolver,
       {Ejoy.Plug.SchamaResolver, :remote_schema_resolver}
