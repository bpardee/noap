import Config

config :noap, :http, Noap.HTTP.Finch

config :noap, :gen_code,
  country_info_service: %{
    wsdl: "config/CountryInfoService.wsdl",
    soap_module: CountryInfoService,
    finch_module: MyFinch
  }
