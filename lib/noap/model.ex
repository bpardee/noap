defmodule Noap.Model do
  defmacro __using__([]) do
    quote do
      @doc false
      def _to_element_tuples(model) do
        Noap.Model._to_element_tuples(model, @xml_field_map)
      end
    end
  end

  def to_element_tuples(model) do
    model.__struct__._to_element_tuples(model)
  end

  @doc false
  def _old_to_element_tuples(model, xml_field_map) do
    Enum.reduce(
      xml_field_map,
      [],
      fn {xml_key, field}, list ->
        case model[field] do
          nil ->
            list

          value ->
            type = model.__struct__.__schema__(:type, field)

            element_value =
              if is_atom(type) do
                to_string(value, type)
              else
                embedded_type = model.__struct__.__schema__(:type, field).related
                embedded_type._to_element_tuples(value)
              end

            # Prepend a tuple which represent an element for xml_builder where 1=name 2=map of attributes (nil for us) 3=value
            [{xml_key, nil, element_value} | list]
        end
      end
    )
  end

  def _to_element_tuples(model, xml_field_map) do
    Enum.map(
      xml_field_map,
      fn {xml_key, field} ->
        type = model.__struct__.__schema__(:type, field)
        value = Map.get(model, field)
        element_value = to_element_value(value, type)

        # Prepend a tuple which represent an element for xml_builder where 1=name 2=map of attributes (nil for us) 3=value
        {xml_key, nil, element_value}
      end
    )
  end

  @spec to_string(any, atom()) :: nil | String.t()
  def to_string(nil, _type), do: nil
  def to_string(val, :date), do: Date.to_iso8601(val)
  def to_string(val, :naive_datetime), do: NaiveDateTime.to_iso8601(val)
  def to_string(val, _type), do: to_string(val)

  defp to_element_value(value, type) when is_atom(type), do: to_string(value, type)

  defp to_element_value(
         model,
         {:parameterized, Ecto.Embedded, %Ecto.Embedded{related: child_type}}
       ) do
    model = model || struct(child_type)
    child_type._to_element_tuples(model)
  end
end
