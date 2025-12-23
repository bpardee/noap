defmodule Noap.MixProject do
  use Mix.Project

  def project do
    [
      app: :noap,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        maintainers: ["Brad Pardee"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/bpardee/noap"}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  defp deps do
    [
      {:bypass, "~> 2.1", optional: true},
      {:mojito, "~> 0.7", optional: true},
      {:finch, "~> 0.20", optional: true},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:ex_doc, "~> 0.39", only: [:dev, :docs], runtime: false},
      {:meeseeks, "~> 0.18"},
      {:xml_builder, "~> 2.4"},
      {:yaml_elixir, "2.11.0", optional: true},
      {:telemetry, "~> 1.0", override: true}
    ]
  end
end
