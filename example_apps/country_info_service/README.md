# CountryInfoService

Example Noap client for CountryInfoService

## Usage

Get dependencies and generate parsing code:
```
mix deps.get
mix noap.gen.code
```

Make calls:
```elixir
iex(1)> {:ok, 200, list_of_countries} = CountryInfoService.call_list_of_country_names_by_name()
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
