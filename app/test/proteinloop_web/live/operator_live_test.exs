defmodule ProteinLoopWeb.OperatorLiveTest do
  use ProteinLoopWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ProteinLoop.Agent.ApprovalQueue

  setup do
    previous = Application.get_env(:proteinloop, :sagents_runtime)
    previous_horde = Application.get_env(:proteinloop, :horde_runtime)
    previous_evidence = Application.get_env(:proteinloop, :nrf9151_evidence)
    previous_dect_client = Application.get_env(:proteinloop, :dect_simulator_client)
    Application.put_env(:proteinloop, :sagents_runtime, ProteinLoop.TestSagentsRuntime)
    Application.put_env(:proteinloop, :horde_runtime, ProteinLoop.TestHordeRuntime)
    Application.put_env(:proteinloop, :nrf9151_evidence, ProteinLoop.TestNRF9151Evidence)
    Application.put_env(:proteinloop, :dect_simulator_client, ProteinLoop.TestDectSimulatorClient)
    Application.put_env(:proteinloop, :test_dect_owner, self())
    ApprovalQueue.reset()

    on_exit(fn ->
      if previous do
        Application.put_env(:proteinloop, :sagents_runtime, previous)
      else
        Application.delete_env(:proteinloop, :sagents_runtime)
      end

      if previous_horde do
        Application.put_env(:proteinloop, :horde_runtime, previous_horde)
      else
        Application.delete_env(:proteinloop, :horde_runtime)
      end

      if previous_evidence do
        Application.put_env(:proteinloop, :nrf9151_evidence, previous_evidence)
      else
        Application.delete_env(:proteinloop, :nrf9151_evidence)
      end

      if previous_dect_client do
        Application.put_env(:proteinloop, :dect_simulator_client, previous_dect_client)
      else
        Application.delete_env(:proteinloop, :dect_simulator_client)
      end

      Application.delete_env(:proteinloop, :test_sagents_runtime_pause)
      Application.delete_env(:proteinloop, :test_dect_owner)
      ApprovalQueue.reset()
    end)

    :ok
  end

  test "shows the real-time living system and explains tank chemistry in plain language", %{
    conn: conn
  } do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "ProteinLoop system control"
    assert has_element?(view, "#operator-system-scene[phx-hook='RealtimeTank']")
    assert has_element?(view, "#operator-system-scene canvas[data-tank-canvas]")
    assert html =~ "Live tank simulation"
    assert html =~ "Main fish &amp; prawn tank"
    assert html =~ "Waste in water"
    assert html =~ "Ammonia"
    assert html =~ "Breathing oxygen"
    assert html =~ "Dissolved oxygen"
    assert html =~ "Simulate water emergency"
    assert has_element?(view, "#operator-system-scene [data-tank-fallback]")
    refute html =~ "protein-loop-system.svg"
  end

  test "streams simulator snapshots into the animated tank", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    snapshot = %{
      connected?: true,
      source: "test-stream",
      reward: nil,
      error: nil,
      state:
        ProteinLoop.SimulatorClient.fallback_state()
        |> Map.put("day", 4)
        |> Map.put("ammonia_mg_l", 3.8)
        |> Map.put("dissolved_oxygen_mg_l", 3.2)
    }

    send(view.pid, {:simulator_snapshot, snapshot})
    html = render(view)

    assert has_element?(
             view,
             "#operator-system-scene[data-day='4'][data-ammonia='3.8'][data-oxygen='3.2'][data-health='critical']"
           )

    assert html =~ "Tank animals are in danger"
  end

  test "keeps one AI workflow above closed advanced evidence", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Ask the AI team to help"
    assert html =~ "Ask AI team for a safe plan"
    assert has_element?(view, "#advanced-evidence")
    refute has_element?(view, "#advanced-evidence[open]")
    assert html =~ "Advanced evidence and controls"

    {scene_position, _length} = :binary.match(html, ~s(id="operator-system-scene"))
    {mission_position, _length} = :binary.match(html, ~s(id="agentic-mission"))
    {advanced_position, _length} = :binary.match(html, ~s(id="advanced-evidence"))

    assert scene_position < mission_position
    assert mission_position < advanced_position
  end

  test "shows and replays the latest physical DECT capture as simulated telemetry", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Physical DECT NR+ link"
    assert html =~ "Sequence #100"
    assert html =~ "1051223739"
    assert html =~ "1051239227"
    assert html =~ "real radio capture"
    assert html =~ ~r/simulated sensor\s+alert/
    assert has_element?(view, "#dect-live-evidence")

    html = view |> element("#replay-dect-sensor") |> render_click()

    assert_receive :dect_replay_requested
    assert html =~ "DECT capture #100 replayed as simulated sensor alert"
    assert html =~ "3.8 mg/L"
  end

  test "starts the verified Sagents Gemma cycle from the DECT panel", %{conn: conn} do
    Application.put_env(:proteinloop, :test_sagents_runtime_pause, {:run, self()})
    {:ok, view, _html} = live(conn, ~p"/")

    view |> element("#dect-run-gemma") |> render_click()

    assert_receive {:test_sagents_runtime_started, :run, task}
    send(task, {:continue_test_sagents_runtime, :run})

    html = render_async(view, 1_000)
    assert html =~ "Day 1 / reward 203.7"
    assert html =~ "real Sagents cycle completed"
  end

  test "runs a user-selected agentic mission and renders an intelligence receipt", %{conn: conn} do
    Application.put_env(:proteinloop, :test_sagents_runtime_pause, {:run, self()})
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Ask the AI team to help"
    assert has_element?(view, "#agentic-mission")
    assert has_element?(view, "#mission-protect-protein")

    html = view |> element("#mission-protect-protein") |> render_click()
    assert html =~ "Protect protein yield"

    html = view |> element("#run-agentic-mission") |> render_click()
    assert html =~ "Specialists deliberating"

    assert_receive {:test_sagents_runtime_options, opts}
    assert Keyword.fetch!(opts, :mission) =~ "Protect fish, prawns, and daily protein yield"
    assert_receive {:test_sagents_runtime_started, :run, task}

    render_click(view, "run-agentic-mission")
    refute_receive {:test_sagents_runtime_started, :run, _duplicate}, 50
    send(task, {:continue_test_sagents_runtime, :run})

    html = render_async(view, 1_000)
    assert html =~ "Intelligence receipt"
    assert html =~ "4 specialist briefs"
    assert html =~ "Pause feed and maximize aeration."
    assert html =~ "Protect duckweed reserve until water stabilizes."
    assert html =~ "Supervisor plan"
    assert html =~ "Supervisor selected oxygen-first recovery."
    assert html =~ "Verifier accepted"
    assert html =~ "Continue oxygen monitoring during recovery."
    assert html =~ "3.8 mg/L"
    assert html =~ "0.9 mg/L"
  end

  test "renders and refreshes the real Horde cluster status", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Real Sagents/Horde cluster"
    assert html =~ "proteinloop_web@web"
    assert html =~ "proteinloop_peer@peer"
    assert html =~ "participation"
    assert html =~ "1 managed"
    assert html =~ "Deterministic failover rehearsal"

    html =
      view
      |> element("button[phx-click='refresh-horde']")
      |> render_click()

    assert html =~ "proteinloop_peer@peer"
  end

  test "runs the real-runtime UI path asynchronously", %{conn: conn} do
    Application.put_env(:proteinloop, :test_sagents_runtime_pause, {:run, self()})
    {:ok, view, html} = live(conn, ~p"/")
    assert html =~ "Ask the AI team to help"

    view
    |> element("#run-agentic-mission")
    |> render_click()

    assert_receive {:test_sagents_runtime_started, :run, task}
    render_click(view, "run-agentic-mission")
    refute_receive {:test_sagents_runtime_started, :run, _duplicate}, 50
    send(task, {:continue_test_sagents_runtime, :run})

    html = render_async(view, 1_000)
    assert html =~ "Day 1 / reward 203.7"
    assert html =~ "fish-tank"
    assert html =~ "close_cycle"
  end

  test "queues a real Sagents HITL interrupt for the producer", %{conn: conn} do
    Application.put_env(:proteinloop, :test_sagents_runtime_pause, {:hitl, self()})
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> element("button[phx-click='request-hitl']")
    |> render_click()

    assert_receive {:test_sagents_runtime_started, :hitl, task}
    render_click(view, "request-hitl")
    refute_receive {:test_sagents_runtime_started, :hitl, _duplicate}, 50
    send(task, {:continue_test_sagents_runtime, :hitl})

    html = render_async(view, 1_000)
    assert html =~ "Producer decision pending"

    pending = ApprovalQueue.snapshot().pending
    assert pending.source == "sagents_hitl"
    assert pending.requested_by == "sagents-supervisor"
    assert pending.tool_call_id == "hitl-call-1"
    assert pending.action["water_exchange_fraction"] == 0.15
  end
end
