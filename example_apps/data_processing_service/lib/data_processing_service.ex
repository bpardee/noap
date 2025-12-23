defmodule DataProcessingService do
  alias __MODULE__.Operations

  @doc "Calls the ProcessData operation"
  defdelegate call_process_data(processing_request, options \\ []), to: Operations
end