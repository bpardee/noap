defmodule Noap.MixProject do
  use Mix.Project

  def project do
    [
      app: :noap,
      version: "0.1.0",
      elixir: "~> 1.17",
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
      # mojito is deprecated - use finch instead
      # {:mojito, "~> 0.7", optional: true},
      {:finch, "~> 0.19", optional: true},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:ex_doc, "~> 0.39", only: [:dev, :docs], runtime: false},
      {:sweet_xml, "~> 0.7"},
      {:xml_builder, "~> 2.1"},
      {:yaml_elixir, "~> 2.5", optional: true}
    ]
  end
end
