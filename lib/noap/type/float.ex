defmodule Noap.Type.Float do
  use Noap.Type

  @impl true
  def from_str(str, _opts) do
    case Float.parse(str) do
      {val, ""} -> {:ok, val}
      _ -> :error
    end
  end
end
