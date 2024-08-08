use Mix.Config

config :prometheus_utils,
       project_name: "battle",
       metric_conf: []

config :ejoy_services, register_before_user_specify: true

import_config "#{Mix.env()}.exs"