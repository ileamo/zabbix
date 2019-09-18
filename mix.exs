defmodule Zabbix.MixProject do
  use Mix.Project

  def project do
    [
      app: :zabbix,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      name: "Zabbix",
      description: description(),
      package: package(),
      source_url: "https://github.com/abanichev/zabbix",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Zabbix.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.1"},
      {:hackney, "~> 1.15.1"},
      {:tesla, "~> 1.2.1"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Simple Elixir wrapper for the Zabbix API.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/abanichev/zabbix"}
    ]
  end
end
