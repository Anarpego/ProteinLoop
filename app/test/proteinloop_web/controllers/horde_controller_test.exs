defmodule ProteinLoopWeb.HordeControllerTest do
  use ProteinLoopWeb.ConnCase, async: false

  setup do
    previous_token = Application.get_env(:proteinloop, :horde_demo_token)
    previous_runtime = Application.get_env(:proteinloop, :horde_runtime)
    previous_owner = Application.get_env(:proteinloop, :test_horde_owner)

    Application.put_env(:proteinloop, :horde_runtime, ProteinLoop.TestHordeRuntime)
    Application.put_env(:proteinloop, :test_horde_owner, self())

    on_exit(fn ->
      restore_env(:horde_demo_token, previous_token)
      restore_env(:horde_runtime, previous_runtime)
      restore_env(:test_horde_owner, previous_owner)
    end)

    :ok
  end

  test "Horde API is unavailable without an explicit demo token", %{conn: conn} do
    Application.delete_env(:proteinloop, :horde_demo_token)

    conn = get(conn, "/api/horde/status")

    assert response(conn, 404)
  end

  test "Horde API rejects an incorrect token", %{conn: conn} do
    Application.put_env(:proteinloop, :horde_demo_token, "correct-token")

    conn =
      conn
      |> put_req_header("authorization", "Bearer wrong-token")
      |> get("/api/horde/status")

    assert json_response(conn, 401) == %{"error" => "unauthorized"}
  end

  test "authorized API starts, inspects, and deletes a managed probe", %{conn: conn} do
    Application.put_env(:proteinloop, :horde_demo_token, "correct-token")
    conn = put_req_header(conn, "authorization", "Bearer correct-token")

    status_conn = get(conn, "/api/horde/status")
    assert json_response(status_conn, 200)["distribution"] == "horde"

    start_conn =
      post(conn, "/api/horde/probes", %{
        "agent_id" => "probe-api",
        "state_token" => "token-api"
      })

    assert json_response(start_conn, 201)["state_fingerprint"] == "fingerprint-api"
    assert_receive {:start_probe, options}
    assert options[:agent_id] == "probe-api"
    assert options[:state_token] == "token-api"

    snapshot_conn = get(conn, "/api/horde/probes/probe-api")
    assert json_response(snapshot_conn, 200)["owner_node"] == "proteinloop_peer@peer"
    assert_receive {:snapshot, "probe-api"}

    delete_conn = delete(conn, "/api/horde/probes/probe-api")
    assert response(delete_conn, 204)
    assert_receive {:delete_probe, "probe-api"}
  end

  defp restore_env(key, nil), do: Application.delete_env(:proteinloop, key)
  defp restore_env(key, value), do: Application.put_env(:proteinloop, key, value)
end
