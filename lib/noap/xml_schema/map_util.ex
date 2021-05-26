defmodule Noap.XMLSchema.MapUtil do
  alias Noap.XMLField

  @spec to_map(Noap.XMLSchema.t(), boolean) :: map()
  def to_map(xml_schema, remove_if_nil? \\ true) do
    type_map = get_typemap(xml_schema)
    __to_map__(xml_schema, type_map, remove_if_nil?)
  end

  @spec to_passthru_map(Noap.XMLSchema.t(), boolean()) :: map()
  def to_passthru_map(xml_schema, remove_if_nil? \\ true) do
    type_map = get_typemap(xml_schema)
    __to_map__(xml_schema, type_map, remove_if_nil?, &child_to_passthru_map/6, :xml_name)
  end

  @doc false
  def __to_map__(
        xml_schema,
        type_map,
        remove_if_nil?,
        child_to_map_fun \\ &child_to_map/6,
        key_field \\ :name
      ) do
    xml_schema.__struct__.xml_fields
    |> Enum.reduce(
      %{},
      fn xml_field, map ->
        value =
          field_value(
            xml_schema,
            xml_field,
            type_map,
            remove_if_nil?,
            child_to_map_fun,
            key_field
          )

        if is_nil(value) && remove_if_nil? do
          map
        else
          key = Map.get(xml_field, key_field)
          Map.put(map, key, value)
        end
      end
    )
  end

  defp field_value(
         xml_schema,
         %{field_or_embeds: :field, name: name},
         _type_map,
         _remove_if_nil?,
         _child_to_map_fun,
         _key_field
       ) do
    Map.get(xml_schema, name)
  end

  defp field_value(
         xml_schema,
         xml_field = %{field_or_embeds: :embeds_one, name: name},
         type_map,
         remove_if_nil?,
         child_to_map_fun,
         key_field
       ) do
    if child = Map.get(xml_schema, name) do
      type = get_type(xml_field, type_map)

      child_map =
        child_to_map_fun.(child, type, type_map, remove_if_nil?, child_to_map_fun, key_field)

      if remove_if_nil? && child_map == %{}, do: nil, else: child_map
    end
  end

  defp field_value(
         xml_schema,
         xml_field = %{field_or_embeds: :embeds_many, name: name},
         type_map,
         remove_if_nil?,
         child_to_map_fun,
         key_field
       ) do
    if list = Map.get(xml_schema, name) do
      type = get_type(xml_field, type_map)

      value_list =
        Enum.map(
          list,
          &child_to_map_fun.(&1, type, type_map, remove_if_nil?, child_to_map_fun, key_field)
        )

      if remove_if_nil? do
        value_list = Enum.reject(value_list, &(is_nil(&1) || &1 == %{}))
        if value_list == [], do: nil, else: value_list
      else
        value_list
      end
    end
  end

  defp child_to_map(
         xml_schema,
         type,
         type_map,
         remove_if_nil?,
         _child_to_map_fun,
         _key_field
       ) do
    type.to_map(xml_schema, type_map, remove_if_nil?)
  end

  defp child_to_passthru_map(
         xml_schema,
         _type,
         type_map,
         remove_if_nil?,
         child_to_map_fun,
         key_field
       ) do
    __to_map__(xml_schema, type_map, remove_if_nil?, child_to_map_fun, key_field)
  end

  defp get_type(%XMLField{xml_name: nil, type: embed_type_atom}, type_map) do
    type_map[embed_type_atom]
  end

  defp get_type(%XMLField{type: xml_schema_type}, _type_map), do: xml_schema_type

  defp get_typemap(xml_schema) do
    {:ok, app} = :application.get_application(xml_schema.__struct__)
    Noap.Type.type_map(app)
  end
end
