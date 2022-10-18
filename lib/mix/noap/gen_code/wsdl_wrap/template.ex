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

  EEx.function_from_file(:def, :create_operation_delegate, EExPath.get("operation_delegate"), [
    :wrap
  ])

  EEx.function_from_file(:def, :create_operations, EExPath.get("operations"), [
    :wrap,
    :wsdl_instance,
    :schema_instances,
    :operation_instances,
    :operation_functions
  ])

  EEx.function_from_file(:def, :create_delegate, EExPath.get("delegate"), [
    :wrap,
    :operation_delegates
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

  def module_name(complex_type) do
    complex_type.parent_module <> "." <> Util.titleize(complex_type.name)
  end

  defp xml_fields(complex_type) do
    complex_type.fields
    |> Stream.map(&Field.line/1)
    |> Enum.join("\n")
  end

  defp only_simple_fields?(%ComplexType{fields: fields}) do
    fields
    |> Enum.all?(&(&1.field_or_embed == :field))
  end

  defp field_count(%ComplexType{fields: fields}) do
    fields
    |> Enum.count()
  end

  defp field_names_as_args(%ComplexType{fields: []}) do
    # Don't append a comma for separating from options if there are no fields
    ""
  end

  defp field_names_as_args(%ComplexType{fields: fields}) do
    fields
    |> Stream.map(& &1.name)
    |> Enum.join(", ")
    # Append with comma to separate from options
    |> String.replace_suffix("", ",")
  end

  defp field_names_as_assigns(%ComplexType{fields: fields}) do
    fields
    |> Stream.map(&(&1.name <> ": " <> &1.name))
    |> Enum.join(", ")
  end
end
