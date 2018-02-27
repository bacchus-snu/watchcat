defmodule Server.MixProject do
  use Mix.Project

  def project do
    [
      app: :server,
      version: "0.1.0",
      build_path: "./_build",
      config_path: "./config/config.exs",
      deps_path: "./deps",
      lockfile: "./mix.lock",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Server, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:msgpax, "~> 2.0"},
      {:cowboy, "~> 2.2"},
      {:poison, "~> 3.1"},
      {:ex2ms, "~> 1.0"},
      {:ssl_verify_fun, git: "https://github.com/deadtrickster/ssl_verify_fun.erl", tag: "1.1.3"}
    ]
  end
end
