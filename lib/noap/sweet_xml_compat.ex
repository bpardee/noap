defmodule Noap.SweetXmlCompat do
  @moduledoc """
  SweetXml-compatible API wrapper using Expath.

  This module provides the same function signatures and behavior as SweetXml,
  but uses Expath under the hood for OTP 25+ compatibility.
  """

  defmodule XPathExpr do
    @moduledoc false
    defstruct [:xpath, :modifier, :namespaces, :options]

    def new(xpath, modifier \\ nil, namespaces \\ %{}, options \\ []) do
      %__MODULE__{
        xpath: xpath,
        modifier: modifier,
        namespaces: namespaces,
        options: options
      }
    end

    def add_namespace(%__MODULE__{} = expr, prefix, namespace_uri) do
      %{expr | namespaces: Map.put(expr.namespaces, prefix, namespace_uri)}
    end
  end

  # Internal structure to represent a node that can be queried
  defmodule Node do
    @moduledoc false
    defstruct [:doc, :xpath_to_node, :namespaces, :xml_string]

    def new(doc, xpath_to_node, namespaces, xml_string) do
      %__MODULE__{
        doc: doc,
        xpath_to_node: xpath_to_node,
        namespaces: namespaces,
        xml_string: xml_string
      }
    end
  end

  @doc """
  Parses XML string into a document that can be queried with xpath/2.

  Options:
  - `:namespace_conformant` - if true, namespaces are preserved (default: true)
  """
  def parse(xml_string, opts \\ []) do
    namespace_conformant = Keyword.get(opts, :namespace_conformant, true)

    case Expath.new(xml_string) do
      {:ok, doc} ->
        if namespace_conformant do
          # Store namespaces in the document metadata
          namespaces = extract_namespaces(xml_string)
          %{doc: doc, namespaces: namespaces, xml_string: xml_string}
        else
          %{doc: doc, namespaces: %{}, xml_string: xml_string}
        end

      {:error, reason} ->
        raise "Failed to parse XML: #{inspect(reason)}"
    end
  end

  @doc """
  XPath sigil for creating XPath expressions.

  Modifiers:
  - `e` - returns a single element (or nil)
  - `l` - returns a list of elements
  - `s` - returns a string (text content)
  - no modifier - returns the raw result
  """
  defmacro sigil_x({:<<>>, _meta, [xpath_string]}, modifiers) when is_binary(xpath_string) do
    modifier = parse_modifier(modifiers)

    quote do
      Noap.SweetXmlCompat.XPathExpr.new(unquote(xpath_string), unquote(modifier))
    end
  end

  defmacro sigil_x({:<<>>, _meta, parts}, modifiers) when is_list(parts) do
    modifier = parse_modifier(modifiers)

    # Handle interpolated strings
    quote do
      xpath_string = unquote({:<<>>, [], parts})
      Noap.SweetXmlCompat.XPathExpr.new(xpath_string, unquote(modifier))
    end
  end

  defp parse_modifier([]), do: nil
  defp parse_modifier([modifier]) when modifier in [?e, ?l, ?s], do: modifier
  defp parse_modifier(_), do: nil

  @doc """
  Executes an XPath query on a document/node.

  Returns the result based on the modifier in the XPathExpr:
  - `e` - single element or nil
  - `l` - list of elements
  - `s` - string (text content)
  """
  # Handle SweetXpath structs from SweetXml
  def xpath(doc_or_node, %{__struct__: SweetXpath} = sweet_expr) do
    # Convert SweetXpath to XPathExpr
    xpath_string = sweet_expr.path |> List.to_string()
    modifier = cond do
      sweet_expr.is_value -> ?s
      sweet_expr.is_list -> ?l
      sweet_expr.is_keyword -> nil
      true -> ?e
    end

    namespaces = Enum.reduce(sweet_expr.namespaces || [], %{}, fn {prefix, uri}, acc ->
      Map.put(acc, prefix, uri)
    end)

    expr = XPathExpr.new(xpath_string, modifier, namespaces)
    xpath(doc_or_node, expr)
  end

  def xpath(doc_or_node, %XPathExpr{} = expr) do
    xpath_string = expr.xpath
    namespaces = expr.namespaces
    modifier = expr.modifier

    # Handle document with namespaces stored
    {expath_doc, all_namespaces, is_node, node_xpath, _node_xml_string, root_xml_string} =
      case doc_or_node do
        %{doc: d, namespaces: ns, xml_string: xml_str} -> {d, Map.merge(ns, namespaces), false, nil, nil, xml_str}
        %{doc: d, namespaces: ns} -> {d, Map.merge(ns, namespaces), false, nil, nil, nil}
        %Node{doc: d, namespaces: ns, xpath_to_node: np, xml_string: xml} when not is_nil(d) -> {d, Map.merge(ns, namespaces), true, np, xml, nil}
        %Node{} -> raise "Cannot query from Node with nil document"
        nil -> raise "Cannot query from nil document or node"
        _ -> {doc_or_node, namespaces, false, nil, nil, nil}
      end

    # Adjust XPath for Node queries
    # When querying from a Node, adjust the XPath appropriately
    adjusted_xpath = if is_node and node_xpath do
      if String.starts_with?(xpath_string, "./") do
        # For Nodes created from XML strings (node_xpath == "."),
        # handle special cases
        if node_xpath == "." do
          cond do
            xpath_string == "./text()" -> "/root/text()"
            xpath_string == "text()" -> "/root/text()"
            String.ends_with?(xpath_string, "/text()") ->
              # For paths ending with /text(), query from root
              base_path = String.replace_suffix(xpath_string, "/text()", "")
              if String.starts_with?(base_path, "./") do
                "/root" <> String.slice(base_path, 1..-1//-1) <> "/text()"
              else
                "/root" <> base_path <> "/text()"
              end
            String.starts_with?(xpath_string, "./@") ->
              # For attributes on standalone element: ./@name -> /*/@name
              attr_name = String.slice(xpath_string, 3..-1//-1)
              "/*/@#{attr_name}"
            String.starts_with?(xpath_string, "@") ->
              # For attributes: @name -> /*/@name
              attr_name = String.slice(xpath_string, 1..-1//-1)
              "/*/@#{attr_name}"
            true ->
              # For relative paths, adjust to work with wrapped root element
              if String.starts_with?(xpath_string, "./") do
                "/root" <> String.slice(xpath_string, 1..-1//-1)
              else
                "/root/" <> xpath_string
              end
          end
        else
          # Remove ./ prefix and append to node's xpath
          relative_path = String.slice(xpath_string, 2..-1//-1)
          if relative_path == "" do
            node_xpath
          else
            # Combine node path with relative path
            if String.ends_with?(node_xpath, "/") do
              node_xpath <> relative_path
            else
              node_xpath <> "/" <> relative_path
            end
          end
        end
      else
        # Absolute path - use as is
        xpath_string
      end
    else
      xpath_string
    end

    # Query using adjusted_xpath - let Expath handle it
    result = if adjusted_xpath == "" do
        # Empty xpath selects current context - return the node or document
        return_result = if is_node do
          doc_or_node
        else
          # For documents, create a Node struct wrapping the document
          %Node{doc: expath_doc, xpath_to_node: ".", namespaces: all_namespaces, xml_string: nil}
        end
        [return_result]
    else
      # Expath has full namespace support
      # When XPath uses namespace prefixes (contains ":"), we must use query/3 with namespace map
      # When XPath doesn't use prefixes, try query/2 first, then query/3 if needed (for default namespace handling)
      xpath_uses_namespaces = String.contains?(adjusted_xpath, ":")

      if xpath_uses_namespaces and map_size(all_namespaces) > 0 do
        # XPath explicitly uses namespaces, must use query/3 with namespace mappings
        # Expath expects namespace map with prefix -> URI
        case Expath.query(expath_doc, adjusted_xpath, all_namespaces) do
          {:ok, res} when res != [] -> res
          {:ok, []} ->
            # Expath namespace queries often return empty for element selection
            # Try using local-name() to match elements regardless of namespace
            local_name_xpath = convert_to_local_name_xpath(adjusted_xpath, all_namespaces)
            case Expath.query(expath_doc, local_name_xpath) do
              {:ok, res} -> res
              {:error, _} -> []
            end
          {:error, _error} ->
            # Try to handle namespace::* axis which Expath might not support
            if String.contains?(adjusted_xpath, "namespace::") do
              # Return empty list for namespace axis queries (not fully supported)
              []
            else
              # Try using local-name() approach
              local_name_xpath = convert_to_local_name_xpath(adjusted_xpath, all_namespaces)
              case Expath.query(expath_doc, local_name_xpath) do
                {:ok, res} -> res
                {:error, _} -> []
              end
            end
        end
      else
        # XPath doesn't use namespace prefixes
        # Try query/2 first (matches elements in no namespace)
        case Expath.query(expath_doc, adjusted_xpath) do
          {:ok, res} when res != [] -> res
          {:ok, []} when map_size(all_namespaces) > 0 ->
            # If query/2 returns empty but we have namespaces (possibly default namespace),
            # use local-name() to match elements regardless of namespace (like SweetXml)
            modified_xpath = modify_xpath_for_default_namespace(adjusted_xpath)
            case Expath.query(expath_doc, modified_xpath) do
              {:ok, res} -> res
              {:error, _} -> []
            end
          {:ok, res} -> res
          {:error, error} ->
            # Try to handle XPath axes that might not be supported
            if String.contains?(adjusted_xpath, "parent::") or String.contains?(adjusted_xpath, "ancestor::") do
              # For parent/ancestor axes, try a workaround or return empty
              # Expath might not support these axes directly
              []
            else
              raise "XPath query failed: #{inspect(error)} for query: #{adjusted_xpath}"
            end
        end
      end
    end

    # Expath.query always returns a list, even for single results
    # result is already extracted from {:ok, res} tuple
    # Debug: check if result is empty when it shouldn't be
    final_result = apply_modifier(result, modifier, expath_doc, adjusted_xpath, all_namespaces, doc_or_node, root_xml_string)
    final_result
  end

  def xpath(doc_or_node, xpath_string) when is_binary(xpath_string) do
    expr = XPathExpr.new(xpath_string)
    xpath(doc_or_node, expr)
  end

  @doc """
  Executes an XPath query with keyword list for extracting multiple values.

  Example:
      xpath(doc, ~x".", name: ~x"./@name"s, value: ~x"./text()"s)
  """
  def xpath(doc_or_node, %XPathExpr{} = base_expr, keyword_list) when is_list(keyword_list) do
    # First, get the base node(s)
    base_result = xpath(doc_or_node, base_expr)

    # Handle list of nodes
    if is_list(base_result) do
      Enum.map(base_result, fn node ->
        extract_keyword_values(node, keyword_list)
      end)
    else
      extract_keyword_values(base_result, keyword_list)
    end
  end

  defp extract_keyword_values(nil, _keyword_list) do
    nil
  end

  defp extract_keyword_values(node, keyword_list) do
    Enum.reduce(keyword_list, %{}, fn {key, %XPathExpr{} = expr}, acc ->
      value = xpath(node, expr)
      Map.put(acc, key, value)
    end)
  end

  defp apply_modifier(result, modifier, _doc, _xpath, _namespaces, _doc_or_node, _root_xml_string) when modifier == nil do
    # No modifier - return raw result
    # Expath returns text content for elements, so we return as-is
    result
  end

  defp apply_modifier(result, ?e, _doc, xpath, namespaces, doc_or_node, root_xml_string) do
    # Single element - return first result or nil
    case result do
      [] -> nil
      [first | _] ->
        # If xpath ends with /text() or text() or string(.), extract text directly
        # string(.) is used when querying ./text() from a Node
        if String.ends_with?(xpath, "/text()") or String.ends_with?(xpath, "text()") or String.ends_with?(xpath, "string(.)") do
          extract_text_content([first])
        else
          # Expath returns text content for elements, not XML strings
          # We need to create a Node that can be queried further
          # For now, wrap the text in XML to create a queryable node
          create_node_from_text(first, namespaces, xpath, doc_or_node, root_xml_string)
        end
      other -> other
    end
  end

  defp apply_modifier(result, ?l, _doc, xpath, namespaces, doc_or_node, root_xml_string) do
    # List of elements - ensure it's a list
    parsed_result = if is_list(result) do
      result
    else
      [result]
    end

    # If the xpath ends with /text() or string(.), return strings directly (not Node structs)
    if String.ends_with?(xpath, "/text()") or String.ends_with?(xpath, "text()") or String.ends_with?(xpath, "string(.)") do
      # For text() queries, Expath already returns strings
      parsed_result
    else
      # Expath returns text content for elements, create Node structs
      Enum.map(parsed_result, fn item ->
        create_node_from_text(item, namespaces, xpath, doc_or_node, root_xml_string)
      end)
    end
  end

  defp apply_modifier(result, ?s, _doc, _xpath, _namespaces, _doc_or_node, _root_xml_string) do
    # String - extract text content
    # SweetXml with 's' modifier joins all text matches into a single string
    # Expath already returns strings, so join them
    # But if result is a list with one string, return the string directly
    case result do
      [single] when is_binary(single) -> single
      list when is_list(list) -> extract_text_content(list)
      other -> extract_text_content([other])
    end
  end

  # Helper to create a Node from text content returned by Expath
  # Expath returns text for elements, so we wrap it in XML to make it queryable
  defp create_node_from_text(text, namespaces, _xpath, _doc_or_node, _root_xml_string) when is_binary(text) do
    # Escape XML special characters
    escaped = text
      |> String.replace("&", "&amp;")
      |> String.replace("<", "&lt;")
      |> String.replace(">", "&gt;")
      |> String.replace("\"", "&quot;")
      |> String.replace("'", "&apos;")
    wrapped_xml = "<root>#{escaped}</root>"
    case Expath.new(wrapped_xml) do
      {:ok, node_doc} ->
        %Node{doc: node_doc, xpath_to_node: ".", namespaces: namespaces, xml_string: wrapped_xml}
      _ ->
        # If parsing fails, return a Node with nil doc (will raise on query)
        %Node{doc: nil, xpath_to_node: ".", namespaces: namespaces, xml_string: wrapped_xml}
    end
  end
  defp create_node_from_text(item, _namespaces, _xpath, _doc_or_node, _root_xml_string), do: item

  defp extract_text_content(nil), do: ""
  defp extract_text_content([]), do: ""
  defp extract_text_content(list) when is_list(list) do
    # Expath returns list of strings, join them
    # SweetXML returns strings (not charlists) for text() queries
    Enum.join(list, "")
  end
  defp extract_text_content(item) when is_binary(item), do: item
  defp extract_text_content(other) do
    # For other types, try to convert to string
    to_string(other)
  end

  @doc """
  Adds a namespace to an XPath expression.

  Example:
      ~x"soap:Body"e |> add_namespace("soap", "http://schemas.xmlsoap.org/soap/envelope/")
  """
  def add_namespace(%XPathExpr{} = expr, prefix, namespace_uri) do
    XPathExpr.add_namespace(expr, prefix, namespace_uri)
  end

  # Handle SweetXpath structs from SweetXml
  def add_namespace(%{__struct__: SweetXpath} = sweet_expr, prefix, namespace_uri) do
    # Convert SweetXpath to XPathExpr
    xpath_string = sweet_expr.path |> List.to_string()
    modifier = cond do
      sweet_expr.is_value -> ?s
      sweet_expr.is_list -> ?l
      sweet_expr.is_keyword -> nil
      true -> ?e
    end

    namespaces = Enum.reduce(sweet_expr.namespaces || [], %{}, fn {p, uri}, acc ->
      Map.put(acc, p, uri)
    end)
    |> Map.put(prefix, namespace_uri)

    XPathExpr.new(xpath_string, modifier, namespaces)
  end

  def add_namespace(xpath_string, prefix, namespace_uri) when is_binary(xpath_string) do
    expr = XPathExpr.new(xpath_string)
    add_namespace(expr, prefix, namespace_uri)
  end

  # Extract namespaces from XML string
  defp extract_namespaces(xml_string) do
    # Parse namespace declarations from XML
    regex = ~r/xmlns(?::(\w+))?=["']([^"']+)["']/
    matches = Regex.scan(regex, xml_string)

    Enum.reduce(matches, %{}, fn [_, prefix, uri], acc ->
      prefix = if prefix == "", do: nil, else: prefix
      if prefix do
        Map.put(acc, prefix, uri)
      else
        Map.put(acc, "", uri) # Default namespace
      end
    end)
  end

  # Modify XPath to use local-name() when elements might be in a default namespace
  # This makes XPath match elements regardless of namespace (like SweetXml behavior)
  defp modify_xpath_for_default_namespace(xpath_string) do
    # Replace element names in path with local-name() to match regardless of namespace
    # e.g., "//name/text()" becomes "//*[local-name()='name']/text()"
    # Handle // at start and / in middle
    xpath_string
    |> String.replace(~r/\/\/([a-zA-Z_][a-zA-Z0-9_]*)/, "//*[local-name()='\\1']")
    |> String.replace(~r/\/([a-zA-Z_][a-zA-Z0-9_]*)(?=\/|$)/, "/*[local-name()='\\1']")
  end

  # Convert namespace-prefixed XPath to local-name() XPath
  # e.g., "soap:Body" -> "//*[local-name()='Body']"
  # e.g., "//soap:Body/name" -> "//*[local-name()='Body']/name"
  defp convert_to_local_name_xpath(xpath_string, _namespaces) do
    # Extract namespace prefix and element name
    # Replace patterns like "prefix:element" with "*[local-name()='element']"
    xpath_string
    |> String.replace(~r/([\/\/]?)([a-zA-Z_][a-zA-Z0-9_]*):([a-zA-Z_][a-zA-Z0-9_]*)/, "\\1*[local-name()='\\3']")
    |> String.replace(~r/^([a-zA-Z_][a-zA-Z0-9_]*):([a-zA-Z_][a-zA-Z0-9_]*)$/, "//*[local-name()='\\2']")
  end
end
