defmodule Noap.Model do
  defmacro __using__([]) do
    quote do
      @doc false
      def xml_fields do
        @xml_fields
      end
    end
  end

  def to_element_tuples(model, env) do
    to_element_tuples(model, env, model.__struct__.xml_fields())
  end

  def to_element_tuples(model, env, xml_fields) do
    Enum.map(
      xml_fields,
      fn {field, xml_key, _simple_or_one_or_many} ->
        type = model.__struct__.__schema__(:type, field)
        value = Map.get(model, field)
        element_value = to_element_value(env, value, type)

        # Prepend a tuple which represent an element for xml_builder where 1=name 2=map of attributes (nil for us) 3=value
        {"#{env}:#{xml_key}", nil, element_value}
      end
    )
  end

  @spec to_string(any, atom()) :: nil | String.t()
  def to_string(nil, _type), do: nil
  def to_string(val, :date), do: Date.to_iso8601(val)
  def to_string(val, :naive_datetime), do: NaiveDateTime.to_iso8601(val)
  def to_string(val, _type), do: to_string(val)

  defp to_element_value(_env, value, type) when is_atom(type), do: to_string(value, type)

  defp to_element_value(
         env,
         model,
         {:parameterized, Ecto.Embedded, %Ecto.Embedded{related: child_type}}
       ) do
    model = model || struct(child_type)
    to_element_tuples(model, env)
  end
end
