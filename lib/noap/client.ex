defmodule Noap.Client do
  require Logger
  import SweetXml, only: [xpath: 2, sigil_x: 2]
  import Noap.XMLUtil, only: [add_soap_namespace: 2]

  @spec call_operation(Noap.WSDL.Operation.t(), Noap.XMLSchema.t(), Keyword.t()) ::
          Noap.call_operation_t()
  def call_operation(operation = %Noap.WSDL.Operation{}, request_xml_schema, options \\ []) do
    http = http()
    endpoint = endpoint(operation, options[:endpoint])
    # TODO: Operation should hold the action
    headers = [{"SOAPAction", ""}, {"Content-Type", "text/xml;charset=utf-8"}]

    soap_request = Noap.XMLSchema.Request.build_soap_request(operation, request_xml_schema, [])
    Logger.debug("SOAP request = #{soap_request}")

    http.post(endpoint, headers, soap_request, options)
    |> parse(operation)
  end

  defp parse({:ok, status_code, soap_response}, _operation) when status_code >= 400 do
    Logger.error("SOAP call failed status_code=#{status_code}: #{soap_response}")

    error =
      SweetXml.parse(soap_response, namespace_conformant: true)
      |> xpath(
        ~x"soap:Body/soap:Fault/faultstring/text()"s
        |> add_soap_namespace("soap")
      )

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
    Logger.error("SOAP call error: #{error}")
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
