# Simulate what happens in the test
xml = "<root><name>John</name></root>"
{:ok, doc} = Expath.new(xml)

# Query //name - Expath returns text
result = Expath.query(doc, "//name")
IO.inspect(result, label: "Expath query //name")

# Create wrapped XML from text
text = hd(elem(result, 1))
wrapped = "<root>#{text}</root>"
{:ok, wrapped_doc} = Expath.new(wrapped)

# Query string(.) from wrapped doc
result2 = Expath.query(wrapped_doc, "string(.)")
IO.inspect(result2, label: "string(.) on wrapped doc")

# Query /root/text() from wrapped doc
result3 = Expath.query(wrapped_doc, "/root/text()")
IO.inspect(result3, label: "/root/text() on wrapped doc")

# Now test the actual Node query path
import Noap.SweetXmlCompat
compat_doc = parse(xml)
compat_expr = Noap.SweetXmlCompat.XPathExpr.new("//name", ?e)
compat_result = xpath(compat_doc, compat_expr)
IO.inspect(compat_result, label: "compat_result (element)")

if compat_result != nil do
  # Test the adjusted XPath
  IO.inspect(compat_result, label: "Node struct")

  # Query string(.) directly on the Node's doc
  result4 = Expath.query(compat_result.doc, "string(.)")
  IO.inspect(result4, label: "Direct Expath.query string(.) on Node.doc")

  # Test what happens in xpath function - manually trace through
  xpath_string = "./text()"
  # This should be converted to "string(.)" for Node with xpath_to_node == "."
  adjusted = "string(.)"
  result5 = Expath.query(compat_result.doc, adjusted)
  IO.inspect(result5, label: "Expath.query with string(.)")

  # Now apply ?s modifier
  case result5 do
    {:ok, res} ->
      IO.inspect(res, label: "Result from Expath")
      # Apply ?s modifier - should call extract_text_content
      text_result = case res do
        [single] when is_binary(single) -> single
        list when is_list(list) -> Enum.join(list, "")
        other -> to_string(other)
      end
      IO.inspect(text_result, label: "After extract_text_content")
    {:error, e} ->
      IO.inspect(e, label: "Error from Expath")
  end

  compat_text_expr = Noap.SweetXmlCompat.XPathExpr.new("./text()", ?s)
  compat_text = xpath(compat_result, compat_text_expr)
  IO.inspect(compat_text, label: "compat_text from node")
end
