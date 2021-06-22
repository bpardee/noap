defmodule Mix.Noap.GenCode.WSDLWrap.YAML do
  alias Mix.Noap.GenCode.WSDLWrap.{ComplexType, Field, SchemaWrap, Util}

  def yamlize(wsdl_wrap = %Mix.Noap.GenCode.WSDLWrap{}, yaml_file) do
    yaml =
      wsdl_wrap.schema_map
      |> Enum.map(fn {name, schema_wrap} ->
        {name, build_map(schema_wrap)}
      end)
      |> Enum.into(%{})
      |> Util.to_yaml()

    File.write!(yaml_file, yaml)
  end

  defp build_map(%SchemaWrap{complex_type_map: complex_type_map}) do
    complex_type_map
    |> Enum.map(fn {name, complex_type} ->
      {name, build_map(complex_type)}
    end)
    |> Enum.into(%{})
  end

  defp build_map(%ComplexType{fields: fields}) do
    fields
    |> Enum.map(fn field ->
      {field.xml_name, build_map(field)}
    end)
    |> Enum.into(%{})
  end

  defp build_map(%Field{type: complex_type = %ComplexType{}}) do
    build_map(complex_type)
  end

  defp build_map(%Field{}), do: %{}
end
