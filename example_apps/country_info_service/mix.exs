defmodule CountryInfoService.MixProject do
  use Mix.Project

  def project do
    [
      app: :country_info_service,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps_path: "../../deps",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:noap, path: "../.."},
      {:mojito, "~> 0.7"}
    ]
  end
end
