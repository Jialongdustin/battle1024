defmodule Battle.MixProject do
  use Mix.Project

  def project do
    [
      app: :battle1024,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Battle.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ejoy_plug, git: "git@gitlab.alibaba-inc.com:battlenet/ejoy_plug.git"},
      {:ejoy_token, git: "git@gitlab.alibaba-inc.com:battlenet/ejoy_token.git"},
      {:ejoy_utils, git: "git@gitlab.alibaba-inc.com:battlenet/ejoy_utils.git"},
      {:mongo_orm, git: "git@gitlab.alibaba-inc.com:battlenet/mongo_orm.git"},
      {:common_utils, git: "git@gitlab.alibaba-inc.com:battlenet/common_utils.git", branch: "platform-battle", override: true},
      {:websock_adapter, "~> 0.5.6"},
      {:mock, "~> 0.3.0", only: :test}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
