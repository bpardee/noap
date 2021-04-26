defmodule Noap.Schema do
  defmacro __using__(_) do
    quote do
      import Noap.Schema, only: [xml_schema: 1]
    end
  end

  defmacro xml_schema(do: block) do
    schema(block)
  end

  defmacro field(name, xml_name, type, opts \\ []) do
    quote do
      Noap.Schema.__field__(
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
      Noap.Schema.__field__(
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
      Noap.Schema.__field__(
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
          import Noap.Schema
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

        def xml_fields, do: @xml_fields_reversed
      end

    quote do
      unquote(prelude)
      unquote(postlude)
    end
  end

  @doc false
  def __field__(mod, field_or_embeds, name, xml_name, type, opts) do
    Module.put_attribute(mod, :xml_fields, {field_or_embeds, name, xml_name, type, opts})
    Module.put_attribute(mod, :struct_fields, name)
  end
end
