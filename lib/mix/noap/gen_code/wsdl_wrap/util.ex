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

  @spec underscore(String.t()) :: String.t()
  @doc """
  Convert from title-case to underscore.
  """
  def underscore(str) do
    # Generally just do Macro.underscore but avoid funky underscoring for things like IDC3456
    String.split(str, ~r/[A-Z]+[0-9]+/, include_captures: true, trim: true)
    |> Enum.map(fn part ->
      if Regex.match?(~r/^[A-Z]+[0-9]+$/, part) do
        String.downcase(part)
      else
        Macro.underscore(part)
      end
    end)
    |> Enum.join("_")
  end

  def convert_url_to_module(url, parent_module) do
    URI.parse(url).host
    |> String.split(".")
    |> remove_common_host_front()
    |> Enum.reverse()
    |> remove_common_host_domain()
    |> Stream.map(&:string.titlecase/1)
    |> Enum.join(".")
    |> String.replace_prefix("", "#{parent_module}.")
  end

  def to_yaml(map, indentation \\ "") do
    map
    |> Enum.map(fn {key, value} ->
      case value do
        map when map == %{} -> "#{indentation}#{key}:"
        map when is_map(map) -> "#{indentation}#{key}:\n#{to_yaml(map, "#{indentation}  ")}"
        value -> "#{indentation}#{key}: #{value}"
      end
    end)
    |> Enum.join("\n")
  end

  defp remove_common_host_front([prefix | rest]) when prefix in ~w[www], do: rest
  defp remove_common_host_front(host), do: host

  defp remove_common_host_domain([domain | rest]) when domain in @common_domains, do: rest
  defp remove_common_host_domain(host), do: host
end
