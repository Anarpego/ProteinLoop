defmodule ProteinLoopWeb.ProducerLiveTest do
  use ProteinLoopWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ProteinLoop.Agent.ApprovalQueue
  alias ProteinLoop.TestSagentsRuntime

  setup do
    previous = Application.get_env(:proteinloop, :sagents_runtime)
    Application.put_env(:proteinloop, :sagents_runtime, TestSagentsRuntime)
    ApprovalQueue.reset()

    on_exit(fn ->
      if previous do
        Application.put_env(:proteinloop, :sagents_runtime, previous)
      else
        Application.delete_env(:proteinloop, :sagents_runtime)
      end

      ApprovalQueue.reset()
    end)

    :ok
  end

  test "producer approval resumes the interrupted Sagents tool", %{conn: conn} do
    request_sagents_hitl(self())
    {:ok, view, _html} = live(conn, ~p"/producer")

    html = view |> element("button[phx-click='approve']") |> render_click()

    assert_receive {:sagents_resumed, :approve, nil}
    assert html =~ "Accion aprobada"
    assert ApprovalQueue.snapshot().pending == nil
    assert hd(ApprovalQueue.snapshot().decisions).status == "approved"
  end

  test "producer edit resumes Sagents with the halved action", %{conn: conn} do
    request_sagents_hitl(self())
    {:ok, view, _html} = live(conn, ~p"/producer")

    html = view |> element("button[phx-click='half']") |> render_click()

    assert_receive {:sagents_resumed, :edit, edited}
    assert edited["water_exchange_fraction"] == 0.075
    assert edited["duckweed_harvest_kg"] == 0.25
    assert html =~ "Accion editada"
    assert hd(ApprovalQueue.snapshot().decisions).status == "edited"
  end

  test "producer rejection resumes Sagents without a mutation", %{conn: conn} do
    request_sagents_hitl(self())
    {:ok, view, _html} = live(conn, ~p"/producer")

    html = view |> element("button[phx-click='reject']") |> render_click()

    assert_receive {:sagents_resumed, :reject, nil}
    assert html =~ "Accion rechazada"
    assert hd(ApprovalQueue.snapshot().decisions).status == "rejected"
  end

  test "an already claimed request cannot resume the Sagents tool twice", %{conn: conn} do
    request = request_sagents_hitl(self())
    {:ok, view, _html} = live(conn, ~p"/producer")

    assert {:ok, _claimed, _snapshot} = ApprovalQueue.claim(request.id)
    html = render_click(view, "approve")

    refute_receive {:sagents_resumed, :approve, nil}
    assert html =~ "procesando"
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
