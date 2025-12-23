defmodule Noap.XMLSchema.Response do
  @moduledoc """
  Provides functions for parsing a soap response body.
  """

  require Logger
  import Meeseeks.XPath
  alias Noap.XMLField

  @soap_namespace "http://schemas.xmlsoap.org/soap/envelope/"

  def parse_soap_response(body, operation) do
    doc = Meeseeks.parse(body, :xml)

    body_node =
      Meeseeks.one(
        doc,
        xpath("//*[namespace-uri()='#{@soap_namespace}' and local-name()='Body']")
      )

    output_node =
      Meeseeks.one(
        body_node,
        xpath(".//*[namespace-uri()='#{operation.output_schema.target_namespace}' and local-name()='#{operation.output_name}']")
      )

    parse_xml_schema(
      output_node,
      operation.output_schema.target_namespace,
      operation.output_module,
      operation.type_map
    )
  end

  # @spec parse_record(tuple()) :: map() | String.t()
  defp parse_xml_schema(node, body_namespace, module, type_map) do
    Logger.debug("Parsing xml_schema=#{module}")

    module.xml_fields
    |> Enum.reduce(
      module.__struct__,
      fn xml_field, model ->
        Logger.debug("Parsing xml_field=#{inspect(xml_field)}")
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
            Logger.debug("Parsing name(atom)=#{name}")
            type = embed_type.type(name)

            value =
              case v do
                xml_name when is_binary(xml_name) ->
                  get_field_value(node, body_namespace, xml_name, type, xml_field.opts, type_map)

                [many_xml_name] ->
                  body_xpath_all(node, body_namespace, many_xml_name)
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
            Logger.debug("Parsing node(string)=#{parent_xml_node}")
            sub_xml_map = v
            child_node = body_xpath_one(node, body_namespace, parent_xml_node)

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
    Logger.debug("parse_field of node #{inspect(node)} xml_field #{inspect(xml_field)}")
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
    body_xpath_one(node, body_namespace, xml_field.xml_name)
    |> parse_xml_schema(body_namespace, xml_field.type, type_map)
  end

  defp parse_field(
         node,
         body_namespace,
         xml_field = %XMLField{field_or_embeds: :embeds_many},
         type_map
       ) do
    body_xpath_all(node, body_namespace, xml_field.xml_name)
    |> Enum.map(&parse_xml_schema(&1, body_namespace, xml_field.type, type_map))
  end

  defp get_field_value(node, body_namespace, xml_name, type, opts, type_map) do
    Logger.debug("get_field_value of node #{inspect(node)}")

    text_value =
      body_xpath_one(node, body_namespace, xml_name)
      |> case do
        nil -> nil
        element -> Meeseeks.text(element)
      end

    text_value
    |> case do
      nil -> nil
      text -> String.trim(text)
    end
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
    Logger.warning("Unable to parse type=#{type} val=#{input_val}")
    nil
  end

  defp verify_ok({:error, message_or_atom}, input_val, type) do
    Logger.warning("Unable to parse type=#{type} val=#{input_val}: #{message_or_atom}")
    nil
  end

  defp body_xpath_one(node, body_namespace, xml_name) do
    Meeseeks.one(
      node,
      xpath(".//*[namespace-uri()='#{body_namespace}' and local-name()='#{xml_name}']")
    )
  end

  defp body_xpath_all(node, body_namespace, xml_name) do
    Meeseeks.all(
      node,
      xpath(".//*[namespace-uri()='#{body_namespace}' and local-name()='#{xml_name}']")
    )
  end

  # def soap_version, do: Application.fetch_env!(:soap, :globals)[:version]
  def soap_version, do: "1.1"
end
