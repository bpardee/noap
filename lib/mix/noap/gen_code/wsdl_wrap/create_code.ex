defmodule Mix.Noap.GenCode.WSDLWrap.CreateCode do
  alias Mix.Noap.GenCode.WSDLWrap
  alias Mix.Noap.GenCode.WSDLWrap.{ComplexType, Field, Template, Util}

  def create_code(wsdl_wrap = %WSDLWrap{}, type_map, options \\ []) do
    overrides = get_create_code_overrides(options)

    wsdl_wrap.schema_map
    |> Enum.each(fn {name, schema_wrap} ->
      schema_overrides = get_nested_overrides(overrides, name)

      schema_wrap.complex_type_map
      |> Stream.map(fn {name, complex_type} ->
        nested_overrides = get_nested_overrides(schema_overrides, name)
        process_complex_type_overrides(complex_type, type_map, nested_overrides)
      end)
      |> Enum.each(&create_complex_type_code/1)
    end)

    wsdl_instance = Template.create_wsdl_instance(wsdl_wrap)

    schema_instances =
      wsdl_wrap.schema_map
      |> Stream.map(fn {_name, schema_wrap} ->
        Template.create_schema_instance(schema_wrap)
      end)
      |> Enum.join("\n")

    operation_instances =
      wsdl_wrap.operations
      |> Stream.map(&Template.create_operation_instance/1)
      |> Enum.join("\n")

    operation_functions =
      wsdl_wrap.operations
      |> Stream.map(&Template.create_operation_function/1)
      |> Enum.join("\n")

    module_dir = Util.get_module_dir(wsdl_wrap.module_prefix)

    Template.create_operations(
      wsdl_wrap,
      wsdl_instance,
      schema_instances,
      operation_instances,
      operation_functions
    )
    |> Template.save!(module_dir, "operations")
  end

  defp get_create_code_overrides(options) do
    if yaml_file = options[:overrides_file] do
      YamlElixir.read_from_file!(yaml_file, atoms: true)
    else
      options[:overrides] || %{}
    end
  end

  defp process_complex_type_overrides(complex_type, type_map, overrides) do
    {embed_one_fields, embed_one_xml_names} =
      process_embed_overrides(complex_type, type_map, :embeds_one, overrides[:embeds_one])

    {embed_many_fields, embed_many_xml_names} =
      process_embed_overrides(complex_type, type_map, :embeds_many, overrides[:embeds_many])

    replaced_xml_names = embed_one_xml_names ++ embed_many_xml_names

    new_fields =
      complex_type.fields
      |> Enum.reduce(
        [],
        fn field, non_removed_fields ->
          if field.xml_name in replaced_xml_names do
            non_removed_fields
          else
            [field | non_removed_fields]
          end
        end
      )
      |> Enum.map(fn field ->
        convert_field(field, type_map, get_nested_overrides(overrides, field.xml_name))
      end)

    %{complex_type | fields: Enum.reverse(embed_many_fields ++ embed_one_fields ++ new_fields)}
  end

  defp process_embed_overrides(complex_type, type_map, one_or_many, embed_overrides) do
    (embed_overrides || [])
    # Allows maintaining of key order (doesn't work!)
    # |> Enum.to_list()
    |> Enum.reduce(
      {[], []},
      fn {name, options}, {embed_fields, replaced_xml_names} ->
        {type, options} = Map.pop(options, :type)

        if is_nil(type) do
          raise "Must specify type for overfide of #{name} in #{complex_type.name}"
        end

        if !is_atom(type) do
          raise "Must specify an atom for type for override of #{name} in #{complex_type.name}"
        end

        embed_field = Field.new_override(one_or_many, name, type, options)
        embed_type = type_map[type]

        if is_nil(embed_type) do
          raise "No mapping for type #{type}"
        end

        xml_names =
          embed_type.xml_map(options)
          |> Enum.map(fn {key, value} ->
            # Parent xml nodes will be in the key, simple fields will be the value
            if is_binary(key), do: key, else: value
          end)

        {[embed_field | embed_fields], xml_names ++ replaced_xml_names}
      end
    )
  end

  defp get_nested_overrides(overrides, xml_name) do
    xml_name = to_string(xml_name)
    overrides[xml_name] || %{}
  end

  defp create_complex_type_code(
         complex_type = %ComplexType{parent_module: parent_module, name: name}
       ) do
    parent_dir = Util.get_module_dir(parent_module)

    Template.create_complex_type(complex_type)
    |> Template.save!(parent_dir, name)

    complex_type.fields
    |> Enum.each(fn field ->
      case field do
        %Field{type: child_complex_type = %ComplexType{}} ->
          create_complex_type_code(child_complex_type)

        _ ->
          nil
      end
    end)

    :ok
  end

  defp convert_field(
         field = %Field{type: child_complex_type = %ComplexType{}},
         type_map,
         overrides
       ) do
    child_complex_type = process_complex_type_overrides(child_complex_type, type_map, overrides)
    %{field | type: child_complex_type}
  end

  defp convert_field(field, _type_map, overrides) do
    convert_field_type(field, overrides[:type])
  end

  defp convert_field_type(field, nil), do: field
  defp convert_field_type(field, type) when is_atom(type), do: %{field | type: type}

  defp convert_field_type(field, type) when is_binary(type) do
    if String.starts_with?(type, ":") do
      type = type |> String.slice(1..-1) |> String.to_atom()
      %{field | type: type}
    else
      raise "Not sure what to do with type=#{type}"
    end
  end
end
