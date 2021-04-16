defmodule Mix.Noap.GenCode.WSDLWrap.Action do
  defstruct [
    :ns,
    :name,
    :tag,
    :attribute
  ]

  def new(name, _action_with_namespace = "", _namespace_map) do
    %__MODULE__{
      ns: "",
      name: name,
      tag: name,
      attribute: %{}
    }
  end

  def new(_name, action_with_namespace, namespace_map) do
    [ns, action] =
      action_with_namespace
      |> String.split(":", parts: 2)

    %__MODULE__{
      ns: ns,
      name: action,
      tag: action_with_namespace,
      attribute: %{"xmlns:#{ns}" => namespace_map[ns]}
    }
  end
end
