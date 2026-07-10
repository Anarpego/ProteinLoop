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

  test "bundles and loads the licensed PBR fish without a runtime CDN" do
    assets = Path.expand("../../../assets", __DIR__)
    model = Path.expand("../../../priv/static/models/barramundi-fish.glb", __DIR__)
    license = Path.expand("../../../priv/static/models/BARRAMUNDI-LICENSE.md", __DIR__)
    tank_hook = assets |> Path.join("js/hooks/realtime_tank.js") |> File.read!()

    assert "models" in ProteinLoopWeb.static_paths()
    assert File.stat!(model).size == 12_488_144

    assert model
           |> File.read!()
           |> then(&:crypto.hash(:sha256, &1))
           |> Base.encode16(case: :lower) ==
             "ecc3bafb6b00f2c8b810863c388e3768a7b7ea0d0335e8cb8c574c266e571f4a"

    assert File.read!(license) =~ "CC0-1.0"
    assert tank_hook =~ "GLTFLoader"
    assert tank_hook =~ ~s("/models/barramundi-fish.glb")
    assert tank_hook =~ "loadAsync"
    assert tank_hook =~ "clone(true)"
    assert tank_hook =~ "distanceForWidth"
    assert tank_hook =~ "distanceForHeight"
    assert tank_hook =~ "disposeObject3D(runtime.scene)"
    assert tank_hook =~ "environmentTarget?.dispose()"
  end

  test "bundles and loads the licensed realistic prawn visual" do
    assets = Path.expand("../../../assets", __DIR__)
    texture = Path.expand("../../../priv/static/models/greasyback-shrimp.jpeg", __DIR__)
    license = Path.expand("../../../priv/static/models/GREASYBACK-SHRIMP-LICENSE.md", __DIR__)
    tank_hook = assets |> Path.join("js/hooks/realtime_tank.js") |> File.read!()

    assert File.stat!(texture).size == 151_238

    assert texture
           |> File.read!()
           |> then(&:crypto.hash(:sha256, &1))
           |> Base.encode16(case: :lower) ==
             "14bfb1ef5226b1af5ae94a03f1cfd02958a246fcb608ff87b816a8dd0c25a92e"

    assert File.read!(license) =~ "CC0 Public Domain"
    assert tank_hook =~ "TextureLoader"
    assert tank_hook =~ ~s("/models/greasyback-shrimp.jpeg")
    assert tank_hook =~ "loadPrawnVisual"
    assert tank_hook =~ "smoothstep"
  end

  test "GET /producer renders the English HITL view", %{conn: conn} do
    conn = get(conn, ~p"/producer")
    html = html_response(conn, 200)

    assert html =~ "Producer decisions"
    assert html =~ "Live tank simulation"
    assert html =~ "Approve"
    assert html =~ "Offline fallback"
    assert html =~ "Local action"
    assert html =~ "WhatsApp/SMS message"
    assert html =~ "Reply: APPROVE, HALF, or REJECT."
    refute html =~ "Simulate water emergency"
    refute html =~ "protein-loop-system.svg"
  end

  test "GET /producer renders a pending English HITL request", %{conn: conn} do
    {:ok, _request, _snapshot} = ApprovalQueue.request_irreversible_action()

    conn = get(conn, ~p"/producer")

    assert html_response(conn, 200) =~ "approval pending"
    assert html_response(conn, 200) =~ "harvest"
    assert html_response(conn, 200) =~ "Apply half"
  end
end
