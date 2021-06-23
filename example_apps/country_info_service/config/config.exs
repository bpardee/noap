import Config

config :noap, :http, Noap.HTTP.Mojito

config :noap, :gen_code,
  country_info_service: ~w[../wsdls/CountryInfoService.wsdl CountryInfoService]

# import_config "#{Mix.env()}.exs"
