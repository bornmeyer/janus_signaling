defmodule Janus.MixProject do
  use Mix.Project

  def project do
    [
      app: :janus,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:sasl, :logger, :gen_state_machine, :crypto, ],
      mod: {Janus.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
      {:call_protocol, in_umbrella: true},
      {:general, in_umbrella: true},
      {:hammox, "~> 0.3"},
      {:gen_state_machine, "~> 3.0"},
      {:websockex, "~> 0.4.2"},
      {:elixir_uuid, "~> 1.2"},
      {:poison, "~> 3.1"},
    ]
  end
end
