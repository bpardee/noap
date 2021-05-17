defmodule Noap.XMLField do
  defstruct [
    :field_or_embeds,
    :name,
    :xml_name,
    :xml_map,
    :type,
    :opts
  ]

  def new(field_or_embeds, name, nil, type, opts) do
    app = Mix.Project.config()[:app]
    type_map = Noap.Type.type_map(app)
    embed_type = type_map[type]
    if is_nil(embed_type) do
      raise "Couldn't find type=#{type} from #{inspect(type_map)} app=#{app}"
    end
    %__MODULE__{
      field_or_embeds: field_or_embeds,
      name: name,
      xml_map: embed_type.xml_map(opts),
      type: type,
      opts: opts
    }
  end

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
