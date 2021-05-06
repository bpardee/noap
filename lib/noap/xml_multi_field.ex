defmodule Noap.XMLMultiField do
  defstruct [
    :name,
    :xml_fields,
    :type,
    :opts
  ]

  def new(name, type, opts) do
    %__MODULE__{
      name: name,
      # Cache the fields so we don't have to calc with every parse
      xml_fields: type.xml_fields(opts),
      type: type,
      opts: opts
    }
  end
end
