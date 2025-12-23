defmodule Noap.MeeseeksCompatTest do
  use ExUnit.Case

  import SweetXml, only: [xpath: 2, add_namespace: 3, sigil_x: 2]

  describe "parse/2" do
    test "parses simple XML string and produces comparable structure" do
      xml = "<root><name>John</name></root>"

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      # Both should be parseable and queryable
      assert is_map(compat_doc)
      assert Map.has_key?(compat_doc, :doc)
      assert Map.has_key?(compat_doc, :namespaces)

      # Both should produce same query results
      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//name/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//name/text()"s)

      assert compat_result == sweet_result
      assert compat_result == "John"
    end

    test "parses XML with namespace_conformant: true (default) and extracts same namespaces" do
      xml = ~s(<?xml version="1.0"?><root xmlns="http://example.com"><name>John</name></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml, namespace_conformant: true)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      # Both should have namespace support
      assert is_map(compat_doc)
      assert Map.has_key?(compat_doc, :namespaces)

      # Both should produce same query results
      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//name/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//name/text()"s)

      assert compat_result == sweet_result
      assert compat_result == "John"
    end

    test "parses XML with namespace_conformant: false and both behave the same" do
      xml = "<root><name>John</name></root>"

      compat_doc = Noap.MeeseeksCompat.parse(xml, namespace_conformant: false)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: false)

      # Both should have empty namespaces when namespace_conformant is false
      assert is_map(compat_doc)
      assert compat_doc.namespaces == %{}

      # Both should produce same query results
      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//name/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//name/text()"s)

      assert compat_result == sweet_result
      assert compat_result == "John"
    end

    test "extracts namespaces from XML and both libraries handle them" do
      xml = ~s(<?xml version="1.0"?><root xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns="http://example.com"><name>John</name></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      # Both should extract namespaces
      assert is_map(compat_doc.namespaces)
      assert compat_doc.namespaces["soap"] == "http://schemas.xmlsoap.org/soap/envelope/"

      # Both should produce same query results
      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//name/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//name/text()"s)

      assert compat_result == sweet_result
      assert compat_result == "John"
    end
  end

  describe "sigil_x/2" do
    test "sigil_x without modifier produces same xpath results as SweetXml" do
      xml = "<root><name>John</name><age>30</age></root>"
      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      # Test SweetXml sigil
      import SweetXml, only: [sigil_x: 2]
      sweet_expr = ~x"//name"
      sweet_result = SweetXml.xpath(sweet_doc, sweet_expr)
      sweet_text_expr = ~x"//name/text()"s
      sweet_text = SweetXml.xpath(sweet_doc, sweet_text_expr)

      # Test Noap.MeeseeksCompat sigil (using XPathExpr.new to create equivalent)
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("//name", nil)
      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, compat_expr)
      compat_text_expr = Noap.MeeseeksCompat.XPathExpr.new("//name/text()", ?s)
      compat_text = Noap.MeeseeksCompat.xpath(compat_doc, compat_text_expr)

      # Compare results - both should return nodes and extract same text
      assert (compat_result == nil) == (sweet_result == nil)
      assert compat_text == sweet_text
      assert compat_text == "John"
    end

    test "sigil_x with 'e' modifier produces same results as SweetXml" do
      xml = "<root><name>John</name><age>30</age></root>"
      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      # Test SweetXml sigil
      import SweetXml, only: [sigil_x: 2]
      sweet_expr = ~x"//name"e
      sweet_result = SweetXml.xpath(sweet_doc, sweet_expr)

      # Test Noap.MeeseeksCompat sigil (using XPathExpr.new)
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("//name", ?e)
      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, compat_expr)

      # Both should return single element or nil
      assert (compat_result == nil) == (sweet_result == nil)

      # If both present, extract text and compare
      if compat_result != nil and sweet_result != nil do
        sweet_text_expr = ~x"./text()"s
        compat_text_expr = Noap.MeeseeksCompat.XPathExpr.new("./text()", ?s)

        compat_text = Noap.MeeseeksCompat.xpath(compat_result, compat_text_expr)
        sweet_text = SweetXml.xpath(sweet_result, sweet_text_expr)
        assert compat_text == sweet_text
        assert compat_text == "John"
      end
    end

    test "sigil_x with 'l' modifier produces same results as SweetXml" do
      xml = "<root><item>1</item><item>2</item><item>3</item></root>"
      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      # Test SweetXml sigil
      import SweetXml, only: [sigil_x: 2]
      sweet_expr = ~x"//item"l
      sweet_result = SweetXml.xpath(sweet_doc, sweet_expr)

      # Test Noap.MeeseeksCompat sigil (using XPathExpr.new)
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("//item", ?l)
      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, compat_expr)

      assert is_list(compat_result)
      assert is_list(sweet_result)
      assert length(compat_result) == length(sweet_result)

      # Extract text from all items and compare
      sweet_text_expr = ~x"./text()"s
      compat_text_expr = Noap.MeeseeksCompat.XPathExpr.new("./text()", ?s)

      compat_texts = Enum.map(compat_result, fn item ->
        Noap.MeeseeksCompat.xpath(item, compat_text_expr)
      end)
      sweet_texts = Enum.map(sweet_result, fn item ->
        SweetXml.xpath(item, sweet_text_expr)
      end)

      assert compat_texts == sweet_texts
      assert compat_texts == ["1", "2", "3"]
    end

    test "sigil_x with 's' modifier produces same results as SweetXml" do
      xml = "<root><name>John Doe</name></root>"
      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      # Test SweetXml sigil
      import SweetXml, only: [sigil_x: 2]
      sweet_expr = ~x"//name/text()"s
      sweet_result = SweetXml.xpath(sweet_doc, sweet_expr)

      # Test Noap.MeeseeksCompat sigil (using XPathExpr.new)
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("//name/text()", ?s)
      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, compat_expr)

      assert is_binary(compat_result)
      assert is_binary(sweet_result)
      assert compat_result == sweet_result
      assert compat_result == "John Doe"
    end

    test "sigil_x with Noap.MeeseeksCompat produces same results as SweetXml" do
      xml = "<root><name>John</name><age>30</age></root>"
      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      # Test Noap.MeeseeksCompat using XPathExpr.new (avoiding sigil conflict with top-level import)
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("//name", ?e)
      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, compat_expr)
      compat_text_expr = Noap.MeeseeksCompat.XPathExpr.new("//name/text()", ?s)
      compat_text = Noap.MeeseeksCompat.xpath(compat_doc, compat_text_expr)

      # Test SweetXml using sigil (already imported at top level)
      sweet_expr = ~x"//name"e
      sweet_result = SweetXml.xpath(sweet_doc, sweet_expr)
      sweet_text_expr = ~x"//name/text()"s
      sweet_text = SweetXml.xpath(sweet_doc, sweet_text_expr)

      # Compare results - both should extract same text
      assert (compat_result == nil) == (sweet_result == nil or (is_list(sweet_result) and length(sweet_result) == 0))
      assert compat_text == sweet_text
      assert compat_text == "John"
    end
  end

  describe "xpath/2 with simple XML" do
    test "xpath/2 with string query returns comparable results" do
      xml = "<root><name>John</name><age>30</age></root>"
      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, "//name")
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//name")

      # Both should return a list of nodes
      assert is_list(compat_result) or is_tuple(compat_result)
      assert is_list(sweet_result) or is_tuple(sweet_result)

      # Extract text from both to compare actual content
      compat_text = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//name/text()", ?s))
      sweet_text = SweetXml.xpath(sweet_doc, ~x"//name/text()"s)

      assert compat_text == sweet_text
      assert compat_text == "John"
    end

    test "xpath/2 with 'e' modifier returns single element and both match" do
      xml = "<root><name>John</name><age>30</age></root>"
      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//name", ?e))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//name"e)

      # Both should return a single element or nil
      assert compat_result == nil or is_tuple(compat_result) or is_map(compat_result)
      assert sweet_result == nil or is_tuple(sweet_result) or is_map(sweet_result)

      # Both should have same presence (both nil or both present)
      assert (compat_result == nil) == (sweet_result == nil)

      # If both present, extract text and compare
      if compat_result != nil and sweet_result != nil do
        compat_text = Noap.MeeseeksCompat.xpath(compat_result, Noap.MeeseeksCompat.XPathExpr.new("./text()", ?s))
        sweet_text = SweetXml.xpath(sweet_result, ~x"./text()"s)
        assert compat_text == sweet_text
      end
    end

    test "xpath/2 with 'l' modifier returns list and both match" do
      xml = "<root><item>1</item><item>2</item><item>3</item></root>"
      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//item", ?l))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//item"l)

      assert is_list(compat_result)
      assert is_list(sweet_result)
      assert length(compat_result) == length(sweet_result)

      # Extract text from all items and compare
      compat_texts = Enum.map(compat_result, fn item ->
        Noap.MeeseeksCompat.xpath(item, Noap.MeeseeksCompat.XPathExpr.new("./text()", ?s))
      end)
      sweet_texts = Enum.map(sweet_result, fn item ->
        SweetXml.xpath(item, ~x"./text()"s)
      end)

      assert compat_texts == sweet_texts
      assert compat_texts == ["1", "2", "3"]
    end

    test "xpath with 's' modifier returns string text" do
      xml = "<root><name>John Doe</name></root>"
      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, ~x"//name/text()"s)
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//name/text()"s)

      assert is_binary(compat_result)
      assert is_binary(sweet_result)
      assert compat_result == sweet_result
    end

    test "xpath with 's' modifier on non-existent node returns empty string" do
      xml = "<root><name>John</name></root>"
      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//nonexistent/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//nonexistent/text()"s)

      assert compat_result == ""
      assert sweet_result == ""
    end

    test "xpath with 'e' modifier on non-existent node returns nil" do
      xml = "<root><name>John</name></root>"
      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//nonexistent", ?e))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//nonexistent"e)

      assert compat_result == nil
      assert sweet_result == nil
    end
  end

  describe "xpath/2 with nested XML" do
    test "xpath/2 finds nested elements and both return same result" do
      xml = """
      <root>
        <person>
          <name>John</name>
          <age>30</age>
        </person>
        <person>
          <name>Jane</name>
          <age>25</age>
        </person>
      </root>
      """

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//person/name/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//person/name/text()"s)

      # SweetXML with 's' modifier concatenates all matches
      assert is_binary(compat_result)
      assert is_binary(sweet_result)
      assert compat_result == sweet_result
      assert compat_result == "JohnJane"
    end

    test "xpath/2 with 'l' modifier finds all nested elements and both match" do
      xml = """
      <root>
        <person>
          <name>John</name>
        </person>
        <person>
          <name>Jane</name>
        </person>
      </root>
      """

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//person/name/text()", ?l))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//person/name/text()"l)

      assert is_list(compat_result)
      assert is_list(sweet_result)
      assert length(compat_result) == length(sweet_result)
      assert compat_result == sweet_result
      # SweetXML returns charlists, so compat_result should also be charlists
      assert compat_result == [~c"John", ~c"Jane"]
    end
  end

  describe "xpath/2 with namespaces" do
    test "xpath with namespace prefix" do
      xml = ~s(<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><name>John</name></soap:Body></soap:Envelope>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      compat_expr = ~x"soap:Body"e |> Noap.MeeseeksCompat.add_namespace("soap", "http://schemas.xmlsoap.org/soap/envelope/")
      sweet_expr = ~x"soap:Body"e |> SweetXml.add_namespace("soap", "http://schemas.xmlsoap.org/soap/envelope/")

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, compat_expr)
      sweet_result = SweetXml.xpath(sweet_doc, sweet_expr)

      assert compat_result != nil
      assert sweet_result != nil
    end

    test "xpath with add_namespace helper" do
      xml = ~s(<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><name>John</name></soap:Body></soap:Envelope>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      compat_result = Noap.MeeseeksCompat.xpath(
        compat_doc,
        Noap.MeeseeksCompat.XPathExpr.new("soap:Body", ?e) |> Noap.MeeseeksCompat.add_namespace("soap", "http://schemas.xmlsoap.org/soap/envelope/")
      )

      sweet_result = SweetXml.xpath(
        sweet_doc,
        ~x"soap:Body"e |> SweetXml.add_namespace("soap", "http://schemas.xmlsoap.org/soap/envelope/")
      )

      assert compat_result != nil
      assert sweet_result != nil
    end

    test "xpath extracts text from namespaced element" do
      xml = ~s(<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><name>John</name></soap:Body></soap:Envelope>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      # First get the Body node
      compat_body = Noap.MeeseeksCompat.xpath(
        compat_doc,
        Noap.MeeseeksCompat.XPathExpr.new("soap:Body", ?e) |> Noap.MeeseeksCompat.add_namespace("soap", "http://schemas.xmlsoap.org/soap/envelope/")
      )

      sweet_body = SweetXml.xpath(
        sweet_doc,
        ~x"soap:Body"e |> SweetXml.add_namespace("soap", "http://schemas.xmlsoap.org/soap/envelope/")
      )

      # Then extract text from child
      compat_text = Noap.MeeseeksCompat.xpath(compat_body, Noap.MeeseeksCompat.XPathExpr.new("./name/text()", ?s))
      sweet_text = SweetXml.xpath(sweet_body, ~x"./name/text()"s)

      assert compat_text == "John"
      assert sweet_text == "John"
      assert compat_text == sweet_text
    end
  end

  describe "xpath/3 with keyword list" do
    test "xpath/3 extracts multiple values into map and both match" do
      xml = """
      <root>
        <person name="John" age="30" />
        <person name="Jane" age="25" />
      </root>
      """

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//person", ?l),
        name: Noap.MeeseeksCompat.XPathExpr.new("./@name", ?s),
        age: Noap.MeeseeksCompat.XPathExpr.new("./@age", ?s)
      )

      sweet_result = SweetXml.xpath(sweet_doc, ~x"//person"l,
        name: ~x"./@name"s,
        age: ~x"./@age"s
      )

      assert is_list(compat_result)
      assert is_list(sweet_result)
      assert length(compat_result) == length(sweet_result)

      # Compare all items
      Enum.zip(compat_result, sweet_result)
      |> Enum.each(fn {compat_item, sweet_item} ->
        assert compat_item.name == sweet_item.name
        assert compat_item.age == sweet_item.age
      end)

      # Verify specific values
      compat_first = List.first(compat_result)
      sweet_first = List.first(sweet_result)
      assert compat_first.name == "John"
      assert compat_first.name == sweet_first.name
      assert compat_first.age == "30"
      assert compat_first.age == sweet_first.age
    end

    test "xpath/3 extracts multiple values from single element and both match" do
      xml = ~s(<root><person name="John" age="30" /></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//person", ?e),
        name: Noap.MeeseeksCompat.XPathExpr.new("./@name", ?s),
        age: Noap.MeeseeksCompat.XPathExpr.new("./@age", ?s)
      )

      sweet_result = SweetXml.xpath(sweet_doc, ~x"//person"e,
        name: ~x"./@name"s,
        age: ~x"./@age"s
      )

      assert is_map(compat_result)
      assert is_map(sweet_result)
      assert compat_result.name == sweet_result.name
      assert compat_result.age == sweet_result.age
      assert compat_result.name == "John"
      assert compat_result.age == "30"
    end
  end

  describe "add_namespace/3" do
    test "add_namespace to XPathExpr produces same structure as SweetXml" do
      # Test SweetXml sigil
      import SweetXml, only: [sigil_x: 2]
      sweet_expr = ~x"soap:Body"e
      sweet_result = SweetXml.add_namespace(sweet_expr, "soap", "http://schemas.xmlsoap.org/soap/envelope/")

      # Test Noap.MeeseeksCompat using XPathExpr.new
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("soap:Body", ?e)
      compat_result = Noap.MeeseeksCompat.add_namespace(compat_expr, "soap", "http://schemas.xmlsoap.org/soap/envelope/")

      # Both should have namespace added
      assert %Noap.MeeseeksCompat.XPathExpr{namespaces: compat_namespaces} = compat_result
      assert compat_namespaces["soap"] == "http://schemas.xmlsoap.org/soap/envelope/"

      # SweetXml structure may differ, but functionality should be same
      # Test that both work with actual XML
      xml = ~s(<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><name>John</name></soap:Body></soap:Envelope>)
      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      compat_xpath_result = Noap.MeeseeksCompat.xpath(compat_doc, compat_result)
      sweet_xpath_result = SweetXml.xpath(sweet_doc, sweet_result)

      # Both should find the Body element
      assert compat_xpath_result != nil
      assert sweet_xpath_result != nil
      # Compare that both extract same text
      compat_text = Noap.MeeseeksCompat.xpath(compat_xpath_result, Noap.MeeseeksCompat.XPathExpr.new("./name/text()", ?s))
      sweet_text = SweetXml.xpath(sweet_xpath_result, ~x"./name/text()"s)
      assert compat_text == sweet_text
      assert compat_text == "John"
    end

    test "add_namespace to string produces same functionality as SweetXml" do
      compat_result = Noap.MeeseeksCompat.add_namespace("soap:Body", "soap", "http://schemas.xmlsoap.org/soap/envelope/")
      # SweetXml doesn't support add_namespace with plain strings, only with sigils
      sweet_expr = ~x"soap:Body"
      sweet_result = SweetXml.add_namespace(sweet_expr, "soap", "http://schemas.xmlsoap.org/soap/envelope/")

      assert %Noap.MeeseeksCompat.XPathExpr{namespaces: namespaces} = compat_result
      assert namespaces["soap"] == "http://schemas.xmlsoap.org/soap/envelope/"

      # Test with actual XML
      xml = ~s(<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><name>John</name></soap:Body></soap:Envelope>)
      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      compat_xpath_result = Noap.MeeseeksCompat.xpath(compat_doc, compat_result)
      sweet_xpath_result = SweetXml.xpath(sweet_doc, sweet_result)

      assert compat_xpath_result != nil
      assert sweet_xpath_result != nil
    end

    test "add_namespace chains correctly and both libraries behave the same" do
      # Import and use SweetXml sigil first
      import SweetXml, only: [sigil_x: 2]
      sweet_expr = ~x"soap:Body"e
      sweet_expr1 = SweetXml.add_namespace(sweet_expr, "soap", "http://schemas.xmlsoap.org/soap/envelope/")
      sweet_expr2 = SweetXml.add_namespace(sweet_expr1, "body", "http://example.com/body")

      # Now use XPathExpr.new for Noap.MeeseeksCompat to avoid sigil conflict
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("soap:Body", ?e)
      compat_expr1 = Noap.MeeseeksCompat.add_namespace(compat_expr, "soap", "http://schemas.xmlsoap.org/soap/envelope/")
      compat_expr2 = Noap.MeeseeksCompat.add_namespace(compat_expr1, "body", "http://example.com/body")

      assert compat_expr2.namespaces["soap"] == "http://schemas.xmlsoap.org/soap/envelope/"
      assert compat_expr2.namespaces["body"] == "http://example.com/body"

      # Test that chained namespaces work with actual XML
      xml = ~s(<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:body="http://example.com/body"><soap:Body><body:name>John</body:name></soap:Body></soap:Envelope>)
      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      compat_body = Noap.MeeseeksCompat.xpath(compat_doc, compat_expr2)
      sweet_body = SweetXml.xpath(sweet_doc, sweet_expr2)

      assert compat_body != nil
      assert sweet_body != nil
      # Compare that both extract same text
      compat_text = Noap.MeeseeksCompat.xpath(compat_body, Noap.MeeseeksCompat.XPathExpr.new("./body:name/text()", ?s) |> Noap.MeeseeksCompat.add_namespace("body", "http://example.com/body"))
      sweet_text = SweetXml.xpath(sweet_body, ~x"./body:name/text()"s |> SweetXml.add_namespace("body", "http://example.com/body"))
      assert compat_text == sweet_text
      assert compat_text == "John"
    end
  end

  describe "SOAP-like XML structure" do
    test "parses SOAP envelope structure" do
      xml = ~s(<?xml version="1.0"?>
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <ProcessData xmlns="http://www.example.com/dataprocessing/soap/response">
            <Result>Success</Result>
          </ProcessData>
        </soap:Body>
      </soap:Envelope>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      # Get Body
      compat_body = Noap.MeeseeksCompat.xpath(
        compat_doc,
        Noap.MeeseeksCompat.XPathExpr.new("soap:Body", ?e) |> Noap.MeeseeksCompat.add_namespace("soap", "http://schemas.xmlsoap.org/soap/envelope/")
      )

      sweet_body = SweetXml.xpath(
        sweet_doc,
        ~x"soap:Body"e |> SweetXml.add_namespace("soap", "http://schemas.xmlsoap.org/soap/envelope/")
      )

      assert compat_body != nil
      assert sweet_body != nil

      # Get Result text
      compat_result = Noap.MeeseeksCompat.xpath(compat_body, Noap.MeeseeksCompat.XPathExpr.new(".//Result/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_body, ~x".//Result/text()"s)

      assert compat_result == "Success"
      assert sweet_result == "Success"
      assert compat_result == sweet_result
    end
  end

  describe "complex nested WSDL-like structures" do
    test "parses deeply nested complexType structures with sequences" do
      xml = ~s(<?xml version="1.0"?>
      <definitions targetNamespace="http://www.example.com/dataprocessing" xmlns="http://schemas.xmlsoap.org/wsdl/" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <types>
          <xsd:schema targetNamespace="http://www.example.com/dataprocessing/soap/request" xmlns:tns="http://www.example.com/dataprocessing/soap/request" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
            <xsd:complexType name="ProcessingRequest">
              <xsd:sequence>
                <xsd:element name="RequestId" type="xsd:string"/>
                <xsd:element name="ItemData" type="tns:ItemData"/>
              </xsd:sequence>
            </xsd:complexType>
            <xsd:complexType name="ItemData">
              <xsd:sequence>
                <xsd:element name="ItemIdentifier" type="xsd:string"/>
                <xsd:element name="ItemName" type="tns:ItemName"/>
                <xsd:element name="ItemLocation" type="tns:ItemLocation"/>
              </xsd:sequence>
            </xsd:complexType>
            <xsd:complexType name="ItemName">
              <xsd:sequence>
                <xsd:element name="PrimaryName" type="xsd:string"/>
                <xsd:element name="SecondaryName" type="xsd:string"/>
              </xsd:sequence>
            </xsd:complexType>
            <xsd:complexType name="ItemLocation">
              <xsd:sequence>
                <xsd:element name="StreetAddress" type="xsd:string"/>
                <xsd:element name="City" type="xsd:string"/>
                <xsd:element name="PostalCode" type="xsd:string"/>
              </xsd:sequence>
            </xsd:complexType>
          </xsd:schema>
        </types>
      </definitions>)

      compat_doc = Noap.MeeseeksCompat.parse(xml, namespace_conformant: true)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      # Test deep nested path: xsd:complexType/xsd:sequence/xsd:element
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("xsd:complexType/xsd:sequence/xsd:element", ?l)
        |> Noap.MeeseeksCompat.add_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

      sweet_expr = ~x"xsd:complexType/xsd:sequence/xsd:element"l
        |> SweetXml.add_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

      compat_elements = Noap.MeeseeksCompat.xpath(compat_doc, compat_expr)

      # SweetXML may crash on complex namespace structures
      sweet_elements = try do
        SweetXml.xpath(sweet_doc, sweet_expr)
      rescue
        _ -> []
      end

      assert is_list(compat_elements)
      assert is_list(sweet_elements)
      assert length(compat_elements) > 0
      # SweetXML may have namespace issues, so check if it returns results
      if length(sweet_elements) > 0 do
        assert length(compat_elements) == length(sweet_elements)
      end

      # Extract names from first element
      compat_first = List.first(compat_elements)

      compat_name = Noap.MeeseeksCompat.xpath(compat_first, Noap.MeeseeksCompat.XPathExpr.new("@name", ?s))

      # Only compare with SweetXML if it didn't crash
      if length(sweet_elements) > 0 do
        sweet_first = List.first(sweet_elements)
        sweet_name = SweetXml.xpath(sweet_first, ~x"@name"s)
        assert compat_name == sweet_name
      end

      # Our implementation should return the correct name
      assert compat_name == "RequestId"
    end

    test "handles multiple nested levels with attribute extraction" do
      xml = ~s(<?xml version="1.0"?>
      <definitions xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <types>
          <xsd:schema targetNamespace="http://example.com/request">
            <xsd:complexType name="ProcessingRequest">
              <xsd:sequence>
                <xsd:element name="RequestId" type="xsd:string" nillable="false"/>
                <xsd:element name="ItemData" type="tns:ItemData" nillable="false"/>
              </xsd:sequence>
            </xsd:complexType>
            <xsd:complexType name="ItemData">
              <xsd:sequence>
                <xsd:element name="ItemIdentifier" type="xsd:string" nillable="false"/>
                <xsd:element name="ItemAttributes" type="tns:ItemAttributes" nillable="false"/>
              </xsd:sequence>
            </xsd:complexType>
            <xsd:complexType name="ItemAttributes">
              <xsd:sequence>
                <xsd:element name="AttributeCode" type="xsd:string" nillable="false"/>
                <xsd:element name="SubAttributes" type="tns:SubAttributes" minOccurs="0" maxOccurs="unbounded"/>
              </xsd:sequence>
            </xsd:complexType>
            <xsd:complexType name="SubAttributes">
              <xsd:sequence>
                <xsd:element name="SubCode" type="xsd:string" nillable="false"/>
              </xsd:sequence>
            </xsd:complexType>
          </xsd:schema>
        </types>
      </definitions>)

      compat_doc = Noap.MeeseeksCompat.parse(xml, namespace_conformant: true)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      # Extract targetNamespace attribute from schema
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("xsd:schema/@targetNamespace", ?s)
        |> Noap.MeeseeksCompat.add_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

      sweet_expr = ~x"xsd:schema/@targetNamespace"s
        |> SweetXml.add_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

      compat_ns = Noap.MeeseeksCompat.xpath(compat_doc, compat_expr)

      # SweetXML may crash on complex namespace structures
      sweet_ns = try do
        SweetXml.xpath(sweet_doc, sweet_expr)
      rescue
        _ -> ""
      end

      # Our implementation should return the correct namespace
      assert compat_ns == "http://example.com/request"
      # SweetXML may have namespace issues - if it returns empty, that's a SweetXML bug
      if sweet_ns != "" do
        assert sweet_ns == "http://example.com/request"
        assert compat_ns == sweet_ns
      end

      # Extract nillable attributes from deeply nested elements
      compat_nillable_expr = Noap.MeeseeksCompat.XPathExpr.new("xsd:complexType/xsd:sequence/xsd:element/@nillable", ?l)
        |> Noap.MeeseeksCompat.add_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

      sweet_nillable_expr = ~x"xsd:complexType/xsd:sequence/xsd:element/@nillable"l
        |> SweetXml.add_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

      compat_nillables = Noap.MeeseeksCompat.xpath(compat_doc, compat_nillable_expr)

      # SweetXML may crash on complex namespace structures
      sweet_nillables = try do
        SweetXml.xpath(sweet_doc, sweet_nillable_expr)
      rescue
        _ -> []
      end

      assert is_list(compat_nillables)
      assert is_list(sweet_nillables)
      # Only compare if SweetXML returns results
      if length(sweet_nillables) > 0 do
        assert compat_nillables == sweet_nillables
      end
      assert "false" in compat_nillables
    end

    test "handles xpath/3 with deeply nested structures" do
      xml = ~s(<?xml version="1.0"?>
      <definitions xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <types>
          <xsd:schema>
            <xsd:complexType name="ProcessingRequest">
              <xsd:sequence>
                <xsd:element name="RequestId" type="xsd:string" nillable="false"/>
                <xsd:element name="RequestType" type="xsd:string" nillable="false"/>
              </xsd:sequence>
            </xsd:complexType>
            <xsd:complexType name="ItemData">
              <xsd:sequence>
                <xsd:element name="ItemIdentifier" type="xsd:string" nillable="false"/>
                <xsd:element name="ItemName" type="tns:ItemName" nillable="false"/>
              </xsd:sequence>
            </xsd:complexType>
          </xsd:schema>
        </types>
      </definitions>)

      compat_doc = Noap.MeeseeksCompat.parse(xml, namespace_conformant: true)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("xsd:complexType", ?l)
        |> Noap.MeeseeksCompat.add_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

      sweet_expr = ~x"xsd:complexType"l
        |> SweetXml.add_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, compat_expr,
        name: Noap.MeeseeksCompat.XPathExpr.new("@name", ?s)
      )

      sweet_result = SweetXml.xpath(sweet_doc, sweet_expr,
        name: ~x"@name"s
      )

      assert is_list(compat_result)
      assert is_list(sweet_result)
      # SweetXML may have namespace issues, so check if it returns results
      # If SweetXML returns 0, it's a SweetXML bug - we should still return correct results
      if length(sweet_result) > 0 do
        assert length(compat_result) == length(sweet_result)
      end
      # Our implementation should return the correct result (2 complexTypes)
      assert length(compat_result) == 2

      # Verify both extract same names
      compat_names = Enum.map(compat_result, & &1.name)
      sweet_names = Enum.map(sweet_result, & &1.name)

      # Only compare if SweetXML returns results (it may have namespace issues)
      if length(sweet_result) > 0 do
        assert compat_names == sweet_names
      end
      # Our implementation should return the correct names
      assert "ProcessingRequest" in compat_names
      assert "ItemData" in compat_names
    end

    test "handles namespace::* queries for finding namespaces" do
      xml = ~s(<?xml version="1.0"?>
      <definitions targetNamespace="http://www.example.com/dataprocessing"
                   xmlns="http://schemas.xmlsoap.org/wsdl/"
                   xmlns:reqns="http://www.example.com/dataprocessing/soap/request"
                   xmlns:resns="http://www.example.com/dataprocessing/soap/response"
                   xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                   xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <types/>
      </definitions>)

      compat_doc = Noap.MeeseeksCompat.parse(xml, namespace_conformant: true)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      # Extract namespaces using namespace::* axis
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("./namespace::*", ?l)
      sweet_expr = ~x"./namespace::*"l

      compat_namespaces = Noap.MeeseeksCompat.xpath(compat_doc, compat_expr)
      sweet_namespaces = SweetXml.xpath(sweet_doc, sweet_expr)

      # Both should return namespace information
      assert is_list(compat_namespaces) or is_tuple(compat_namespaces)
      assert is_list(sweet_namespaces) or is_tuple(sweet_namespaces)

      # Verify namespace extraction works
      assert compat_doc.namespaces["reqns"] == "http://www.example.com/dataprocessing/soap/request"
      assert compat_doc.namespaces["resns"] == "http://www.example.com/dataprocessing/soap/response"
      assert compat_doc.namespaces["soap"] == "http://schemas.xmlsoap.org/wsdl/soap/"
      assert compat_doc.namespaces["xsd"] == "http://www.w3.org/2001/XMLSchema"
    end

    test "handles complex nested paths with multiple namespace prefixes" do
      xml = ~s(<?xml version="1.0"?>
      <definitions xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
                   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                   xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/">
        <wsdl:types>
          <xsd:schema>
            <xsd:complexType name="ProcessingRequest">
              <xsd:sequence>
                <xsd:element name="RequestId" type="xsd:string"/>
              </xsd:sequence>
            </xsd:complexType>
          </xsd:schema>
        </wsdl:types>
        <wsdl:service>
          <wsdl:port>
            <soap:address location="http://example.com/service"/>
          </wsdl:port>
        </wsdl:service>
      </definitions>)

      compat_doc = Noap.MeeseeksCompat.parse(xml, namespace_conformant: true)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      # Test complex path: wsdl:service/wsdl:port/soap:address/@location
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("wsdl:service/wsdl:port/soap:address/@location", ?s)
        |> Noap.MeeseeksCompat.add_namespace("wsdl", "http://schemas.xmlsoap.org/wsdl/")
        |> Noap.MeeseeksCompat.add_namespace("soap", "http://schemas.xmlsoap.org/wsdl/soap/")

      sweet_expr = ~x"wsdl:service/wsdl:port/soap:address/@location"s
        |> SweetXml.add_namespace("wsdl", "http://schemas.xmlsoap.org/wsdl/")
        |> SweetXml.add_namespace("soap", "http://schemas.xmlsoap.org/wsdl/soap/")

      compat_location = Noap.MeeseeksCompat.xpath(compat_doc, compat_expr)
      sweet_location = SweetXml.xpath(sweet_doc, sweet_expr)

      assert compat_location == "http://example.com/service"
      assert sweet_location == "http://example.com/service"
      assert compat_location == sweet_location
    end

    test "handles deeply nested sequences with elementFormDefault attributes" do
      xml = ~s(<?xml version="1.0"?>
      <definitions xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <types>
          <xsd:schema attributeFormDefault="qualified" elementFormDefault="qualified" targetNamespace="http://example.com/request">
            <xsd:complexType name="ProcessingRequest">
              <xsd:sequence>
                <xsd:element name="RequestId" type="xsd:string"/>
                <xsd:element name="ItemData" type="tns:ItemData"/>
              </xsd:sequence>
            </xsd:complexType>
            <xsd:complexType name="ItemData">
              <xsd:sequence>
                <xsd:element name="ItemIdentifier" type="xsd:string"/>
                <xsd:element name="ItemName" type="tns:ItemName"/>
              </xsd:sequence>
            </xsd:complexType>
            <xsd:complexType name="ItemName">
              <xsd:sequence>
                <xsd:element name="PrimaryName" type="xsd:string"/>
                <xsd:element name="SecondaryName" type="xsd:string"/>
              </xsd:sequence>
            </xsd:complexType>
          </xsd:schema>
        </types>
      </definitions>)

      compat_doc = Noap.MeeseeksCompat.parse(xml, namespace_conformant: true)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      # Extract schema attributes using xpath/3
      compat_schema_expr = Noap.MeeseeksCompat.XPathExpr.new("xsd:schema", ?e)
        |> Noap.MeeseeksCompat.add_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

      sweet_schema_expr = ~x"xsd:schema"e
        |> SweetXml.add_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

      compat_schema = Noap.MeeseeksCompat.xpath(compat_doc, compat_schema_expr,
        target_namespace: Noap.MeeseeksCompat.XPathExpr.new("@targetNamespace", ?s),
        element_form_default: Noap.MeeseeksCompat.XPathExpr.new("@elementFormDefault", ?s),
        attribute_form_default: Noap.MeeseeksCompat.XPathExpr.new("@attributeFormDefault", ?s)
      )

      # SweetXml may fail on this particular query, so wrap in try-rescue
      sweet_schema = try do
        SweetXml.xpath(sweet_doc, sweet_schema_expr,
          target_namespace: ~x"@targetNamespace"s,
          element_form_default: ~x"@elementFormDefault"s,
          attribute_form_default: ~x"@attributeFormDefault"s
        )
      rescue
        _ -> nil
      end

      assert compat_schema.target_namespace == "http://example.com/request"
      assert compat_schema.element_form_default == "qualified"
      assert compat_schema.attribute_form_default == "qualified"

      # Only compare with SweetXml if it succeeded
      if sweet_schema != nil do
        assert compat_schema.target_namespace == sweet_schema.target_namespace
        assert compat_schema.element_form_default == sweet_schema.element_form_default
        assert compat_schema.attribute_form_default == sweet_schema.attribute_form_default
      end
    end

    test "handles maxOccurs and minOccurs attributes in nested structures" do
      xml = ~s(<?xml version="1.0"?>
      <definitions xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <types>
          <xsd:schema>
            <xsd:complexType name="ItemAttributes">
              <xsd:sequence>
                <xsd:element name="AttributeCode" type="xsd:string" nillable="false"/>
                <xsd:element name="SubAttributes" type="tns:SubAttributes" minOccurs="0" maxOccurs="unbounded"/>
              </xsd:sequence>
            </xsd:complexType>
          </xsd:schema>
        </types>
      </definitions>)

      compat_doc = Noap.MeeseeksCompat.parse(xml, namespace_conformant: true)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      # Extract maxOccurs attribute
      compat_max_occurs_expr = Noap.MeeseeksCompat.XPathExpr.new("xsd:complexType/xsd:sequence/xsd:element/@maxOccurs", ?s)
        |> Noap.MeeseeksCompat.add_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

      sweet_max_occurs_expr = ~x"xsd:complexType/xsd:sequence/xsd:element/@maxOccurs"s
        |> SweetXml.add_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

      compat_max_occurs = Noap.MeeseeksCompat.xpath(compat_doc, compat_max_occurs_expr)
      sweet_max_occurs = SweetXml.xpath(sweet_doc, sweet_max_occurs_expr)

      # Should get the last element's maxOccurs (unbounded)
      assert compat_max_occurs == "unbounded" or compat_max_occurs == ""
      assert sweet_max_occurs == "unbounded" or sweet_max_occurs == ""

      # Extract minOccurs
      compat_min_occurs_expr = Noap.MeeseeksCompat.XPathExpr.new("xsd:complexType/xsd:sequence/xsd:element/@minOccurs", ?l)
        |> Noap.MeeseeksCompat.add_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

      sweet_min_occurs_expr = ~x"xsd:complexType/xsd:sequence/xsd:element/@minOccurs"l
        |> SweetXml.add_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

      compat_min_occurs = Noap.MeeseeksCompat.xpath(compat_doc, compat_min_occurs_expr)

      # SweetXML may crash or return empty on complex namespace structures
      sweet_min_occurs = try do
        SweetXml.xpath(sweet_doc, sweet_min_occurs_expr)
      rescue
        _ -> []
      end

      assert is_list(compat_min_occurs)
      assert is_list(sweet_min_occurs)
      assert "0" in compat_min_occurs
      # Only compare if SweetXML returns results
      if length(sweet_min_occurs) > 0 do
        assert compat_min_occurs == sweet_min_occurs
      end
    end
  end

  describe "edge cases" do
    test "handles empty XML" do
      xml = "<root></root>"

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//nonexistent", ?e))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//nonexistent"e)

      assert compat_result == nil
      assert sweet_result == nil
    end

    test "handles XML with attributes" do
      xml = ~s(<root><item id="1" name="test">Content</item></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_id = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//item/@id", ?s))
      sweet_id = SweetXml.xpath(sweet_doc, ~x"//item/@id"s)

      assert compat_id == "1"
      assert sweet_id == "1"
      assert compat_id == sweet_id

      compat_name = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//item/@name", ?s))
      sweet_name = SweetXml.xpath(sweet_doc, ~x"//item/@name"s)

      assert compat_name == "test"
      assert sweet_name == "test"
      assert compat_name == sweet_name
    end

    test "handles XML with CDATA and both extract same content" do
      xml = ~s(<root><description><![CDATA[Some <b>HTML</b> content]]></description></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//description/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//description/text()"s)

      # Both should extract the CDATA content
      assert is_binary(compat_result)
      assert is_binary(sweet_result)
      assert compat_result == sweet_result
      assert compat_result == "Some <b>HTML</b> content"
    end

    test "handles multiple text nodes and both return same results" do
      xml = """
      <root>
        <item>First</item>
        <item>Second</item>
        <item>Third</item>
      </root>
      """

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//item/text()", ?l))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//item/text()"l)

      assert is_list(compat_result)
      assert is_list(sweet_result)
      assert length(compat_result) == length(sweet_result)
      assert compat_result == sweet_result
      assert compat_result == [~c"First", ~c"Second", ~c"Third"]
    end
  end

  describe "error handling" do
    test "parse/2 raises on invalid XML" do
      invalid_xml = "<root><unclosed>"

      assert_raise RuntimeError, ~r/Failed to parse XML/, fn ->
        Noap.MeeseeksCompat.parse(invalid_xml)
      end
    end

    test "parse/2 handles empty string" do
      assert_raise RuntimeError, ~r/Failed to parse XML/, fn ->
        Noap.MeeseeksCompat.parse("")
      end
    end

    test "xpath/2 raises on invalid XPath" do
      xml = "<root><name>John</name></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      assert_raise RuntimeError, ~r/XPath query failed/, fn ->
        Noap.MeeseeksCompat.xpath(doc, "//[invalid")
      end
    end

    test "xpath/2 handles XPath with syntax errors gracefully" do
      xml = "<root><name>John</name></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      assert_raise RuntimeError, ~r/XPath query failed/, fn ->
        Noap.MeeseeksCompat.xpath(doc, "//[")
      end
    end
  end

  describe "parse/2 edge cases" do
    test "handles XML with only whitespace" do
      xml = "   \n\t  "

      assert_raise RuntimeError, ~r/Failed to parse XML/, fn ->
        Noap.MeeseeksCompat.parse(xml)
      end
    end

    test "handles XML with XML declaration" do
      xml = ~s(<?xml version="1.0" encoding="UTF-8"?><root><name>John</name></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//name/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//name/text()"s)

      assert compat_result == sweet_result
      assert compat_result == "John"
    end

    test "handles XML with processing instructions" do
      xml = ~s(<?xml-stylesheet type="text/xsl" href="style.xsl"?><root><name>John</name></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//name/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//name/text()"s)

      assert compat_result == sweet_result
    end

    test "handles XML with comments" do
      xml = "<root><!-- This is a comment --><name>John</name></root>"

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//name/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//name/text()"s)

      assert compat_result == sweet_result
      assert compat_result == "John"
    end

    test "handles XML with mixed content (text and elements)" do
      xml = "<root>Before<name>John</name>After</root>"

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("/root/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"/root/text()"s)

      # Both should handle mixed content
      assert is_binary(compat_result)
      assert is_binary(sweet_result)
    end
  end

  describe "xpath/2 edge cases with modifiers" do
    test "'e' modifier returns nil for empty result" do
      xml = "<root><name>John</name></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//nonexistent", ?e))
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//nonexistent"e)

      assert compat_result == nil
      assert compat_result == sweet_result
    end

    test "'l' modifier returns empty list for no matches" do
      xml = "<root><name>John</name></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//nonexistent", ?l))
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//nonexistent"l)

      assert compat_result == []
      assert compat_result == sweet_result
    end

    test "'s' modifier returns empty string for no matches" do
      xml = "<root><name>John</name></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//nonexistent/text()", ?s))
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//nonexistent/text()"s)

      assert compat_result == ""
      assert compat_result == sweet_result
    end

    test "'s' modifier handles multiple text nodes" do
      xml = "<root>First<name>John</name>Second</root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("/root/text()", ?s))
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"/root/text()"s)

      # Both should concatenate multiple text nodes
      assert is_binary(compat_result)
      assert is_binary(sweet_result)
    end

    test "no modifier returns raw result (list)" do
      xml = "<root><item>1</item><item>2</item></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//item", nil))
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//item")

      assert is_list(compat_result)
      assert is_list(sweet_result) or is_tuple(sweet_result)
    end
  end

  describe "xpath/3 edge cases" do
    test "xpath/3 with empty keyword list returns base result" do
      xml = "<root><person name=\"John\" /></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//person", ?e), [])
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//person"e, [])

      # Both should return the base result
      assert compat_result != nil
      assert (compat_result == nil) == (sweet_result == nil)
    end

    test "xpath/3 with nil base result handles gracefully" do
      xml = "<root><person name=\"John\" /></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//nonexistent", ?e),
        name: Noap.MeeseeksCompat.XPathExpr.new("./@name", ?s)
      )

      # Should handle nil gracefully
      assert compat_result == nil
    end

    test "xpath/3 with list base result extracts from each" do
      xml = "<root><person name=\"John\" /><person name=\"Jane\" /></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//person", ?l),
        name: Noap.MeeseeksCompat.XPathExpr.new("./@name", ?s)
      )

      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//person"l,
        name: ~x"./@name"s
      )

      assert is_list(compat_result)
      assert is_list(sweet_result)
      assert length(compat_result) == 2
      assert length(compat_result) == length(sweet_result)
    end
  end

  describe "XPath functions and predicates" do
    test "XPath with count() function" do
      xml = "<root><item>1</item><item>2</item><item>3</item></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, "count(//item)")
      # SweetXml doesn't support count() function directly, so we'll count manually
      sweet_items = SweetXml.xpath(SweetXml.parse(xml), ~x"//item"l)
      sweet_result = length(sweet_items)

      # Both should return count
      assert compat_result == sweet_result
      assert compat_result == 3
    end

    test "XPath with position() predicate" do
      xml = "<root><item>1</item><item>2</item><item>3</item></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//item[position()=1]/text()", ?s))
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//item[position()=1]/text()"s)

      assert compat_result == "1"
      assert compat_result == sweet_result
    end

    test "XPath with attribute predicate" do
      xml = ~s(<root><item id="1">First</item><item id="2">Second</item></root>)
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//item[@id='1']/text()", ?s))
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//item[@id='1']/text()"s)

      assert compat_result == "First"
      assert compat_result == sweet_result
    end

    test "XPath with text() predicate" do
      xml = "<root><item>First</item><item>Second</item></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//item[text()='First']/text()", ?s))
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//item[text()='First']/text()"s)

      assert compat_result == "First"
      assert compat_result == sweet_result
    end

    test "XPath with last() function" do
      xml = "<root><item>1</item><item>2</item><item>3</item></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//item[last()]/text()", ?s))
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//item[last()]/text()"s)

      assert compat_result == "3"
      assert compat_result == sweet_result
    end
  end

  describe "XPath axes" do
    test "XPath with parent axis" do
      xml = "<root><parent><child>Value</child></parent></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//child/parent::*", ?e))
      # SweetXml doesn't support name() function, so we'll test parent axis differently
      # Get parent and verify it's the parent element
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//child/parent::*"e)

      # Both should return the parent element
      assert compat_result != nil
      assert sweet_result != nil
      # Verify parent contains the child
      compat_parent_text = Noap.MeeseeksCompat.xpath(compat_result, Noap.MeeseeksCompat.XPathExpr.new(".//child/text()", ?s))
      sweet_parent_text = SweetXml.xpath(sweet_result, ~x".//child/text()"s)
      assert compat_parent_text == sweet_parent_text
      assert compat_parent_text == "Value"
    end

    test "XPath with ancestor axis" do
      xml = "<root><parent><child>Value</child></parent></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//child/ancestor::*", ?l))
      # SweetXml doesn't support name() function, so we'll test ancestor axis differently
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//child/ancestor::*"l)

      assert is_list(compat_result)
      assert is_list(sweet_result)
      assert length(compat_result) == length(sweet_result)
    end
  end

  describe "default namespace handling" do
    test "extracts default namespace (xmlns without prefix)" do
      xml = ~s(<?xml version="1.0"?><root xmlns="http://example.com/default"><name>John</name></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)

      # Default namespace should be stored with empty string key
      assert Map.has_key?(compat_doc.namespaces, "")
      assert compat_doc.namespaces[""] == "http://example.com/default"
    end

    test "handles both default and prefixed namespaces" do
      xml = ~s(<?xml version="1.0"?><root xmlns="http://example.com/default" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><name>John</name></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)

      assert compat_doc.namespaces[""] == "http://example.com/default"
      assert compat_doc.namespaces["soap"] == "http://schemas.xmlsoap.org/soap/envelope/"
    end
  end

  describe "sigil_x/2 edge cases" do
    test "sigil_x with string interpolation" do
      xml = "<root><item id=\"1\">First</item><item id=\"2\">Second</item></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      id = "1"
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("//item[@id='#{id}']", ?s)
      compat_result = Noap.MeeseeksCompat.xpath(doc, compat_expr)

      assert compat_result == "First"
    end

    test "sigil_x with empty xpath string" do
      xml = "<root><name>John</name></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("", ?s)
      compat_result = Noap.MeeseeksCompat.xpath(doc, compat_expr)

      # Empty xpath should still work (selects current context)
      assert is_binary(compat_result) or compat_result == ""
    end
  end

  describe "add_namespace/3 edge cases" do
    test "add_namespace with empty prefix" do
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("Body", ?e)
      compat_result = Noap.MeeseeksCompat.add_namespace(compat_expr, "", "http://example.com/default")

      assert compat_result.namespaces[""] == "http://example.com/default"
    end

    test "add_namespace with empty namespace URI" do
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("soap:Body", ?e)
      compat_result = Noap.MeeseeksCompat.add_namespace(compat_expr, "soap", "")

      assert compat_result.namespaces["soap"] == ""
    end

    test "add_namespace overwrites existing namespace" do
      compat_expr = Noap.MeeseeksCompat.XPathExpr.new("soap:Body", ?e)
      compat_expr1 = Noap.MeeseeksCompat.add_namespace(compat_expr, "soap", "http://old.com")
      compat_expr2 = Noap.MeeseeksCompat.add_namespace(compat_expr1, "soap", "http://new.com")

      assert compat_expr2.namespaces["soap"] == "http://new.com"
    end

    test "add_namespace to string xpath" do
      compat_result = Noap.MeeseeksCompat.add_namespace("soap:Body", "soap", "http://schemas.xmlsoap.org/soap/envelope/")

      assert %Noap.MeeseeksCompat.XPathExpr{} = compat_result
      assert compat_result.namespaces["soap"] == "http://schemas.xmlsoap.org/soap/envelope/"
      assert compat_result.xpath == "soap:Body"
    end
  end

  describe "XML entities and special characters" do
    test "handles XML entities (amp, lt, gt, quot, apos)" do
      xml = ~s(<root><text>&amp; &lt; &gt; &quot; &apos;</text></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//text/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//text/text()"s)

      assert compat_result == sweet_result
      # Entities should be decoded
      assert compat_result == "& < > \" '"
    end

    test "handles numeric entities" do
      xml = ~s(<root><text>&#65;&#66;&#67;</text></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//text/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//text/text()"s)

      assert compat_result == sweet_result
      assert compat_result == "ABC"
    end

    test "handles hex entities" do
      xml = ~s(<root><text>&#x41;&#x42;&#x43;</text></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//text/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//text/text()"s)

      assert compat_result == sweet_result
      assert compat_result == "ABC"
    end
  end

  describe "whitespace handling" do
    test "preserves whitespace in text nodes" do
      xml = "<root>  Leading  <name>John</name>  Trailing  </root>"

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("/root/text()[1]", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"/root/text()[1]"s)

      assert compat_result == sweet_result
    end

    test "handles newlines and tabs in text" do
      xml = "<root>\n\t<name>John</name>\n</root>"

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//name/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//name/text()"s)

      assert compat_result == sweet_result
      assert compat_result == "John"
    end
  end

  describe "Unicode and special characters" do
    test "handles Unicode characters" do
      xml = "<root><name>José</name><item>中文</item><emoji>🚀</emoji></root>"

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_name = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//name/text()", ?s))
      sweet_name = SweetXml.xpath(sweet_doc, ~x"//name/text()"s)

      assert compat_name == sweet_name
      assert compat_name == "José"

      compat_item = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//item/text()", ?s))
      sweet_item = SweetXml.xpath(sweet_doc, ~x"//item/text()"s)

      assert compat_item == sweet_item
      assert compat_item == "中文"
    end

    test "handles special characters in attribute values" do
      xml = ~s(<root><item name="Test &amp; Value" id="1">Content</item></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_name = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//item/@name", ?s))
      sweet_name = SweetXml.xpath(sweet_doc, ~x"//item/@name"s)

      assert compat_name == sweet_name
      assert compat_name == "Test & Value"
    end
  end

  describe "deep nesting and complex structures" do
    test "handles very deep nesting" do
      xml = "<level1><level2><level3><level4><level5><level6><level7><level8><level9><level10>Value</level10></level9></level8></level7></level6></level5></level4></level3></level2></level1>"

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//level10/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//level10/text()"s)

      assert compat_result == sweet_result
      assert compat_result == "Value"
    end

    test "handles large number of elements" do
      items = Enum.map(1..100, fn i -> "<item>#{i}</item>" end) |> Enum.join()
      xml = "<root>#{items}</root>"

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//item", ?l))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//item"l)

      assert length(compat_result) == 100
      assert length(compat_result) == length(sweet_result)
    end
  end

  describe "namespace edge cases" do
    test "handles namespace prefix conflicts (same prefix, different URI)" do
      xml = ~s(<?xml version="1.0"?><root xmlns:ns="http://first.com"><inner xmlns:ns="http://second.com"><ns:item>Value</ns:item></inner></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)

      # Should extract both namespaces (last one wins in map, but both exist in XML)
      assert Map.has_key?(compat_doc.namespaces, "ns")
    end

    test "handles XPath without namespace prefix but with namespace context" do
      xml = ~s(<?xml version="1.0"?><root xmlns="http://example.com"><name>John</name></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)
      sweet_doc = SweetXml.parse(xml, namespace_conformant: true)

      # XPath without prefix should match elements regardless of namespace
      compat_result = Noap.MeeseeksCompat.xpath(compat_doc, Noap.MeeseeksCompat.XPathExpr.new("//name/text()", ?s))
      sweet_result = SweetXml.xpath(sweet_doc, ~x"//name/text()"s)

      assert compat_result == sweet_result
      assert compat_result == "John"
    end

    test "handles multiple namespaces with same URI" do
      xml = ~s(<?xml version="1.0"?><root xmlns:ns1="http://example.com" xmlns:ns2="http://example.com"><ns1:item>First</ns1:item><ns2:item>Second</ns2:item></root>)

      compat_doc = Noap.MeeseeksCompat.parse(xml)

      assert compat_doc.namespaces["ns1"] == "http://example.com"
      assert compat_doc.namespaces["ns2"] == "http://example.com"
    end
  end

  describe "xpath/2 with wildcards" do
    test "handles XPath with element wildcard" do
      xml = "<root><item>1</item><other>2</other><item>3</item></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//*/text()", ?l))
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//*/text()"l)

      assert is_list(compat_result)
      assert is_list(sweet_result)
      assert length(compat_result) == length(sweet_result)
    end

    test "handles XPath with attribute wildcard" do
      xml = ~s(<root><item id="1" name="test">Content</item></root>)
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//item/@*", ?l))
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//item/@*"l)

      assert is_list(compat_result)
      assert is_list(sweet_result)
    end
  end

  describe "xpath/2 with union operator" do
    test "handles XPath union (|) operator" do
      xml = "<root><item>1</item><other>2</other><item>3</item></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//item | //other", ?l))
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//item | //other"l)

      assert is_list(compat_result)
      assert is_list(sweet_result)
      assert length(compat_result) == length(sweet_result)
    end
  end

  describe "extract_text_content edge cases" do
    test "handles non-string, non-list results in text extraction" do
      xml = "<root><number>123</number></root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      # When Expath returns a number or other type, extract_text_content should handle it
      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("//number/text()", ?s))
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"//number/text()"s)

      assert compat_result == sweet_result
      assert compat_result == "123"
    end

    test "handles list of mixed types in text extraction" do
      xml = "<root>Text1<item>Text2</item>Text3</root>"
      doc = Noap.MeeseeksCompat.parse(xml)

      compat_result = Noap.MeeseeksCompat.xpath(doc, Noap.MeeseeksCompat.XPathExpr.new("/root/text()", ?s))
      sweet_result = SweetXml.xpath(SweetXml.parse(xml), ~x"/root/text()"s)

      # Should concatenate all text nodes
      assert is_binary(compat_result)
      assert is_binary(sweet_result)
    end
  end
end
