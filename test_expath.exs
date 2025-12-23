xml = "<root><name>John</name></root>"
{:ok, doc} = Expath.new(xml)

IO.puts("Testing Expath.query:")
result = Expath.query(doc, "//name/text()")
IO.inspect(result, label: "Result for //name/text()")

result2 = Expath.query(doc, "//name")
IO.inspect(result2, label: "Result for //name")
IO.inspect(hd(elem(result2, 1)), label: "First element type")

# Try to get XML string
result2a = Expath.query(doc, "string(//name)")
IO.inspect(result2a, label: "Result for string(//name)")

# Try outer-xml or similar
result2b = Expath.query(doc, "//name[1]")
IO.inspect(result2b, label: "Result for //name[1]")

xml2 = ~s(<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><name>John</name></soap:Body></soap:Envelope>)
{:ok, doc2} = Expath.new(xml2)
namespaces = %{"soap" => "http://schemas.xmlsoap.org/soap/envelope/"}
result3 = Expath.query(doc2, "soap:Body", namespaces)
IO.inspect(result3, label: "Result for soap:Body with namespaces")

# Try with local-name
result3a = Expath.query(doc2, "//*[local-name()='Body' and namespace-uri()='http://schemas.xmlsoap.org/soap/envelope/']")
IO.inspect(result3a, label: "Result for Body with local-name")

# Test without namespace map
result4 = Expath.query(doc2, "//Body")
IO.inspect(result4, label: "Result for //Body (no namespace)")

# Try different namespace query approaches
result5 = Expath.query(doc2, "//*[local-name()='Body']")
IO.inspect(result5, label: "Result for //*[local-name()='Body']")

# Try getting text from namespaced element
result6 = Expath.query(doc2, "//soap:Body/name/text()", namespaces)
IO.inspect(result6, label: "Result for //soap:Body/name/text() with namespaces")

result7 = Expath.query(doc2, "//*[local-name()='Body']/name/text()")
IO.inspect(result7, label: "Result for //*[local-name()='Body']/name/text()")

# Test attribute
xml3 = ~s(<root><item id="1" name="test">Content</item></root>)
{:ok, doc3} = Expath.new(xml3)
result5 = Expath.query(doc3, "//item/@id")
IO.inspect(result5, label: "Result for //item/@id")

# Test getting element with attributes
result6 = Expath.query(doc3, "//item")
IO.inspect(result6, label: "Result for //item (element)")

# Test string(.) on wrapped XML
wrapped = "<root>John</root>"
{:ok, doc4} = Expath.new(wrapped)
result7 = Expath.query(doc4, "string(.)")
IO.inspect(result7, label: "Result for string(.) on wrapped XML")

result8 = Expath.query(doc4, "//root/text()")
IO.inspect(result8, label: "Result for //root/text() on wrapped XML")

result9 = Expath.query(doc4, "/root/text()")
IO.inspect(result9, label: "Result for /root/text() on wrapped XML")
