defmodule Noap.XMLUtil do
  import Meeseeks.XPath

  @soap_namespace "http://schemas.xmlsoap.org/soap/envelope/"

  @spec find_namespace(Meeseeks.Document.t(), String.t()) :: String.t()
  def find_namespace(doc, url) do
    # Meeseeks doesn't support namespace axis directly
    # We'll search for elements with the target namespace and extract prefix
    # Try common prefixes first
    common_prefixes = ["soap", "wsdl", "xsd", "xs", "tns", "s", "body"]

    found =
      Enum.find_value(common_prefixes, fn prefix ->
        xpath_expr = "//*[namespace-uri()='#{url}' and starts-with(name(), '#{prefix}:')]"
        case Meeseeks.one(doc, xpath(xpath_expr)) do
          nil -> nil
          _ -> prefix
        end
      end)

    found || ""
  end

  def add_soap_namespace(xpath_expr, _prefix) do
    # Convert prefix-based XPath to namespace-uri() based XPath
    String.replace(xpath_expr, "soap:", "//*[namespace-uri()='#{@soap_namespace}']/")
    |> String.replace("/", "//")
    |> String.replace("//", "/", parts: 1)
  end
end
