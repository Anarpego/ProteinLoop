defmodule ProteinLoopWeb.PageControllerTest do
  use ProteinLoopWeb.ConnCase

  alias ProteinLoop.Agent.ApprovalQueue

  setup do
    ApprovalQueue.reset()
    :ok
  end

  test "GET / renders the operator dashboard", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Operator dashboard"
    assert html_response(conn, 200) =~ "Agent harness"
    assert html_response(conn, 200) =~ "Unsafe proposal"
    assert html_response(conn, 200) =~ "RLVR trace artifact"
    assert html_response(conn, 200) =~ "Trace timeline"
    assert html_response(conn, 200) =~ "Run demo cascade"
    assert html_response(conn, 200) =~ "Model endpoint"
    assert html_response(conn, 200) =~ "Check model"
    assert html_response(conn, 200) =~ "RLVR reward verifier"
    assert html_response(conn, 200) =~ "Policy comparison"
    assert html_response(conn, 200) =~ "Policy search improvement"
    assert html_response(conn, 200) =~ "Subsystem agent topology"
    assert html_response(conn, 200) =~ "Fish tank agent"
    assert html_response(conn, 200) =~ "Freshwater prawn agent"
    assert html_response(conn, 200) =~ "Self-healing mesh"
    assert html_response(conn, 200) =~ "Simulate node loss"
    assert html_response(conn, 200) =~ "Spanish HITL approval"
    assert html_response(conn, 200) =~ "Request producer approval"
    assert html_response(conn, 200) =~ "Real Sagents runtime"
    assert html_response(conn, 200) =~ "Sagents 0.9.0"
    assert html_response(conn, 200) =~ "until_tool_success"
    assert html_response(conn, 200) =~ "Run Gemma agents"
    assert html_response(conn, 200) =~ "Anomaly forecast"
    assert html_response(conn, 200) =~ "Near-term risk"
  end

  test "GET /producer renders the Spanish HITL view", %{conn: conn} do
    conn = get(conn, ~p"/producer")
    assert html_response(conn, 200) =~ "Productor"
    assert html_response(conn, 200) =~ "Aprobar"
    assert html_response(conn, 200) =~ "Respaldo offline"
    assert html_response(conn, 200) =~ "Accion local"
    assert html_response(conn, 200) =~ "Mensaje WhatsApp/SMS"
    assert html_response(conn, 200) =~ "Responda: APROBAR, MITAD o RECHAZAR."
  end

  test "GET /producer renders pending Spanish HITL request", %{conn: conn} do
    {:ok, _request, _snapshot} = ApprovalQueue.request_irreversible_action()

    conn = get(conn, ~p"/producer")

    assert html_response(conn, 200) =~ "aprobacion pendiente"
    assert html_response(conn, 200) =~ "Cosecha"
    assert html_response(conn, 200) =~ "Solo mitad"
  end
end
