defmodule Noap.Type.Date do
  use Noap.Type

  @impl true
  def from_str(str, _opts), do: Date.from_iso8601(str)

  @impl true
  def to_str(date = %Date{}, _opts), do: Date.to_iso8601(date)
end
