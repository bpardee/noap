defmodule Noap.HTTP do
  @type header :: {String.t(), String.t()}

  @type headers :: [header]

  @type url :: String.t()
  @type soap_request :: String.t()
  @type soap_response :: String.t()
  @type status_code :: pos_integer()

  @callback post(url(), headers(), soap_request(), options :: Keyword.t()) ::
              {:ok, status_code, soap_response}
              | {:error, atom}
              | {:error, String.t()}
              | no_return()
end
