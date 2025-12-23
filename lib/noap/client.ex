defmodule Noap.Client do
  require Logger
  import Meeseeks.XPath

  @spec call_operation(Noap.WSDL.Operation.t(), Noap.XMLSchema.t(), Keyword.t()) ::
          Noap.call_operation_t()
  def call_operation(operation = %Noap.WSDL.Operation{}, request_xml_schema, options \\ []) do
    http = http()
    endpoint = endpoint(operation, options[:endpoint])
    headers = [{"SOAPAction", operation.soap_action}, {"Content-Type", "text/xml;charset=utf-8"}]

    soap_request = Noap.XMLSchema.Request.build_soap_request(operation, request_xml_schema, [])
    Logger.debug("SOAP request = #{soap_request}")

    http.post(endpoint, headers, soap_request, options)
    |> parse(operation)
  end

  defp parse({:ok, status_code, soap_response}, _operation) when status_code >= 400 do
    Logger.error("Error processing SOAP call status_code: #{status_code}, response: #{inspect(soap_response)}")

    error =
      Meeseeks.parse(soap_response, :xml)
      |> Meeseeks.one(xpath("//*[namespace-uri()='http://schemas.xmlsoap.org/soap/envelope/']/*[local-name()='Body']/*[local-name()='Fault']/*[local-name()='faultstring']"))
      |> case do
        nil -> nil
        element -> Meeseeks.text(element)
      end

    error =
      if is_nil(error) || error == "" do
        "System error"
      else
        error
      end

    {:error, status_code, error}
  end

  defp parse({:ok, status_code, soap_response}, operation) do
    Logger.debug("SOAP respone = #{soap_response}")
    response_xml_schema = Noap.XMLSchema.Response.parse_soap_response(soap_response, operation)

    {:ok, status_code, response_xml_schema}
  end

  defp parse({:error, error}, _operation) do
    Logger.error("SOAP call error: #{inspect(error)}")
    {:error, 500, error}
  end

  defp http do
    Application.fetch_env!(:noap, :http)
  end

  defp endpoint(operation, nil) do
    Application.get_env(operation.application, :endpoint, operation.endpoint)
  end

  defp endpoint(_operation, options_endpoint) do
    options_endpoint
  end
end
