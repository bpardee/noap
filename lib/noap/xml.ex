defmodule Noap.XML do
  @moduledoc """
  XML parsing and XPath queries using Erlang's built-in xmerl.
  Provides a SweetXML-compatible API without external dependencies.
  """

  defmodule XPath do
    @moduledoc false
    defstruct path: ".",
              is_value: true,
              is_list: false,
              is_keyword: false,
              is_optional: false,
              cast_to: false,
              transform_fun: &__MODULE__.self_val/1,
              namespaces: []

    def self_val(val), do: val
  end

  require Record

  # Use explicit path for Erlang 28+ compatibility (from_lib resolution can fail in Mix)
  @xmerl_opts (if path = Application.compile_env(:noap, :xmerl_hrl_path, nil) do
    [from: path]
  else
    [from_lib: "xmerl/include/xmerl.hrl"]
  end)

  Record.defrecord(:xmlAttribute, Record.extract(:xmlAttribute, @xmerl_opts))
  Record.defrecord(:xmlComment, Record.extract(:xmlComment, @xmerl_opts))
  Record.defrecord(:xmlElement, Record.extract(:xmlElement, @xmerl_opts))
  Record.defrecord(:xmlObj, Record.extract(:xmlObj, @xmerl_opts))
  Record.defrecord(:xmlPI, Record.extract(:xmlPI, @xmerl_opts))
  Record.defrecord(:xmlText, Record.extract(:xmlText, @xmerl_opts))

  @doc """
  Sigil for XPath expressions. Modifiers: e (element), l (list), s (string), i (integer), f (float), o (optional).
  """
  def sigil_x(path, modifiers \\ [])

  def sigil_x(path, modifiers) when is_list(modifiers) do
    # modifiers is charlist e.g. 'l', 's', 'e', 'el'
    mod_str = to_string(modifiers)

    %XPath{
      path: String.to_charlist(path),
      is_value: not String.contains?(mod_str, "e"),
      is_list: String.contains?(mod_str, "l"),
      is_keyword: String.contains?(mod_str, "k"),
      is_optional: String.contains?(mod_str, "o"),
      cast_to: cast_from_modifiers(mod_str)
    }
  end

  defp cast_from_modifiers(mod_str) do
    cond do
      String.contains?(mod_str, "s") -> :string
      String.contains?(mod_str, "S") -> :soft_string
      String.contains?(mod_str, "i") -> :integer
      String.contains?(mod_str, "I") -> :soft_integer
      String.contains?(mod_str, "f") -> :float
      String.contains?(mod_str, "F") -> :soft_float
      true -> false
    end
  end

  @doc """
  Apply a transform function to the result of an xpath query.
  """
  def transform_by(%XPath{} = xpath, fun) when is_function(fun) do
    %XPath{xpath | transform_fun: fun}
  end

  @doc """
  Add a namespace prefix for XPath queries.
  """
  def add_namespace(%XPath{} = xpath, prefix, uri) do
    %XPath{
      xpath
      | namespaces: [{to_charlist(prefix), to_charlist(uri)} | xpath.namespaces]
    }
  end

  defp ensure_xmerl_on_path do
    case :code.ensure_loaded(:xmerl_scan) do
      {:module, _} ->
        :ok

      {:error, _} ->
        xmerl_dir =
          case :code.lib_dir(:xmerl) do
            dir when is_list(dir) or is_binary(dir) ->
              dir

            _ ->
              root = to_string(:code.root_dir())
              xmerl_candidates = Path.wildcard(Path.join([root, "lib", "xmerl-*"]))

              case xmerl_candidates do
                [dir | _] -> dir
                [] -> raise "xmerl not found (looked in #{Path.join([root, "lib"])})"
              end
          end

        xmerl_ebin = Path.join([to_string(xmerl_dir), "ebin"])
        true = :code.add_pathz(to_charlist(xmerl_ebin))
    end
  end

  @doc """
  Parse XML string into xmerl format. Options passed to xmerl_scan.
  """
  def parse(doc, opts \\ []) do
    # Ensure xmerl is on code path before starting (Mix/umbrella can have restricted path)
    ensure_xmerl_on_path()

    Application.ensure_all_started(:xmerl)

    opts = Keyword.put_new(opts, :namespace_conformant, true)
    opts = Keyword.put_new(opts, :validation, :off)

    doc = if is_binary(doc), do: :erlang.binary_to_list(doc), else: doc
    {parsed, _} = :xmerl_scan.string(doc, opts)
    parsed
  end

  @doc """
  Query XML with XPath. Supports xpath/2 and xpath/3 (with keyword mapping).
  """
  def xpath(parent, spec, subspec \\ [])

  def xpath(parent, spec, []) when not is_tuple(parent) do
    parent |> parse() |> xpath(spec)
  end

  def xpath(
        parent,
        %XPath{is_list: true, is_value: true, cast_to: cast, is_optional: is_opt?} = spec,
        []
      ) do
    get_current_entities(parent, spec)
    |> Enum.map(&(value_from_entity(&1) |> to_cast(cast, is_opt?)))
    |> spec.transform_fun.()
  end

  def xpath(parent, %XPath{is_list: true, is_value: false} = spec, []) do
    get_current_entities(parent, spec) |> spec.transform_fun.()
  end

  def xpath(
        parent,
        %XPath{is_list: false, is_value: true, cast_to: string_type, is_optional: is_opt?} = spec,
        []
      )
      when string_type in [:string, :soft_string] do
    spec = %XPath{spec | is_list: true}

    get_current_entities(parent, spec)
    |> Enum.map(&(value_from_entity(&1) |> to_cast(string_type, is_opt?)))
    |> Enum.join()
    |> spec.transform_fun.()
  end

  def xpath(
        parent,
        %XPath{is_list: false, is_value: true, cast_to: cast, is_optional: is_opt?} = spec,
        []
      ) do
    get_current_entities(parent, spec)
    |> value_from_entity()
    |> to_cast(cast, is_opt?)
    |> spec.transform_fun.()
  end

  def xpath(parent, %XPath{is_list: false, is_value: false} = spec, []) do
    get_current_entities(parent, spec) |> spec.transform_fun.()
  end

  def xpath(parent, sweet_xpath, subspec) do
    if sweet_xpath.is_list do
      current_entities = xpath(parent, sweet_xpath)
      Enum.map(current_entities, fn entity -> xmap(entity, subspec, sweet_xpath) end)
    else
      current_entity = xpath(parent, sweet_xpath)
      xmap(current_entity, subspec, sweet_xpath)
    end
  end

  defp xmap(nil, _, %XPath{is_optional: true}), do: nil

  defp xmap(parent, [{label, spec} | tail], _) when is_list(spec) do
    [sweet_xpath | subspec] = spec
    result = xmap(parent, tail, nil)
    Map.put(result, label, xpath(parent, sweet_xpath, subspec))
  end

  defp xmap(parent, [{label, sweet_xpath} | tail], _) do
    result = xmap(parent, tail, nil)
    Map.put(result, label, xpath(parent, sweet_xpath))
  end

  defp xmap(_, [], _), do: %{}

  defp get_current_entities(nil, _spec), do: []

  defp get_current_entities(parent, %XPath{path: path, is_list: true, namespaces: namespaces}) do
    :xmerl_xpath.string(path, parent, namespace: namespaces) |> List.wrap()
  end

  defp get_current_entities(parent, %XPath{path: path, is_list: false, namespaces: namespaces}) do
    ret = :xmerl_xpath.string(path, parent, namespace: namespaces)

    if is_record?(ret, :xmlObj) do
      ret
    else
      List.first(ret)
    end
  end

  defp is_record?(data, kind) do
    is_tuple(data) and tuple_size(data) > 0 and :erlang.element(1, data) == kind
  end

  defp value_from_entity(entity) do
    cond do
      is_record?(entity, :xmlText) -> xmlText(entity, :value)
      is_record?(entity, :xmlComment) -> xmlComment(entity, :value)
      is_record?(entity, :xmlPI) -> xmlPI(entity, :value)
      is_record?(entity, :xmlAttribute) -> xmlAttribute(entity, :value)
      is_record?(entity, :xmlObj) -> xmlObj(entity, :value)
      true -> entity
    end
  end

  defp to_cast(value, false, _is_opt?), do: value
  defp to_cast(nil, _, true), do: nil
  defp to_cast(value, :string, _is_opt?), do: to_string(value)
  defp to_cast(value, :integer, _is_opt?), do: String.to_integer(to_string(value))

  defp to_cast(value, :float, _is_opt?) do
    {float, _} = Float.parse(to_string(value))
    float
  end

  defp to_cast(value, :soft_string, is_opt?) do
    if String.Chars.impl_for(value) do
      to_string(value)
    else
      if is_opt?, do: nil, else: ""
    end
  end

  defp to_cast(value, :soft_integer, is_opt?) do
    if String.Chars.impl_for(value) do
      case Integer.parse(to_string(value)) do
        :error -> if is_opt?, do: nil, else: 0
        {int, _} -> int
      end
    else
      if is_opt?, do: nil, else: 0
    end
  end

  defp to_cast(value, :soft_float, is_opt?) do
    if String.Chars.impl_for(value) do
      case Float.parse(to_string(value)) do
        :error -> if is_opt?, do: nil, else: 0.0
        {float, _} -> float
      end
    else
      if is_opt?, do: nil, else: 0.0
    end
  end
end
