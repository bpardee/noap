defmodule Mix.Noap.GenCode.WSDLWrap do
  defstruct [
    :endpoint,
    :module_prefix,
    :namespace_map,
    :schema_map,
    :operations,
    :message_map
  ]

  @soap_version_namespaces %{
    "1.1" => "http://schemas.xmlsoap.org/wsdl/soap/",
    "1.2" => "http://schemas.xmlsoap.org/wsdl/soap12/"
  }

  import SweetXml, only: [add_namespace: 3, xpath: 2, xpath: 3, sigil_x: 2, parse: 2]

  import __MODULE__.NamespaceUtil,
    only: [
      add_schema_namespace: 2,
      add_protocol_namespace: 2,
      add_soap_namespace: 2
    ]

  alias __MODULE__.{ComplexType, Field, OperationWrap, SchemaWrap, Template, Util}

  # defp soap_version, do: Application.fetch_env!(:soap, :globals)[:version]
  defp soap_version, do: "1.1"
  defp soap_version(opts) when is_list(opts), do: Keyword.get(opts, :soap_version, soap_version())

  @spec new(String.t(), String.t(), keyword()) :: {:ok, map()}
  def new(wsdl_path, module_prefix, options \\ []) do
    str = File.read!(wsdl_path)
    doc = parse(str, namespace_conformant: true)
    schema_ns = Noap.XML.find_namespace(doc, "http://www.w3.org/2001/XMLSchema")
    endpoint = get_endpoint(doc)
    namespace_map = get_namespace_map(doc)
    module_dir = Util.get_module_dir(module_prefix)
    schema_map = get_schema_map(doc, schema_ns, module_prefix, module_dir, namespace_map, options)
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

  def create_code(wsdl_wrap = %__MODULE__{}, options \\ []) do
    overrides = get_create_code_overrides(options)
    IO.inspect("Starting with keys=#{inspect(Map.keys(overrides))}")

    wsdl_wrap.schema_map
    |> Enum.each(fn {name, schema_wrap} ->
      schema_overrides = get_nested_overrides(overrides, name)

      schema_wrap.type_map
      |> Stream.map(fn {name, complex_type} ->
        nested_overrides = get_nested_overrides(schema_overrides, name)
        process_complex_type_overrides(complex_type, nested_overrides)
      end)
      |> Enum.each(&create_complex_type_code/1)
    end)

    wsdl_instance = Template.create_wsdl_instance(wsdl_wrap)

    schema_instances =
      wsdl_wrap.schema_map
      |> Stream.map(fn {_name, schema_wrap} ->
        Template.create_schema_instance(schema_wrap)
      end)
      |> Enum.join("\n")

    operation_instances =
      wsdl_wrap.operations
      |> Stream.map(&Template.create_operation_instance/1)
      |> Enum.join("\n")

    operation_functions =
      wsdl_wrap.operations
      |> Stream.map(&Template.create_operation_function/1)
      |> Enum.join("\n")

    module_dir = Util.get_module_dir(wsdl_wrap.module_prefix)

    Template.create_service(
      wsdl_wrap,
      wsdl_instance,
      schema_instances,
      operation_instances,
      operation_functions
    )
    |> Template.save!(module_dir, "service")
  end

  def yamlize(wsdl_wrap = %__MODULE__{}, yaml_file) do
    yaml =
      wsdl_wrap.schema_map
      |> Enum.map(fn {name, schema_wrap} ->
        {name, build_map(schema_wrap)}
      end)
      |> Enum.into(%{})
      |> Util.to_yaml()

    File.write!(yaml_file, yaml)
  end

  defp get_create_code_overrides(options) do
    if yaml_file = options[:overrides_file] do
      YamlElixir.read_from_file!(yaml_file)
    else
      options[:overrides] || %{}
    end
  end

  defp get_nested_overrides(overrides, name) do
    name = to_string(name)
    IO.puts("Looking for #{name} in #{inspect(Map.keys(overrides))}")
    overrides[name] || %{}
  end

  defp build_map(%SchemaWrap{type_map: type_map}) do
    type_map
    |> Enum.map(fn {name, complex_type} ->
      {name, build_map(complex_type)}
    end)
    |> Enum.into(%{})
  end

  defp build_map(%ComplexType{fields: fields}) do
    fields
    |> Enum.map(fn field ->
      {field.name, build_map(field)}
    end)
    |> Enum.into(%{})
  end

  defp build_map(%Field{type: complex_type = %ComplexType{}}) do
    build_map(complex_type)
  end

  defp build_map(%Field{}), do: %{}

  defp process_complex_type_overrides(complex_type, overrides) do
    new_fields =
      complex_type.fields
      |> Enum.map(fn field ->
        convert_field(field, get_nested_overrides(overrides, field.name))
      end)

    %{complex_type | fields: new_fields}
  end

  defp convert_field(field = %Field{type: child_complex_type = %ComplexType{}}, overrides) do
    child_complex_type = process_complex_type_overrides(child_complex_type, overrides)
    %{field | type: child_complex_type}
  end

  defp convert_field(field, overrides) do
    field
    |> convert_field_type(overrides["type"])
  end

  defp convert_field_type(field, nil), do: field
  defp convert_field_type(field, type) when is_atom(type), do: %{field | type: type}

  defp convert_field_type(field, type) when is_binary(type) do
    if String.starts_with?(type, ":") do
      type = type |> String.slice(1..-1) |> String.to_atom()
      %{field | type: type}
    else
      raise "Not sure what to do with type=#{type}"
    end
  end

  defp create_complex_type_code(complex_type = %ComplexType{parent_dir: parent_dir, name: name}) do
    Template.create_complex_type(complex_type)
    |> Template.save!(parent_dir, name)

    complex_type.fields
    |> Enum.each(fn field ->
      case field do
        %Field{type: child_complex_type = %ComplexType{}} ->
          create_complex_type_code(child_complex_type)

        _ ->
          nil
      end
    end)

    :ok
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

    type = schema.type_map[action.name]

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

  defp build_schema_instance({ns, schema}) do
    {ns,
     %Noap.WSDL.Schema{
       schema_ns: schema.schema_ns,
       target_namespace: schema.target_namespace,
       target_ns: schema.target_ns,
       action_tag_attributes: action_tag_attributes(schema)
     }}
  end

  defp get_schema_map(doc, schema_ns, module_prefix, module_dir, namespace_map, options) do
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
            module_dir,
            schema_node,
            namespace_map,
            options
          )

        {schema.target_ns, schema}
      end
    )
  end

  defp action_tag_attributes(%Mix.Noap.GenCode.WSDLWrap.SchemaWrap{
         element_form_default: "qualified",
         target_namespace: target_namespace
       }) do
    %{xmlns: target_namespace}
  end

  defp action_tag_attributes(_schema), do: %{}

  @spec get_endpoint(String.t()) :: String.t()
  defp get_endpoint(doc) do
    doc
    |> xpath(
      ~x"wsdl:service/wsdl:port/soap:address/@location"s
      |> add_protocol_namespace("wsdl")
      |> add_soap_namespace("soap")
    )
  end

  defp get_operations(doc, schema_map, message_map, opts) do
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
    |> IO.inspect()
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
