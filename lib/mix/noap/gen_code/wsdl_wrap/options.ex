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

  def schema_module(%{}, _ns), do: nil

  @doc """
  Reverse lookup: find the target_ns (atom) for a given target_namespace URI
  by checking which schema_module entry's namespace URI matches.
  This uses the namespace_map to find which prefix maps to the target_namespace URI.
  """
  def find_target_ns_from_uri(options, target_namespace, namespace_map) when is_binary(target_namespace) do
    # First, try to find the prefix in namespace_map that maps to this URI
    prefix = Enum.find_value(namespace_map, fn {prefix, uri} ->
      if uri == target_namespace, do: prefix
    end)

    if prefix do
      # Convert prefix string to atom
      try do
        String.to_existing_atom(prefix)
      rescue
        ArgumentError -> String.to_atom(prefix)
      end
    else
      # Fallback: check schema_module config and match by checking namespace_map
      # for each schema_module entry to see if its URI matches target_namespace
      case options[:schema_module] do
        list when is_list(list) ->
          Enum.find_value(list, fn
            {ns, _module} when is_atom(ns) ->
              ns_string = Atom.to_string(ns)
              # Check if namespace_map has this prefix and if its URI matches
              case Map.get(namespace_map, ns_string) do
                uri when uri == target_namespace -> ns
                _ -> nil
              end
            _ ->
              nil
          end) ||
          # Last resort: try pattern matching on the URI
          Enum.find_value(list, fn
            {ns, _module} when is_atom(ns) ->
              ns_string = Atom.to_string(ns)
              # Check if the namespace URI contains the ns string (case-insensitive)
              if String.contains?(String.downcase(target_namespace), String.downcase(ns_string)) do
                ns
              else
                nil
              end
            _ ->
              nil
          end)
        _ ->
          nil
      end
    end
  end

  def find_target_ns_from_uri(_options, _target_namespace, _namespace_map), do: nil

  def overrides(options) do
    case options[:overrides] do
      path when is_binary(path) ->
        if Code.ensure_loaded?(YamlElixir) and function_exported?(YamlElixir, :read_from_file!, 2) do
          apply(YamlElixir, :read_from_file!, [path, [atoms: true]])
        else
          raise "yaml_elixir dependency is required when using overrides from a file. Add {:yaml_elixir, \"~> 2.12\"} to your deps."
        end
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
