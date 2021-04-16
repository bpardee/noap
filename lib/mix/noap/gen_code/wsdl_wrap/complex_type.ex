defmodule Mix.Noap.GenCode.WSDLWrap.ComplexType do
  defstruct [
    :module,
    :parent_dir,
    :name,
    :underscored_name,
    :fields
  ]

  alias Mix.Noap.GenCode.WSDLWrap.{Field, Template, Util}

  def new(parent_module, parent_dir, name, _parent = nil) do
    %__MODULE__{
      module: "#{parent_module}.#{name}",
      parent_dir: parent_dir,
      name: name,
      underscored_name: Util.underscore(name),
      fields: []
    }
  end

  def new(_parent_module, _parent_dir, name, %__MODULE__{
        module: parent_module,
        parent_dir: grandparent_dir,
        name: parent_name
      }) do
    parent_dir = Path.join(grandparent_dir, Util.underscore(parent_name))
    File.mkdir_p!(parent_dir)
    new(parent_module, parent_dir, name, nil)
  end

  def add_field(complex_type = %__MODULE__{}, field = %Field{}) do
    %{complex_type | fields: [field | complex_type.fields]}
  end

  def create_code(complex_type = %__MODULE__{parent_dir: parent_dir, name: name}) do
    # The fields are in reverse order based on add_field so reverse them
    complex_type = %{complex_type | fields: Enum.reverse(complex_type.fields)}

    Template.create_model(complex_type)
    |> Template.save!(parent_dir, name)

    complex_type
  end
end
