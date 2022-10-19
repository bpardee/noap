# Noap

Soap client for Elixir

*When you're asked to do a SOAP client, just say NOAP*

## Installation



```elixir
def deps do
  [
    {:noap, "~> 0.1.0"},
    # finch is optional, otherwise create a module similar to Noap.HTTP.Finch
    {:finch, "~> 0.13"}
  ]
end
```

## Usage

See [CountryInfoService](example_apps/country_info_service) example

Add the HTTP implementation and code gen arguments to your config:
```
config :noap, :http, Noap.HTTP.Finch

config :noap, :gen_code,
  country_info_service: %{
    wsdl: "config/CountryInfoService.wsdl",
    soap_module: CountryInfoService,
    # This line doesn't actually do anything yet.  You must configure Finch using the name MyFinch
    finch_module: MyFinch
  }
```

Generate code based on the wsdl:
```
mix noap.gen.code
```

Operations are underscored and prefixed with `call_`:
```elixir
iex(1)> {:ok, status_code, list_of_countries} = CountryInfoService.call_list_of_country_names_by_name()
iex(2)> list_of_countries
%CountryInfoService.Oorsprong.ListOfCountryNamesByNameResponse{
  list_of_country_names_by_name_result: %CountryInfoService.Oorsprong.ArrayOftCountryCodeAndName{
    t_country_code_and_name: [
      %CountryInfoService.Oorsprong.TCountryCodeAndName{
        s_iso_code: "AX",
        s_name: "Åland Islands"
      },
      %CountryInfoService.Oorsprong.TCountryCodeAndName{
        s_iso_code: "AF",
        s_name: "Afghanistan"
      },
...
```

## License

Noap is released under the MIT license.
