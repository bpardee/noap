defmodule Mix.Noap.GenCode.WSDLWrap.Field do
  require Logger
  alias Mix.Noap.GenCode.WSDLWrap.{ComplexType, Template, Util}

  defstruct [:field_or_embed, :xml_name, :name, :type, :options]

  def new(field_or_embeds, xml_name, simple_type) when is_atom(simple_type) do
    Logger.debug("#{xml_name} of type #{simple_type}")
    do_new(field_or_embeds, xml_name, Util.underscore(xml_name), simple_type)
  end

  def new(embeds, xml_name, complex_type_name) when is_binary(complex_type_name) do
    Logger.debug("#{xml_name} of type #{complex_type_name}")

    do_new(
      embeds,
      xml_name,
      Util.underscore(xml_name),
      complex_type_name
    )
  end

  def new_override(embeds, name, embed_type, options) do
    do_new(embeds, nil, name, embed_type, options)
  end

  defp do_new(field_or_embed, xml_name, name, type, options \\ %{}) do
    %__MODULE__{
      field_or_embed: field_or_embed,
      xml_name: xml_name,
      name: name,
      type: type,
      options: options
    }
  end

  def line(field = %__MODULE__{type: complex_type = %ComplexType{}}) do
    do_line(field, Template.module_name(complex_type))
  end

  def line(field = %__MODULE__{type: type}) do
    do_line(field, ":#{type}")
  end

  defp do_line(field, type) do
    "#{field.field_or_embed} :#{field.name}, #{inspect(field.xml_name)}, #{type}" <>
      line_append_options(field.options)
  end

  defp line_append_options(options) when options == %{}, do: ""

  defp line_append_options(options = %{}) do
    options
    |> Stream.map(fn {name, value} ->
      "#{name}: #{inspect(value)}"
    end)
    |> Enum.join(", ")
    |> String.replace_prefix("", ", ")
  end
end
