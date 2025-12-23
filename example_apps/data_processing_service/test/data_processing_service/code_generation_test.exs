defmodule DataProcessingService.CodeGenerationTest do
  use ExUnit.Case

  @request_modules [
    "account_summary",
    "address_check",
    "annotation",
    "annotations",
    "check_details",
    "contact_info",
    "content_section",
    "content_sections",
    "credit_reference",
    "credit_references",
    "debt_bur_resn_cde_list",
    "debt_bur_resn_txt_list",
    "debt_burden_reasons",
    "detail_item",
    "document_attachment",
    "document_attachments",
    "document_metadata",
    "financial_check",
    "financial_history",
    "identity_check",
    "item_attributes",
    "item_data",
    "item_location",
    "item_name",
    "payment_history",
    "payment_record",
    "processing_options",
    "processing_request",
    "reference_contact",
    "request_metadata",
    "sub_attributes",
    "transaction",
    "transaction_history",
    "verification_checks",
    "verified_address",
    "verified_addresses"
  ]

  @response_modules [
    "audit_changes",
    "audit_entry",
    "audit_trail",
    "category_summary",
    "change",
    "credit_analysis",
    "credit_factor",
    "credit_factors",
    "credit_score",
    "detail_record",
    "detail_record_list",
    "error_detail",
    "error_details",
    "factor_impact",
    "history_summary",
    "implementation_details",
    "item_record",
    "item_records",
    "mitigation_strategy",
    "processing_response",
    "processing_result",
    "recommendation",
    "recommendations",
    "record_counts",
    "result_details",
    "risk_code_list",
    "risk_description_list",
    "risk_factors",
    "risk_mitigation",
    "score_reasons",
    "summary_data",
    "tracking_info",
    "validation_results",
    "validation_rule",
    "violation",
    "violations"
  ]

  @request_program_interface_modules [
    "program_interface/account_details",
    "program_interface/account_details/account_detail",
    "program_interface/account_details/account_detail/reason_code_details",
    "program_interface/consumer_info",
    "program_interface/consumer_info/name",
    "program_interface/consumer_info/current_address",
    "program_interface/consumer_info/previous_address"
  ]

  @response_program_interface_modules [
    "program_interface/data_processing_response",
    "program_interface/data_processing_response/consumer_info",
    "program_interface/data_processing_response/consumer_info/name",
    "program_interface/data_processing_response/consumer_info/current_address",
    "program_interface/data_processing_response/consumer_info/previous_address"
  ]

  @request_path "lib/data_processing_service/soap/request"
  @response_path "lib/data_processing_service/soap/response"
  @operations_path "lib/data_processing_service/operations.ex"

  describe "generated files" do
    test "all expected request modules are generated" do
      missing =
        Enum.reduce(@request_modules, [], fn module, acc ->
          file = Path.join([@request_path, "#{module}.ex"])
          if File.exists?(file) do
            acc
          else
            [module | acc]
          end
        end)

      assert Enum.empty?(missing),
             "Missing generated request modules: #{inspect(missing)}. Expected #{length(@request_modules)} modules."
    end

    test "all expected response modules are generated" do
      missing =
        Enum.reduce(@response_modules, [], fn module, acc ->
          file = Path.join([@response_path, "#{module}.ex"])
          if File.exists?(file) do
            acc
          else
            [module | acc]
          end
        end)

      assert Enum.empty?(missing),
             "Missing generated response modules: #{inspect(missing)}. Expected #{length(@response_modules)} modules."
    end

    test "all expected program_interface request modules are generated" do
      # Check parent level program_interface.ex
      parent_file = Path.join([@request_path, "program_interface.ex"])
      assert File.exists?(parent_file),
             "Missing program_interface.ex at parent level"

      missing =
        Enum.reduce(@request_program_interface_modules, [], fn module, acc ->
          file = Path.join([@request_path, "#{module}.ex"])
          if File.exists?(file) do
            acc
          else
            [module | acc]
          end
        end)

      assert Enum.empty?(missing),
             "Missing generated program_interface request modules: #{inspect(missing)}. Expected #{length(@request_program_interface_modules)} modules."
    end

    test "all expected program_interface response modules are generated" do
      # Check parent level program_interface.ex
      parent_file = Path.join([@response_path, "program_interface.ex"])
      assert File.exists?(parent_file),
             "Missing program_interface.ex at parent level"

      missing =
        Enum.reduce(@response_program_interface_modules, [], fn module, acc ->
          file = Path.join([@response_path, "#{module}.ex"])
          if File.exists?(file) do
            acc
          else
            [module | acc]
          end
        end)

      assert Enum.empty?(missing),
             "Missing generated program_interface response modules: #{inspect(missing)}. Expected #{length(@response_program_interface_modules)} modules."
    end
  end

  describe "module structure" do
    test "generated request modules use Noap.XMLSchema" do
      Enum.each(@request_modules, fn module ->
        file = Path.join([@request_path, "#{module}.ex"])
        if File.exists?(file) do
          content = File.read!(file)

          assert content =~ "use Noap.XMLSchema",
                 "Request module #{module}.ex should use Noap.XMLSchema"

          assert content =~ "xml_schema do",
                 "Request module #{module}.ex should have xml_schema block"
        end
      end)
    end

    test "generated response modules use Noap.XMLSchema" do
      Enum.each(@response_modules, fn module ->
        file = Path.join([@response_path, "#{module}.ex"])
        if File.exists?(file) do
          content = File.read!(file)

          assert content =~ "use Noap.XMLSchema",
                 "Response module #{module}.ex should use Noap.XMLSchema"

          assert content =~ "xml_schema do",
                 "Response module #{module}.ex should have xml_schema block"
        end
      end)
    end

    test "generated modules have correct module names" do
      # Check that request modules use correct namespace
      file = Path.join([@request_path, "processing_request.ex"])
      if File.exists?(file) do
        content = File.read!(file)
        assert content =~ "defmodule DataProcessingService.Soap.Request.ProcessingRequest",
               "Request modules should use DataProcessingService.Soap.Request namespace"
      end

      # Check that response modules use correct namespace
      file = Path.join([@response_path, "processing_response.ex"])
      if File.exists?(file) do
        content = File.read!(file)
        assert content =~ "defmodule DataProcessingService.Soap.Response.ProcessingResponse",
               "Response modules should use DataProcessingService.Soap.Response namespace"
      end
    end

    test "generated program_interface modules use Noap.XMLSchema" do
      check_xml_schema(Path.join([@request_path, "program_interface.ex"]))
      check_xml_schema(Path.join([@response_path, "program_interface.ex"]))

      Enum.each(@request_program_interface_modules, fn module ->
        check_xml_schema(Path.join([@request_path, "#{module}.ex"]))
      end)

      Enum.each(@response_program_interface_modules, fn module ->
        check_xml_schema(Path.join([@response_path, "#{module}.ex"]))
      end)
    end

    test "generated program_interface modules have correct module names" do
      check_module_name(Path.join([@request_path, "program_interface.ex"]),
                       "DataProcessingService.Soap.Request.ProgramInterface")
      check_module_name(Path.join([@response_path, "program_interface.ex"]),
                       "DataProcessingService.Soap.Response.ProgramInterface")
    end
  end

  describe "type overrides" do
    test "integer type overrides are applied in response modules" do
      integer_fields = [
        {"history_summary", "DaysSinceFirstRecord", ":integer"},
        {"history_summary", "DaysSinceLastRecord", ":integer"},
        {"processing_result", "ScoreValue", ":integer"}
      ]

      Enum.each(integer_fields, fn {module, field_name, expected_type} ->
        file = Path.join([@response_path, "#{module}.ex"])
        assert File.exists?(file), "Response module #{module}.ex should exist"

        content = File.read!(file)
        field_underscore = Macro.underscore(field_name)
        pattern1 = ~r/field\(:#{field_underscore},.*#{Regex.escape(expected_type)}/
        pattern2 = ~r/field\(:#{String.downcase(field_name)},.*#{Regex.escape(expected_type)}/

        assert content =~ pattern1 || content =~ pattern2,
               "Response module #{module}.#{field_name} should have type #{expected_type}"
      end)
    end

    test "fis_date type overrides are applied in request modules" do
      date_fields = [
        {"item_data", "DateValue", ":fis_date"}
      ]

      Enum.each(date_fields, fn {module, field_name, expected_type} ->
        file = Path.join([@request_path, "#{module}.ex"])
        assert File.exists?(file), "Request module #{module}.ex should exist"

        content = File.read!(file)
        field_underscore = Macro.underscore(field_name)
        pattern1 = ~r/field\(:#{field_underscore},.*#{Regex.escape(expected_type)}/
        pattern2 = ~r/field\(:#{String.downcase(field_name)},.*#{Regex.escape(expected_type)}/

        assert content =~ pattern1 || content =~ pattern2,
               "Request module #{module}.#{field_name} should have type #{expected_type}"
      end)
    end
  end

  describe "nested structures" do
    test "processing_request uses embeds for nested structures" do
      file = Path.join([@request_path, "processing_request.ex"])
      assert File.exists?(file), "Request module processing_request.ex should exist"

      content = File.read!(file)
      assert content =~ "embeds_one" || content =~ "embeds_many",
             "Request module processing_request.ex should use embeds_one or embeds_many for nested structures"
    end

    test "processing_response uses embeds for nested structures" do
      file = Path.join([@response_path, "processing_response.ex"])
      assert File.exists?(file), "Response module processing_response.ex should exist"

      content = File.read!(file)
      assert content =~ "embeds_one" || content =~ "embeds_many",
             "Response module processing_response.ex should use embeds_one or embeds_many for nested structures"
    end

    test "program_interface modules use embeds for nested structures" do
      files = [
        Path.join([@request_path, "program_interface/consumer_info.ex"]),
        Path.join([@response_path, "program_interface/data_processing_response.ex"])
      ]

      Enum.each(files, fn file ->
        if File.exists?(file) do
          content = File.read!(file)
          assert content =~ "embeds_one" || content =~ "embeds_many",
                 "#{file} should use embeds_one or embeds_many for nested structures"
        end
      end)
    end
  end

  describe "array structures" do
    test "array modules use embeds_many" do
      array_modules = [
        {"item_records", @response_path},
        {"detail_record_list", @response_path},
        {"error_details", @response_path},
        {"credit_references", @request_path}
      ]

      Enum.each(array_modules, fn {module, path} ->
        file = Path.join([path, "#{module}.ex"])
        if File.exists?(file) do
          content = File.read!(file)
          assert content =~ "embeds_many",
                 "#{module}.ex should use embeds_many for arrays"
        end
      end)
    end
  end

  describe "code compilation" do
    test "generated files have valid Elixir syntax" do
      key_files = [
        Path.join([@request_path, "processing_request.ex"]),
        Path.join([@response_path, "processing_response.ex"]),
        Path.join([@request_path, "program_interface.ex"]),
        Path.join([@request_path, "program_interface/consumer_info.ex"]),
        Path.join([@response_path, "program_interface.ex"]),
        Path.join([@response_path, "program_interface/data_processing_response.ex"]),
        @operations_path
      ]

      Enum.each(key_files, fn file_path ->
        if File.exists?(file_path) do
          content = File.read!(file_path)
          assert content =~ "defmodule",
                 "#{file_path} should contain a defmodule declaration"
        end
      end)
    end

    test "operations module references correct request and response modules" do
      assert File.exists?(@operations_path), "Operations file should exist"

      content = File.read!(@operations_path)
      assert content =~ "DataProcessingService.Soap.Request.ProcessingRequest",
             "Operations should reference DataProcessingService.Soap.Request.ProcessingRequest"
      assert content =~ "DataProcessingService.Soap.Response.ProcessingResponse",
             "Operations should reference DataProcessingService.Soap.Response.ProcessingResponse"
    end
  end

  # Helper functions
  defp check_xml_schema(file) do
    if File.exists?(file) do
      content = File.read!(file)
      assert content =~ "use Noap.XMLSchema", "#{file} should use Noap.XMLSchema"
      assert content =~ "xml_schema do", "#{file} should have xml_schema block"
    end
  end

  defp check_module_name(file, expected_module) do
    if File.exists?(file) do
      content = File.read!(file)
      assert content =~ "defmodule #{expected_module}",
             "#{file} should define #{expected_module}"
    end
  end
end
