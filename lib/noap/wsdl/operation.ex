defmodule Noap.WSDL.Operation do
  defstruct [
    :name,
    :input_name,
    :input_schema,
    :input_module,
    :output_name,
    :output_schema,
    :output_module,
    :action_attribute,
    :action_tag,
    {:body_namespace, :m}
    # :soap_action,
    # :action_ns,
    # :action_tag_attributes,
  ]
end
