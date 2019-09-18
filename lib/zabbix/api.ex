defmodule Zabbix.API do
  @moduledoc """
  Provides simple wrapper to Zabbix API.

  ## Example usage

  ### Create client

      iex(1)> Zabbix.API.create_client("https://zabbix.example.com")
      :ok

  ### Log in

      iex(2)> Zabbix.API.login("elixir", "elixir")
      {:ok, "7959e30884cf778cbf693c66c46a382c"}

  ### Do what you want

      iex(3)> Zabbix.API.call("apiinfo.version")
      {:ok, %{"id" => 2, "jsonrpc" => "2.0", "result" => "4.2.6"}}

      iex(4)> Zabbix.API.call("host.get", %{hostids: [10001, 10042, 10069], output: ["name"]})
      {:ok,
       %{
         "id" => 3,
         "jsonrpc" => "2.0",
         "result" => [
           %{"hostid" => "10001", "name" => "ZBX-APP001"},
           %{"hostid" => "10042", "name" => "ZBX-APP042"},
           %{"hostid" => "10069", "name" => "ZBX-APP069"}
         ]
       }}

  ### Log out

      iex(5)> Zabbix.API.logout()
      {:ok, :deauthorized}
  """

  alias Zabbix.API.Client

  @doc """
  Updates session state with new client instance.

  The function will set `url` as base URL for all requests with `timeout` milliseconds timeout.

  Calling `create_client/2` will always session state.

  ## Examples

      iex> Zabbix.API.create_client("http://zabbix.example.com")
      :ok

      iex> Zabbix.API.create_client("http://example.com/zabbix", 1_000)
      :ok
  """

  def create_client(url, timeout \\ 5_000) do
    Client.create(url, timeout)
  end

  @doc """
  Performs request to Zabbix API.

  The function will perform request to specified `method` of Zabbix API with specified `params`.

  Session state must be initialized with `create_client/2` before performing requests.

  Most of methods requires authorization. You can auth with `login/2` function using login and password
  or with `login/1` using token.

  ## Examples

      iex> Zabbix.API.call("apiinfo.version")
      {:ok, %{"id" => 2, "jsonrpc" => "2.0", "result" => "4.2.6"}}

      iex> Zabbix.API.call("host.get", %{hostids: [10001, 10042, 10069], output: ["name"]})
      {:ok,
       %{
         "id" => 3,
         "jsonrpc" => "2.0",
         "result" => [
           %{"hostid" => "10001", "name" => "ZBX-APP001"},
           %{"hostid" => "10042", "name" => "ZBX-APP042"},
           %{"hostid" => "10069", "name" => "ZBX-APP069"}
         ]
       }}
  """

  def call(method, params \\ %{}) do
    Client.do_request(method, params)
  end

  @doc """
  Authorizes in Zabbix API using `user` and `password` and updates session state with granted token.

  The function will call `call/2` with `user` and `password` as parameters and store granted token in session state in
  case of successful authorization.

  ## Examples

      iex> Zabbix.API.login("elixir", "correct_password")
      {:ok, "ea22fa26bf0a446301055920bf2f25a2"}

      iex> Zabbix.API.login("elixir", "incorrect_password")
      {:error, :unauthorized}
  """

  def login(user, password) when is_binary(user) and is_binary(password) do
    with {:ok, response} <- call("user.login", %{user: user, password: password}),
         %{"result" => token} <- response,
         :ok <- Client.set_token(token) do
      {:ok, token}
    else
      {:error, error_message} -> {:error, error_message}
      _ -> {:error, :unauthorized}
    end
  end

  @doc """
  Authorizes in Zabbix API using `token` and updates session state with granted token.

  The function will call `call/2` with `token` as parameter and store granted token in session state in
  case of successful authorization.

  ## Examples

      iex> Zabbix.API.login("ea22fa26bf0a446301055920bf2f25a2")
      {:ok, "ea22fa26bf0a446301055920bf2f25a2"}

      iex> Zabbix.API.login("incorrect_token")
      {:error, :unauthorized}
  """

  def login(token) when is_binary(token) do
    with {:ok, response} <- call("user.checkAuthentication", %{sessionid: token}),
         %{"result" => auth} <- response,
         %{"sessionid" => sessionid} <- auth,
         :ok <- Client.set_token(sessionid) do
      {:ok, sessionid}
    else
      {:error, error_message} -> {:error, error_message}
      _ -> {:error, :unauthorized}
    end
  end

  @doc """
  Deauthorizes in Zabbix API and updates session state with `nil` token.

  The function will call `call/2` and store `nil` token in session state in case of successful logout.

  ## Examples

      iex> Zabbix.API.logout()
      {:ok, :deauthorized}
  """

  def logout do
    with {:ok, response} <- call("user.logout"),
         %{"result" => result} <- response,
         true <- result,
         :ok <- Client.set_token(nil) do
      {:ok, :deauthorized}
    else
      {:error, error_message} -> {:error, error_message}
      _ -> {:error, :unauthorized}
    end
  end
end
