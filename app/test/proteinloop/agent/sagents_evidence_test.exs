defmodule ProteinLoop.Agent.SagentsEvidenceTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.SagentsEvidence

  @initial_state %{
    "day" => 0,
    "ammonia_mg_l" => 0.35,
    "dissolved_oxygen_mg_l" => 6.8,
    "duckweed_kg" => 3.0,
    "collapsed" => false
  }

  @action %{
    "feed_kg" => 0.1,
    "aeration_hours" => 12.0,
    "water_exchange_fraction" => 0.15,
    "duckweed_harvest_kg" => 0.5,
    "note" => "verified cycle"
  }

  test "builds passing real runtime and non-mutating HITL evidence" do
    assert {:ok, evidence} = SagentsEvidence.build(evidence_opts())

    assert evidence.ok
    assert evidence.runtime.framework == "sagents"
    assert evidence.runtime.framework_version == "0.9.0"
    assert evidence.runtime.langchain_version == "0.9.2"
    assert evidence.runtime.execution_mode == ProteinLoop.Agent.SafetyMode
    assert evidence.cycle.action == @action
    assert evidence.cycle.state["day"] == 1
    assert evidence.hitl.tool == "irreversible_cycle"
    assert evidence.hitl.allowed_decisions == [:approve, :edit, :reject]
    assert evidence.hitl.mutation_before_approval == false
    assert evidence.hitl.reject_decision == :rejected
    assert evidence.hitl.mutation_after_reject == false
    assert evidence.checks.four_subagents_completed
    assert evidence.checks.real_sagents_subagents
    assert evidence.checks.until_tool_success
    assert evidence.checks.hitl_interrupted_before_mutation
    assert evidence.checks.hitl_reject_resumed_without_mutation

    markdown = SagentsEvidence.render_markdown(evidence)
    assert markdown =~ "# ProteinLoop Real Sagents Evidence"
    assert markdown =~ "Sagents 0.9.0"
    assert markdown =~ "No mutation before approval: true"
  end

  test "rejects evidence when HITL mutates simulator state before approval" do
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    state_fun = fn ->
      call = Agent.get_and_update(calls, &{&1, &1 + 1})
      state = if call == 0, do: @initial_state, else: Map.put(@initial_state, "day", 1)
      {:ok, %{"state" => state}}
    end

    assert {:error, {:evidence_failed, evidence}} =
             SagentsEvidence.build(Keyword.put(evidence_opts(), :state_fun, state_fun))

    refute evidence.ok
    assert evidence.hitl.mutation_before_approval
    refute evidence.checks.hitl_interrupted_before_mutation
  end

  defp evidence_opts do
    [
      reset_fun: fn -> {:ok, %{"state" => @initial_state}} end,
      state_fun: fn -> {:ok, %{"state" => @initial_state}} end,
      hitl_fun: fn @initial_state -> {:interrupt, hitl_pending()} end,
      resume_fun: fn _pending, :reject ->
        {:ok, %{decision: :rejected, mutated: false}}
      end,
      run_fun: fn -> {:ok, cycle_result()} end,
      now_fun: fn -> ~U[2026-07-09 12:00:00Z] end,
      endpoint: "http://127.0.0.1:8001",
      model: "google/gemma-4-E2B-it"
    ]
  end

  defp hitl_pending do
    %{
      tool: "irreversible_cycle",
      allowed_decisions: [:approve, :edit, :reject],
      interrupt_data: %{
        action_requests: [
          %{
            tool_call_id: "call-hitl-1",
            tool_name: "irreversible_cycle",
            arguments: @action
          }
        ]
      }
    }
  end

  defp cycle_result do
    %{
      framework: "sagents",
      framework_version: "0.9.0",
      langchain_version: "0.9.2",
      distribution: :local,
      execution_mode: ProteinLoop.Agent.SafetyMode,
      termination: "until_tool_success",
      tool: "close_cycle",
      action: @action,
      state: Map.put(@initial_state, "day", 1),
      reward: 203.7,
      verification: %{"ok" => true, "violations" => [], "warnings" => []},
      subagents:
        Enum.map(
          ["fish-tank", "freshwater-prawn", "hydroponia", "duckweed-chickens"],
          &%{name: &1, runtime: Sagents.SubAgent, report: %{"status" => "stable"}}
        )
    }
  end
end
