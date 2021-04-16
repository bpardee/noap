defmodule Mix.Noap.GenCode.WSDLWrap.Template do
  require EEx

  alias Mix.Noap.GenCode.WSDLWrap.Util

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

  EEx.function_from_file(:def, :create_model, EExPath.get("model"), [
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
end
