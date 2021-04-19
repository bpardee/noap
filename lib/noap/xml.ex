defmodule Noap.XML do
  import SweetXml, only: [xpath: 2, sigil_x: 2]

  @spec find_namespace(String.t(), String.t()) :: String.t()
  def find_namespace(doc, url) do
    doc
    |> xpath(~x"//namespace::*"l)
    |> Enum.find(fn {_, _, _, _, x} -> url == to_string(x) end)
    |> elem(3)
    |> to_string()
  end
end
