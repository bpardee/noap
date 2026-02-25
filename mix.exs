defmodule Noap.MixProject do
  use Mix.Project

  def project do
    # Set xmerl path for Noap.XML (Erlang 28+ from_lib resolution can fail)
    case :code.lib_dir(:xmerl) do
      dir when is_list(dir) ->
        Application.put_env(:noap, :xmerl_hrl_path, Path.join([to_string(dir), "include", "xmerl.hrl"]))

      _ ->
        :ok
    end

    [
      app: :noap,
      version: "0.2.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      hex: hex_config(),
      package: [
        maintainers: ["Brad Pardee"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/bpardee/noap"}
      ]
    ]
  end

  defp hex_config do
    # Fix TLS "Unknown CA" on macOS: use system CA bundle
    cacerts_path =
      cond do
        File.exists?("/opt/homebrew/etc/openssl@3/cert.pem") ->
          "/opt/homebrew/etc/openssl@3/cert.pem"

        File.exists?("/usr/local/etc/openssl@3/cert.pem") ->
          "/usr/local/etc/openssl@3/cert.pem"

        true ->
          nil
      end

    if cacerts_path, do: [cacerts_path: cacerts_path], else: []
  end

  def application do
    [
      extra_applications: [:logger, :eex, :xmerl]
    ]
  end

  defp deps do
    [
      {:bypass, "~> 2.1", optional: true},
      {:finch, "~> 0.21", optional: true},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:ex_doc, "~> 0.32", only: [:dev, :docs], runtime: false},
      {:xml_builder, "~> 2.4"},
      {:yaml_elixir, "~> 2.5", optional: true},
      # Override: cowlib 2.11 fails to compile on Erlang 28 (State unbound)
      {:cowlib, "~> 2.16", override: true}
    ]
  end
end
