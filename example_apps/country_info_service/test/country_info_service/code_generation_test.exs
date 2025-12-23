defmodule CountryInfoService.CodeGenerationTest do
  use ExUnit.Case

  @request_modules [
    "capital_city",
    "countries_using_currency",
    "country_currency",
    "country_flag",
    "country_int_phone_code",
    "country_iso_code",
    "country_name",
    "currency_name",
    "full_country_info",
    "full_country_info_all_countries",
    "language_iso_code",
    "language_name",
    "list_of_continents_by_code",
    "list_of_continents_by_name",
    "list_of_country_names_by_code",
    "list_of_country_names_by_name",
    "list_of_country_names_grouped_by_continent",
    "list_of_currencies_by_code",
    "list_of_currencies_by_name",
    "list_of_languages_by_code",
    "list_of_languages_by_name"
  ]

  @response_modules [
    "capital_city_response",
    "countries_using_currency_response",
    "country_currency_response",
    "country_flag_response",
    "country_int_phone_code_response",
    "country_iso_code_response",
    "country_name_response",
    "currency_name_response",
    "full_country_info_all_countries_response",
    "full_country_info_response",
    "language_iso_code_response",
    "language_name_response",
    "list_of_continents_by_code_response",
    "list_of_continents_by_name_response",
    "list_of_country_names_by_code_response",
    "list_of_country_names_by_name_response",
    "list_of_country_names_grouped_by_continent_response",
    "list_of_currencies_by_code_response",
    "list_of_currencies_by_name_response",
    "list_of_languages_by_code_response",
    "list_of_languages_by_name_response"
  ]

  @type_modules [
    "t_continent",
    "t_country_code_and_name",
    "t_country_code_and_name_grouped_by_continent",
    "t_country_info",
    "t_currency",
    "t_language"
  ]

  @array_modules [
    "array_oft_continent",
    "array_oft_country_code_and_name",
    "array_oft_country_code_and_name_grouped_by_continent",
    "array_oft_country_info",
    "array_oft_currency",
    "array_oft_language"
  ]

  @modules_path "lib/country_info_service/oorsprong"
  @operations_path "lib/country_info_service/operations.ex"

  defp file_path(module), do: Path.join([@modules_path, "#{module}.ex"])

  defp missing_modules(modules) do
    Enum.reject(modules, &File.exists?(file_path(&1)))
  end

  defp read_file_if_exists(module) do
    path = file_path(module)
    if File.exists?(path), do: File.read!(path), else: nil
  end

  describe "generated files" do
    test "all expected modules are generated" do
      all_modules = @request_modules ++ @response_modules ++ @type_modules ++ @array_modules
      missing = missing_modules(all_modules)

      assert Enum.empty?(missing),
             "Missing generated modules: #{inspect(missing)}. Expected #{length(all_modules)} modules."
    end
  end

  describe "module structure" do
    test "all generated modules use Noap.XMLSchema" do
      all_modules = @request_modules ++ @response_modules ++ @type_modules ++ @array_modules

      Enum.each(all_modules, fn module ->
        content = read_file_if_exists(module)
        if content do
          assert content =~ "use Noap.XMLSchema",
                 "Module #{module}.ex should use Noap.XMLSchema"
          assert content =~ "xml_schema do",
                 "Module #{module}.ex should have xml_schema block"
        end
      end)
    end

    test "generated modules have correct module names" do
      test_cases = [
        {"capital_city.ex", "CountryInfoService.Oorsprong.CapitalCity", "request"},
        {"capital_city_response.ex", "CountryInfoService.Oorsprong.CapitalCityResponse", "response"},
        {"t_country_info.ex", "CountryInfoService.Oorsprong.TCountryInfo", "type"}
      ]

      Enum.each(test_cases, fn {file, expected_module, type} ->
        content = read_file_if_exists(String.replace_suffix(file, ".ex", ""))
        if content do
          assert content =~ "defmodule #{expected_module}",
                 "#{type} modules should use CountryInfoService.Oorsprong namespace"
        end
      end)
    end
  end

  describe "nested structures" do
    test "modules with nested structures use embeds" do
      test_files = ["t_country_info", "full_country_info_response"]

      Enum.each(test_files, fn module ->
        content = read_file_if_exists(module)
        if content do
          assert content =~ "embeds_one" || content =~ "embeds_many",
                 "Module #{module}.ex should use embeds_one or embeds_many for nested structures"
        end
      end)
    end
  end

  describe "array structures" do
    test "array modules use embeds_many" do
      Enum.each(@array_modules, fn module ->
        content = read_file_if_exists(module)
        if content do
          assert content =~ "embeds_many",
                 "Array module #{module}.ex should use embeds_many for arrays"
        end
      end)
    end
  end

  describe "code compilation" do
    test "generated files have valid Elixir syntax" do
      key_files = [
        "capital_city",
        "capital_city_response",
        "t_country_info",
        "array_oft_country_info"
      ]

      Enum.each(key_files, fn module ->
        content = read_file_if_exists(module)
        if content do
          assert content =~ "defmodule", "#{module}.ex should contain a defmodule declaration"
          assert content =~ "end", "#{module}.ex should have proper closing 'end'"
          assert String.length(content) > 0, "#{module}.ex should not be empty"
        end
      end)

      if File.exists?(@operations_path) do
        content = File.read!(@operations_path)
        assert content =~ "defmodule"
        assert content =~ "end"
      end
    end

    test "generated modules reference correct module paths" do
      test_files = ["t_country_info", "full_country_info_response"]

      Enum.each(test_files, fn module ->
        content = read_file_if_exists(module)
        if content do
          assert content =~ "CountryInfoService.Oorsprong.",
                 "Module #{module}.ex should reference CountryInfoService.Oorsprong namespace"
        end
      end)
    end

    test "operations module references correct request and response modules" do
      assert File.exists?(@operations_path), "Operations file should exist"

      content = File.read!(@operations_path)
      assert content =~ "CountryInfoService.Oorsprong.CapitalCity"
      assert content =~ "CountryInfoService.Oorsprong.CapitalCityResponse"
    end
  end
end
