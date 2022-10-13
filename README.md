# Noap

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `noap` to your list of dependencies in `mix.exs`:

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

Add the HTTP implementation to your config:
```
config :noap, :http, Noap.HTTP.Finch
```

Generate code based on the wsdl:
```
mix noap.gen.code config/CountryInfoService.wsdl CountryInfoService
```

Or optionally you can add the arguments to your config:
```
config :noap, :gen_code,
  country_info_service: ~w[config/CountryInfoService.wsdl CountryInfoService]
```

And then generate the code without the arguments:
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
