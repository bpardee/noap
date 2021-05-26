defmodule Noap.Client do
  require Logger
  import SweetXml, only: [xpath: 2, sigil_x: 2]
  import Noap.XMLUtil, only: [add_soap_namespace: 2]

  def perform_operation(operation, request_xml_schema) do
    http = http()
    endpoint = endpoint(operation)
    type_map = operation.type_map
    # TODO: Operation should hold the action
    headers = [{"SOAPAction", ""}, {"Content-Type", "text/xml;charset=utf-8"}]

    soap_request =
      Noap.XMLSchema.Request.build_request_xml(request_xml_schema, operation, [], type_map)

    http.post(endpoint, headers, soap_request, [])
    |> parse(operation, type_map)
  end

  defp parse({:ok, status_code, soap_response}, _operation, _type_map) when status_code >= 400 do
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

  defp parse({:ok, status_code, soap_response}, operation, type_map) do
    response_xml_schema =
      Noap.XMLSchema.Response.parse_soap_response(soap_response, operation, type_map)

    {:ok, status_code, response_xml_schema}
  end

  defp parse({:error, error}, _operation, _type_map) do
    {:error, 500, error}
  end

  defp http do
    Application.fetch_env!(:noap, :http)
  end

  defp endpoint(operation) do
    Application.get_env(operation.application, :endpoint, operation.endpoint)
  end
end
