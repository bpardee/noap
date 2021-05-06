defmodule Mix.Noap.GenCode.WSDLWrap.Field do
  defstruct [:xml_name, :name, :type, :many?, :options]

  alias Mix.Noap.GenCode.WSDLWrap.{ComplexType, Util}

  def new(xml_name, simple_type, many? = false) when is_atom(simple_type) do
    do_new(xml_name, Util.underscore(xml_name), simple_type, many?)
  end

  def new(xml_name, complex_type = %ComplexType{}, many?) do
    do_new(xml_name, Util.underscore(xml_name), complex_type, many?)
  end

  # Called via overrides, doesn't occur during normal generation
  def new(name, multi_type, many? = true, options) when is_atom(multi_type) do
    do_new(nil, name, multi_type, many?, options)
  end

  defp do_new(xml_name, name, type, many?, options \\ %{}) do
    %__MODULE__{
      xml_name: xml_name,
      name: name,
      type: type,
      many?: many?,
      options: options
    }
  end

  def line(field = %__MODULE__{type: type, many?: false}) when is_atom(type) do
    "field :#{field.name}, \"#{field.xml_name}\", :#{type}"
  end

  def line(field = %__MODULE__{type: type, many?: true}) when is_atom(type) do
    "multi_field :#{field.name}, :#{type}" <> line_append_options(field.options)
    # ", min: :days_14, max: :years_3, xml_prefix: "NbrOfNDDAInqsInPast"
  end

  def line(field = %__MODULE__{type: %ComplexType{module: module}, many?: false}) do
    "embeds_one :#{field.name}, \"#{field.xml_name}\", #{module}"
  end

  def line(field = %__MODULE__{type: %ComplexType{module: module}, many?: true}) do
    "embeds_many :#{field.name}, \"#{field.xml_name}\", #{module}"
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
