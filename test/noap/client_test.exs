defmodule Noap.ClientTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  test "handle_timeout_error logs warning and returns {:error, 500, :timeout}" do
    error = %Mint.TransportError{reason: :timeout}

    log =
      capture_log(fn ->
        result = Noap.Client.handle_timeout_error(error)
        assert result == {:error, 500, :timeout}
      end)

    assert log =~ "SOAP call timeout"
  end
end
