defmodule Mix.Noap.GenCode.WSDLWrap.Options do
  @moduledoc false

  alias Mix.Noap.GenCode.WSDLWrap.Util

  @doc """
  Check the options and return the schema_module matching the target namespace if specified with "<ns>:<module>".
  If given just in the form "module" than that will be used for all schemas.  Otherwise, the module
  will be derived from the namespace.
      iex> opts = %{schema_module: Bar, other_option: "lobster"}
      iex> Mix.Noap.GenCode.WSDLWrap.Options.schema_module(opts, :foo)
      "Bar"
      iex> opts = %{schema_module: {:foo, Bar}}
      iex> Mix.Noap.GenCode.WSDLWrap.Options.schema_module(opts, :foo)
      "Bar"
      iex> Mix.Noap.GenCode.WSDLWrap.Options.schema_module(opts, :faa)
      nil
      iex> opts = %{schema_module: [{:foo, Bar}, Zulu]}
      iex> Mix.Noap.GenCode.WSDLWrap.Options.schema_module(opts, :foo)
      "Bar"
      iex> Mix.Noap.GenCode.WSDLWrap.Options.schema_module(opts, :faa)
      "Zulu"
      iex> Mix.Noap.GenCode.WSDLWrap.Options.schema_module(%{}, :foo)
      nil
  """
  def schema_module(%{schema_module: list}, ns) when is_list(list) do
    map = Enum.reduce(list, %{}, &schema_module_put_map/2)
    map[to_string(ns)] || map[nil]
  end

  def schema_module(%{schema_module: schema_module}, ns) do
    map = schema_module_put_map(schema_module, %{})
    map[to_string(ns)] || map[nil]
  end

  def schema_module(%{}, ns), do: nil

  def overrides(options) do
    case options[:overrides] do
      path when is_binary(path) -> YamlElixir.read_from_file!(path, atoms: true)
      map when is_map(map) -> map
      nil -> %{}
    end
  end

  defp schema_module_put_map({ns, module}, map) do
    Map.put(map, to_string(ns), Util.module_to_string(module))
  end

  defp schema_module_put_map(module, map) do
    Map.put(map, nil, Util.module_to_string(module))
  end
end
