defmodule Mix.Noap.GenCode.WSDLWrap.Options do
  @moduledoc false

  @doc """
  Check the options and return the schema_module matching the target namespace if specified with "<ns>:<module>".
  If given just in the form "module" than that will be used for all schemas.  Otherwise, the module
  will be derived from the namespace.
      iex> Mix.Noap.GenCode.WSDLWrap.Options.schema_module([schema_module: "foo:Bar", schema_module: "Zulu", other_option: "lobster"], :foo)
      "Bar"
      iex> Mix.Noap.GenCode.WSDLWrap.Options.schema_module([schema_module: "foo:Bar", schema_module: "Zulu", other_option: "lobster"], :faa)
      "Zulu"
      iex> Mix.Noap.GenCode.WSDLWrap.Options.schema_module([other_option: "lobster"], :foo)
      nil
  """
  def schema_module(options, ns) do
    map = Enum.reduce(options, %{}, &schema_module_put_map/2)
    map[to_string(ns)] || map[nil]
  end

  defp schema_module_put_map({:schema_module, value}, map) do
    case String.split(value, ":", parts: 2) do
      [ns, module] -> Map.put(map, ns, module)
      [module] -> Map.put(map, nil, module)
    end
  end

  defp schema_module_put_map(_other_option, map), do: map
end
