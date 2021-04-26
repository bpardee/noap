defmodule Noap.Type.Integer do
  use Noap.Type

  @impl true
  def from_str(str, _opts) do
    case Integer.parse(str) do
      {val, ""} -> {:ok, val}
      _ -> :error
    end
  end
end
