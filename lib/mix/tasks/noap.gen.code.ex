defmodule Mix.Tasks.Noap.Gen.Code do
  use Mix.Task

  @shortdoc "Generates code to perform encoding/parsing of SOAP xml based on a WSDL"

  @switches [
    yaml_file: [:string]
  ]

  @aliases [
    y: :yaml_file
  ]

  @moduledoc """
  Generates code based on a WSDL.

  The repository will be placed in the `lib` directory.

  ## Examples

      mix noap.gen.code

  ## Command line options

    * `-y`, `--yaml_file` - dump the attributes to a YAML file for use in overrides
         to change default parsing behaviour

  """

  @recursive true
  @doc false
  def run(args) do
    case OptionParser.parse!(args, strict: @switches, aliases: @aliases) do
      # Refer to Mix.Noap.GenCode.WSDLWrap.Options for the various configuration options
      {mix_opts, []} ->
        with app_opts when is_list(app_opts) <- Application.get_env(:noap, :gen_code),
             opts when is_map(opts) <- Keyword.get(app_opts, Mix.Project.config()[:app]) do
          do_run(mix_opts, opts)
        end

      {_mix_opts, _args} ->
        Mix.shell().info("wsdl_path and parent_module must be specified")
    end
  end

  defp do_run(mix_opts, opts = %{wsdl: wsdl_path, soap_module: soap_module}) do
    type_map =
      Mix.Project.config()[:app]
      |> Noap.Type.type_map()

    wsdl_wrap = Mix.Noap.GenCode.WSDLWrap.new(wsdl_path, soap_module, opts)

    if yaml_file = mix_opts[:yaml_file] do
      Mix.Noap.GenCode.WSDLWrap.YAML.yamlize(wsdl_wrap, yaml_file)
    else
      Mix.Noap.GenCode.WSDLWrap.CreateCode.create_code(wsdl_wrap, type_map, opts)
    end
  end

  defp do_run(mix_opts, opts) do
    Mix.shell().info("wsdl_path and soap_module must be specified")
  end
end
