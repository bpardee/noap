defmodule Mix.Noap.GenCode.WSDLWrap.ComplexType do
  defstruct [
    :parent_module,
    :name,
    :fields
  ]

  alias Mix.Noap.GenCode.WSDLWrap.{Field, Util}

  def new(parent_module, name, _parent = nil) do
    %__MODULE__{
      parent_module: parent_module,
      name: name,
      fields: []
    }
  end

  def new(_parent_module, name, %__MODULE__{parent_module: grand_parent_module, name: parent_name}) do
    new("#{grand_parent_module}.#{Util.titleize(parent_name)}", name, nil)
  end

  def add_field(complex_type = %__MODULE__{}, field = %Field{}) do
    %{complex_type | fields: [field | complex_type.fields]}
  end
end
