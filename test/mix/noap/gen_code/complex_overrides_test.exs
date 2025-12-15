defmodule Mix.Noap.GenCode.ComplexOverridesTest do
  use ExUnit.Case

  alias Mix.Noap.GenCode.WSDLWrap
  alias Mix.Noap.GenCode.WSDLWrap.CreateCode

  @wsdl_path "example_apps/country_info_service/config/CountryInfoService.wsdl"
  @tmp_dir "test/tmp/complex_overrides_generated"

  setup do
    if File.exists?(@tmp_dir) do
      File.rm_rf!(@tmp_dir)
    end

    File.mkdir_p!(@tmp_dir)

    on_exit(fn ->
      if File.exists?(@tmp_dir) do
        File.rm_rf!(@tmp_dir)
      end
    end)

    :ok
  end

  describe "overrides with different types" do
    test "handles type overrides from YAML file" do
      yaml_content = """
      tns:
        FullCountryInfoResponse:
          FullCountryInfoResult:
            PhoneCode:
              :type: :integer
            CapitalCity:
              :type: :custom_date
      """

      yaml_path = Path.join(@tmp_dir, "test_overrides.yml")
      File.write!(yaml_path, yaml_content)

      overrides = Mix.Noap.GenCode.WSDLWrap.Options.overrides([overrides: yaml_path])

      assert get_in(overrides, ["tns", "FullCountryInfoResponse", "FullCountryInfoResult", "PhoneCode"])[:type] == :integer
      assert get_in(overrides, ["tns", "FullCountryInfoResponse", "FullCountryInfoResult", "CapitalCity"])[:type] == :custom_date
    end

    test "handles deeply nested overrides" do
      yaml_content = """
      tns:
        FullCountryInfoResponse:
          FullCountryInfoResult:
            Languages:
              ArrayOftLanguage:
                tLanguage:
                  sISOCode:
                    :type: :integer
                  sName:
                    :type: :custom_string
      """

      yaml_path = Path.join(@tmp_dir, "test_nested_overrides.yml")
      File.write!(yaml_path, yaml_content)

      overrides = Mix.Noap.GenCode.WSDLWrap.Options.overrides([overrides: yaml_path])

      assert get_in(overrides, ["tns", "FullCountryInfoResponse", "FullCountryInfoResult", "Languages", "ArrayOftLanguage", "tLanguage", "sISOCode"])[:type] == :integer
      assert get_in(overrides, ["tns", "FullCountryInfoResponse", "FullCountryInfoResult", "Languages", "ArrayOftLanguage", "tLanguage", "sName"])[:type] == :custom_string
    end

    test "handles multiple field overrides at same level" do
      yaml_content = """
      tns:
        FullCountryInfoResponse:
          FullCountryInfoResult:
            sISOCode:
              :type: :integer
            sName:
              :type: :custom_string
            sCapitalCity:
              :type: :custom_date
      """

      yaml_path = Path.join(@tmp_dir, "test_multiple_overrides.yml")
      File.write!(yaml_path, yaml_content)

      overrides = Mix.Noap.GenCode.WSDLWrap.Options.overrides([overrides: yaml_path])
      result_overrides = get_in(overrides, ["tns", "FullCountryInfoResponse", "FullCountryInfoResult"])

      assert result_overrides["sISOCode"][:type] == :integer
      assert result_overrides["sName"][:type] == :custom_string
      assert result_overrides["sCapitalCity"][:type] == :custom_date
    end
  end

  describe "code generation with overrides" do
    test "generates code with type overrides applied" do
      yaml_content = """
      tns:
        FullCountryInfoResponse:
          FullCountryInfoResult:
            PhoneCode:
              :type: :integer
      """

      yaml_path = Path.expand(Path.join(@tmp_dir, "test_overrides.yml"))
      File.write!(yaml_path, yaml_content)

      wsdl_wrap = WSDLWrap.new(@wsdl_path, CountryInfoService.Oorsprong, %{})
      type_map = Noap.Type.type_map(:country_info_service) |> Map.put(:integer, Noap.Type.Integer)

      original_cwd = File.cwd!()
      File.cd!(@tmp_dir)

      try do
        CreateCode.create_code(wsdl_wrap, type_map, [overrides: yaml_path])
        operations_path = Path.join(["lib", "country_info_service", "oorsprong", "operations.ex"])
        assert File.exists?(operations_path)
      after
        File.cd!(original_cwd)
      end
    end
  end

  describe "error handling" do
    test "raises error when override type is not in type_map" do
      overrides_map = %{
        "tns" => %{
          "FullCountryInfoResponse" => %{
            embeds_one: %{
              "CustomField" => %{type: :nonexistent_type}
            }
          }
        }
      }

      wsdl_wrap = WSDLWrap.new(@wsdl_path, CountryInfoService.Oorsprong, %{})
      type_map = Noap.Type.type_map(:country_info_service)

      assert_raise RuntimeError, ~r/No mapping for type/, fn ->
        CreateCode.create_code(wsdl_wrap, type_map, [overrides: overrides_map])
      end
    end
  end
end
