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
      # Soap
      # {:sweet_xml, "~> 0.6.6"},
      # Http && XML
      {:httpoison, "~> 1.3"},
      # {:xml_builder, "~> 2.1"},
      # Code style
      # {:credo, "~> 1.0", only: [:dev, :test]},
      # Docs
      # {:ex_doc, "~>  0.19.3", only: [:dev, :docs], runtime: false},
      # Testing
      {:mock, "~> 0.3.0", only: :test},
      {:excoveralls, "~> 0.10", only: :test},

      # Castile
      # hex version is old and doesn't have write/3 or write related perf
      # improvements
      {:erlsom, "~> 1.4.2"},
      # {:httpoison, "~> 0.13 or ~> 1.0"}, #, optional: true},
      # {:credo, "~> 0.9.1", only: [:dev, :test], runtime: false},
      {:exvcr, "~> 0.10", only: :test},

      # noap
      {:bypass, "~> 2.1", optional: true},
      {:mojito, "~> 0.7", optional: true},
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:ex_doc, "~>  0.19.3", only: [:dev, :docs], runtime: false},
      {:sweet_xml, "~> 0.6.6"},
      {:xml_builder, "~> 2.1"},
      {:yaml_elixir, "~> 2.5", optional: true}
    ]
  end
end
