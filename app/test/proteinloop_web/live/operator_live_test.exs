defmodule ProteinLoopWeb.OperatorLiveTest do
  use ProteinLoopWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ProteinLoop.Agent.ApprovalQueue

  setup do
    previous = Application.get_env(:proteinloop, :sagents_runtime)
    previous_horde = Application.get_env(:proteinloop, :horde_runtime)
    Application.put_env(:proteinloop, :sagents_runtime, ProteinLoop.TestSagentsRuntime)
    Application.put_env(:proteinloop, :horde_runtime, ProteinLoop.TestHordeRuntime)
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

      Application.delete_env(:proteinloop, :test_sagents_runtime_pause)
      ApprovalQueue.reset()
    end)

    :ok
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
    assert html =~ "Real Sagents runtime"

    view
    |> element("button[phx-click='run-verified-loop']")
    |> render_click()

    assert_receive {:test_sagents_runtime_started, :run, task}
    render_click(view, "run-verified-loop")
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
