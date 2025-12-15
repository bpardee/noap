# DataProcessingService

Example Noap client for DataProcessingService - a complex SOAP service with nested structures, multiple namespaces, arrays, and various data types.

This example demonstrates:
- Complex nested structures with multiple levels
- Multiple namespaces (request and response)
- Arrays and lists with minOccurs/maxOccurs
- Various data types (strings, integers, decimals, booleans, dates)
- Optional and required fields
- Type overrides via YAML configuration

## Usage

Get dependencies and generate parsing code:
```
mix deps.get
mix noap.gen.code
```

Make calls:
```elixir
iex(1)> request = %DataProcessingService.Request.ProcessingRequest{
  request_id: "REQ-001",
  request_type: "PROCESS",
  category_code: "CAT01",
  item_data: %DataProcessingService.Request.ItemData{
    item_identifier: "ITEM-123",
    item_name: %DataProcessingService.Request.ItemName{
      primary_name: "Primary Item",
      secondary_name: "Secondary Item",
      middle_identifier: "MID"
    },
    item_location: %DataProcessingService.Request.ItemLocation{
      street_address: "123 Main St",
      city: "Example City",
      region_code: "REG",
      postal_code: "12345"
    },
    item_attributes: %DataProcessingService.Request.ItemAttributes{
      attribute_code: "ATTR1",
      attribute_value: "Value1"
    },
    contact_info: %DataProcessingService.Request.ContactInfo{
      primary_contact: "555-0100",
      secondary_contact: "555-0101"
    },
    numeric_value: "100",
    date_value: "20240101",
    category_code: "CAT01",
    months_at_location: "6",
    years_at_location: "2"
  },
  metadata: %DataProcessingService.Request.RequestMetadata{
    version: "1.0",
    system_identifier: "SYS-001",
    request_indicator: "Y",
    summary_indicator: "N"
  },
  processing_options: %DataProcessingService.Request.ProcessingOptions{
    option_code: "OPT1",
    include_details: true,
    include_history: false
  }
}

iex(2)> {:ok, 200, response} = DataProcessingService.call_process_data(request)
iex(3)> response
%DataProcessingService.Response.ProcessingResponse{
  response_id: "RESP-001",
  request_id: "REQ-001",
  processing_result: %DataProcessingService.Response.ProcessingResult{
    result_code: "SUCCESS",
    result_message: "Processing completed",
    score_value: 85,
    score_reasons: %DataProcessingService.Response.ScoreReasons{
      reason_code1: "R001",
      reason_text1: "Reason one"
    }
  },
  ...
}
```

## Features Tested

This example app tests:
- Deep nesting (4+ levels)
- Multiple namespaces in same WSDL
- Arrays with unbounded maxOccurs
- Complex type inheritance
- Type overrides (fis_date, integer)
- Optional vs required fields
- Mixed data types (string, integer, decimal, boolean)
- Nested arrays and lists

