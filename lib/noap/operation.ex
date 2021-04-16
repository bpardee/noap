defmodule Noap.Operation do
  defstruct [
    :name,
    :input_schema,
    :input_module,
    :output_schema,
    :output_module,
    :soap_action,
    :action_tag,
    :action_ns,
    :action_tag_attributes,
    :action_attribute
  ]
end
