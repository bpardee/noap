defmodule Noap do
  @type status_code :: pos_integer()
  @type ok_status :: {:ok, status_code(), Noap.XMLSchema.t()}
  @type error_status :: {:error, status_code(), String.t()} | {:error, status_code(), atom()}
  @type call_operation_t :: ok_status() | error_status() | no_return()

  @spec call_operation(Noap.WSDL.Operation.t(), Noap.XMLSchema.t(), Keyword.t()) ::
          call_operation_t()
  defdelegate call_operation(operation, request_xml_schema, options \\ []), to: Noap.Client

  @deprecated "Use call_operation/3 instead"
  def perform_operation(operation, request_xml_schema, options \\ []) do
    call_operation(operation, request_xml_schema, options)
  end

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
