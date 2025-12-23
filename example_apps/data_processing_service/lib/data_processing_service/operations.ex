defmodule DataProcessingService.Operations do
  @application Mix.Project.config()[:app]

  @wsdl %Noap.WSDL{
    endpoint: "http://example.com/dataprocessing/service"
  }

  @schema_reqns %Noap.WSDL.Schema{
    wsdl: @wsdl,
    schema_ns: "",
    target_namespace: "http://www.example.com/dataprocessing/soap/request",
    target_ns: "reqns",
    action_tag_attributes: %{xmlns: "http://www.example.com/dataprocessing/soap/request"}
  }

  @schema_resns %Noap.WSDL.Schema{
    wsdl: @wsdl,
    schema_ns: "",
    target_namespace: "http://www.example.com/dataprocessing/soap/response",
    target_ns: "resns",
    action_tag_attributes: %{xmlns: "http://www.example.com/dataprocessing/soap/response"}
  }

  @process_data %Noap.WSDL.Operation{
    name: "ProcessData",
    soap_action: "",
    input_name: "ProcessData",
    input_schema: @schema_reqns,
    input_module: DataProcessingService.Soap.Request.ProcessingRequest,
    output_name: "ProcessDataResponse",
    output_schema: @schema_resns,
    output_module: DataProcessingService.Soap.Response.ProcessingResponse,
    action_attribute: %{"xmlns:tns" => "http://www.example.com/dataprocessing"},
    action_tag: "tns:ProcessingRequest",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @spec process_data :: Noap.WSDL.Operation.t()
  @doc "Returns information on the ProcessData operation"
  def process_data do
    @process_data
  end

  @doc "Calls the ProcessData operation"
  def call_process_data(
        processing_request = %DataProcessingService.Soap.Request.ProcessingRequest{},
        options \\ []
      ) do
    Noap.call_operation(@process_data, processing_request, options)
  end
end