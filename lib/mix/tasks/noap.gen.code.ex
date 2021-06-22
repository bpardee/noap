defmodule Mix.Tasks.Noap.Gen.Code do
  use Mix.Task

  @shortdoc "Generates code to perform encoding/parsing of SOAP xml based on a WSDL"

  @switches [
    schema_module: [:string, :keep],
    overrides_file: [:string]
  ]

  @aliases [
    s: :schema_module,
    o: :overrides_file
  ]

  @moduledoc """
  Generates code based on a WSDL.

  The repository will be placed in the `lib` directory.

  ## Examples

      mix noap.gen.code TBD

  ## Command line options

    * `-s`, `--schema_module` - name of the schema module that will override the one automatically used based on the namespace url
    * `-o`, `--overrides_file` - yml file that contains type overrides, etc to override default parsing behaviour

  """

  @recursive true
  @doc false
  def run([]) do
    with app_args when is_list(app_args) <- Application.get_env(:noap, :gen_code),
         args when is_list(args) <- Keyword.get(app_args, Mix.Project.config()[:app]) do
      run(args)
    end
  end

  def run(args) do
    IO.inspect(args, label: :args)

    case OptionParser.parse!(args, strict: @switches, aliases: @aliases) do
      {opts, [wsdl_path, parent_module]} ->
        type_map =
          Mix.Project.config()[:app]
          |> Noap.Type.type_map()

        Mix.Noap.GenCode.WSDLWrap.new(wsdl_path, parent_module, opts)
        |> Mix.Noap.GenCode.WSDLWrap.CreateCode.create_code(type_map, opts)

        Mix.shell().info("""
        Don't forget to add your new repo to your supervision tree
        """)

      {_opts, _args} ->
        Mix.shell().info("wsdl_path and parent_module must be specified")
    end
  end
end
