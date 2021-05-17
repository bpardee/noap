defmodule Noap.XMLSchema do
  alias Noap.XMLField

  defmacro __using__(_) do
    quote do
      import Noap.XMLSchema, only: [xml_schema: 1]
    end
  end

  defmacro xml_schema(do: block) do
    schema(block)
  end

  defmacro field(name, xml_name, type, opts \\ []) do
    quote do
      Noap.XMLSchema.__field__(
        __MODULE__,
        :field,
        unquote(name),
        unquote(xml_name),
        unquote(type),
        unquote(opts)
      )
    end
  end

  defmacro embeds_one(name, xml_name, type, opts \\ []) do
    quote do
      Noap.XMLSchema.__field__(
        __MODULE__,
        :embeds_one,
        unquote(name),
        unquote(xml_name),
        unquote(type),
        unquote(opts)
      )
    end
  end

  defmacro embeds_many(name, xml_name, type, opts \\ []) do
    quote do
      Noap.XMLSchema.__field__(
        __MODULE__,
        :embeds_many,
        unquote(name),
        unquote(xml_name),
        unquote(type),
        unquote(opts)
      )
    end
  end

  defp schema(block) do
    prelude =
      quote do
        Module.register_attribute(__MODULE__, :xml_fields_reversed, accumulate: true)
        Module.register_attribute(__MODULE__, :struct_fields, accumulate: true)

        try do
          import Noap.XMLSchema
          unquote(block)
        after
          :ok
        end
      end

    postlude =
      quote unquote: false do
        defstruct @struct_fields
        # Put them back in the order they were originally listed
        @xml_fields Enum.reverse(@xml_fields_reversed)

        def xml_fields(), do: @xml_fields

        def to_map(xml_schema = %__MODULE__{}, type_map, remove_if_nil \\ true) do
          Noap.XMLSchema.__to_map__(@xml_fields, xml_schema, type_map, remove_if_nil)
        end
      end

    quote do
      unquote(prelude)
      unquote(postlude)
    end
  end

  @doc false
  def __field__(mod, field_or_embeds, name, xml_name, type, opts) do
    Module.put_attribute(
      mod,
      :xml_fields_reversed,
      XMLField.new(field_or_embeds, name, xml_name, type, Enum.into(opts, %{}))
    )

    Module.put_attribute(mod, :struct_fields, name)
  end

  def __to_map__(xml_fields, xml_schema, type_map, remove_if_nil) do
    xml_fields
    |> Enum.reduce(
      %{},
      fn xml_field, map ->
        value = field_value(xml_schema, xml_field, type_map, remove_if_nil)

        if is_nil(value) && remove_if_nil do
          map
        else
          Map.put(map, xml_field.name, value)
        end
      end
    )
  end

  defp field_value(xml_schema, %{field_or_embeds: :field, name: name}, _type_map, _remove_if_nil) do
    Map.get(xml_schema, name)
  end

  defp field_value(
         xml_schema,
         xml_field = %{field_or_embeds: :embeds_one, name: name},
         type_map,
         remove_if_nil
       ) do
    if child = Map.get(xml_schema, name) do
      type = get_type(xml_field, type_map)
      child_map = type.to_map(child, type_map, remove_if_nil)
      if remove_if_nil && child_map == %{}, do: nil, else: child_map
    end
  end

  defp field_value(
         xml_schema,
         xml_field = %{field_or_embeds: :embeds_many, name: name},
         type_map,
         remove_if_nil
       ) do
    if list = Map.get(xml_schema, name) do
      type = get_type(xml_field, type_map)
      value_list = Enum.map(list, &type.to_map(&1, type_map, remove_if_nil))

      if remove_if_nil do
        value_list = Enum.reject(value_list, &(is_nil(&1) || &1 == %{}))
        if value_list == [], do: nil, else: value_list
      else
        value_list
      end
    end
  end

  defp get_type(%XMLField{xml_name: nil, type: embed_type_atom}, type_map) do
    type_map[embed_type_atom]
  end

  defp get_type(%XMLField{type: xml_schema_type}, _type_map), do: xml_schema_type
end
