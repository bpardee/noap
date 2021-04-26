defmodule Noap.Type.Boolean do
  use Noap.Type

  @impl true
  def from_str("true", _opts), do: {:ok, true}
  def from_str("false", _opts), do: {:ok, false}
  def from_str("1", _opts), do: {:ok, true}
  def from_str("0", _opts), do: {:ok, false}
  def from_str("Y", _opts), do: {:ok, true}
  def from_str("N", _opts), do: {:ok, false}
  def from_str(_str, _opts), do: :error
end
