defmodule Mix.Noap.GenCode.OverridesTest do
  use ExUnit.Case

  alias Mix.Noap.GenCode.WSDLWrap
  alias Mix.Noap.GenCode.WSDLWrap.CreateCode

  @wsdl_path "example_apps/country_info_service/config/CountryInfoService.wsdl"

  describe "overrides functionality" do
    test "handles overrides from YAML file" do
      yaml_content = """
      tns:
        FullCountryInfoResponse:
          FullCountryInfoResult:
            :type: :integer
      """

      tmp_dir = "test/tmp/generated"
      yaml_path = Path.join(tmp_dir, "test_overrides.yml")
      File.mkdir_p!(Path.dirname(yaml_path))
      File.write!(yaml_path, yaml_content)

      try do
        wsdl_wrap = WSDLWrap.new(@wsdl_path, CountryInfoService.Oorsprong, %{})
        type_map = Noap.Type.type_map(:country_info_service)

        CreateCode.create_code(wsdl_wrap, type_map, [overrides: yaml_path])
        assert wsdl_wrap.schema_map != %{}
      after
        File.rm_rf!(tmp_dir)
      end
    end

    test "handles overrides from map" do
      overrides_map = %{
        "tns" => %{
          "FullCountryInfoResponse" => %{
            "FullCountryInfoResult" => %{type: :integer}
          }
        }
      }

      wsdl_wrap = WSDLWrap.new(@wsdl_path, CountryInfoService.Oorsprong, %{})
      type_map = Noap.Type.type_map(:country_info_service)

      CreateCode.create_code(wsdl_wrap, type_map, [overrides: overrides_map])
      assert wsdl_wrap.schema_map != %{}
    end
  end

  describe "error handling" do
    test "raises error when override type is missing" do
      overrides_map = %{
        "tns" => %{
          "FullCountryInfoResponse" => %{
            embeds_one: %{"CustomField" => %{}}
          }
        }
      }

      wsdl_wrap = WSDLWrap.new(@wsdl_path, CountryInfoService.Oorsprong, %{})
      type_map = Noap.Type.type_map(:country_info_service)

      assert_raise RuntimeError, ~r/Must specify type for overfide/, fn ->
        CreateCode.create_code(wsdl_wrap, type_map, [overrides: overrides_map])
      end
    end

    test "raises error when override type is not an atom" do
      overrides_map = %{
        "tns" => %{
          "FullCountryInfoResponse" => %{
            embeds_one: %{"CustomField" => %{type: "string"}}
          }
        }
      }

      wsdl_wrap = WSDLWrap.new(@wsdl_path, CountryInfoService.Oorsprong, %{})
      type_map = Noap.Type.type_map(:country_info_service)

      assert_raise RuntimeError, ~r/Must specify an atom for type/, fn ->
        CreateCode.create_code(wsdl_wrap, type_map, [overrides: overrides_map])
      end
    end
  end
end
