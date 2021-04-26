defmodule Mix.Noap.GenCode.WSDLWrap.Template do
  require EEx

  alias Mix.Noap.GenCode.WSDLWrap.{ComplexType, Field, Util}

  defmodule EExPath do
    def get(name) do
      Path.dirname(__ENV__.file) <> "/templates/" <> name <> ".eex"
    end
  end

  EEx.function_from_file(:def, :create_operation_instance, EExPath.get("operation_instance"), [
    :wrap
  ])

  EEx.function_from_file(:def, :create_operation_function, EExPath.get("operation_function"), [
    :wrap
  ])

  EEx.function_from_file(:def, :create_service, EExPath.get("service"), [
    :wrap,
    :wsdl_instance,
    :schema_instances,
    :operation_instances,
    :operation_functions
  ])

  EEx.function_from_file(:def, :create_wsdl_instance, EExPath.get("wsdl_instance"), [
    :wsdl_wrap
  ])

  EEx.function_from_file(:def, :create_schema_instance, EExPath.get("schema_instance"), [
    :schema_wrap
  ])

  EEx.function_from_file(:def, :create_complex_type, EExPath.get("complex_type"), [
    :complex_type
  ])

  def save!(code, dir, name) do
    File.mkdir_p!(dir)
    file_name = Path.join(dir, Util.underscore(name) <> ".ex")
    save!(code, file_name)
  end

  def save!(code, file_name) do
    IO.puts("Creating #{file_name}")
    File.write!(file_name, Code.format_string!(code), [:write])
  end

  defp xml_fields(complex_type) do
    complex_type.fields
    |> Stream.map(fn field ->
      {spec, tname} = spec_type_pair(field)
      "#{spec}(:#{field.underscored_name}, \"#{field.name}\", #{tname})"
    end)
    |> Enum.join("\n")
  end

  defp spec_type_pair(%Field{type: type}) when is_atom(type), do: {"field", ":#{type}"}
  defp spec_type_pair(%Field{type: %ComplexType{module: m}, many?: false}), do: {"embeds_one", m}
  defp spec_type_pair(%Field{type: %ComplexType{module: m}, many?: true}), do: {"embeds_many", m}
end
