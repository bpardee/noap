import Noap.SweetXmlCompat

xml = "<root><name>John</name></root>"
doc = parse(xml)

# Query //name with ?e modifier
expr = Noap.SweetXmlCompat.XPathExpr.new("//name", ?e)
result = xpath(doc, expr)
IO.inspect(result, label: "Result from //name")

if result != nil do
  # Query ./text() from the result
  text_expr = Noap.SweetXmlCompat.XPathExpr.new("./text()", ?s)

  # Check what the Node looks like
  IO.inspect(result, label: "Node struct")
  IO.inspect(result.doc, label: "Node.doc")

  # Query directly from Node's doc
  direct_result = Expath.query(result.doc, "/root/text()")
  IO.inspect(direct_result, label: "Direct query /root/text() from Node.doc")

  # Now query through xpath function
  text_result = xpath(result, text_expr)
  IO.inspect(text_result, label: "Text result from xpath function")
end
