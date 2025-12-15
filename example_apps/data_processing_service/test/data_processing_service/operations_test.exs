defmodule DataProcessingService.OperationsTest do
  use ExUnit.Case
  doctest DataProcessingService.Operations

  @request_base "lib/data_processing_service/soap/request"
  @response_base "lib/data_processing_service/soap/response"

  describe "operations module" do
    test "operations module exports operation info functions" do
      assert function_exported?(DataProcessingService.Operations, :process_data, 0)
    end

    test "operations module exports call functions with parameters" do
      assert function_exported?(DataProcessingService.Operations, :call_process_data, 2)
    end
  end

  describe "program_interface modules" do
    @request_modules [
      "account_details.ex",
      "account_details/account_detail.ex",
      "account_details/account_detail/reason_code_details.ex",
      "consumer_info.ex",
      "consumer_info/name.ex",
      "consumer_info/current_address.ex",
      "consumer_info/previous_address.ex"
    ]

    @response_modules [
      "data_processing_response.ex",
      "data_processing_response/consumer_info.ex",
      "data_processing_response/consumer_info/name.ex",
      "data_processing_response/consumer_info/current_address.ex",
      "data_processing_response/consumer_info/previous_address.ex"
    ]

    test "all program_interface modules are generated" do
      assert_file_exists(Path.join([@request_base, "program_interface.ex"]))
      assert_file_exists(Path.join([@response_base, "program_interface.ex"]))

      assert_all_files_exist(@request_modules, Path.join([@request_base, "program_interface"]))
      assert_all_files_exist(@response_modules, Path.join([@response_base, "program_interface"]))
    end

    test "program_interface modules use Noap.XMLSchema" do
      assert_uses_xml_schema(Path.join([@request_base, "program_interface.ex"]))
      assert_uses_xml_schema(Path.join([@response_base, "program_interface.ex"]))

      assert_modules_use_xml_schema(@request_modules, Path.join([@request_base, "program_interface"]))
      assert_modules_use_xml_schema(@response_modules, Path.join([@response_base, "program_interface"]))
    end

    test "program_interface modules have correct module names" do
      assert_module_name(Path.join([@request_base, "program_interface.ex"]),
                        "DataProcessingService.Soap.Request.ProgramInterface")
      assert_module_name(Path.join([@response_base, "program_interface.ex"]),
                        "DataProcessingService.Soap.Response.ProgramInterface")
    end
  end

  describe "program_interface nested structures" do
    test "modules use embeds for nested structures" do
      files = [
        Path.join([@request_base, "program_interface/consumer_info.ex"]),
        Path.join([@request_base, "program_interface/account_details.ex"]),
        Path.join([@response_base, "program_interface/data_processing_response.ex"])
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

  describe "all files and directories validation" do
    @all_request_files [
      "account_summary.ex",
      "address_check.ex",
      "annotation.ex",
      "annotations.ex",
      "check_details.ex",
      "contact_info.ex",
      "content_section.ex",
      "content_sections.ex",
      "credit_reference.ex",
      "credit_references.ex",
      "debt_bur_resn_cde_list.ex",
      "debt_bur_resn_txt_list.ex",
      "debt_burden_reasons.ex",
      "detail_item.ex",
      "document_attachment.ex",
      "document_attachments.ex",
      "document_metadata.ex",
      "financial_check.ex",
      "financial_history.ex",
      "identity_check.ex",
      "item_attributes.ex",
      "item_data.ex",
      "item_location.ex",
      "item_name.ex",
      "payment_history.ex",
      "payment_record.ex",
      "processing_options.ex",
      "processing_request.ex",
      "program_interface.ex",
      "program_interface/account_details.ex",
      "program_interface/account_details/account_detail.ex",
      "program_interface/account_details/account_detail/reason_code_details.ex",
      "program_interface/consumer_info.ex",
      "program_interface/consumer_info/name.ex",
      "program_interface/consumer_info/current_address.ex",
      "program_interface/consumer_info/previous_address.ex",
      "reference_contact.ex",
      "request_metadata.ex",
      "sub_attributes.ex",
      "transaction.ex",
      "transaction_history.ex",
      "verification_checks.ex",
      "verified_address.ex",
      "verified_addresses.ex"
    ]

    @all_response_files [
      "audit_changes.ex",
      "audit_entry.ex",
      "audit_trail.ex",
      "category_summary.ex",
      "change.ex",
      "credit_analysis.ex",
      "credit_factor.ex",
      "credit_factors.ex",
      "credit_score.ex",
      "detail_record.ex",
      "detail_record_list.ex",
      "error_detail.ex",
      "error_details.ex",
      "factor_impact.ex",
      "history_summary.ex",
      "implementation_details.ex",
      "item_record.ex",
      "item_records.ex",
      "mitigation_strategy.ex",
      "processing_response.ex",
      "processing_result.ex",
      "program_interface.ex",
      "program_interface/data_processing_response.ex",
      "program_interface/data_processing_response/consumer_info.ex",
      "program_interface/data_processing_response/consumer_info/name.ex",
      "program_interface/data_processing_response/consumer_info/current_address.ex",
      "program_interface/data_processing_response/consumer_info/previous_address.ex",
      "recommendation.ex",
      "recommendations.ex",
      "record_counts.ex",
      "result_details.ex",
      "risk_code_list.ex",
      "risk_description_list.ex",
      "risk_factors.ex",
      "risk_mitigation.ex",
      "score_reasons.ex",
      "summary_data.ex",
      "tracking_info.ex",
      "validation_results.ex",
      "validation_rule.ex",
      "violation.ex",
      "violations.ex"
    ]

    test "all request files exist exactly once" do
      # Check all expected files exist
      missing = check_missing_files(@all_request_files, @request_base)
      assert Enum.empty?(missing), "Missing request files: #{inspect(missing)}"

      # Check top-level directory
      check_extra_files(@request_base, @all_request_files, "", 37, "request")

      # Check nested directories
      check_nested_dir(@request_base, "program_interface", @all_request_files, 2, 2)
      check_nested_dir(@request_base, "program_interface/account_details", @all_request_files, nil, nil)
      check_nested_dir(@request_base, "program_interface/account_details/account_detail", @all_request_files, nil, nil)
      check_nested_dir(@request_base, "program_interface/consumer_info", @all_request_files, nil, nil)
    end

    test "all response files exist exactly once" do
      # Check all expected files exist
      missing = check_missing_files(@all_response_files, @response_base)
      assert Enum.empty?(missing), "Missing response files: #{inspect(missing)}"

      # Check top-level directory
      check_extra_files(@response_base, @all_response_files, "", 37, "response")

      # Check nested directories
      check_nested_dir(@response_base, "program_interface", @all_response_files, 1, 1)
      check_nested_dir(@response_base, "program_interface/data_processing_response", @all_response_files, nil, nil)
      check_nested_dir(@response_base, "program_interface/data_processing_response/consumer_info", @all_response_files, nil, nil)
    end
  end

  # Helper functions
  defp assert_file_exists(file) do
    assert File.exists?(file), "Missing file: #{file}"
  end

  defp assert_all_files_exist(modules, base_path) do
    missing =
      Enum.reduce(modules, [], fn module, acc ->
        file = Path.join([base_path, module])
        if File.exists?(file), do: acc, else: [module | acc]
      end)

    assert Enum.empty?(missing), "Missing files: #{inspect(missing)}"
  end

  defp assert_uses_xml_schema(file) do
    if File.exists?(file) do
      content = File.read!(file)
      assert content =~ "use Noap.XMLSchema", "#{file} should use Noap.XMLSchema"
      assert content =~ "xml_schema do", "#{file} should have xml_schema block"
    end
  end

  defp assert_modules_use_xml_schema(modules, base_path) do
    Enum.each(modules, fn module ->
      file = Path.join([base_path, module])
      assert_uses_xml_schema(file)
    end)
  end

  defp assert_module_name(file, expected_module) do
    if File.exists?(file) do
      content = File.read!(file)
      assert content =~ "defmodule #{expected_module}",
             "#{file} should define #{expected_module}"
    end
  end

  # Helper functions for file validation
  defp check_missing_files(expected_files, base_path) do
    Enum.reduce(expected_files, [], fn file, acc ->
      path = Path.join([base_path, file])
      if File.exists?(path), do: acc, else: [file | acc]
    end)
  end

  defp check_extra_files(base_path, expected_files, prefix, expected_count, type) do
    dir_path = if prefix == "", do: base_path, else: Path.join([base_path, prefix])
    if File.exists?(dir_path) do
      actual_files = dir_path |> Path.expand() |> File.ls!() |> Enum.filter(&String.ends_with?(&1, ".ex"))
      expected_in_dir = if prefix == "" do
        Enum.filter(expected_files, fn f -> not String.contains?(f, "/") end)
      else
        Enum.filter(expected_files, fn f ->
          String.starts_with?(f, "#{prefix}/") and
          not String.contains?(String.replace_prefix(f, "#{prefix}/", ""), "/")
        end) |> Enum.map(&String.replace_prefix(&1, "#{prefix}/", ""))
      end
      extra = actual_files -- expected_in_dir
      assert Enum.empty?(extra), "Unexpected #{type} files in #{prefix || "top-level"} directory: #{inspect(extra)}"
      if expected_count do
        assert length(actual_files) == expected_count, "Expected #{expected_count} files in #{prefix || "top-level"} #{type} directory, found #{length(actual_files)}: #{inspect(actual_files)}"
      end
    end
  end

  defp check_nested_dir(base_path, dir_path, expected_files, expected_file_count, expected_dir_count) do
    full_dir = Path.join([base_path, dir_path])
    if File.exists?(full_dir) do
      files = full_dir |> Path.expand() |> File.ls!() |> Enum.filter(&String.ends_with?(&1, ".ex"))
      dirs = full_dir |> Path.expand() |> File.ls!() |> Enum.reject(&String.ends_with?(&1, ".ex"))
      expected_files_in_dir = Enum.filter(expected_files, fn f ->
        String.starts_with?(f, "#{dir_path}/") and
        not String.contains?(String.replace_prefix(f, "#{dir_path}/", ""), "/")
      end) |> Enum.map(&String.replace_prefix(&1, "#{dir_path}/", ""))
      extra = files -- expected_files_in_dir
      assert Enum.empty?(extra), "Unexpected files in #{dir_path}: #{inspect(extra)}"
      if expected_file_count do
        assert length(files) == expected_file_count, "Expected #{expected_file_count} files in #{dir_path}, found #{length(files)}: #{inspect(files)}"
      end
      if expected_dir_count do
        assert length(dirs) == expected_dir_count, "Expected #{expected_dir_count} directories in #{dir_path}, found #{length(dirs)}: #{inspect(dirs)}"
      end
    end
  end
end
