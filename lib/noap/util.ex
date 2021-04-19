defmodule Noap.Util do
  def nil_if_empty(""), do: nil
  def nil_if_empty(str), do: str
end
