defmodule CountryInfoService.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [{Finch, name: MyFinch}]
    opts = [strategy: :one_for_one, name: CountryInfoService.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
