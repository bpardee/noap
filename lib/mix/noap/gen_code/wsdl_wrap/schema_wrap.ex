defmodule Mix.Noap.GenCode.WSDLWrap.SchemaWrap do
  defstruct [
    :schema_ns,
    :target_namespace,
    :element_form_default,
    :target_ns,
    :module,
    :top_types,
    :complex_type_map
  ]

  @type_to_ecto_map %{
    "boolean" => :boolean,
    "date" => :date,
    "dateTime" => :datetime,
    "double" => :float,
    "float" => :float,
    "int" => :integer,
    "integer" => :integer,
    "long" => :integer,
    "string" => :string
  }

  alias Mix.Noap.GenCode.WSDLWrap
  alias Mix.Noap.GenCode.WSDLWrap.{Action, ComplexType, Field, Options, Util}
  import SweetXml, only: [xpath: 2, xpath: 3, sigil_x: 2]

  import WSDLWrap.NamespaceUtil, only: [add_schema_namespace: 2]

  def new(schema_ns, parent_module, schema_element, namespace_map, options) do
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

    target_ns = Noap.XMLUtil.find_namespace(schema_element, target_namespace) |> String.to_atom()

    module =
      Options.schema_module(options, target_ns) ||
        Util.convert_url_to_module(target_namespace, parent_module)

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
      top_types: top_types,
      complex_type_map: nil
    }

    complex_type_map =
      schema_element
      |> xpath(
        ~x"xsd:complexType"l
        |> add_schema_namespace("xsd")
      )
      |> Enum.map(&parse_complex_type(schema, &1, nil))
      |> Enum.into(%{}, &{&1.name, &1})

    schema = %{schema | complex_type_map: complex_type_map}

    complex_type_map =
      top_type_elements
      |> Enum.map(&parse_type(schema, &1, nil))
      |> Enum.into(complex_type_map, &{&1.name, &1})

    %{schema | complex_type_map: complex_type_map}
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
      ComplexType.new(schema.module, name, parent_complex_type),
      fn element, complex_type ->
        field = parse_field(schema, element, complex_type)
        ComplexType.add_field(complex_type, field)
      end
    )
    # The fields are in reverse order based on add_field so put them back in correct order
    |> (fn complex_type -> %{complex_type | fields: Enum.reverse(complex_type.fields)} end).()
  end

  defp parse_field(schema, element, parent_complex_type) do
    xml_name = element |> xpath(~x"@name"s)

    if xml_name == "" do
      raise "Not sure how to parse type without name #{inspect(element)}"
    end

    case element |> xpath(~x"@type"s) do
      "" ->
        field_type = parse_type(schema, element, parent_complex_type)
        max_occurs = element |> xpath(~x"@maxOccurs"s)

        embeds =
          cond do
            is_atom(field_type) -> :field
            max_occurs == "" || String.to_integer(max_occurs) <= 1 -> :embeds_one
            true -> :embeds_many
          end

        Field.new(embeds, xml_name, field_type)

      xml_type ->
        get_simple_field(schema, xml_name, xml_type)
    end
  end

  defp get_simple_field(schema, xml_name, xml_type) do
    type = convert_type(schema, xml_type)
    Field.new(:field, xml_name, type)
  end

  defp convert_type(schema, xml_type) do
    case String.split(xml_type, ":", parts: 2) do
      [simple_type] ->
        ecto_type = @type_to_ecto_map[simple_type]

        if is_nil(ecto_type) do
          raise("Not sure how to handle type=#{xml_type}")
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
    schema.complex_type_map[name]
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
