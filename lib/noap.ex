defmodule Noap do
  @spec to_map(Noap.XMLSchema.t(), boolean) :: map()
  @doc """
  Convert the given xml_schema to a map using the derived fields names.  If remove_if_nil? is true,
  then the nil fields and maps will be removed.
  """
  defdelegate to_map(xml_schema, remove_if_nil? \\ true), to: Noap.XMLSchema.MapUtil

  @spec to_passthru_map(Noap.XMLSchema.t(), boolean) :: map()
  @doc """
  Convert the given xml_schema to a map using the names from the WSDL.  If remove_if_nil? is true,
  then the nil fields and maps will be removed.
  """
  defdelegate to_passthru_map(xml_schema, remove_if_nil? \\ true), to: Noap.XMLSchema.MapUtil
end
