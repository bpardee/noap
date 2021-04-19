defmodule Mix.Noap.GenCode.WSDLWrap.Field do
  defstruct [:name, :underscored_name, :type, :simple_or_one_or_many]

  alias Mix.Noap.GenCode.WSDLWrap.{ComplexType, Util}

  def new(name, ecto_type, spec \\ :simple) when is_atom(ecto_type) do
    if spec != :simple do
      raise "Unexpected simple field spec: #{spec}"
    end

    do_new(name, ":#{ecto_type}", :simple)
  end

  def new(name, complex_type = %ComplexType{}, one_or_many) do
    do_new(name, complex_type.module, one_or_many)
  end

  defp do_new(name, type, simple_or_one_or_many) do
    %__MODULE__{
      name: name,
      underscored_name: Util.underscore(name),
      type: type,
      simple_or_one_or_many: simple_or_one_or_many
    }
  end
end
