defmodule ProteinLoopWeb.ProducerLiveTest do
  use ProteinLoopWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ProteinLoop.Agent.ApprovalQueue
  alias ProteinLoop.TestSagentsRuntime

  setup do
    previous = Application.get_env(:proteinloop, :sagents_runtime)
    previous_evidence = Application.get_env(:proteinloop, :nrf9151_evidence)
    Application.put_env(:proteinloop, :sagents_runtime, TestSagentsRuntime)
    Application.put_env(:proteinloop, :nrf9151_evidence, ProteinLoop.TestNRF9151Evidence)
    ApprovalQueue.reset()

    on_exit(fn ->
      if previous do
        Application.put_env(:proteinloop, :sagents_runtime, previous)
      else
        Application.delete_env(:proteinloop, :sagents_runtime)
      end

      if previous_evidence do
        Application.put_env(:proteinloop, :nrf9151_evidence, previous_evidence)
      else
        Application.delete_env(:proteinloop, :nrf9151_evidence)
      end

      ApprovalQueue.reset()
    end)

    :ok
  end

  test "shows the latest real DECT exchange without claiming physical sensor telemetry", %{
    conn: conn
  } do
    {:ok, view, html} = live(conn, ~p"/producer")

    assert has_element?(view, "#producer-system-scene[phx-hook='RealtimeTank']")
    assert has_element?(view, "#producer-system-scene canvas[data-tank-canvas]")
    assert has_element?(view, "#producer-system-scene [data-tank-fullscreen]")
    refute has_element?(view, "#tank-agent-console")
    refute has_element?(view, "#producer-system-scene button[phx-click='spike']")
    refute has_element?(view, "#producer-system-scene button[phx-click='reset']")
    assert html =~ "Producer decisions"
    assert has_element?(view, "#producer-decision-workspace")
    assert has_element?(view, "#producer-approve[phx-click='approve']")
    assert has_element?(view, "#producer-half[phx-click='half']")
    assert has_element?(view, "#producer-reject[phx-click='reject']")

    {workspace_position, _length} = :binary.match(html, ~s(id="producer-decision-workspace"))
    {tank_position, _length} = :binary.match(html, ~s(id="producer-system-scene"))
    assert workspace_position < tank_position
    assert html =~ "Live tank simulation"
    assert html =~ "Main fish &amp; prawn tank"
    assert html =~ "Waste in water"
    assert html =~ "Breathing oxygen"
    assert html =~ "Plants → feed → eggs"
    assert html =~ "6 hens · 0.0 eggs"
    assert has_element?(view, "#producer-dect-status")
    assert html =~ "Latest DECT NR+ link"
    assert html =~ "Sequence #100"
    assert html =~ "1051223739"
    assert html =~ "1051239227"
    assert html =~ "real radio"
    assert html =~ "DECT NR+ is the private, non-cellular 5G field link"
    assert html =~ "without Wi-Fi, a SIM, or cloud access"

    assert html =~
             ~r/Gemma runs on a separate\s+local edge computer connected to the gateway radio, not on either nRF9151 board/

    assert html =~ "Water chemistry remains simulated"
    assert html =~ ~r/not a\s+chemical\s+sensor reading/
    assert html =~ "Approve"
    assert html =~ "Apply half"
    assert html =~ "Reject"
    refute html =~ "Run one-click verifier proof"
    refute html =~ "Productor"
    refute html =~ "Aprobar"
  end

  test "producer approval resumes the interrupted Sagents tool", %{conn: conn} do
    request_sagents_hitl(self())
    {:ok, view, _html} = live(conn, ~p"/producer")

    html = view |> element("button[phx-click='approve']") |> render_click()

    assert_receive {:sagents_resumed, :approve, nil}
    assert html =~ "Action approved"

    assert has_element?(
             view,
             "#producer-decision-result[role='status'][aria-live='polite']"
           )

    assert html =~ "Decision applied safely"
    assert html =~ "Simulator mutation"
    assert html =~ "Applied after verification"
    assert html =~ "Current ammonia"
    assert html =~ "0.35 mg/L"
    assert html =~ "Current oxygen"
    assert html =~ "6.8 mg/L"
    assert html =~ "Reward 201.5"
    assert has_element?(view, "#producer-decision-result a[href='/']", "See recovered tank")
    refute has_element?(view, "#producer-approve")
    assert ApprovalQueue.snapshot().pending == nil
    assert hd(ApprovalQueue.snapshot().decisions).status == "approved"

    {:ok, reopened_view, reopened_html} = live(conn, ~p"/producer")
    assert has_element?(reopened_view, "#producer-decision-result", "Decision applied safely")
    assert reopened_html =~ "Reward 201.5"
    assert reopened_html =~ "15.0%"
    refute has_element?(reopened_view, "#producer-approve")

    request_sagents_hitl(self())
    assert has_element?(view, "#producer-approve[phx-click='approve']")
    refute has_element?(view, "#producer-decision-result")
  end

  test "producer edit resumes Sagents with the halved action", %{conn: conn} do
    request_sagents_hitl(self())
    {:ok, view, _html} = live(conn, ~p"/producer")

    html = view |> element("button[phx-click='half']") |> render_click()

    assert_receive {:sagents_resumed, :edit, edited}
    assert edited["water_exchange_fraction"] == 0.075
    assert edited["duckweed_harvest_kg"] == 0.25
    assert html =~ "Action reduced and approved"
    assert html =~ "Reduced action applied safely"
    assert html =~ "Applied after verification"
    assert hd(ApprovalQueue.snapshot().decisions).status == "edited"
  end

  test "producer rejection resumes Sagents without a mutation", %{conn: conn} do
    request_sagents_hitl(self())
    {:ok, view, _html} = live(conn, ~p"/producer")

    html = view |> element("button[phx-click='reject']") |> render_click()

    assert_receive {:sagents_resumed, :reject, nil}
    assert html =~ "Action rejected"
    assert html =~ "Decision recorded without changing the system"
    assert html =~ "No simulator mutation"
    assert html =~ "Reward not applicable"
    assert has_element?(view, "#producer-decision-result a[href='/']", "Return to operator")
    assert hd(ApprovalQueue.snapshot().decisions).status == "rejected"
  end

  test "an already claimed request cannot resume the Sagents tool twice", %{conn: conn} do
    request = request_sagents_hitl(self())
    {:ok, view, _html} = live(conn, ~p"/producer")

    assert {:ok, _claimed, _snapshot} = ApprovalQueue.claim(request.id)
    html = render_click(view, "approve")

    refute_receive {:sagents_resumed, :approve, nil}
    assert html =~ "processing"
    assert html =~ "disabled"
    assert ApprovalQueue.snapshot().pending.status == "processing"
  end

  defp request_sagents_hitl(owner) do
    {:ok, request, _snapshot} =
      ApprovalQueue.request(TestSagentsRuntime.action(),
        source: "sagents_hitl",
        requested_by: "sagents-supervisor",
        tool_call_id: "hitl-call-1",
        runtime_context: %{owner: owner}
      )

    request
  end
end
