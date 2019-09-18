defmodule Zabbix.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [{Zabbix.API.Client, []}]
    opts = [strategy: :one_for_one, name: Zabbix.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
