defmodule Noap.XMLSchema do
  alias Noap.XMLField

  @type t :: %{optional(atom) => any, __struct__: atom}

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

        def to_map(xml_schema = %__MODULE__{}, type_map, remove_if_nil? \\ true) do
          Noap.XMLSchema.MapUtil.__to_map__(xml_schema, type_map, remove_if_nil?)
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
end
