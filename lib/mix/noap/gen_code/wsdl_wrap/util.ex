defmodule Mix.Noap.GenCode.WSDLWrap.Util do
  @common_domains ~w[com org biz mil edu gov net int]

  def get_module_dir(module) do
    dir =
      [
        "lib"
        | module
          |> String.split(".")
          |> Enum.map(&underscore/1)
      ]
      |> Path.join()

    File.mkdir_p!(dir)
    dir
  end

  def charlist_to_string(nil), do: nil
  def charlist_to_string(cl), do: to_string(cl)

  def titleize(str) do
    str
    |> String.split("_")
    |> Stream.map(&:string.titlecase/1)
    |> Enum.join()
  end

  def underscore(str) do
    if Regex.match?(~r/^[A-Z]+[0-9]+$/, str) do
      String.downcase(str)
    else
      Macro.underscore(str)
    end
  end

  def convert_url_to_module(url, parent_module, module_dir) do
    split_host =
      URI.parse(url).host
      |> String.split(".")
      |> remove_common_host_front()
      |> Enum.reverse()
      |> remove_common_host_domain()

    postfix =
      split_host
      |> Stream.map(&:string.titlecase/1)
      |> Enum.join(".")

    reldir =
      split_host
      |> Enum.map(&underscore/1)
      |> Path.join()

    dir = Path.join(module_dir, reldir)
    File.mkdir_p!(dir)

    {"#{parent_module}.#{postfix}", dir}
  end

  defp remove_common_host_front([prefix | rest]) when prefix in ~w[www], do: rest
  defp remove_common_host_front(host), do: host

  defp remove_common_host_domain([domain | rest]) when domain in @common_domains, do: rest
  defp remove_common_host_domain(host), do: host
end
