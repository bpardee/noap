if Code.ensure_loaded?(Finch) do
  defmodule Noap.HTTP.Finch do
    @behaviour Noap.HTTP

    @impl Noap.HTTP
    def post(url, headers, soap_request, options) do
      case Finch.build(:post, url, headers, soap_request, options) |> Finch.request(MyFinch) do
        {:ok, %Finch.Response{status: status, body: soap_response}} ->
          {:ok, status, soap_response}

        {:error, error} ->
          {:error, inspect(error)}
      end
    end
  end
end
