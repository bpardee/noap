defmodule Mix.Noap.GenCode.WSDLWrap.Field do
  defstruct [:name, :underscored_name, :type, :many?]

  alias Mix.Noap.GenCode.WSDLWrap.{ComplexType, Util}

  def new(name, simple_type, many? = false) when is_atom(simple_type) do
    do_new(name, simple_type, many?)
  end

  def new(name, complex_type = %ComplexType{}, many?) do
    do_new(name, complex_type, many?)
  end

  defp do_new(name, type, many?) do
    %__MODULE__{
      name: name,
      underscored_name: Util.underscore(name),
      type: type,
      many?: many?
    }
  end
end
