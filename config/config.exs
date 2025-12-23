import Config

config :noap, :http, Noap.HTTP.Finch

config :noap, :gen_code,
  noap: %{
    wsdl: "example_apps/country_info_service/config/CountryInfoService.wsdl",
    soap_module: CountryInfoService
  }
