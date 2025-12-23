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

  import Meeseeks.XPath

  alias __MODULE__.{OperationWrap, Util}

  @wsdl_namespace "http://schemas.xmlsoap.org/wsdl/"
  @soap_namespace "http://schemas.xmlsoap.org/wsdl/soap/"
  @schema_namespace "http://www.w3.org/2001/XMLSchema"

  def new(wsdl_path, module_prefix, options \\ []) do
    module_prefix = Util.module_to_string(module_prefix)
    str = File.read!(wsdl_path)
    doc = Meeseeks.parse(str, :xml)
    schema_ns = Noap.XMLUtil.find_namespace(doc, "http://www.w3.org/2001/XMLSchema")
    endpoint = get_endpoint(doc)
    namespace_map = get_namespace_map(doc)
    schema_map = get_schema_map(doc, schema_ns, module_prefix, namespace_map, options)
    message_map = get_message_map(doc, namespace_map)
    operations = get_operations(doc, schema_map, message_map, namespace_map, options)

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

    # Direct lookup: schema_map is keyed by target_ns (atom) which matches message.ns
    schema = schema_map[message.ns]

    if is_nil(schema) do
      # Provide more debugging info
      target_ns_list = Enum.map(schema_map, fn {_ns, s} -> s.target_ns end)
      raise "Could not find schema for message=#{inspect(message)}, message.ns=#{inspect(message.ns)}, available_schemas=#{inspect(Map.keys(schema_map))}, target_ns_list=#{inspect(target_ns_list)}"
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
    # Meeseeks doesn't support namespace axis directly
    # We'll extract namespaces by checking the root element's xmlns attributes
    root = Meeseeks.one(doc, xpath("/*"))

    namespace_map = case root do
      nil -> %{}
      element -> extract_namespaces_from_element(element, %{})
    end

    # Also extract namespaces from schema elements (they may define reqns/resns)
    schema_elements = Meeseeks.all(doc, xpath("//*[namespace-uri()='#{@schema_namespace}' and local-name()='schema']"))
    schema_elements = if Enum.empty?(schema_elements) do
      Meeseeks.all(doc, xpath("//schema"))
    else
      schema_elements
    end

    namespace_map = Enum.reduce(schema_elements, namespace_map, fn schema_element, acc ->
      extract_namespaces_from_element(schema_element, acc)
    end)

    # Also get targetNamespace and map it to "tns" prefix if not already present
    target_ns = case root do
      nil -> nil
      element -> Meeseeks.attr(element, "targetNamespace")
    end

    if target_ns && !Map.has_key?(namespace_map, "tns") do
      Map.put(namespace_map, "tns", target_ns)
    else
      namespace_map
    end
  end

  defp extract_namespaces_from_element(element, acc) do
    # Check default namespace
    acc =
      case Meeseeks.attr(element, "xmlns") do
        nil -> acc
        value -> Map.put(acc, "", value)
      end

    # Check common prefixes
    common_prefixes = ["soap", "wsdl", "xsd", "xs", "tns", "s", "body", "ns0", "ns1", "ns2", "ns3", "ns4", "reqns", "resns"]
    acc = Enum.reduce(common_prefixes, acc, fn prefix, acc ->
      case Meeseeks.attr(element, "xmlns:#{prefix}") do
        nil -> acc
        value -> Map.put(acc, prefix, value)
      end
    end)

    # Also try to extract any other xmlns:* attributes that weren't in the common list
    # This is a fallback for custom namespace prefixes
    acc
  end

  defp get_schema_map(doc, schema_ns, module_prefix, namespace_map, options) do
    # Try namespace-uri() first, fall back to simple query for default namespaces
    schemas =
      doc
      |> Meeseeks.all(
        xpath("//*[namespace-uri()='#{@wsdl_namespace}' and local-name()='types']/*[namespace-uri()='#{@schema_namespace}' and local-name()='schema']")
      )

    # Fallback: if namespace-uri() didn't work, try simple query
    schemas = if Enum.empty?(schemas) do
      doc
      |> Meeseeks.all(xpath("//types//schema"))
    else
      schemas
    end

    schemas
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

        # Key by target_ns (atom) to match message.ns
        {schema.target_ns, schema}
      end
    )
  end

  @spec get_endpoint(Meeseeks.Document.t()) :: String.t()
  defp get_endpoint(doc) do
    address_node =
      doc
      |> Meeseeks.one(
        xpath("//*[namespace-uri()='#{@wsdl_namespace}' and local-name()='service']/*[namespace-uri()='#{@wsdl_namespace}' and local-name()='port']/*[namespace-uri()='#{@soap_namespace}' and local-name()='address']")
      )

    address_node = if is_nil(address_node) do
      doc
      |> Meeseeks.one(xpath("//service//port//address"))
    else
      address_node
    end

    case address_node do
      nil -> ""
      node -> Meeseeks.attr(node, "location") || ""
    end
  end

  defp get_operations(doc, schema_map, message_map, _namespace_map, _opts) do
    # Try namespace-uri() first, fall back to simple query for default namespaces
    port_type_node = Meeseeks.one(doc, xpath("//*[namespace-uri()='#{@wsdl_namespace}' and local-name()='portType']"))

    port_type_node = if is_nil(port_type_node) do
      Meeseeks.one(doc, xpath("//portType"))
    else
      port_type_node
    end

    port_type_name =
      case port_type_node do
        nil -> ""
        node -> Meeseeks.attr(node, "name") || ""
      end

    binding_node =
      if port_type_name != "" do
        binding = Meeseeks.one(
          doc,
          xpath("//*[namespace-uri()='#{@wsdl_namespace}' and local-name()='binding' and @name='#{port_type_name}']")
        )
        if is_nil(binding) do
          Meeseeks.one(doc, xpath("//binding[@name='#{port_type_name}']"))
        else
          binding
        end
      else
        nil
      end || Meeseeks.one(doc, xpath("//*[namespace-uri()='#{@wsdl_namespace}' and local-name()='binding']")) || Meeseeks.one(doc, xpath("//binding"))

    port_type_node
    |> case do
      nil -> []
      node ->
        ops = Meeseeks.all(node, xpath(".//*[namespace-uri()='#{@wsdl_namespace}' and local-name()='operation']"))
        ops = if Enum.empty?(ops) do
          Meeseeks.all(node, xpath(".//operation"))
        else
          ops
        end
        ops
        |> Enum.map(&build_operation(binding_node, &1, schema_map, message_map))
    end
  end

  defp build_operation(binding_node, op_node, schema_map, message_map) do
    name = Meeseeks.attr(op_node, "name") || ""
    soap_action = get_soap_action(binding_node, name) || ""
    input_message_name = get_operation_arg_name(op_node, "input", "message")
    output_message_name = get_operation_arg_name(op_node, "output", "message")
    input_name = message_map[input_message_name][:name]
    output_name = message_map[output_message_name][:name]
    input_header = get_operation_input_header(op_node)

    {input_schema, input_complex_type} =
      find_complex_type(schema_map, message_map, input_message_name)

    {output_schema, output_complex_type} =
      find_complex_type(schema_map, message_map, output_message_name)

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
      soap_action: soap_action,
      input_header_message: input_header[:message],
      input_header_part: input_header[:part],
      action_attribute: action.attribute,
      action_tag: action.tag
    }
  end

  defp get_soap_action(nil, _name), do: nil

  defp get_soap_action(binding_node, name) do
    operation_node =
      Meeseeks.one(
        binding_node,
        xpath(".//*[namespace-uri()='#{@wsdl_namespace}' and local-name()='operation' and @name='#{name}']")
      )

    operation_node = if is_nil(operation_node) do
      Meeseeks.one(binding_node, xpath(".//operation[@name='#{name}']"))
    else
      operation_node
    end

    case operation_node do
      nil -> nil
      node ->
        soap_op = Meeseeks.one(node, xpath(".//*[namespace-uri()='#{@soap_namespace}' and local-name()='operation']"))
        soap_op = if is_nil(soap_op) do
          Meeseeks.one(node, xpath(".//operation"))
        else
          soap_op
        end

        case soap_op do
          nil -> nil
          soap_node -> Meeseeks.attr(soap_node, "soapAction") || nil
        end
    end
  end

  defp get_operation_arg_name(op_node, element_name, attr_name) do
    input_node = Meeseeks.one(op_node, xpath(".//*[namespace-uri()='#{@wsdl_namespace}' and local-name()='#{element_name}']"))
    input_node = if is_nil(input_node) do
      Meeseeks.one(op_node, xpath(".//#{element_name}"))
    else
      input_node
    end

    case input_node do
      nil -> ""
      node ->
        attr_value = Meeseeks.attr(node, attr_name) || ""
        parts = String.split(attr_value, ":", parts: 2)
        case parts do
          [_ns, name] -> name
          [name] -> name
          _ -> ""
        end
    end
  end

  defp get_operation_input_header(op_node) do
    input_node = Meeseeks.one(op_node, xpath(".//*[namespace-uri()='#{@wsdl_namespace}' and local-name()='input']"))
    input_node = if is_nil(input_node) do
      Meeseeks.one(op_node, xpath(".//input"))
    else
      input_node
    end

    case input_node do
      nil -> %{}
      node ->
        header_node = Meeseeks.one(node, xpath(".//*[namespace-uri()='#{@soap_namespace}' and local-name()='header']"))
        header_node = if is_nil(header_node) do
          Meeseeks.one(node, xpath(".//header"))
        else
          header_node
        end
        get_operation_input_header_message_part(header_node)
    end
  end

  defp get_operation_input_header_message_part(nil), do: %{}

  defp get_operation_input_header_message_part(header_node) do
    %{
      message: Meeseeks.attr(header_node, "message") || "",
      part: Meeseeks.attr(header_node, "part") || ""
    }
  end

  defp get_message_map(doc, namespace_map) do
    messages = doc
    |> Meeseeks.all(xpath("//*[namespace-uri()='#{@wsdl_namespace}' and local-name()='message']"))

    messages = if Enum.empty?(messages) do
      doc
      |> Meeseeks.all(xpath("//message"))
    else
      messages
    end

    messages
    |> Enum.reduce(
      %{},
      fn node, map ->
        name = Meeseeks.attr(node, "name") || ""
        Map.put(map, name, get_message_part(node, namespace_map))
      end
    )
  end

  defp get_message_part(element, namespace_map) do
    part_node = Meeseeks.one(element, xpath(".//*[namespace-uri()='#{@wsdl_namespace}' and local-name()='part']"))
    part_node = if is_nil(part_node) do
      Meeseeks.one(element, xpath(".//part"))
    else
      part_node
    end

    element_attr =
      case part_node do
        nil -> ""
        node -> Meeseeks.attr(node, "element") || ""
      end

    parts = String.split(element_attr, ":", parts: 2)
    case parts do
      [ns_prefix, name] ->
        # Use the prefix as atom to match schema_map keys (which are keyed by target_ns atoms)
        # The schema_map is keyed by target_ns (atom like :tns, :reqns, :resns), not by URI strings
        ns = String.to_atom(ns_prefix)
        %{ns: ns, name: name || ""}
      [name] ->
        # No prefix, try default namespace or empty
        default_ns = Map.get(namespace_map, "", nil)
        # If there's a default namespace, try to find its prefix in namespace_map
        ns = if default_ns do
          # Find the prefix that maps to this URI
          found_prefix = Enum.find_value(namespace_map, fn {prefix, uri} ->
            if uri == default_ns, do: prefix
          end)
          if found_prefix do
            String.to_atom(found_prefix)
          else
            :""
          end
        else
          :""
        end
        %{ns: ns, name: name || ""}
      _ -> %{ns: :"", name: ""}
    end
  end
end
