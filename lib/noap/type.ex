defmodule Noap.Type do
  @moduledoc """
  Defines a behaviour for converting to/from a soap string element
  """

  @typedoc "Implements the Noap.Type behaviour"
  @type t :: struct()

  @typedoc "One of the values :boolean, :date, :date_time, :float, :integer, :string or a user-defined type atom"
  @type type_atom :: atom()

  @callback from_str(String.t(), opts :: Keyword.t()) ::
              {:ok, value :: any} | :error | {:error, message :: String.t()} | {:error, atom}
  @callback to_str(any, opts :: Keyword.t()) :: String.t()

  @optional_callbacks from_str: 2, to_str: 2

  @default_type_map %{
    boolean: __MODULE__.Boolean,
    date: __MODULE__.Date,
    date_time: __MODULE__.DateTime,
    float: __MODULE__.Float,
    integer: __MODULE__.Integer,
    string: __MODULE__.String
  }

  def default_type_map() do
    @default_type_map
  end

  def type_map(application) do
    application
    |> Application.get_env(:noap_types, [])
    |> Enum.into(@default_type_map())
  end

  defmacro __using__([]) do
    quote do
      @behaviour Noap.Type

      @impl Noap.Type
      @doc """
      Default implementation which should be overridden unless you're sure your type is never used for
      converting from soap responses.
      """
      def from_str(_str, _opts) do
        raise "You need to override from_str for #{__MODULE__}"
      end

      @impl Noap.Type
      @doc "Default implementation which just performs a Kernel.to_string/1"
      def to_str(value, _opts), do: to_string(value)

      defoverridable from_str: 2, to_str: 2
    end
  end
end
