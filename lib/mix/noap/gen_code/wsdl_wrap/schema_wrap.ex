defmodule Mix.Noap.GenCode.WSDLWrap.SchemaWrap do
  require Logger

  defstruct [
    :schema_ns,
    :target_namespace,
    :element_form_default,
    :target_ns,
    :module,
    :top_types,
    :complex_type_map
  ]

  @type_to_simple_map %{
    "boolean" => :boolean,
    "date" => :date,
    "dateTime" => :datetime,
    "double" => :float,
    "float" => :float,
    "int" => :integer,
    "integer" => :integer,
    "long" => :integer,
    "string" => :string
  }

  alias Mix.Noap.GenCode.WSDLWrap.{Action, ComplexType, Field, Options, Util}
  import Meeseeks.XPath

  @schema_namespace "http://www.w3.org/2001/XMLSchema"

  def new(schema_ns, parent_module, schema_element, namespace_map, options) do
    target_namespace = Meeseeks.attr(schema_element, "targetNamespace") || ""
    element_form_default = Meeseeks.attr(schema_element, "elementFormDefault") || ""

    if target_namespace == "" do
      raise "Not sure how to handle with no targetNamespace: #{inspect(schema_element)}"
    end

    # Try to find namespace prefix that maps to target_namespace
    # First check namespace_map (extracted from root element and schema elements)
    # namespace_map keys are strings, values are URIs
    found_prefix = Enum.find_value(namespace_map, fn {prefix, uri} ->
      if uri == target_namespace, do: prefix
    end)

    # If not found in namespace_map, try to find in schema element itself
    found_prefix = found_prefix || Enum.find_value(["reqns", "resns", "tns", "ns0", "ns1", "ns2", "ns3", "ns4"], fn prefix ->
      case Meeseeks.attr(schema_element, "xmlns:#{prefix}") do
        uri when uri == target_namespace -> prefix
        _ -> nil
      end
    end) || Noap.XMLUtil.find_namespace(schema_element, target_namespace)

    # If we couldn't find it, try to determine from schema_module configuration
    target_ns = cond do
      found_prefix != nil and found_prefix != "" and found_prefix != :"" ->
        # found_prefix is a string, convert to atom
        String.to_atom(found_prefix)
      true ->
        # Use schema_module config to find target_ns by matching target_namespace URI
        case options[:schema_module] do
          list when is_list(list) ->
            # For each schema_module entry, check if its namespace URI matches target_namespace
            # First try exact match via namespace_map
            result = Enum.find_value(list, fn
              {ns, _module} when is_atom(ns) ->
                ns_string = Atom.to_string(ns)
                # Check if namespace_map has this prefix and if its URI matches target_namespace
                case Map.get(namespace_map, ns_string) do
                  uri when uri == target_namespace -> ns
                  _ -> nil
                end
              _ ->
                nil
            end)

            result ||
            # Fallback: try pattern matching based on common patterns
            # Check if target_namespace URI contains keywords that match schema_module entries
            Enum.find_value(list, fn
              {ns, _module} when is_atom(ns) ->
                ns_string = Atom.to_string(ns)
                target_lower = String.downcase(target_namespace)
                # Map common namespace prefixes to keywords they might contain
                keyword_map = %{
                  "reqns" => "request",
                  "resns" => "response"
                }
                keyword = Map.get(keyword_map, ns_string, ns_string)
                # Check if target_namespace contains the keyword
                if String.contains?(target_lower, keyword) do
                  ns
                else
                  nil
                end
              _ ->
                nil
            end) || :""
          _ ->
            :""
        end
    end

    module =
      Options.schema_module(options, target_ns) ||
        Util.convert_url_to_module(target_namespace, parent_module)

    # Only get direct child elements of the schema, not nested elements
    # Try to get direct children first using ./ which gets only immediate children
    top_type_elements = Meeseeks.all(schema_element, xpath("./*[namespace-uri()='#{@schema_namespace}' and local-name()='element']"))

    # Fallback: if namespace-uri() didn't work, try simple query for direct children
    top_type_elements = if Enum.empty?(top_type_elements) do
      Meeseeks.all(schema_element, xpath("./element"))
    else
      top_type_elements
    end

    # If still empty, fall back to the ancestor filtering approach
    top_type_elements = if Enum.empty?(top_type_elements) do
      all_elements = Meeseeks.all(schema_element, xpath(".//*[namespace-uri()='#{@schema_namespace}' and local-name()='element']"))

      # Fallback: if namespace-uri() didn't work, try simple query
      all_elements = if Enum.empty?(all_elements) do
        Meeseeks.all(schema_element, xpath(".//element"))
      else
        all_elements
      end

      # Filter to only direct children: an element is a direct child if schema_element
      # is its immediate parent. We check this by getting ancestors and seeing if schema is the first one
      all_elements
      |> Enum.filter(fn element ->
        # Get all ancestor elements (not just any node)
        ancestors = Meeseeks.all(element, xpath("ancestor::*"))
        # For a direct child, schema_element should be the last ancestor (closest parent)
        case ancestors do
          [] -> false
          ancestor_list ->
            # Check if schema_element is the immediate parent (last in ancestor list)
            List.last(ancestor_list) == schema_element
        end
      end)
    else
      top_type_elements
    end

    Logger.debug("Found #{length(top_type_elements)} top-level elements: #{Enum.map(top_type_elements, fn e -> Meeseeks.attr(e, "name") || "unnamed" end) |> Enum.join(", ")}")

      top_types =
      top_type_elements
      |> Enum.into(
        %{},
        fn element ->
          name = Meeseeks.attr(element, "name") || ""
          action_with_namespace = Meeseeks.attr(element, "type") || ""
          {name, Action.new(name, action_with_namespace, namespace_map)}
        end
      )

    schema = %__MODULE__{
      schema_ns: schema_ns,
      # element: schema_element,
      target_namespace: target_namespace,
      target_ns: target_ns,
      element_form_default: element_form_default,
      module: module,
      top_types: top_types,
      complex_type_map: nil
    }

    # Only get direct child named complexTypes of the schema, not nested ones
    # Named complexTypes are always top-level in XSD, so we can get all of them
    # and filter to only those with names (inline types don't have names)
    complex_type_elements = schema_element
    |> Meeseeks.all(xpath("./*[namespace-uri()='#{@schema_namespace}' and local-name()='complexType']"))

    # Fallback: if namespace-uri() didn't work, try simple query
    complex_type_elements = if Enum.empty?(complex_type_elements) do
      schema_element
      |> Meeseeks.all(xpath("./complexType"))
    else
      complex_type_elements
    end
    |> Enum.filter(fn element ->
      # Skip complexTypes without names (inline types)
      name = Meeseeks.attr(element, "name")
      name != nil && name != ""
    end)

    complex_type_map =
      complex_type_elements
      |> Enum.filter(fn element ->
        # Skip complexTypes without names (inline types)
        name = Meeseeks.attr(element, "name")
        name != nil && name != ""
      end)
      |> Enum.map(&parse_complex_type(schema, &1, nil))
      |> Enum.into(%{}, &{&1.name, &1})

    schema = %{schema | complex_type_map: complex_type_map}

    complex_type_map =
      top_type_elements
      |> Enum.map(&parse_type(schema, &1, nil))
      |> Enum.reduce(complex_type_map, fn result, map ->
        Logger.debug("Processing result from top_type_element: #{inspect(result)}")
        add_to_complex_type_map(result, map, schema.module)
      end)

    complex_type_map =
      complex_type_map
      |> Enum.map(fn {name, complex_type} ->
        {name, convert_name_to_complex_type(complex_type_map, complex_type)}
      end)
      |> Enum.into(%{})

    %{schema | complex_type_map: complex_type_map}
  end

  defp convert_name_to_complex_type(complex_type_map, complex_type = %ComplexType{}) do
    fields =
      complex_type.fields
      |> Enum.map(fn field ->
        %{field | type: convert_name_to_complex_type(complex_type_map, field.type)}
      end)

    %{complex_type | fields: fields}
  end

  defp convert_name_to_complex_type(_complex_type_map, simple_type) when is_atom(simple_type) do
    simple_type
  end

  defp convert_name_to_complex_type(complex_type_map, type_name)
       when is_binary(type_name) do
    # Check if it's a simple type name that should be converted to atom
    simple_type = @type_to_simple_map[type_name]
    if simple_type do
      simple_type
    else
      # It's a complex type name
      complex_type_map[type_name] ||
        raise "Couldn't find complex type of #{type_name}"
    end
  end

  defp add_to_complex_type_map(complex_type = %ComplexType{parent_module: parent_module}, map, schema_module) do
    # Only add top-level types to the map. Nested types have a parent_module that extends
    # beyond the schema.module (e.g., "Schema.Module.Parent.Child" vs "Schema.Module").
    # We determine nesting from the XML structure during parsing, which sets the parent_module
    # correctly. Top-level types have parent_module = schema.module.
    parent_module_str = to_string(parent_module)
    schema_module_str = to_string(schema_module)

    # If parent_module equals schema.module, it's top-level. Otherwise, it's nested.
    if parent_module_str == schema_module_str do
      Logger.debug("Adding top-level type #{complex_type.name} with parent_module=#{parent_module_str}")
      Map.put(map, complex_type.name, complex_type)
    else
      # This is a nested type, don't add it to the top-level map
      Logger.debug("Skipping nested type #{complex_type.name} with parent_module=#{parent_module_str} (schema.module=#{schema_module_str})")
      map
    end
  end

  defp add_to_complex_type_map(complex_type_name, map, _schema_module) when is_binary(complex_type_name) do
    # Should already exist or will be created later
    map
  end

  defp parse_complex_type(schema, parent_element, parent_complex_type) do
    name = Meeseeks.attr(parent_element, "name") || ""

    if name == "" do
      raise "Not sure how to handle complex_type without name #{inspect(parent_element)}"
    end

    elements = Meeseeks.all(
      parent_element,
      xpath(".//*[namespace-uri()='#{@schema_namespace}' and local-name()='sequence']/*[namespace-uri()='#{@schema_namespace}' and local-name()='element']")
    )

    # Fallback: if namespace-uri() didn't work, try simple query
    elements = if Enum.empty?(elements) do
      Meeseeks.all(parent_element, xpath(".//sequence//element"))
    else
      elements
    end
    parse_complex_type(schema, name, elements, parent_complex_type)
  end

  defp parse_complex_type(schema, name, elements, parent_complex_type) do
    Logger.debug("Creating complex type name=#{name}")

    Enum.reduce(
      elements,
      ComplexType.new(schema.module, name, parent_complex_type),
      fn element, complex_type ->
        field = parse_field(schema, element, complex_type)
        ComplexType.add_field(complex_type, field)
      end
    )
    # The fields are in reverse order based on add_field so put them back in correct order
    |> (fn complex_type -> %{complex_type | fields: Enum.reverse(complex_type.fields)} end).()
  end

  defp parse_field(schema, element, parent_complex_type) do
    xml_name = Meeseeks.attr(element, "name") || ""

    if xml_name == "" do
      raise "Not sure how to parse type without name #{inspect(element)}"
    end

    xml_type = Meeseeks.attr(element, "type") || ""

    case xml_type do
      "" ->
        field_type = parse_type(schema, element, parent_complex_type)

        embeds =
          cond do
            is_atom(field_type) ->
              :field

            true ->
              max_occurs = Meeseeks.attr(element, "maxOccurs") || ""
              Util.max_occurs_embed(max_occurs)
          end

        Field.new(embeds, xml_name, field_type)

      xml_type ->
        {field_or_embeds, type} = convert_type(schema, element, xml_type)
        Field.new(field_or_embeds, xml_name, type)
    end
  end

  defp convert_type(schema, element, xml_type) do
    case String.split(xml_type, ":", parts: 2) do
      [simple_type] ->
        type = @type_to_simple_map[simple_type]

        if is_nil(type) do
          raise("Not sure how to handle type=#{xml_type}")
        end

        {:field, type}

      [namespace, name] ->
        cond do
          namespace == schema.schema_ns ->
            convert_type(schema, element, name)

          true ->
            max_occurs = Meeseeks.attr(element, "maxOccurs") || ""
            embeds = Util.max_occurs_embed(max_occurs)
            {embeds, name}
        end
    end
  end

  defp parse_type(schema, parent_element, parent_complex_type) do
    name = Meeseeks.attr(parent_element, "name") || ""

    type = Meeseeks.attr(parent_element, "type") || ""

    cond do
      type != "" ->
        {_field_or_embeds, ctype} = convert_type(schema, parent_element, type)
        ctype

      (complex_elements = get_complex_type_elements(parent_element)) != [] ->
        parse_complex_type(schema, name, complex_elements, parent_complex_type)

      (simple_type_restriction = get_simple_type_restriction_element(parent_element)) != nil ->
        base_type = Meeseeks.attr(simple_type_restriction, "base") || ""

        if base_type == "" do
          raise(
            "Not sure how to handle name=#{name} simple_type_restriction " <>
              inspect(simple_type_restriction)
          )
        end

        {_field_or_embeds, ctype} = convert_type(schema, parent_element, base_type)
        ctype

      true ->
        # Empty field list is the only other possibility?
        parse_complex_type(schema, name, [], parent_complex_type)
    end
  end

  defp get_complex_type_elements(parent_element) do
    elements = parent_element
    |> Meeseeks.all(
      xpath(".//*[namespace-uri()='#{@schema_namespace}' and local-name()='complexType']/*[namespace-uri()='#{@schema_namespace}' and local-name()='sequence']/*[namespace-uri()='#{@schema_namespace}' and local-name()='element']")
    )

    # Fallback: if namespace-uri() didn't work, try simple query
    if Enum.empty?(elements) do
      parent_element
      |> Meeseeks.all(xpath(".//complexType//sequence//element"))
    else
      elements
    end
  end

  defp get_simple_type_restriction_element(parent_element) do
    element = parent_element
    |> Meeseeks.one(
      xpath(".//*[namespace-uri()='#{@schema_namespace}' and local-name()='simpleType']/*[namespace-uri()='#{@schema_namespace}' and local-name()='restriction']")
    )

    # Fallback: if namespace-uri() didn't work, try simple query
    if is_nil(element) do
      parent_element
      |> Meeseeks.one(xpath(".//simpleType//restriction"))
    else
      element
    end
  end
end
