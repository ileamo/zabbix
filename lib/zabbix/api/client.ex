defmodule Zabbix.API.Client do
  @moduledoc """
  Provides an agent for storing session state and implements related functions.
  """

  use Agent

  @endpoint "/api_jsonrpc.php"

  def start_link(_) do
    Agent.start_link(&init/0, name: __MODULE__)
  end

  defp init() do
    %{client: nil, token: nil, id: 1}
  end

  defp init(_, %Tesla.Client{} = client) do
    %{client: client, token: nil, id: 1}
  end

  defp fetch(key) when is_atom(key) do
    case key do
      :id ->
        Agent.get_and_update(__MODULE__, fn data -> {data, %{data | id: data.id + 1}} end)
        |> Map.fetch!(:id)

      _ ->
        Agent.get(__MODULE__, & &1)
        |> Map.fetch!(key)
    end
  end

  defp update(key, value) when is_atom(key) do
    Agent.update(__MODULE__, fn state -> %{state | key => value} end)
  end

  @doc """
  Updates token in session state with new `value`.

  Used internally in login helpers functions, e.g., `Zabbix.API.login/2`.
  """

  def set_token(value) do
    update(:token, value)
  end

  @doc """
  Updates session state with new client instance.

  The function will set `url` as base URL for all requests with `timeout` milliseconds timeout.

  Calling `create/2` will always session state.

  Used internally by `Zabbix.API.create_client/2`.
  """

  def create(url, timeout \\ 5_000) do
    middleware = [Tesla.Middleware.JSON]
    middleware = [{Tesla.Middleware.BaseUrl, url} | middleware]
    middleware = [{Tesla.Middleware.Headers, [{"user-agent", "elixir/zabbix"}]} | middleware]
    middleware = [{Tesla.Middleware.Timeout, timeout: timeout} | middleware]
    #    middleware = [Tesla.Middleware.Logger | middleware]
    adapter = {Tesla.Adapter.Hackney, [recv_timeout: timeout + 1_000]}
    client = Tesla.client(middleware, adapter)
    Agent.update(__MODULE__, &init(&1, client))
  end

  @doc """
  Performs request to Zabbix API.

  The function will construct and perform request to specified `method` of Zabbix API with specified `params`.

  Used internally by `Zabbix.API.call/2`.
  """

  def do_request(method, params) do
    with client <- fetch(:client),
         {:ok, client} <- check_client(client),
         {:ok, request} <- prepare_request(method, params),
         {:ok, response} <- Tesla.post(client, @endpoint, request),
         :ok <- check_status(response) do
      {:ok, response.body}
    end
  end

  defp prepare_request(method, params) when method == "apiinfo.version" do
    prepare_request(method, params, nil)
  end

  defp prepare_request(method, params) when method == "user.login" do
    prepare_request(method, params, nil)
  end

  defp prepare_request(method, params) when method == "user.checkAuthentication" do
    prepare_request(method, params, nil)
  end

  defp prepare_request(method, params) do
    prepare_request(method, params, fetch(:token))
  end

  defp prepare_request(method, params, token) do
    {:ok,
     %{
       id: fetch(:id),
       auth: token,
       method: method,
       params: params,
       jsonrpc: "2.0"
     }}
  end

  defp check_client(client) do
    case client do
      %Tesla.Client{} -> {:ok, client}
      _ -> {:error, {:badclient, client}}
    end
  end

  defp check_status(response) do
    case response.status do
      200 -> :ok
      status -> {:error, {:badstatus, status}}
    end
  end
end
