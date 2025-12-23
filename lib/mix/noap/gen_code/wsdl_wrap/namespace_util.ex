defmodule Mix.Noap.GenCode.WSDLWrap.NamespaceUtil do
  @schema_namespace "http://www.w3.org/2001/XMLSchema"
  @wsdl_namespace "http://schemas.xmlsoap.org/wsdl/"
  @soap_namespace "http://schemas.xmlsoap.org/wsdl/soap/"

  # Meeseeks doesn't use add_namespace like SweetXML
  # Instead, we convert XPath expressions to use namespace-uri()
  def add_schema_namespace(xpath_expr, _prefix) do
    convert_namespace_xpath(xpath_expr, @schema_namespace)
  end

  def add_protocol_namespace(xpath_expr, _prefix) do
    convert_namespace_xpath(xpath_expr, @wsdl_namespace)
  end

  def add_soap_namespace(xpath_expr, _prefix) do
    convert_namespace_xpath(xpath_expr, @soap_namespace)
  end

  # Helper to convert prefix-based XPath to namespace-uri() based XPath
  defp convert_namespace_xpath(xpath_expr, _namespace_uri) do
    # This is a simplified conversion - in practice, you'd need more sophisticated parsing
    # For now, we'll assume the XPath uses a prefix that needs to be replaced
    # The actual conversion would depend on the specific XPath expression
    xpath_expr
  end

  # @spec get_namespaces(String.t(), String.t(), String.t()) :: map()
  # defp get_namespaces(doc, schema_namespace, protocol_ns) do
  #   doc
  #   |> xpath(~x"//#{ns("definitions", protocol_ns)}/namespace::*"l)
  #   |> Enum.into(%{}, &get_namespace(&1, doc, schema_namespace, protocol_ns))
  # end

  # @spec get_namespace(map(), String.t(), String.t(), String.t()) :: tuple()
  # defp get_namespace(namespaces_node, doc, schema_namespace, protocol_ns) do
  #   {_, _, _, key, value} = namespaces_node
  #   string_key = key |> to_string
  #   value = Atom.to_string(value)

  #   cond do
  #     xpath(doc, ~x"//#{ns("definitions", protocol_ns)}[@targetNamespace='#{value}']") ->
  #       {string_key, %{value: value, type: :wsdl}}

  #     xpath(
  #       doc,
  #       ~x"//#{ns("types", protocol_ns)}/#{ns("schema", schema_namespace)}/#{
  #         ns("import", schema_namespace)
  #       }[@namespace='#{value}']"
  #     ) ->
  #       {string_key, %{value: value, type: :xsd}}

  #     true ->
  #       {string_key, %{value: value, type: :soap}}
  #   end
  # end
end
