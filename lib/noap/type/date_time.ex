defmodule Noap.Type.DateTime do
  use Noap.Type

  @impl true
  def from_str(str, _opts) do
    case DateTime.from_iso8601(str) do
      {:ok, value, _offset} -> value
      error -> error
    end
  end

  @impl true
  def to_str(date_time = %DateTime{}, _opts), do: DateTime.to_iso8601(date_time)
end
