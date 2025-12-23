defmodule CountryInfoService.Operations do
  @application Mix.Project.config()[:app]

  @wsdl %Noap.WSDL{
    endpoint: "http://webservices.oorsprong.org/websamples.countryinfo/CountryInfoService.wso"
  }

  @schema_ %Noap.WSDL.Schema{
    wsdl: @wsdl,
    schema_ns: "",
    target_namespace: "http://www.oorsprong.org/websamples.countryinfo",
    target_ns: "",
    action_tag_attributes: %{xmlns: "http://www.oorsprong.org/websamples.countryinfo"}
  }

  @list_of_continents_by_name %Noap.WSDL.Operation{
    name: "ListOfContinentsByName",
    soap_action: "",
    input_name: "ListOfContinentsByName",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.ListOfContinentsByName,
    output_name: "ListOfContinentsByNameResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.ListOfContinentsByNameResponse,
    action_attribute: %{},
    action_tag: "ListOfContinentsByName",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @list_of_continents_by_code %Noap.WSDL.Operation{
    name: "ListOfContinentsByCode",
    soap_action: "",
    input_name: "ListOfContinentsByCode",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.ListOfContinentsByCode,
    output_name: "ListOfContinentsByCodeResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.ListOfContinentsByCodeResponse,
    action_attribute: %{},
    action_tag: "ListOfContinentsByCode",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @list_of_currencies_by_name %Noap.WSDL.Operation{
    name: "ListOfCurrenciesByName",
    soap_action: "",
    input_name: "ListOfCurrenciesByName",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.ListOfCurrenciesByName,
    output_name: "ListOfCurrenciesByNameResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.ListOfCurrenciesByNameResponse,
    action_attribute: %{},
    action_tag: "ListOfCurrenciesByName",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @list_of_currencies_by_code %Noap.WSDL.Operation{
    name: "ListOfCurrenciesByCode",
    soap_action: "",
    input_name: "ListOfCurrenciesByCode",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.ListOfCurrenciesByCode,
    output_name: "ListOfCurrenciesByCodeResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.ListOfCurrenciesByCodeResponse,
    action_attribute: %{},
    action_tag: "ListOfCurrenciesByCode",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @currency_name %Noap.WSDL.Operation{
    name: "CurrencyName",
    soap_action: "",
    input_name: "CurrencyName",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.CurrencyName,
    output_name: "CurrencyNameResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.CurrencyNameResponse,
    action_attribute: %{},
    action_tag: "CurrencyName",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @list_of_country_names_by_code %Noap.WSDL.Operation{
    name: "ListOfCountryNamesByCode",
    soap_action: "",
    input_name: "ListOfCountryNamesByCode",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.ListOfCountryNamesByCode,
    output_name: "ListOfCountryNamesByCodeResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.ListOfCountryNamesByCodeResponse,
    action_attribute: %{},
    action_tag: "ListOfCountryNamesByCode",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @list_of_country_names_by_name %Noap.WSDL.Operation{
    name: "ListOfCountryNamesByName",
    soap_action: "",
    input_name: "ListOfCountryNamesByName",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.ListOfCountryNamesByName,
    output_name: "ListOfCountryNamesByNameResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.ListOfCountryNamesByNameResponse,
    action_attribute: %{},
    action_tag: "ListOfCountryNamesByName",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @list_of_country_names_grouped_by_continent %Noap.WSDL.Operation{
    name: "ListOfCountryNamesGroupedByContinent",
    soap_action: "",
    input_name: "ListOfCountryNamesGroupedByContinent",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.ListOfCountryNamesGroupedByContinent,
    output_name: "ListOfCountryNamesGroupedByContinentResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.ListOfCountryNamesGroupedByContinentResponse,
    action_attribute: %{},
    action_tag: "ListOfCountryNamesGroupedByContinent",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @country_name %Noap.WSDL.Operation{
    name: "CountryName",
    soap_action: "",
    input_name: "CountryName",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.CountryName,
    output_name: "CountryNameResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.CountryNameResponse,
    action_attribute: %{},
    action_tag: "CountryName",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @country_iso_code %Noap.WSDL.Operation{
    name: "CountryISOCode",
    soap_action: "",
    input_name: "CountryISOCode",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.CountryISOCode,
    output_name: "CountryISOCodeResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.CountryISOCodeResponse,
    action_attribute: %{},
    action_tag: "CountryISOCode",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @capital_city %Noap.WSDL.Operation{
    name: "CapitalCity",
    soap_action: "",
    input_name: "CapitalCity",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.CapitalCity,
    output_name: "CapitalCityResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.CapitalCityResponse,
    action_attribute: %{},
    action_tag: "CapitalCity",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @country_currency %Noap.WSDL.Operation{
    name: "CountryCurrency",
    soap_action: "",
    input_name: "CountryCurrency",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.CountryCurrency,
    output_name: "CountryCurrencyResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.CountryCurrencyResponse,
    action_attribute: %{},
    action_tag: "CountryCurrency",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @country_flag %Noap.WSDL.Operation{
    name: "CountryFlag",
    soap_action: "",
    input_name: "CountryFlag",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.CountryFlag,
    output_name: "CountryFlagResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.CountryFlagResponse,
    action_attribute: %{},
    action_tag: "CountryFlag",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @country_int_phone_code %Noap.WSDL.Operation{
    name: "CountryIntPhoneCode",
    soap_action: "",
    input_name: "CountryIntPhoneCode",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.CountryIntPhoneCode,
    output_name: "CountryIntPhoneCodeResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.CountryIntPhoneCodeResponse,
    action_attribute: %{},
    action_tag: "CountryIntPhoneCode",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @full_country_info %Noap.WSDL.Operation{
    name: "FullCountryInfo",
    soap_action: "",
    input_name: "FullCountryInfo",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.FullCountryInfo,
    output_name: "FullCountryInfoResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.FullCountryInfoResponse,
    action_attribute: %{},
    action_tag: "FullCountryInfo",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @full_country_info_all_countries %Noap.WSDL.Operation{
    name: "FullCountryInfoAllCountries",
    soap_action: "",
    input_name: "FullCountryInfoAllCountries",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.FullCountryInfoAllCountries,
    output_name: "FullCountryInfoAllCountriesResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.FullCountryInfoAllCountriesResponse,
    action_attribute: %{},
    action_tag: "FullCountryInfoAllCountries",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @countries_using_currency %Noap.WSDL.Operation{
    name: "CountriesUsingCurrency",
    soap_action: "",
    input_name: "CountriesUsingCurrency",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.CountriesUsingCurrency,
    output_name: "CountriesUsingCurrencyResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.CountriesUsingCurrencyResponse,
    action_attribute: %{},
    action_tag: "CountriesUsingCurrency",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @list_of_languages_by_name %Noap.WSDL.Operation{
    name: "ListOfLanguagesByName",
    soap_action: "",
    input_name: "ListOfLanguagesByName",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.ListOfLanguagesByName,
    output_name: "ListOfLanguagesByNameResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.ListOfLanguagesByNameResponse,
    action_attribute: %{},
    action_tag: "ListOfLanguagesByName",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @list_of_languages_by_code %Noap.WSDL.Operation{
    name: "ListOfLanguagesByCode",
    soap_action: "",
    input_name: "ListOfLanguagesByCode",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.ListOfLanguagesByCode,
    output_name: "ListOfLanguagesByCodeResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.ListOfLanguagesByCodeResponse,
    action_attribute: %{},
    action_tag: "ListOfLanguagesByCode",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @language_name %Noap.WSDL.Operation{
    name: "LanguageName",
    soap_action: "",
    input_name: "LanguageName",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.LanguageName,
    output_name: "LanguageNameResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.LanguageNameResponse,
    action_attribute: %{},
    action_tag: "LanguageName",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @language_iso_code %Noap.WSDL.Operation{
    name: "LanguageISOCode",
    soap_action: "",
    input_name: "LanguageISOCode",
    input_schema: @schema_,
    input_module: CountryInfoService.Oorsprong.LanguageISOCode,
    output_name: "LanguageISOCodeResponse",
    output_schema: @schema_,
    output_module: CountryInfoService.Oorsprong.LanguageISOCodeResponse,
    action_attribute: %{},
    action_tag: "LanguageISOCode",
    application: @application,
    type_map: Noap.Type.type_map(@application),
    endpoint: @wsdl.endpoint
  }

  @spec list_of_continents_by_name :: Noap.WSDL.Operation.t()
  @doc "Returns information on the ListOfContinentsByName operation"
  def list_of_continents_by_name do
    @list_of_continents_by_name
  end

  @doc "Calls the ListOfContinentsByName operation"
  def call_list_of_continents_by_name(options \\ []) do
    Noap.call_operation(
      @list_of_continents_by_name,
      %CountryInfoService.Oorsprong.ListOfContinentsByName{},
      options
    )
  end

  @spec list_of_continents_by_code :: Noap.WSDL.Operation.t()
  @doc "Returns information on the ListOfContinentsByCode operation"
  def list_of_continents_by_code do
    @list_of_continents_by_code
  end

  @doc "Calls the ListOfContinentsByCode operation"
  def call_list_of_continents_by_code(options \\ []) do
    Noap.call_operation(
      @list_of_continents_by_code,
      %CountryInfoService.Oorsprong.ListOfContinentsByCode{},
      options
    )
  end

  @spec list_of_currencies_by_name :: Noap.WSDL.Operation.t()
  @doc "Returns information on the ListOfCurrenciesByName operation"
  def list_of_currencies_by_name do
    @list_of_currencies_by_name
  end

  @doc "Calls the ListOfCurrenciesByName operation"
  def call_list_of_currencies_by_name(options \\ []) do
    Noap.call_operation(
      @list_of_currencies_by_name,
      %CountryInfoService.Oorsprong.ListOfCurrenciesByName{},
      options
    )
  end

  @spec list_of_currencies_by_code :: Noap.WSDL.Operation.t()
  @doc "Returns information on the ListOfCurrenciesByCode operation"
  def list_of_currencies_by_code do
    @list_of_currencies_by_code
  end

  @doc "Calls the ListOfCurrenciesByCode operation"
  def call_list_of_currencies_by_code(options \\ []) do
    Noap.call_operation(
      @list_of_currencies_by_code,
      %CountryInfoService.Oorsprong.ListOfCurrenciesByCode{},
      options
    )
  end

  @spec currency_name :: Noap.WSDL.Operation.t()
  @doc "Returns information on the CurrencyName operation"
  def currency_name do
    @currency_name
  end

  @doc "Calls the CurrencyName operation"
  def call_currency_name(
        currency_name = %CountryInfoService.Oorsprong.CurrencyName{},
        options \\ []
      ) do
    Noap.call_operation(@currency_name, currency_name, options)
  end

  @spec list_of_country_names_by_code :: Noap.WSDL.Operation.t()
  @doc "Returns information on the ListOfCountryNamesByCode operation"
  def list_of_country_names_by_code do
    @list_of_country_names_by_code
  end

  @doc "Calls the ListOfCountryNamesByCode operation"
  def call_list_of_country_names_by_code(options \\ []) do
    Noap.call_operation(
      @list_of_country_names_by_code,
      %CountryInfoService.Oorsprong.ListOfCountryNamesByCode{},
      options
    )
  end

  @spec list_of_country_names_by_name :: Noap.WSDL.Operation.t()
  @doc "Returns information on the ListOfCountryNamesByName operation"
  def list_of_country_names_by_name do
    @list_of_country_names_by_name
  end

  @doc "Calls the ListOfCountryNamesByName operation"
  def call_list_of_country_names_by_name(options \\ []) do
    Noap.call_operation(
      @list_of_country_names_by_name,
      %CountryInfoService.Oorsprong.ListOfCountryNamesByName{},
      options
    )
  end

  @spec list_of_country_names_grouped_by_continent :: Noap.WSDL.Operation.t()
  @doc "Returns information on the ListOfCountryNamesGroupedByContinent operation"
  def list_of_country_names_grouped_by_continent do
    @list_of_country_names_grouped_by_continent
  end

  @doc "Calls the ListOfCountryNamesGroupedByContinent operation"
  def call_list_of_country_names_grouped_by_continent(options \\ []) do
    Noap.call_operation(
      @list_of_country_names_grouped_by_continent,
      %CountryInfoService.Oorsprong.ListOfCountryNamesGroupedByContinent{},
      options
    )
  end

  @spec country_name :: Noap.WSDL.Operation.t()
  @doc "Returns information on the CountryName operation"
  def country_name do
    @country_name
  end

  @doc "Calls the CountryName operation"
  def call_country_name(country_name = %CountryInfoService.Oorsprong.CountryName{}, options \\ []) do
    Noap.call_operation(@country_name, country_name, options)
  end

  @spec country_iso_code :: Noap.WSDL.Operation.t()
  @doc "Returns information on the CountryISOCode operation"
  def country_iso_code do
    @country_iso_code
  end

  @doc "Calls the CountryISOCode operation"
  def call_country_iso_code(
        country_iso_code = %CountryInfoService.Oorsprong.CountryISOCode{},
        options \\ []
      ) do
    Noap.call_operation(@country_iso_code, country_iso_code, options)
  end

  @spec capital_city :: Noap.WSDL.Operation.t()
  @doc "Returns information on the CapitalCity operation"
  def capital_city do
    @capital_city
  end

  @doc "Calls the CapitalCity operation"
  def call_capital_city(capital_city = %CountryInfoService.Oorsprong.CapitalCity{}, options \\ []) do
    Noap.call_operation(@capital_city, capital_city, options)
  end

  @spec country_currency :: Noap.WSDL.Operation.t()
  @doc "Returns information on the CountryCurrency operation"
  def country_currency do
    @country_currency
  end

  @doc "Calls the CountryCurrency operation"
  def call_country_currency(
        country_currency = %CountryInfoService.Oorsprong.CountryCurrency{},
        options \\ []
      ) do
    Noap.call_operation(@country_currency, country_currency, options)
  end

  @spec country_flag :: Noap.WSDL.Operation.t()
  @doc "Returns information on the CountryFlag operation"
  def country_flag do
    @country_flag
  end

  @doc "Calls the CountryFlag operation"
  def call_country_flag(country_flag = %CountryInfoService.Oorsprong.CountryFlag{}, options \\ []) do
    Noap.call_operation(@country_flag, country_flag, options)
  end

  @spec country_int_phone_code :: Noap.WSDL.Operation.t()
  @doc "Returns information on the CountryIntPhoneCode operation"
  def country_int_phone_code do
    @country_int_phone_code
  end

  @doc "Calls the CountryIntPhoneCode operation"
  def call_country_int_phone_code(
        country_int_phone_code = %CountryInfoService.Oorsprong.CountryIntPhoneCode{},
        options \\ []
      ) do
    Noap.call_operation(@country_int_phone_code, country_int_phone_code, options)
  end

  @spec full_country_info :: Noap.WSDL.Operation.t()
  @doc "Returns information on the FullCountryInfo operation"
  def full_country_info do
    @full_country_info
  end

  @doc "Calls the FullCountryInfo operation"
  def call_full_country_info(
        full_country_info = %CountryInfoService.Oorsprong.FullCountryInfo{},
        options \\ []
      ) do
    Noap.call_operation(@full_country_info, full_country_info, options)
  end

  @spec full_country_info_all_countries :: Noap.WSDL.Operation.t()
  @doc "Returns information on the FullCountryInfoAllCountries operation"
  def full_country_info_all_countries do
    @full_country_info_all_countries
  end

  @doc "Calls the FullCountryInfoAllCountries operation"
  def call_full_country_info_all_countries(options \\ []) do
    Noap.call_operation(
      @full_country_info_all_countries,
      %CountryInfoService.Oorsprong.FullCountryInfoAllCountries{},
      options
    )
  end

  @spec countries_using_currency :: Noap.WSDL.Operation.t()
  @doc "Returns information on the CountriesUsingCurrency operation"
  def countries_using_currency do
    @countries_using_currency
  end

  @doc "Calls the CountriesUsingCurrency operation"
  def call_countries_using_currency(
        countries_using_currency = %CountryInfoService.Oorsprong.CountriesUsingCurrency{},
        options \\ []
      ) do
    Noap.call_operation(@countries_using_currency, countries_using_currency, options)
  end

  @spec list_of_languages_by_name :: Noap.WSDL.Operation.t()
  @doc "Returns information on the ListOfLanguagesByName operation"
  def list_of_languages_by_name do
    @list_of_languages_by_name
  end

  @doc "Calls the ListOfLanguagesByName operation"
  def call_list_of_languages_by_name(options \\ []) do
    Noap.call_operation(
      @list_of_languages_by_name,
      %CountryInfoService.Oorsprong.ListOfLanguagesByName{},
      options
    )
  end

  @spec list_of_languages_by_code :: Noap.WSDL.Operation.t()
  @doc "Returns information on the ListOfLanguagesByCode operation"
  def list_of_languages_by_code do
    @list_of_languages_by_code
  end

  @doc "Calls the ListOfLanguagesByCode operation"
  def call_list_of_languages_by_code(options \\ []) do
    Noap.call_operation(
      @list_of_languages_by_code,
      %CountryInfoService.Oorsprong.ListOfLanguagesByCode{},
      options
    )
  end

  @spec language_name :: Noap.WSDL.Operation.t()
  @doc "Returns information on the LanguageName operation"
  def language_name do
    @language_name
  end

  @doc "Calls the LanguageName operation"
  def call_language_name(
        language_name = %CountryInfoService.Oorsprong.LanguageName{},
        options \\ []
      ) do
    Noap.call_operation(@language_name, language_name, options)
  end

  @spec language_iso_code :: Noap.WSDL.Operation.t()
  @doc "Returns information on the LanguageISOCode operation"
  def language_iso_code do
    @language_iso_code
  end

  @doc "Calls the LanguageISOCode operation"
  def call_language_iso_code(
        language_iso_code = %CountryInfoService.Oorsprong.LanguageISOCode{},
        options \\ []
      ) do
    Noap.call_operation(@language_iso_code, language_iso_code, options)
  end
end
