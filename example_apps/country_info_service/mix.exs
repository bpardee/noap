defmodule CountryInfoService.MixProject do
  use Mix.Project

  def project do
    # Clean CountryInfoService modules from noap test build before compilation
    # to avoid "redefining module" warnings
    clean_noap_test_build()

    [
      app: :country_info_service,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps_path: "../../deps",
      build_path: "../../_build",
      deps: deps()
    ]
  end

  # Clean CountryInfoService modules from noap test build before compilation
  # to avoid "redefining module" warnings
  defp clean_noap_test_build do
    noap_test_ebin = Path.expand("../../_build/test/lib/noap/ebin", __DIR__)
    if File.exists?(noap_test_ebin) do
      Path.wildcard(Path.join(noap_test_ebin, "Elixir.CountryInfoService*.beam"))
      |> Enum.each(fn beam_file ->
        File.rm(beam_file)
      end)
    end
  end

  def application do
    [
      mod: {CountryInfoService.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:noap, path: "../.."},
      {:finch, "~> 0.20"}
    ]
  end
end
