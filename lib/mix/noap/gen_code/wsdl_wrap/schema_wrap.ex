defmodule Mix.Noap.GenCode.WSDLWrap.SchemaWrap do
  require Logger

  defstruct [
    :schema_ns,
    :target_namespace,
    :element_form_default,
    :target_ns,
    :module,
    :top_types,
    :complex_type_map
  ]

  @type_to_simple_map %{
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
      |> Enum.reduce(complex_type_map, &add_to_complex_type_map/2)

    %{schema | complex_type_map: complex_type_map}
  end

  defp add_to_complex_type_map(complex_type = %ComplexType{}, map) do
    Map.put(map, complex_type.name, complex_type)
  end

  defp add_to_complex_type_map(complex_type_name, map) when is_binary(complex_type_name) do
    map
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
    Logger.debug("Creating complex type name=#{name}")

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

        embeds =
          cond do
            is_atom(field_type) -> :field
            true -> xpath(element, ~x"@maxOccurs"s) |> Util.max_occurs_embed()
          end

        Field.new(embeds, xml_name, field_type)

      xml_type ->
        {field_or_embeds, type} = convert_type(schema, element, xml_type)
        Field.new(field_or_embeds, xml_name, type)
    end
  end

  defp convert_type(schema, element, xml_type) do
    case String.split(xml_type, ":", parts: 2) do
      [simple_type] ->
        type = @type_to_simple_map[simple_type]

        if is_nil(type) do
          raise("Not sure how to handle type=#{xml_type}")
        end

        {:field, type}

      [namespace, name] ->
        cond do
          namespace == schema.schema_ns ->
            convert_type(schema, element, name)

          true ->
            embeds = xpath(element, ~x"@maxOccurs"s) |> Util.max_occurs_embed()
            {embeds, name}
        end
    end
  end

  defp parse_type(schema, parent_element, parent_complex_type) do
    name = parent_element |> xpath(~x"@name"s)

    cond do
      (type = parent_element |> xpath(~x"@type"s)) != "" ->
        {_field_or_embeds, ctype} = convert_type(schema, parent_element, type)
        ctype

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

        {_field_or_embeds, ctype} = convert_type(schema, parent_element, type)
        ctype

      true ->
        # Empty field list is the only other possibility?
        parse_complex_type(schema, name, [], parent_complex_type)
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
