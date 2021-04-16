defmodule Mix.Noap.GenCode do
  def run(_wsdl_path, _module_namespace) do
    # model = parse_wsdl_from_file(wsdl_path)
    # module_dir = get_module_namespace_dir(module_namespace)

    # Enum.each(types, fn type ->
    #   IO.inspect(type, label: :type)
    #   # type(name: name, els: [el(alts: alts)]) = type
    #   type(name: name, els: els) = type
    #   soap_type = to_string(name)
    #   IO.puts("soap_type=#{soap_type}")
    #   # IO.inspect(alts, label: :alts)
    #   IO.inspect(els, label: :els)

    #   process_soap_type(soap_type, module_namespace, module_dir)
    # end)
  end
end
