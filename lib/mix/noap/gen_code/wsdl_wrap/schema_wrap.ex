defmodule Mix.Noap.GenCode.WSDLWrap.SchemaWrap do
  defstruct [
    :schema_ns,
    :target_namespace,
    :element_form_default,
    :target_ns,
    :module,
    :dir,
    :top_types,
    :type_map
  ]

  @type_to_ecto_map %{
    "boolean" => :boolean,
    "date" => :date,
    "dateTime" => :utc_datetime,
    "double" => :float,
    "float" => :float,
    "int" => :integer,
    "integer" => :integer,
    "long" => :integer,
    "string" => :string
  }

  @soap_version_namespaces %{
    "1.1" => "http://schemas.xmlsoap.org/wsdl/soap/",
    "1.2" => "http://schemas.xmlsoap.org/wsdl/soap12/"
  }

  alias Mix.Noap.GenCode.WSDLWrap
  alias Mix.Noap.GenCode.WSDLWrap.{Action, ComplexType, Field, Options, Util}
  import SweetXml, only: [xpath: 2, xpath: 3, sigil_x: 2]

  import WSDLWrap.NamespaceUtil, only: [add_schema_namespace: 2]

  def new(schema_ns, parent_module, parent_dir, schema_element, namespace_map, options) do
    %{
      target_namespace: target_namespace,
      element_form_default: element_form_default
    } =
      xpath(schema_element, ~x".",
        target_namespace: ~x"./@targetNamespace"s,
        element_form_default: ~x"./@elementFormDefault"s
      )

    if target_namespace == "" do
      raise "Not sure how to handle with no targetNamespace: #{inspect(schema_element)}"
    end

    target_ns = Noap.XML.find_namespace(schema_element, target_namespace) |> String.to_atom()

    {module, dir} =
      case Options.schema_module(options, target_ns) do
        nil -> Util.convert_url_to_module(target_namespace, parent_module, parent_dir)
        module -> {module, Util.get_module_dir(module)}
      end

    top_type_elements =
      schema_element
      |> xpath(
        ~x"xsd:element"l
        |> add_schema_namespace("xsd")
      )

    top_types =
      top_type_elements
      |> Enum.into(
        %{},
        fn element ->
          name = element |> xpath(~x"@name"s)
          action_with_namespace = element |> xpath(~x"@type"s)
          {name, Action.new(name, action_with_namespace, namespace_map)}
        end
      )

    schema = %__MODULE__{
      schema_ns: schema_ns,
      # element: schema_element,
      target_namespace: target_namespace,
      target_ns: target_ns,
      element_form_default: element_form_default,
      module: module,
      dir: dir,
      top_types: top_types,
      type_map: nil
    }

    type_map =
      schema_element
      |> xpath(
        ~x"xsd:complexType"l
        |> add_schema_namespace("xsd")
      )
      |> Enum.map(&parse_complex_type(schema, &1, nil))
      |> Enum.into(%{}, &{&1.name, &1})

    schema = %{schema | type_map: type_map}

    type_map =
      top_type_elements
      |> Enum.map(&parse_type(schema, &1, nil))
      |> Enum.into(type_map, &{&1.name, &1})

    %{schema | type_map: type_map}
  end

  defp parse_complex_type(schema, parent_element, parent_complex_type) do
    name = parent_element |> xpath(~x"@name"s)

    if name == "" do
      raise "Not sure how to handle complex_type without name #{inspect(parent_element)}"
    end

    elements = xpath(parent_element, ~x"xsd:sequence/xsd:element"l |> add_schema_namespace("xsd"))
    parse_complex_type(schema, name, elements, parent_complex_type)
  end

  defp parse_complex_type(schema, name, elements, parent_complex_type) do
    # IO.puts("Creating complex type name=#{name}")

    Enum.reduce(
      elements,
      ComplexType.new(schema.module, schema.dir, name, parent_complex_type),
      fn element, complex_type ->
        field = parse_field(schema, element, complex_type)
        ComplexType.add_field(complex_type, field)
      end
    )
    |> ComplexType.create_code()
  end

  defp parse_field(schema, element, parent_complex_type) do
    name = element |> xpath(~x"@name"s)
    type = element |> xpath(~x"@type"s)

    if name == "" do
      raise "Not sure how to parse type without name #{inspect(element)}"
    end

    case type do
      "" ->
        complex_type = parse_type(schema, element, parent_complex_type)
        max_occurs = element |> xpath(~x"@maxOccurs"s)

        simple_or_one_or_many =
          cond do
            is_atom(complex_type) -> :simple
            max_occurs == "" || String.to_integer(max_occurs) <= 1 -> :one
            true -> :many
          end

        Field.new(name, complex_type, simple_or_one_or_many)

      type ->
        get_simple_field(schema, name, type)
    end
  end

  defp get_simple_field(schema, name, type) do
    converted_type = convert_type(schema, type)
    Field.new(name, converted_type)
  end

  defp convert_type(schema, type) do
    case String.split(type, ":", parts: 2) do
      [simple_type] ->
        ecto_type = @type_to_ecto_map[simple_type]

        if is_nil(ecto_type) do
          raise("Not sure how to handle type=#{type}")
        end

        ecto_type

      [namespace, name] ->
        cond do
          namespace == schema.schema_ns ->
            convert_type(schema, name)

          # namespace == schema.target_ns ->

          (type = find_complex_type(schema, name)) != nil ->
            type

          true ->
            raise("Not sure how to handle namespace=#{namespace} type=#{name}")
        end
    end
  end

  defp find_complex_type(schema, name) do
    schema.type_map[name]
  end

  defp parse_type(schema, parent_element, parent_complex_type) do
    name = parent_element |> xpath(~x"@name"s)

    cond do
      (type = parent_element |> xpath(~x"@type"s)) != "" ->
        convert_type(schema, type)

      (complex_elements = get_complex_type_elements(parent_element)) != [] ->
        parse_complex_type(schema, name, complex_elements, parent_complex_type)

      (simple_type_restriction = get_simple_type_restriction_element(parent_element)) != nil ->
        type = simple_type_restriction |> xpath(~x"@base"s)

        if type == "" do
          raise(
            "Not sure how to handle name=#{name} simple_type_restriction " <>
              inspect(simple_type_restriction)
          )
        end

        convert_type(schema, type)

      true ->
        raise("Not sure how to handle name=#{name} #{inspect(parent_element)}")
    end
  end

  defp get_complex_type_elements(parent_element) do
    parent_element
    |> xpath(~x"xsd:complexType/xsd:sequence/xsd:element"l |> add_schema_namespace("xsd"))
  end

  defp get_simple_type_restriction_element(parent_element) do
    parent_element
    |> xpath(~x"xsd:simpleType/xsd:restriction"e |> add_schema_namespace("xsd"))
  end
end
