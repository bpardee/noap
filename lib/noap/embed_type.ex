defmodule Noap.EmbedType do
  @moduledoc """
  Defines a behaviour for converting from multiple soap string elements to a user-defined structure
  """

  @typedoc "Implements the Noap.EmbedType behaviour"
  @type t :: struct()

  @typedoc "Designates that this atom signifies a user-registered embed type"
  @type embed_type_atom :: atom()

  @doc """
  Provide a mapping of the names (atoms) to the xml_names of the element containing the field.
  """
  @callback xml_map(opts :: Map.t()) :: map()

  @callback type(name :: atom()) :: atom()

  @callback from_map(embed_atom :: embed_type_atom(), values :: map, opts :: Keyword.t()) ::
              {:ok, value :: any}
              | :error
              | {:error, message :: String.t()}
              | {:error, atom}
              | no_return()

  @callback to_map(embed_type :: any(), type_map :: map(), remove_if_nil :: boolean()) ::
              value :: any()

  defmacro __using__(_) do
    quote do
      @behaviour Noap.EmbedType

      @impl Noap.EmbedType
      def xml_map(%{xml_map: xml_map}), do: xml_map

      @impl Noap.EmbedType
      def type(_name) do
        :string
      end

      @impl Noap.EmbedType
      def from_map(_field_or_embeds, map, _opts) do
        {:ok, struct(__MODULE__, map)}
      end

      @impl Noap.EmbedType
      def to_map(embed_type, _type_map, remove_if_nil \\ true) do
        Noap.EmbedType.__to_map__(embed_type, remove_if_nil)
      end

      defoverridable Noap.EmbedType
    end
  end

  def __to_map__(embed_type, remove_if_nil) do
    map = Map.from_struct(embed_type)

    if remove_if_nil do
      keyword =
        map
        |> Enum.reject(fn {_, v} -> is_nil(v) end)

      if keyword == [], do: nil, else: Map.new(keyword)
    else
      map
    end
  end
end
