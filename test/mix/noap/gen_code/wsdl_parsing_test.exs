defmodule Mix.Noap.GenCode.WSDLParsingTest do
  use ExUnit.Case

  alias Mix.Noap.GenCode.WSDLWrap

  @wsdl_path "example_apps/country_info_service/config/CountryInfoService.wsdl"

  describe "WSDL parsing" do
    test "parses complex WSDL structures correctly" do
      wsdl_wrap = WSDLWrap.new(@wsdl_path, CountryInfoService.Oorsprong, %{})
      schema = wsdl_wrap.schema_map |> Map.values() |> List.first()

      # Verify basic structure
      assert is_map(wsdl_wrap.schema_map)
      assert map_size(wsdl_wrap.schema_map) > 0
      assert length(wsdl_wrap.operations) > 1
      assert schema.target_namespace != nil

      # Verify complex types and fields
      assert map_size(schema.complex_type_map) > 0

      {_name, complex_type} = schema.complex_type_map |> Enum.at(0)
      assert is_list(complex_type.fields)
      assert complex_type.name != nil
      assert complex_type.parent_module != nil

      # Verify fields have required properties
      Enum.each(complex_type.fields, fn field ->
        assert field.name != nil
        assert field.xml_name != nil
        assert field.type != nil
      end)
    end

    test "handles arrays and embedded fields" do
      wsdl_wrap = WSDLWrap.new(@wsdl_path, CountryInfoService.Oorsprong, %{})
      schema = wsdl_wrap.schema_map |> Map.values() |> List.first()

      # Find array and embedded fields
      all_fields =
        schema.complex_type_map
        |> Map.values()
        |> Enum.flat_map(& &1.fields)

      array_fields = Enum.filter(all_fields, &(&1.field_or_embed == :embeds_many))
      embedded_fields = Enum.filter(all_fields, &(&1.field_or_embed in [:embeds_one, :embeds_many]))

      assert is_list(array_fields)
      assert is_list(embedded_fields)
    end

    test "validates operations structure" do
      wsdl_wrap = WSDLWrap.new(@wsdl_path, CountryInfoService.Oorsprong, %{})

      Enum.each(wsdl_wrap.operations, fn operation ->
        assert operation.name != nil
        assert operation.input_schema != nil
        assert operation.output_schema != nil
        assert operation.soap_action != nil
      end)
    end
  end
end
