defmodule Noap.XMLSchema.Request do
  @moduledoc false

  alias Noap.XMLField

  @schema_types %{
    "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
    "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
  }
  @soap_version_namespaces %{
    "1.1" => "http://schemas.xmlsoap.org/soap/envelope/",
    "1.2" => "http://www.w3.org/2003/05/soap-envelope"
  }

  @doc """
  Parsing parameters map and generate body xml by given soap action name and body params(Map).
  Returns xml-like string.
  """
  @spec build_request_xml(
          model :: map(),
          operation :: Noap.WSDL.Operation.t(),
          headers :: map(),
          type_map :: map()
        ) :: String.t() | no_return()
  def build_request_xml(model, operation, headers, type_map) do
    body = build_soap_body(operation, model, type_map)
    header = build_soap_header(operation, headers)

    [header, body]
    |> add_envelope_tag_wrapper(operation)
    |> XmlBuilder.document()
    |> XmlBuilder.generate(format: :none)
    |> String.replace(["\n", "\t"], "")
  end

  def build_soap_body(operation, model, type_map) do
    model
    |> to_element_tuples(type_map, "m")
    |> add_action_tag_wrapper(operation)
    |> add_body_tag_wrapper(operation.input_schema.wsdl)
  end

  def build_soap_header(operation, headers) do
    map_to_tuple_element_list(headers)
    |> add_header_part_tag_wrapper(operation)
    |> add_header_tag_wrapper(operation.input_schema.wsdl)
  end

  defp map_to_tuple_element_list(map) do
    map
    |> Enum.map(fn {name, value} -> {name, nil, value} end)
  end

  @spec add_action_tag_wrapper(list(), Noap.WSDL.Operation.t()) :: list()
  def add_action_tag_wrapper(body, operation) do
    op_tag = "#{operation.body_namespace}:#{operation.input_name}"

    op_tag_attributes = %{
      "xmlns:#{operation.body_namespace}" => operation.input_schema.target_namespace
    }

    [XmlBuilder.element(op_tag, op_tag_attributes, body)]
  end

  @spec add_header_part_tag_wrapper(map(), String.t()) :: list()
  def add_header_part_tag_wrapper(_body, _operation) do
    # TBD
    nil
  end

  @spec get_header_with_namespace(operation :: String.t()) :: String.t()
  def get_header_with_namespace(operation) do
    # with %{input: %{header: %{message: message, part: part}}} <-
    #        Enum.find(wsdl[:operations], &(&1[:name] == operation)),
    #      %{name: name} <- get_message_part(wsdl, message, part) do
    #   name
    # else
    #   _ -> nil
    # end
    nil

    # iex(10)> action_attribute_namespace = Soap.Request.Params.[get_action_with]_namespace(model2, "IDC52700Operation")
    # "tns:ProgramInterface"
  end

  # def get_message_part(wsdl, message, part) do
  #   wsdl[:messages]
  #   |> Enum.find(&("tns:#{&1[:name]}" == message))
  #   |> Map.get(:parts)
  #   |> Enum.find(&(&1[:name] == part))
  # end

  @spec add_header_tag_wrapper(list(), Noap.WSDL.t()) :: list()
  def add_header_tag_wrapper(body, wsdl),
    do: [XmlBuilder.element("#{wsdl.soap_namespace}:Header", nil, body)]

  @spec add_body_tag_wrapper(list(), Noap.WSDL.t()) :: list()
  def add_body_tag_wrapper(body, wsdl),
    do: [XmlBuilder.element("#{wsdl.soap_namespace}:Body", nil, body)]

  @spec add_envelope_tag_wrapper(body :: any(), operation :: String.t()) :: any()
  def add_envelope_tag_wrapper(body, operation) do
    wsdl = operation.input_schema.wsdl

    envelop_attributes =
      @schema_types
      |> Map.merge(build_soap_version_attribute(wsdl))
      |> Map.merge(operation.action_attribute)
      |> Map.merge(custom_namespaces())

    [XmlBuilder.element(:"#{wsdl.soap_namespace}:Envelope", envelop_attributes, body)]
  end

  @spec build_soap_version_attribute(Map.t()) :: map()
  def build_soap_version_attribute(wsdl) do
    %{"xmlns:#{wsdl.soap_namespace}" => @soap_version_namespaces[wsdl.soap_version]}
  end

  defp to_element_tuples(model, type_map, env) do
    to_element_tuples(model, type_map, env, model.__struct__.xml_fields())
  end

  defp to_element_tuples(model, type_map, env, xml_fields) do
    Enum.map(
      xml_fields,
      fn xml_field ->
        value = Map.get(model, xml_field.name)
        element_value = to_element_value(xml_field, type_map, env, value)

        # Prepend a tuple which represent an element for xml_builder where 1=name 2=map of attributes (nil for us) 3=value
        {"#{env}:#{xml_field.xml_name}", nil, element_value}
      end
    )
  end

  defp to_element_value(xml_field = %XMLField{field_or_embeds: :field}, type_map, _env, value) do
    module = type_map[xml_field.type] || raise("Unknown type: #{xml_field.type}")
    module.to_str(value, xml_field.opts)
  end

  defp to_element_value(xml_field, type_map, env, model) do
    model = model || struct(xml_field.type)
    to_element_tuples(model, type_map, env)
  end

  def soap_version(wsdl) do
    Map.get(wsdl, :soap_version, Application.get_env(:noap, :soap_version, "1.1"))
  end

  def custom_namespaces, do: Application.get_env(:noap, :custom_namespaces, %{})
end
