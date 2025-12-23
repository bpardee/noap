defmodule Mix.Noap.GenCode.WSDLWrapTest do
  use ExUnit.Case

  alias Mix.Noap.GenCode.WSDLWrap

  describe "WSDL parsing" do
    test "parses WSDL file and extracts endpoint" do
      wsdl_path = "example_apps/country_info_service/config/CountryInfoService.wsdl"
      wsdl_wrap = WSDLWrap.new(wsdl_path, CountryInfoService.Oorsprong, %{})

      assert wsdl_wrap.endpoint ==
               "http://webservices.oorsprong.org/websamples.countryinfo/CountryInfoService.wso"
    end

    test "parses WSDL and extracts schema map" do
      wsdl_path = "example_apps/country_info_service/config/CountryInfoService.wsdl"
      wsdl_wrap = WSDLWrap.new(wsdl_path, CountryInfoService.Oorsprong, %{})

      assert is_map(wsdl_wrap.schema_map)
      assert map_size(wsdl_wrap.schema_map) > 0
    end

    test "parses WSDL and extracts operations" do
      wsdl_path = "example_apps/country_info_service/config/CountryInfoService.wsdl"
      wsdl_wrap = WSDLWrap.new(wsdl_path, CountryInfoService.Oorsprong, %{})

      assert is_list(wsdl_wrap.operations)
      assert length(wsdl_wrap.operations) > 0

      # Verify operation structure
      first_op = List.first(wsdl_wrap.operations)
      assert first_op.name != nil
      assert first_op.input_schema != nil
      assert first_op.output_schema != nil
    end

    test "parses WSDL and extracts namespace map" do
      wsdl_path = "example_apps/country_info_service/config/CountryInfoService.wsdl"
      wsdl_wrap = WSDLWrap.new(wsdl_path, CountryInfoService.Oorsprong, %{})

      assert is_map(wsdl_wrap.namespace_map)
    end

    test "parses WSDL and extracts message map" do
      wsdl_path = "example_apps/country_info_service/config/CountryInfoService.wsdl"
      wsdl_wrap = WSDLWrap.new(wsdl_path, CountryInfoService.Oorsprong, %{})

      assert is_map(wsdl_wrap.message_map)
    end
  end

  describe "complex type extraction" do
    test "extracts complex types from WSDL" do
      wsdl_path = "example_apps/country_info_service/config/CountryInfoService.wsdl"
      wsdl_wrap = WSDLWrap.new(wsdl_path, CountryInfoService.Oorsprong, %{})

      # Verify complex types are extracted
      schema = wsdl_wrap.schema_map |> Map.values() |> List.first()
      assert is_map(schema.complex_type_map)
      assert map_size(schema.complex_type_map) > 0
    end

    test "extracts fields from complex types" do
      wsdl_path = "example_apps/country_info_service/config/CountryInfoService.wsdl"
      wsdl_wrap = WSDLWrap.new(wsdl_path, CountryInfoService.Oorsprong, %{})

      schema = wsdl_wrap.schema_map |> Map.values() |> List.first()
      complex_type = schema.complex_type_map |> Map.values() |> List.first()

      assert is_list(complex_type.fields)
    end
  end

  describe "operation extraction" do
    test "extracts operation input and output schemas" do
      wsdl_path = "example_apps/country_info_service/config/CountryInfoService.wsdl"
      wsdl_wrap = WSDLWrap.new(wsdl_path, CountryInfoService.Oorsprong, %{})

      operation = Enum.find(wsdl_wrap.operations, &(&1.name == "ListOfContinentsByName"))

      assert operation != nil
      assert operation.input_schema != nil
      assert operation.output_schema != nil
    end

    test "extracts SOAP action for operations" do
      wsdl_path = "example_apps/country_info_service/config/CountryInfoService.wsdl"
      wsdl_wrap = WSDLWrap.new(wsdl_path, CountryInfoService.Oorsprong, %{})

      operation = Enum.find(wsdl_wrap.operations, &(&1.name == "ListOfContinentsByName"))

      assert operation.soap_action != nil
    end
  end

  describe "error handling" do
    test "raises error for non-existent WSDL file" do
      assert_raise File.Error, fn ->
        WSDLWrap.new("non_existent.wsdl", CountryInfoService.Oorsprong, %{})
      end
    end
  end
end
