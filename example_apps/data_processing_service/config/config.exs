import Config

config :noap, :http, Noap.HTTP.Finch

config :noap, :gen_code,
  data_processing_service: %{
    wsdl: "config/DataProcessingService.wsdl",
    soap_module: DataProcessingService,
    finch_module: MyFinch,
    overrides: "config/overrides.yml",
    schema_module: [
      {:reqns, DataProcessingService.Soap.Request},
      {:resns, DataProcessingService.Soap.Response}
    ]
  }
