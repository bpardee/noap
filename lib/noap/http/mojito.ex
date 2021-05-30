if Code.ensure_loaded?(Mojito) do
  defmodule Noap.HTTP.Mojito do
    @behaviour Noap.HTTP

    @impl Noap.HTTP
    def post(url, headers, soap_request, options) do
      case Mojito.post(url, headers, soap_request, options) do
        {:ok, %Mojito.Response{status_code: status_code, body: soap_response}} ->
          {:ok, status_code, soap_response}

        {:error, error} ->
          {:error, inspect(error)}
      end
    end
  end
end
