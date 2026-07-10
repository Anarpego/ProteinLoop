defmodule ProteinLoopWeb.HordeController do
  use ProteinLoopWeb, :controller

  import Plug.Conn

  plug :authorize_demo

  def status(conn, _params) do
    json(conn, runtime().cluster_status())
  end

  def create(conn, params) do
    options =
      []
      |> maybe_put(:agent_id, params["agent_id"])
      |> maybe_put(:state_token, params["state_token"])

    case runtime().start_probe(options) do
      {:ok, snapshot} -> conn |> put_status(:created) |> json(snapshot)
      {:error, :horde_not_enabled} -> error(conn, :conflict, "horde_not_enabled")
      {:error, reason} -> error(conn, :unprocessable_entity, inspect(reason))
    end
  end

  def show(conn, %{"id" => agent_id}) do
    case runtime().snapshot(agent_id) do
      {:ok, snapshot} -> json(conn, snapshot)
      {:error, :not_found} -> error(conn, :not_found, "probe_not_found")
      {:error, reason} -> error(conn, :service_unavailable, inspect(reason))
    end
  end

  def delete(conn, %{"id" => agent_id}) do
    case runtime().delete_probe(agent_id) do
      :ok -> send_resp(conn, :no_content, "")
      {:error, reason} -> error(conn, :unprocessable_entity, inspect(reason))
    end
  end

  defp authorize_demo(conn, _opts) do
    expected =
      Application.get_env(:proteinloop, :horde_demo_token) ||
        System.get_env("HORDE_DEMO_TOKEN")

    cond do
      not is_binary(expected) or expected == "" ->
        conn |> send_resp(:not_found, "Not Found") |> halt()

      authorized?(conn, expected) ->
        conn

      true ->
        conn |> error(:unauthorized, "unauthorized") |> halt()
    end
  end

  defp authorized?(conn, expected) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> supplied] when byte_size(supplied) == byte_size(expected) ->
        Plug.Crypto.secure_compare(supplied, expected)

      _other ->
        false
    end
  end

  defp maybe_put(options, _key, value) when value in [nil, ""], do: options
  defp maybe_put(options, key, value), do: Keyword.put(options, key, value)

  defp runtime do
    Application.get_env(:proteinloop, :horde_runtime, ProteinLoop.Agent.HordeRuntime)
  end

  defp error(conn, status, message) do
    conn |> put_status(status) |> json(%{error: message})
  end
end
