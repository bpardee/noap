defmodule Noap.WSDL do
  defstruct [
    {:soap_version, "1.1"},
    {:soap_namespace, :soap},
    :endpoint
  ]
end
