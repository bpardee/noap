defmodule Noap.XMLField do
  defstruct [
    :field_or_embeds,
    :name,
    :xml_name,
    :type,
    :opts
  ]

  def new(field_or_embeds, name, xml_name, type, opts) do
    %__MODULE__{
      field_or_embeds: field_or_embeds,
      name: name,
      xml_name: xml_name,
      type: type,
      opts: opts
    }
  end
end
