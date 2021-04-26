defmodule Noap.Schema.Response do
  @moduledoc """
  Provides a functions for parse an xml-like response body.
  """

  require Logger
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
    |> xpath(
      ~x"soap:Fault/*"l
      |> add_namespace("soap", "http://schemas.xmlsoap.org/soap/envelope/")
    )

    # |> parse_elements()
  end

  def parse_response_xml(body, operation, type_map) do
    doc = SweetXml.parse(body, namespace_conformant: true)

    body_node =
      xpath(
        doc,
        ~x"soap:Body"e |> add_namespace("soap", "http://schemas.xmlsoap.org/soap/envelope/")
      )

    body_node
    |> xpath(
      ~x"#{operation.output_name}"e
      |> add_namespace("body", operation.output_schema.target_namespace)
    )
    |> parse_model(
      operation.output_schema.target_namespace,
      operation.output_module,
      [],
      type_map
    )
  end

  # @spec parse_record(tuple()) :: map() | String.t()
  defp parse_model(node, body_namespace, module, opts, type_map) do
    Enum.reduce(
      module.xml_fields,
      module.__struct__,
      fn {field_or_embeds, name, xml_name, type, opts}, model ->
        value = parse_field(node, body_namespace, field_or_embeds, xml_name, type, opts, type_map)
        Map.put(model, name, value)
      end
    )
  end

  defp parse_field(node, body_namespace, :field, xml_name, type, opts, type_map) do
    body_xpath(node, body_namespace, ~x"body:#{xml_name}/text()"s)
    |> String.trim()
    |> Noap.Util.nil_if_empty()
    |> from_str(type, opts, type_map)
  end

  defp parse_field(node, body_namespace, :embeds_one, xml_name, child_module, opts, type_map) do
    body_xpath(node, body_namespace, ~x"body:#{xml_name}"e)
    |> parse_model(body_namespace, child_module, opts, type_map)
  end

  defp parse_field(node, body_namespace, :embeds_many, xml_name, child_module, opts, type_map) do
    body_xpath(node, body_namespace, ~x"body:#{xml_name}"l)
    |> Enum.map(&parse_model(&1, body_namespace, child_module, opts, type_map))
  end

  defp from_str(nil, _type, _opts, _type_map), do: nil

  defp from_str(str, type, opts, type_map) do
    ntype = type_map[type] || raise "Could not find type #{type}"

    case ntype.from_str(str, opts) do
      {:ok, val} ->
        val

      :error ->
        Logger.warn("Unable to parse type=#{type} str=#{str}")
        nil

      {:error, message_or_atom} ->
        Logger.warn("Unable to parse type=#{type} str=#{str}: #{message_or_atom}")
        nil
    end
  end

  defp get_child_module(parent_module, field) do
    {:parameterized, Ecto.Embedded, %Ecto.Embedded{related: module}} =
      parent_module.__schema__(:type, field)

    module
  end

  defp body_xpath(node, body_namespace, body_sigil) do
    node
    |> xpath(body_sigil |> add_namespace("body", body_namespace))
  end

  # def soap_version, do: Application.fetch_env!(:soap, :globals)[:version]
  def soap_version, do: "1.1"
end
