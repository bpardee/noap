defmodule CountryInfoService.OperationsTest do
  use ExUnit.Case
  doctest CountryInfoService.Operations

  describe "operations module" do
    test "exports all operation info functions" do
      info_functions = [
        :capital_city,
        :country_name,
        :country_flag,
        :country_currency,
        :country_iso_code,
        :full_country_info,
        :list_of_continents_by_name,
        :list_of_country_names_by_code
      ]

      Enum.each(info_functions, fn fun ->
        assert function_exported?(CountryInfoService.Operations, fun, 0)
      end)
    end

    test "exports all call functions" do
      call_with_params = [
        :call_country_flag,
        :call_capital_city,
        :call_country_name,
        :call_country_currency,
        :call_country_iso_code,
        :call_full_country_info,
        :call_currency_name,
        :call_language_name
      ]

      call_without_params = [
        :call_list_of_continents_by_name,
        :call_list_of_continents_by_code,
        :call_list_of_country_names_by_code,
        :call_list_of_currencies_by_name,
        :call_list_of_languages_by_code,
        :call_full_country_info_all_countries
      ]

      Enum.each(call_with_params, fn fun ->
        assert function_exported?(CountryInfoService.Operations, fun, 2)
      end)

      Enum.each(call_without_params, fn fun ->
        assert function_exported?(CountryInfoService.Operations, fun, 1)
      end)
    end
  end

  describe "all files and directories validation" do
    @modules_path "lib/country_info_service/oorsprong"
    @all_files [
      "array_oft_continent.ex",
      "array_oft_country_code_and_name.ex",
      "array_oft_country_code_and_name_grouped_by_continent.ex",
      "array_oft_country_info.ex",
      "array_oft_currency.ex",
      "array_oft_language.ex",
      "capital_city.ex",
      "capital_city_response.ex",
      "countries_using_currency.ex",
      "countries_using_currency_response.ex",
      "country_currency.ex",
      "country_currency_response.ex",
      "country_flag.ex",
      "country_flag_response.ex",
      "country_int_phone_code.ex",
      "country_int_phone_code_response.ex",
      "country_iso_code.ex",
      "country_iso_code_response.ex",
      "country_name.ex",
      "country_name_response.ex",
      "currency_name.ex",
      "currency_name_response.ex",
      "full_country_info.ex",
      "full_country_info_all_countries.ex",
      "full_country_info_all_countries_response.ex",
      "full_country_info_response.ex",
      "language_iso_code.ex",
      "language_iso_code_response.ex",
      "language_name.ex",
      "language_name_response.ex",
      "list_of_continents_by_code.ex",
      "list_of_continents_by_code_response.ex",
      "list_of_continents_by_name.ex",
      "list_of_continents_by_name_response.ex",
      "list_of_country_names_by_code.ex",
      "list_of_country_names_by_code_response.ex",
      "list_of_country_names_by_name.ex",
      "list_of_country_names_by_name_response.ex",
      "list_of_country_names_grouped_by_continent.ex",
      "list_of_country_names_grouped_by_continent_response.ex",
      "list_of_currencies_by_code.ex",
      "list_of_currencies_by_code_response.ex",
      "list_of_currencies_by_name.ex",
      "list_of_currencies_by_name_response.ex",
      "list_of_languages_by_code.ex",
      "list_of_languages_by_code_response.ex",
      "list_of_languages_by_name.ex",
      "list_of_languages_by_name_response.ex",
      "t_continent.ex",
      "t_country_code_and_name.ex",
      "t_country_code_and_name_grouped_by_continent.ex",
      "t_country_info.ex",
      "t_currency.ex",
      "t_language.ex"
    ]

    test "all files exist exactly once" do
      Enum.each(@all_files, fn file ->
        path = Path.join([@modules_path, file])
        assert File.exists?(path), "Missing file: #{path}"
      end)

      # Check file count in oorsprong directory
      oorsprong_files = @modules_path |> Path.expand() |> File.ls!() |> Enum.filter(&String.ends_with?(&1, ".ex"))
      assert length(oorsprong_files) == 54, "Expected 54 files in oorsprong directory, found #{length(oorsprong_files)}"
    end
  end
end
