defmodule Mix.Noap.GenCode.CreateCodeTest do
  use ExUnit.Case

  alias Mix.Noap.GenCode.WSDLWrap
  alias Mix.Noap.GenCode.WSDLWrap.CreateCode

  @wsdl_path "example_apps/country_info_service/config/CountryInfoService.wsdl"

  describe "code generation" do
    test "generates all required files" do
      wsdl_wrap = WSDLWrap.new(@wsdl_path, CountryInfoService.Oorsprong, %{})
      type_map = Noap.Type.type_map(:country_info_service)

      CreateCode.create_code(wsdl_wrap, type_map, [])

      # Verify operations file
      operations_path = Path.join(["lib", "country_info_service", "oorsprong", "operations.ex"])
      assert File.exists?(operations_path)

      content = File.read!(operations_path)
      assert content =~ "defmodule CountryInfoService.Oorsprong.Operations"

      # Verify main module file
      main_path = Path.join(["lib", "country_info_service", "oorsprong.ex"])
      assert File.exists?(main_path)

      # Verify complex type file
      schema = wsdl_wrap.schema_map |> Map.values() |> List.first()
      complex_type = schema.complex_type_map |> Map.values() |> List.first()

      module_path = complex_type.parent_module |> String.split(".") |> Enum.map(&Macro.underscore/1)
      type_path = Path.join(["lib" | module_path] ++ ["#{Macro.underscore(complex_type.name)}.ex"])

      assert File.exists?(type_path)

      type_content = File.read!(type_path)
      assert type_content =~ "use Noap.XMLSchema"
      assert type_content =~ "xml_schema"
    end
  end
end
