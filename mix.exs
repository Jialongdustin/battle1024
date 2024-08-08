defmodule Battle.MixProject do
  use Mix.Project

  def project do
    [
      app: :battle,
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
      {:ejoy_token,git: "git@gitlab.alibaba-inc.com:battlenet/ejoy_token.git"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
