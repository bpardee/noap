defmodule Noap.Type.String do
  use Noap.Type

  @impl true
  def from_str(str, _opts), do: {:ok, str}

  @impl true
  def to_str(str, _opts), do: str
end
