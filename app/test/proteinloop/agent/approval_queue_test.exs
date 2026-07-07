defmodule ProteinLoop.Agent.ApprovalQueueTest do
  use ExUnit.Case, async: false

  alias ProteinLoop.Agent.ApprovalQueue

  setup do
    ApprovalQueue.reset()
    :ok
  end

  test "creates one pending irreversible approval request" do
    assert {:ok, request, snapshot} =
             ApprovalQueue.request_irreversible_action(%{"duckweed_kg" => 3.0})

    assert request.action["water_exchange_fraction"] == 0.2
    assert request.action["duckweed_harvest_kg"] == 0.4
    assert request.prompt =~ "Procedo?"
    assert snapshot.pending.id == request.id

    assert {:pending, ^request, _snapshot} =
             ApprovalQueue.request_irreversible_action(%{"duckweed_kg" => 3.0})
  end

  test "half action reduces irreversible portions" do
    action = ApprovalQueue.irreversible_action(%{"duckweed_kg" => 2.5})

    edited = ApprovalQueue.half_action(action)

    assert edited["water_exchange_fraction"] == 0.1
    assert edited["duckweed_harvest_kg"] == 0.2
    assert edited["note"] == "producer_half_irreversible"
  end

  test "resolve moves pending request into decisions" do
    {:ok, request, _snapshot} = ApprovalQueue.request_irreversible_action()

    assert {:ok, decision, snapshot} =
             ApprovalQueue.resolve(request.id, :approved, %{reward: 123.4})

    assert decision.status == "approved"
    assert decision.result.reward == 123.4
    assert snapshot.pending == nil
    assert [latest] = snapshot.decisions
    assert latest.id == request.id
  end

  test "reject resolves without an execution result" do
    {:ok, request, _snapshot} = ApprovalQueue.request_irreversible_action()

    assert {:ok, decision, snapshot} =
             ApprovalQueue.resolve(request.id, :rejected, %{message: "producer_rejected"})

    assert decision.status == "rejected"
    assert snapshot.pending == nil
    assert hd(snapshot.decisions).result.message == "producer_rejected"
  end

  test "reset clears pending and decisions" do
    {:ok, request, _snapshot} = ApprovalQueue.request_irreversible_action()
    {:ok, _decision, _snapshot} = ApprovalQueue.resolve(request.id, :edited, %{reward: 1.0})

    assert %{pending: nil, decisions: []} = ApprovalQueue.reset()
  end
end
