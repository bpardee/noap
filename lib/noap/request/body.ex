defmodule Noap.Request.Body do
  @moduledoc false

  @schema_types %{
    "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
    "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
  }
  @soap_version_namespaces %{
    "1.1" => "http://schemas.xmlsoap.org/soap/envelope/",
    "1.2" => "http://www.w3.org/2003/05/soap-envelope"
  }

  alias Noap.Schema

  @doc """
  Parsing parameters map and generate body xml by given soap action name and body params(Map).
  Returns xml-like string.
  """
  @spec build_body(
          operation :: Noap.Operation.t(),
          model :: map(),
          headers :: map()
        ) :: String.t() | no_return()
  def build_body(operation, model, headers) do
    body = build_soap_body(operation, model)
    header = build_soap_header(operation, headers)

    [header, body]
    |> add_envelope_tag_wrapper(operation)
    |> XmlBuilder.document()
    |> XmlBuilder.generate(format: :none)
    |> String.replace(["\n", "\t"], "")
  end

  def build_soap_body(operation, model) do
    model
    |> Noap.Model.to_element_tuples()
    |> add_action_tag_wrapper(operation)
    |> add_body_tag_wrapper
  end

  def build_soap_header(operation, headers) do
    map_to_tuple_element_list(headers)
    |> add_header_part_tag_wrapper(operation)
    |> add_header_tag_wrapper
  end

  defp map_to_tuple_element_list(map) do
    map
    |> Enum.map(fn {name, value} -> {name, nil, value} end)
  end

  @spec add_action_tag_wrapper(list(), Noap.Operation.t()) :: list()
  def add_action_tag_wrapper(body, operation) do
    action_tag_attributes = operation.input_schema.action_tag_attributes
    # "CACustomer"
    # "tns:ProgramInterface"
    action_tag = operation.action_tag
    [XmlBuilder.element(action_tag, action_tag_attributes, body)]
  end

  @spec add_header_part_tag_wrapper(map(), String.t()) :: list()
  def add_header_part_tag_wrapper(body, operation) do
    action_tag_attributes = operation.action_tag_attributes
    action_tag = operation.action_tag

    case get_header_with_namespace(operation) do
      nil ->
        nil

      action_tag ->
        [XmlBuilder.element(action_tag, action_tag_attributes, body)]
    end
  end

  @spec get_header_with_namespace(operation :: String.t()) :: String.t()
  def get_header_with_namespace(operation) do
    # with %{input: %{header: %{message: message, part: part}}} <-
    #        Enum.find(wsdl[:operations], &(&1[:name] == operation)),
    #      %{name: name} <- get_message_part(wsdl, message, part) do
    #   name
    # else
    #   _ -> nil
    # end
    nil

    # iex(10)> action_attribute_namespace = Soap.Request.Params.get_action_with_namespace(model2, "IDC52700Operation")
    # "tns:ProgramInterface"
  end

  # def get_message_part(wsdl, message, part) do
  #   wsdl[:messages]
  #   |> Enum.find(&("tns:#{&1[:name]}" == message))
  #   |> Map.get(:parts)
  #   |> Enum.find(&(&1[:name] == part))
  # end

  @spec add_body_tag_wrapper(list()) :: list()
  def add_body_tag_wrapper(body), do: [XmlBuilder.element(:"#{env_namespace()}:Body", nil, body)]

  @spec add_header_tag_wrapper(list()) :: list()
  def add_header_tag_wrapper(body),
    do: [XmlBuilder.element(:"#{env_namespace()}:Header", nil, body)]

  @spec add_envelope_tag_wrapper(body :: any(), operation :: String.t()) :: any()
  def add_envelope_tag_wrapper(body, operation) do
    envelop_attributes =
      @schema_types
      |> Map.merge(build_soap_version_attribute(operation.input_schema.wsdl))
      |> Map.merge(operation.action_attribute)
      |> Map.merge(custom_namespaces())

    [XmlBuilder.element(:"#{env_namespace()}:Envelope", envelop_attributes, body)]
  end

  @spec build_soap_version_attribute(Map.t()) :: map()
  def build_soap_version_attribute(wsdl) do
    soap_version = wsdl |> soap_version() |> to_string
    %{"xmlns:#{env_namespace()}" => @soap_version_namespaces[soap_version]}
  end

  def soap_version(wsdl) do
    Map.get(wsdl, :soap_version, Application.fetch_env!(:soap, :globals)[:version])
  end

  def env_namespace, do: Application.fetch_env!(:soap, :globals)[:env_namespace] || :env
  def custom_namespaces, do: Application.fetch_env!(:soap, :globals)[:custom_namespaces] || %{}
end
