defmodule Noap.MultiType do
  @moduledoc """
  Defines a behaviour for converting from multiple soap string elements to a user-defined structure
  """

  @typedoc "Implements the Noap.MultiType behaviour"
  @type t :: struct()

  @typedoc "Designates that this atom signifies a user-registered multi type"
  @type multi_type_atom :: atom()

  @callback xml_fields(opts :: Map.t()) :: list(XMLField.t() | XMLMuultiField.t())

  @callback from_map(map, opts :: Keyword.t()) ::
              {:ok, value :: any}
              | :error
              | {:error, message :: String.t()}
              | {:error, atom}
              | no_return()
end
