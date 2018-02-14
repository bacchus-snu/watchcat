defmodule Client.MixProject do
  use Mix.Project

  def project do
    [
      app: :client,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      build_embedded: Mix.env() == :prod
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Client, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:msgpax, "~>2.0"},
    ]
  end
end
