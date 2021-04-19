defmodule Noap.Model.Response do
  @moduledoc """
  Provides a functions for parse an xml-like response body.
  """

  import SweetXml, only: [xpath: 2, sigil_x: 2, add_namespace: 3]

  @soap_version_namespaces %{
    "1.1" => "http://schemas.xmlsoap.org/soap/envelope/",
    "1.2" => "http://www.w3.org/2003/05/soap-envelope"
  }
  @doc """
  Executing with xml response body.

  If a list is empty then `parse/1` returns full parsed response structure into map.
  """
  @spec parse_fault(String.t()) :: map()
  def parse_fault(body) do
    doc = SweetXml.parse(body, namespace_conformant: true)
    doc
    |> xpath(~x"soap:Fault/*"l |> add_namespace("soap", "http://schemas.xmlsoap.org/soap/envelope/"))
    #|> parse_elements()
  end

  def parse_response_xml(body, operation) do
    doc = SweetXml.parse(body, namespace_conformant: true)
    model = operation.output_module.__struct__
    body_node = xpath(doc, ~x"soap:Body"e |> add_namespace("soap", "http://schemas.xmlsoap.org/soap/envelope/"))
    body_node
    |> xpath(~x"#{operation.output_name}"e |> add_namespace("body", operation.output_schema.target_namespace))
    |> parse_model(operation.output_schema.target_namespace, operation.output_module)
  end

  # @spec parse_record(tuple()) :: map() | String.t()
  defp parse_model(node, body_namespace, module) do
    Enum.reduce(
      module.xml_fields,
      %{},
      fn {field, xml_key, simple_or_one_or_many} = foo, map ->
        IO.inspect(foo)
        value = parse_field(node, body_namespace, module, field, xml_key, simple_or_one_or_many)
        Map.put(map, field, value)
      end
    )
  end

  defp parse_field(node, body_namespace, _module, _field, xml_key, :simple) do
    body_xpath(node, body_namespace, ~x"body:#{xml_key}/text()"s)
    |> String.trim
    |> Noap.Util.nil_if_empty
  end

  defp parse_field(node, body_namespace, module, field, xml_key, :one) do
    child_module = get_child_module(module, field)
    body_xpath(node, body_namespace, ~x"body:#{xml_key}"e)
    |> parse_model(body_namespace, child_module)
  end

  defp parse_field(node, body_namespace, module, field, xml_key, :many) do
    child_module = get_child_module(module, field)
    body_xpath(node, body_namespace, ~x"body:#{xml_key}"l)
    |> Enum.map(& parse_model(&1, body_namespace, child_module))
  end

  defp get_child_module(parent_module, field) do
    {:parameterized, Ecto.Embedded, %Ecto.Embedded{related: module}} = parent_module.__schema__(:type, field)
    module
  end

  defp body_xpath(node, body_namespace, body_sigil) do
    node
    |> xpath(body_sigil |> add_namespace("body", body_namespace))
  end

  # def soap_version, do: Application.fetch_env!(:soap, :globals)[:version]
  def soap_version, do: "1.1"
end
