defmodule ProteinLoopWeb.PageControllerTest do
  use ProteinLoopWeb.ConnCase

  alias ProteinLoop.Agent.ApprovalQueue

  setup do
    ApprovalQueue.reset()
    :ok
  end

  test "GET / renders the guided operator control", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ ~r/<html[^>]*lang="en"[^>]*data-theme="light"/
    assert html_response(conn, 200) =~ ~s(<meta name="color-scheme" content="light")
    refute html_response(conn, 200) =~ "prefers-color-scheme"
    assert html_response(conn, 200) =~ "ProteinLoop system control"
    assert html_response(conn, 200) =~ "Live tank simulation"
    assert html_response(conn, 200) =~ "Ask the AI team to help"
    assert html_response(conn, 200) =~ "Advanced evidence and controls"
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
    assert html_response(conn, 200) =~ "Real Sagents/Horde cluster"
    assert html_response(conn, 200) =~ "Deterministic failover rehearsal"
    assert html_response(conn, 200) =~ "Simulate node loss"
    assert html_response(conn, 200) =~ "Human approval"
    assert html_response(conn, 200) =~ "Request producer approval"
    assert html_response(conn, 200) =~ "Ask the AI team to help"
    assert html_response(conn, 200) =~ "Sagents 0.9.0"
    assert html_response(conn, 200) =~ "until_tool_success"
    assert html_response(conn, 200) =~ "Ask AI team for a safe plan"
    assert html_response(conn, 200) =~ "Anomaly forecast"
    assert html_response(conn, 200) =~ "Near-term risk"
  end

  test "CSS contains no dark theme definition" do
    css = File.read!(Path.expand("../../../assets/css/app.css", __DIR__))

    refute css =~ ~s(name: "dark")
    refute css =~ "prefersdark: true"
  end

  test "frontend pins and registers the real-time Three.js tank" do
    assets = Path.expand("../../../assets", __DIR__)
    package = assets |> Path.join("package.json") |> File.read!() |> Jason.decode!()
    app_js = assets |> Path.join("js/app.js") |> File.read!()
    tank_hook = assets |> Path.join("js/hooks/realtime_tank.js") |> File.read!()

    assert package["dependencies"]["three"] == "0.185.1"
    assert app_js =~ "RealtimeTank"
    assert tank_hook =~ "setAnimationLoop"
    assert tank_hook =~ "ResizeObserver"
  end

  test "GET /producer renders the English HITL view", %{conn: conn} do
    conn = get(conn, ~p"/producer")
    assert html_response(conn, 200) =~ "Producer decisions"
    assert html_response(conn, 200) =~ "Approve"
    assert html_response(conn, 200) =~ "Offline fallback"
    assert html_response(conn, 200) =~ "Local action"
    assert html_response(conn, 200) =~ "WhatsApp/SMS message"
    assert html_response(conn, 200) =~ "Reply: APPROVE, HALF, or REJECT."
  end

  test "GET /producer renders a pending English HITL request", %{conn: conn} do
    {:ok, _request, _snapshot} = ApprovalQueue.request_irreversible_action()

    conn = get(conn, ~p"/producer")

    assert html_response(conn, 200) =~ "approval pending"
    assert html_response(conn, 200) =~ "harvest"
    assert html_response(conn, 200) =~ "Apply half"
  end
end
