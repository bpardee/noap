defmodule Mix.Noap.GenCode.WSDLWrap do
  defstruct [
    :endpoint,
    :module_prefix,
    :namespace_map,
    :schema_map,
    :operations,
    :message_map
  ]

  # @soap_version_namespaces %{
  #   "1.1" => "http://schemas.xmlsoap.org/wsdl/soap/",
  #   "1.2" => "http://schemas.xmlsoap.org/wsdl/soap12/"
  # }

  import SweetXml, only: [xpath: 2, xpath: 3, sigil_x: 2, parse: 2]

  import __MODULE__.NamespaceUtil,
    only: [
      add_schema_namespace: 2,
      add_protocol_namespace: 2,
      add_soap_namespace: 2
    ]

  alias __MODULE__.{ComplexType, Field, OperationWrap, SchemaWrap, Util}

  # defp soap_version, do: Application.fetch_env!(:soap, :globals)[:version]
  # defp soap_version, do: "1.1"
  # defp soap_version(opts) when is_list(opts), do: Keyword.get(opts, :soap_version, soap_version())

  def new(wsdl_path, module_prefix, options \\ []) do
    module_prefix = Util.module_to_string(module_prefix)
    str = File.read!(wsdl_path)
    doc = parse(str, namespace_conformant: true)
    schema_ns = Noap.XMLUtil.find_namespace(doc, "http://www.w3.org/2001/XMLSchema")
    endpoint = get_endpoint(doc)
    namespace_map = get_namespace_map(doc)
    schema_map = get_schema_map(doc, schema_ns, module_prefix, namespace_map, options)
    message_map = get_message_map(doc)
    operations = get_operations(doc, schema_map, message_map, options)

    %__MODULE__{
      endpoint: endpoint,
      module_prefix: module_prefix,
      namespace_map: namespace_map,
      schema_map: schema_map,
      operations: operations,
      message_map: message_map
    }
  end

  defp find_complex_type(schema_map, message_map, message_name) do
    message = message_map[message_name]

    if is_nil(message) do
      raise "Could not find message matching #{message_name} for operation"
    end

    schema = schema_map[message.ns]

    if is_nil(schema) do
      raise "Could not find schema for message=#{inspect(message)}"
    end

    action = schema.top_types[message.name]

    if is_nil(action) do
      raise "Couldn't find action for #{message.name} #{inspect(schema)}"
    end

    type = schema.complex_type_map[action.name]

    if is_nil(type) do
      raise "Couldn't find type for #{action.name} #{inspect(schema)}"
    end

    {schema, type}
  end

  defp get_namespace_map(doc) do
    doc
    |> xpath(~x"./namespace::*"l)
    |> Enum.into(%{}, &get_namespace/1)
  end

  defp get_namespace({_, _, _, ns, namespace}) do
    {to_string(ns), to_string(namespace)}
  end

  defp get_schema_map(doc, schema_ns, module_prefix, namespace_map, options) do
    doc
    |> xpath(
      ~x"wsdl:types/xsd:schema"l
      |> add_protocol_namespace("wsdl")
      |> add_schema_namespace("xsd")
    )
    |> Enum.into(
      %{},
      fn schema_node ->
        schema =
          __MODULE__.SchemaWrap.new(
            schema_ns,
            module_prefix,
            schema_node,
            namespace_map,
            options
          )

        {schema.target_ns, schema}
      end
    )
  end

  @spec get_endpoint(String.t()) :: String.t()
  defp get_endpoint(doc) do
    doc
    |> xpath(
      ~x"wsdl:service/wsdl:port/soap:address/@location"s
      |> add_protocol_namespace("wsdl")
      |> add_soap_namespace("soap")
    )
  end

  defp get_operations(doc, schema_map, message_map, _opts) do
    doc
    |> xpath(
      ~x"wsdl:portType/wsdl:operation"l
      |> add_protocol_namespace("wsdl")
    )
    |> Enum.map(&build_operation(&1, schema_map, message_map))
  end

  defp build_operation(op_node, schema_map, message_map) do
    name = xpath(op_node, ~x"./@name"s)
    input_message_name = get_operation_arg_name(op_node, ~x"./wsdl:input/@message"s)
    output_message_name = get_operation_arg_name(op_node, ~x"./wsdl:output/@message"s)
    input_name = message_map[input_message_name][:name]
    output_name = message_map[output_message_name][:name]
    input_header = get_operation_input_header(op_node)

    {input_schema, input_complex_type} =
      find_complex_type(schema_map, message_map, input_message_name)

    # IO.puts("Found input type=#{inspect(input_complex_type)}")
    {output_schema, output_complex_type} =
      find_complex_type(schema_map, message_map, output_message_name)

    # IO.puts("Found output type=#{inspect(output_complex_type)}")
    action = input_schema.top_types[name]

    if is_nil(action) do
      raise "Could not find action for operation=#{name}"
    end

    %OperationWrap{
      name: name,
      underscored_name: Util.underscore(name),
      input_name: input_name,
      input_schema: input_schema,
      input_complex_type: input_complex_type,
      output_name: output_name,
      output_schema: output_schema,
      output_complex_type: output_complex_type,
      soap_action: nil,
      input_header_message: input_header[:message],
      input_header_part: input_header[:part],
      action_attribute: action.attribute,
      action_tag: action.tag
    }
    # |> IO.inspect()
  end

  defp get_operation_arg_name(op_node, path) do
    op_node
    |> xpath(path |> add_protocol_namespace("wsdl"))
    |> String.split(":", parts: 2)
    |> Enum.at(1)
  end

  defp get_operation_input_header(op_node) do
    xpath(
      op_node,
      ~x"./wsdl:input/soap:header"
      |> add_protocol_namespace("wsdl")
      |> add_soap_namespace("soap")
    )
    |> get_operation_input_header_message_part()
  end

  defp get_operation_input_header_message_part(nil), do: %{}

  defp get_operation_input_header_message_part(header_node) do
    xpath(header_node, ~x".", message: ~x"./@message"s, part: ~x"./@part"s)
  end

  defp get_message_map(doc) do
    doc
    |> xpath(
      ~x"wsdl:message"l
      |> add_protocol_namespace("wsdl")
    )
    |> Enum.reduce(
      %{},
      fn node, map ->
        name = xpath(node, ~x"./@name"s)
        Map.put(map, name, get_message_part(node))
      end
    )
  end

  defp get_message_part(element) do
    [ns, name] =
      xpath(
        element,
        ~x"wsdl:part/@element"s |> add_protocol_namespace("wsdl")
      )
      |> String.split(":", parts: 2)

    %{ns: String.to_atom(ns), name: name}
  end
end
