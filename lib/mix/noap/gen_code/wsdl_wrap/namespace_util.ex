defmodule Mix.Noap.GenCode.WSDLWrap.NamespaceUtil do
  import SweetXml, only: [add_namespace: 3, xpath: 2, sigil_x: 2, parse: 2]
  import Mix.Noap.GenCode.WSDLWrap.Util, only: [charlist_to_string: 1]

  def find_namespace(doc, url) do
    doc
    |> xpath(~x"//namespace::*"l)
    |> Enum.find(fn {_, _, _, _, x} -> url == to_string(x) end)
    |> elem(3)
    |> charlist_to_string()
  end

  def add_schema_namespace(xpath, prefix) do
    add_namespace(xpath, prefix, "http://www.w3.org/2001/XMLSchema")
  end

  def add_protocol_namespace(xpath, prefix) do
    add_namespace(xpath, prefix, "http://schemas.xmlsoap.org/wsdl/")
  end

  # @spec get_soap_namespace(String.t(), list()) :: String.t()
  # defp get_soap_namespace(doc, opts) when is_list(opts) do
  #   version = soap_version(opts)
  #   url = @soap_version_namespaces[version]
  #   find_namespace(doc, url)
  # end

  def add_soap_namespace(xpath, prefix) do
    add_namespace(xpath, prefix, "http://schemas.xmlsoap.org/wsdl/soap/")
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
