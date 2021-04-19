defmodule Mix.Noap.GenCode.WSDLWrap.OperationWrap do
  defstruct [
    :name,
    :underscored_name,
    :input_name,
    :input_schema,
    :input_complex_type,
    :output_name,
    :output_schema,
    :output_complex_type,
    :soap_action,
    :input_header_message,
    :input_header_part,
    :action_attribute,
    :action_tag
  ]
end
