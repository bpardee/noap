defmodule DataProcessingService.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_processing_service,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps_path: "../../deps",
      deps: deps()
    ]
  end

  def application do
    [
      mod: {DataProcessingService.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:noap, path: "../.."},
      {:finch, "~> 0.13"},
      {:yaml_elixir, "~> 2.5"}
    ]
  end
end
