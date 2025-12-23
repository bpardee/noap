defmodule CountryInfoService.Oorsprong do
  alias __MODULE__.Operations

  @doc "Calls the ListOfContinentsByName operation"
  defdelegate call_list_of_continents_by_name(options \\ []), to: Operations

  @doc "Calls the ListOfContinentsByCode operation"
  defdelegate call_list_of_continents_by_code(options \\ []), to: Operations

  @doc "Calls the ListOfCurrenciesByName operation"
  defdelegate call_list_of_currencies_by_name(options \\ []), to: Operations

  @doc "Calls the ListOfCurrenciesByCode operation"
  defdelegate call_list_of_currencies_by_code(options \\ []), to: Operations

  @doc "Calls the CurrencyName operation"
  defdelegate call_currency_name(currency_name, options \\ []), to: Operations

  @doc "Calls the ListOfCountryNamesByCode operation"
  defdelegate call_list_of_country_names_by_code(options \\ []), to: Operations

  @doc "Calls the ListOfCountryNamesByName operation"
  defdelegate call_list_of_country_names_by_name(options \\ []), to: Operations

  @doc "Calls the ListOfCountryNamesGroupedByContinent operation"
  defdelegate call_list_of_country_names_grouped_by_continent(options \\ []), to: Operations

  @doc "Calls the CountryName operation"
  defdelegate call_country_name(country_name, options \\ []), to: Operations

  @doc "Calls the CountryISOCode operation"
  defdelegate call_country_iso_code(country_iso_code, options \\ []), to: Operations

  @doc "Calls the CapitalCity operation"
  defdelegate call_capital_city(capital_city, options \\ []), to: Operations

  @doc "Calls the CountryCurrency operation"
  defdelegate call_country_currency(country_currency, options \\ []), to: Operations

  @doc "Calls the CountryFlag operation"
  defdelegate call_country_flag(country_flag, options \\ []), to: Operations

  @doc "Calls the CountryIntPhoneCode operation"
  defdelegate call_country_int_phone_code(country_int_phone_code, options \\ []), to: Operations

  @doc "Calls the FullCountryInfo operation"
  defdelegate call_full_country_info(full_country_info, options \\ []), to: Operations

  @doc "Calls the FullCountryInfoAllCountries operation"
  defdelegate call_full_country_info_all_countries(options \\ []), to: Operations

  @doc "Calls the CountriesUsingCurrency operation"
  defdelegate call_countries_using_currency(countries_using_currency, options \\ []),
    to: Operations

  @doc "Calls the ListOfLanguagesByName operation"
  defdelegate call_list_of_languages_by_name(options \\ []), to: Operations

  @doc "Calls the ListOfLanguagesByCode operation"
  defdelegate call_list_of_languages_by_code(options \\ []), to: Operations

  @doc "Calls the LanguageName operation"
  defdelegate call_language_name(language_name, options \\ []), to: Operations

  @doc "Calls the LanguageISOCode operation"
  defdelegate call_language_iso_code(language_iso_code, options \\ []), to: Operations
end