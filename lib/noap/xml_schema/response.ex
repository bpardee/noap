defmodule Noap.XMLSchema.Response do
  @moduledoc """
  Provides a functions for parse an xml-like response body.
  """

  require Logger
  import SweetXml, only: [xpath: 2, sigil_x: 2, add_namespace: 3]
  import Noap.XMLUtil, only: [add_soap_namespace: 2]
  alias Noap.XMLField

  def parse_soap_response(body, operation, type_map) do
    doc = SweetXml.parse(body, namespace_conformant: true)

    body_node =
      xpath(
        doc,
        ~x"soap:Body"e |> add_soap_namespace("soap")
      )

    body_node
    |> xpath(
      ~x"#{operation.output_name}"e
      |> add_namespace("body", operation.output_schema.target_namespace)
    )
    |> parse_xml_schema(
      operation.output_schema.target_namespace,
      operation.output_module,
      type_map
    )
  end

  # @spec parse_record(tuple()) :: map() | String.t()
  defp parse_xml_schema(node, body_namespace, module, type_map) do
    module.xml_fields
    |> Enum.reduce(
      module.__struct__,
      fn xml_field, model ->
        value = parse_field(node, body_namespace, xml_field, type_map)
        Map.put(model, xml_field.name, value)
      end
    )
  end

  defp parse_xml_map(value_map, node, body_namespace, embed_type, xml_map, xml_field, type_map) do
    xml_map
    |> Enum.reduce(
      value_map,
      fn {k, v}, value_map ->
        case k do
          name when is_atom(name) ->
            type = embed_type.type(name)

            value =
              case v do
                xml_name when is_binary(xml_name) ->
                  get_field_value(node, body_namespace, xml_name, type, xml_field.opts, type_map)

                [many_xml_name] ->
                  body_xpath(node, body_namespace, ~x"body:#{many_xml_name}"l)
                  |> Enum.map(
                    &get_field_value(
                      &1,
                      body_namespace,
                      ".",
                      xml_field.type,
                      xml_field.opts,
                      type_map
                    )
                  )

                xml_names when is_list(xml_names) ->
                  xml_names
                  |> Enum.map(
                    &get_field_value(node, body_namespace, &1, type, xml_field.opts, type_map)
                  )
              end

            Map.put(value_map, name, value)

          parent_xml_node when is_binary(parent_xml_node) ->
            sub_xml_map = v
            child_node = body_xpath(node, body_namespace, ~x"body:#{parent_xml_node}"e)

            parse_xml_map(
              value_map,
              child_node,
              body_namespace,
              embed_type,
              sub_xml_map,
              xml_field,
              type_map
            )
        end
      end
    )
  end

  defp parse_field(node, body_namespace, xml_field = %XMLField{field_or_embeds: :field}, type_map) do
    get_field_value(
      node,
      body_namespace,
      xml_field.xml_name,
      xml_field.type,
      xml_field.opts,
      type_map
    )
  end

  defp parse_field(
         node,
         body_namespace,
         xml_field = %XMLField{xml_name: nil},
         type_map
       ) do
    embed_type = type_map[xml_field.type]
    xml_map = xml_field.xml_map
    value_map = parse_xml_map(%{}, node, body_namespace, embed_type, xml_map, xml_field, type_map)

    embed_type.from_map(xml_field.field_or_embeds, value_map, xml_field.opts)
    |> verify_ok(value_map, xml_field.type)
  end

  defp parse_field(
         node,
         body_namespace,
         xml_field = %XMLField{field_or_embeds: :embeds_one},
         type_map
       ) do
    body_xpath(node, body_namespace, ~x"body:#{xml_field.xml_name}"e)
    |> parse_xml_schema(body_namespace, xml_field.type, type_map)
  end

  defp parse_field(
         node,
         body_namespace,
         xml_field = %XMLField{field_or_embeds: :embeds_many},
         type_map
       ) do
    body_xpath(node, body_namespace, ~x"body:#{xml_field.xml_name}"l)
    |> Enum.map(&parse_xml_schema(&1, body_namespace, xml_field.type, type_map))
  end

  defp get_field_value(node, body_namespace, xml_name, type, opts, type_map) do
    body_xpath(node, body_namespace, ~x"body:#{xml_name}/text()"s)
    |> String.trim()
    |> Noap.Util.nil_if_empty()
    |> from_str(type, opts, type_map)
  end

  defp from_str(nil, _type, _opts, _type_map), do: nil

  defp from_str(str, type, opts, type_map) do
    ntype = type_map[type] || raise "Could not find type #{type}"

    ntype.from_str(str, opts)
    |> verify_ok(str, type)
  end

  defp verify_ok({:ok, val}, _input_val, _type), do: val

  defp verify_ok(:error, input_val, type) do
    Logger.warn("Unable to parse type=#{type} val=#{input_val}")
    nil
  end

  defp verify_ok({:error, message_or_atom}, input_val, type) do
    Logger.warn("Unable to parse type=#{type} val=#{input_val}: #{message_or_atom}")
    nil
  end

  defp body_xpath(node, body_namespace, body_sigil) do
    node
    |> xpath(body_sigil |> add_namespace("body", body_namespace))
  end

  # def soap_version, do: Application.fetch_env!(:soap, :globals)[:version]
  def soap_version, do: "1.1"
end
