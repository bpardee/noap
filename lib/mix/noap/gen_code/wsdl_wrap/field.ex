defmodule Mix.Noap.GenCode.WSDLWrap.Field do
  defstruct [:name, :underscored_name, :type, :field_or_embed]

  alias Mix.Noap.GenCode.WSDLWrap.{ComplexType, Util}

  def new(name, ecto_type) when is_atom(ecto_type) do
    do_new(name, ":#{ecto_type}", "field")
  end

  def new(name, complex_type = %ComplexType{}) do
    do_new(name, complex_type.module, "embeds_one")
  end

  defp do_new(name, type, field_or_embed) do
    %__MODULE__{
      name: name,
      underscored_name: Util.underscore(name),
      type: type,
      field_or_embed: field_or_embed
    }
  end
end
