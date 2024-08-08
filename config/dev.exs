use Mix.Config
config :union_config_app,
       config_db: [
         host: "localhost",
         port: 20717,
         db: "config",
         collection: "config"
       ],
       product: :P10020,
      static_config: [
        product_db: %{
          P10020: %{
            host: "localhost",
            port: 27017
          }
        }
      ]

config :ejoy_etcd,lib_prefix: "one_test"