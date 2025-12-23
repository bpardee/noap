# Code Generation Validation Guide

This guide explains how to verify that the code generation for `data_processing_service` is correct.

## Quick Validation Steps

### 1. Compilation Check
The most basic check is that all generated code compiles without errors:

```bash
cd example_apps/data_processing_service
mix compile
```

**Expected result**: Should compile successfully with no errors.

### 2. Test Execution
Run the test suite which includes comprehensive code generation validation:

```bash
mix test
```

**Expected result**: All tests should pass, including the code generation tests.

### 3. Generated Files Check
Verify that all expected modules are generated:

```bash
# Count generated request modules (should be 21)
ls lib/data_processing_service/soap/request/*.ex | wc -l

# Count generated response modules (should be 28)
ls lib/data_processing_service/soap/response/*.ex | wc -l

# List all generated request files
ls -la lib/data_processing_service/soap/request/

# List all generated response files
ls -la lib/data_processing_service/soap/response/
```

**Expected request modules** (21 modules):
- `account_summary.ex`
- `contact_info.ex`
- `credit_reference.ex`
- `credit_references.ex`
- `debt_bur_resn_cde_list.ex`
- `debt_bur_resn_txt_list.ex`
- `debt_burden_reasons.ex`
- `financial_history.ex`
- `item_attributes.ex`
- `item_data.ex`
- `item_location.ex`
- `item_name.ex`
- `payment_history.ex`
- `payment_record.ex`
- `processing_options.ex`
- `processing_request.ex`
- `reference_contact.ex`
- `request_metadata.ex`
- `sub_attributes.ex`
- `transaction.ex`
- `transaction_history.ex`

**Expected response modules** (28 modules):
- `category_summary.ex`
- `credit_analysis.ex`
- `credit_factor.ex`
- `credit_factors.ex`
- `credit_score.ex`
- `detail_record.ex`
- `detail_record_list.ex`
- `error_detail.ex`
- `error_details.ex`
- `factor_impact.ex`
- `history_summary.ex`
- `implementation_details.ex`
- `item_record.ex`
- `item_records.ex`
- `mitigation_strategy.ex`
- `processing_response.ex`
- `processing_result.ex`
- `recommendation.ex`
- `recommendations.ex`
- `record_counts.ex`
- `result_details.ex`
- `risk_code_list.ex`
- `risk_description_list.ex`
- `risk_factors.ex`
- `risk_mitigation.ex`
- `score_reasons.ex`
- `summary_data.ex`
- `tracking_info.ex`

### 4. Operations Module Check
Verify the operations module is generated correctly:

```bash
cat lib/data_processing_service/operations.ex
```

**Expected content**:
- Should define `process_data/0` function
- Should define `call_process_data/2` function
- Should reference correct input/output modules (`DataProcessingService.Soap.Request.ProcessingRequest` and `DataProcessingService.Soap.Response.ProcessingResponse`)
- Should have correct endpoint URL

### 5. Module Structure Validation
Each generated module should:
- Use `Noap.XMLSchema`
- Have `xml_schema do ... end` block
- Define correct fields matching WSDL schema
- Use correct module namespace (`DataProcessingService.Soap.Request.*` or `DataProcessingService.Soap.Response.*`)

Example check:
```bash
# Check a sample request module structure
cat lib/data_processing_service/soap/request/processing_request.ex

# Check a sample response module structure
cat lib/data_processing_service/soap/response/processing_response.ex
```

**Expected structure**:
```elixir
defmodule DataProcessingService.Soap.Request.ProcessingRequest do
  use Noap.XMLSchema

  xml_schema do
    field(:request_id, "RequestId", :string)
    embeds_one(:item_data, "ItemData", DataProcessingService.Soap.Request.ItemData)
    # ... more fields
  end
end
```

### 6. Type Overrides Validation
Check that type overrides from `config/overrides.yml` are applied:

```bash
# Check for integer types (should be :integer, not :string)
grep -r ":integer" lib/data_processing_service/soap/

# Check for fis_date types
grep -r ":fis_date" lib/data_processing_service/soap/
```

**Expected**: Fields specified in `overrides.yml` with `:type: :integer` or `:type: :fis_date` should use those types.

### 7. Nested Structure Validation
Verify nested structures are correctly generated:

```bash
# Check that ItemData has nested structures
cat lib/data_processing_service/soap/request/item_data.ex | grep -A 5 embeds

# Check that ProcessingResponse has nested ProcessingResult
cat lib/data_processing_service/soap/response/processing_response.ex | grep -A 5 ProcessingResult
```

**Expected**: Should use `embeds_one` or `embeds_many` for nested structures.

### 8. Array/List Validation
Verify arrays are correctly generated:

```bash
# Check ItemRecords uses embeds_many
cat lib/data_processing_service/soap/response/item_records.ex

# Check DetailRecordList
cat lib/data_processing_service/soap/response/detail_record_list.ex

# Check CreditReferences
cat lib/data_processing_service/soap/request/credit_references.ex
```

**Expected**: Arrays should use `embeds_many` macro.

### 9. Interactive Validation (IEx)
Start an interactive session and test the generated code:

```bash
iex -S mix
```

Then test:
```elixir
# Test that modules can be created
alias DataProcessingService.Soap.Request.ProcessingRequest

request = %ProcessingRequest{
  request_id: "TEST-001",
  request_type: "PROCESS",
  category_code: "CAT01"
}

# Should not raise an error
%ProcessingRequest{} = request

# Test operations
alias DataProcessingService.Operations
operation = Operations.process_data()
# Should return %Noap.WSDL.Operation{}
```

### 10. WSDL Schema Comparison
Compare generated code with WSDL schema:

1. Check that all complex types in WSDL have corresponding modules
2. Verify field names match XML element names
3. Verify required vs optional fields (nillable="false" vs nillable="true")
4. Verify namespace separation (request vs response)

## Automated Validation Tests

The code generation is validated through comprehensive ExUnit tests in:
```
test/data_processing_service/code_generation_test.exs
```

Run the tests with:
```bash
mix test
```

Or run just the code generation tests:
```bash
mix test test/data_processing_service/code_generation_test.exs
```

### What the Tests Validate

The test suite checks:

1. **Generated Files**: All expected request (21) and response (28) modules are generated
2. **Operations Module**: Operations file exists and has correct structure
3. **Module Structure**: 
   - All modules use `Noap.XMLSchema`
   - All modules have `xml_schema do ... end` blocks
   - Module namespaces are correct (`DataProcessingService.Soap.Request.*` and `DataProcessingService.Soap.Response.*`)
4. **Type Overrides**: Type overrides from `overrides.yml` are correctly applied (integer, fis_date)
5. **Nested Structures**: Nested structures use `embeds_one` or `embeds_many`
6. **Array Structures**: Arrays use `embeds_many`
7. **Code Compilation**: 
   - Generated files have valid Elixir syntax
   - Module references use correct paths
   - Operations module references correct request/response modules

**Note**: The tests focus on file generation, code structure, and compilation - they do not test Elixir runtime features, only that the generated code is correct and compilable.

## Common Issues to Check

1. **Missing modules**: If a complex type in WSDL doesn't have a generated module
2. **Wrong field types**: Fields should match types specified in overrides.yml
3. **Missing nested structures**: Complex nested types should use `embeds_one`/`embeds_many`
4. **Incorrect module names**: Module names should follow Elixir naming conventions and use correct namespaces
5. **Compilation errors**: Any syntax errors or missing dependencies
6. **Wrong namespace**: Request and response modules should be in separate directories/namespaces

## Re-generating Code

If validation fails, you can regenerate the code:

```bash
mix noap.gen.code
mix compile
mix test
```

## File Structure

The generated code follows this structure:

```
lib/data_processing_service/
├── operations.ex                    # Main operations module
├── soap/
│   ├── request/                     # Request namespace modules (21 files)
│   │   ├── processing_request.ex
│   │   ├── item_data.ex
│   │   └── ...
│   └── response/                    # Response namespace modules (28 files)
│       ├── processing_response.ex
│       ├── processing_result.ex
│       └── ...
```

This structure matches the WSDL namespace separation between request (`reqns`) and response (`resns`) schemas.
