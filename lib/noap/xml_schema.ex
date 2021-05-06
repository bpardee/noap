defmodule Noap.XMLSchema do
  alias Noap.XMLField

  @callback from_map(Map.t(), opts :: Keyword.t()) :: any

  @optional_callbacks from_map: 2

  defmacro __using__(_) do
    quote do
      @behaviour Noap.MultiType

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

  defmacro multi_field(name, type, opts \\ []) do
    quote do
      Noap.XMLSchema.__field__(
        __MODULE__,
        :multi_field,
        unquote(name),
        nil,
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
        Module.register_attribute(__MODULE__, :xml_fields, accumulate: true)
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
        @xml_fields_reversed Enum.reverse(@xml_fields)

        @impl Noap.MultiType
        def xml_fields(_opts), do: @xml_fields_reversed

        @impl Noap.MultiType
        def from_map(map, _opts), do: {:ok, struct(__MODULE__, map)}
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
      :xml_fields,
      XMLField.new(field_or_embeds, name, xml_name, type, opts)
    )

    Module.put_attribute(mod, :struct_fields, name)
  end
end
