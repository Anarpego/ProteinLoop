defmodule ProteinLoop.Agent.SagentsEvidence do
  @moduledoc """
  Builds executable evidence for the real Sagents and Gemma runtime.

  The evidence combines a non-mutating HumanInTheLoop interrupt, a rejection
  resumed through Sagents, and one verified closed-loop mutation. It only
  succeeds when every required proof check passes.
  """

  alias ProteinLoop.Agent.SagentsRuntime
  alias ProteinLoop.SimulatorClient

  @expected_subagents ["duckweed-chickens", "fish-tank", "freshwater-prawn", "hydroponia"]
  @action_keys [
    "feed_kg",
    "aeration_hours",
    "water_exchange_fraction",
    "duckweed_harvest_kg",
    "note"
  ]

  def build(opts \\ []) do
    reset_fun = Keyword.get(opts, :reset_fun, &SimulatorClient.reset/0)
    state_fun = Keyword.get(opts, :state_fun, &SimulatorClient.state/0)
    hitl_fun = Keyword.get(opts, :hitl_fun, &SagentsRuntime.request_irreversible/1)

    resume_fun =
      Keyword.get(opts, :resume_fun, fn pending, decision ->
        SagentsRuntime.resume_irreversible(pending, decision)
      end)

    run_fun = Keyword.get(opts, :run_fun, &SagentsRuntime.run/0)
    now_fun = Keyword.get(opts, :now_fun, &DateTime.utc_now/0)

    with {:ok, _reset_state} <- reset_state(reset_fun),
         {:ok, before_hitl} <- current_state(state_fun),
         {:ok, hitl} <- hitl_interrupt(hitl_fun, before_hitl),
         {:ok, after_hitl} <- current_state(state_fun),
         {:ok, reject_result} <- resume_rejection(resume_fun, hitl.runtime_context),
         {:ok, after_reject} <- current_state(state_fun),
         {:ok, _cycle_reset} <- reset_state(reset_fun),
         {:ok, cycle} <- run_fun.() do
      evidence =
        evidence_packet(
          cycle,
          hitl,
          reject_result,
          before_hitl,
          after_hitl,
          after_reject,
          now_fun.(),
          Keyword.get(opts, :endpoint, Application.get_env(:proteinloop, :gemma_endpoint)),
          Keyword.get(opts, :model, Application.get_env(:proteinloop, :gemma_model, "gemma"))
        )

      if evidence.ok do
        {:ok, evidence}
      else
        {:error, {:evidence_failed, evidence}}
      end
    else
      {:error, _reason} = error -> error
      other -> {:error, {:unexpected_evidence_result, other}}
    end
  end

  def render_markdown(evidence) do
    subagent_lines =
      Enum.map(evidence.cycle.subagents, fn subagent ->
        report = map_get(subagent, :report, %{})
        "- #{map_get(subagent, :name)}: #{map_get(report, "status", "unknown")}"
      end)

    check_lines =
      Enum.map(evidence.checks, fn {name, passed?} ->
        "- #{name}: #{passed?}"
      end)

    lines = [
      "# ProteinLoop Real Sagents Evidence",
      "",
      "Generated from the live local Gemma OpenAI-compatible endpoint and Docker simulator.",
      "",
      "## Runtime",
      "",
      "- Sagents #{evidence.runtime.framework_version}",
      "- LangChain #{evidence.runtime.langchain_version}",
      "- Model: #{evidence.model.name}",
      "- Distribution: #{evidence.runtime.distribution}",
      "- Execution mode: #{inspect(evidence.runtime.execution_mode)}",
      "- Termination: #{evidence.runtime.termination}",
      "",
      "## Verified Cycle",
      "",
      "- Tool: #{evidence.cycle.tool}",
      "- Final day: #{evidence.cycle.state["day"]}",
      "- Reward: #{evidence.cycle.reward}",
      "- Verifier accepted: #{evidence.cycle.verification["ok"]}",
      "",
      "## Subagents",
      ""
    ]

    hitl_lines = [
      "",
      "## HumanInTheLoop",
      "",
      "- Tool: #{evidence.hitl.tool}",
      "- Decisions: #{Enum.join(evidence.hitl.allowed_decisions, ", ")}",
      "- No mutation before approval: #{not evidence.hitl.mutation_before_approval}",
      "- Rejection resumed through Sagents: #{evidence.hitl.reject_decision == :rejected}",
      "- No mutation after rejection: #{not evidence.hitl.mutation_after_reject}",
      "",
      "## Checks",
      ""
    ]

    Enum.join(lines ++ subagent_lines ++ hitl_lines ++ check_lines ++ [""], "\n")
  end

  defp evidence_packet(
         cycle,
         hitl,
         reject_result,
         before_hitl,
         after_hitl,
         after_reject,
         now,
         endpoint,
         model
       ) do
    subagent_names =
      cycle
      |> map_get(:subagents, [])
      |> Enum.map(&map_get(&1, :name))
      |> Enum.sort()

    real_subagents? =
      cycle
      |> map_get(:subagents, [])
      |> Enum.all?(&(map_get(&1, :runtime) == Sagents.SubAgent))

    action = map_get(cycle, :action)
    verification = map_get(cycle, :verification, %{})

    checks = %{
      real_sagents_runtime:
        map_get(cycle, :framework) == "sagents" and
          map_get(cycle, :framework_version) == "0.9.0",
      four_subagents_completed: subagent_names == @expected_subagents,
      real_sagents_subagents: real_subagents?,
      custom_safety_mode: map_get(cycle, :execution_mode) == ProteinLoop.Agent.SafetyMode,
      until_tool_success:
        map_get(cycle, :termination) == "until_tool_success" and
          map_get(cycle, :tool) == "close_cycle",
      verification_accepted: map_get(verification, "ok") == true,
      action_preserved: is_map(action) and Enum.all?(@action_keys, &Map.has_key?(action, &1)),
      hitl_interrupted_before_mutation:
        hitl.tool == "irreversible_cycle" and before_hitl == after_hitl,
      hitl_reject_resumed_without_mutation:
        map_get(reject_result, :decision) == :rejected and
          map_get(reject_result, :mutated) == false and before_hitl == after_reject
    }

    %{
      title: "ProteinLoop real Sagents runtime evidence",
      generated_at: now |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      ok: Enum.all?(Map.values(checks)),
      model: %{
        name: model,
        endpoint: endpoint,
        deployment: "local-offline",
        temperature: 0.0
      },
      runtime: %{
        framework: map_get(cycle, :framework),
        framework_version: map_get(cycle, :framework_version),
        langchain_version: map_get(cycle, :langchain_version),
        distribution: map_get(cycle, :distribution),
        execution_mode: map_get(cycle, :execution_mode),
        termination: map_get(cycle, :termination)
      },
      cycle: cycle,
      hitl: %{
        tool: hitl.tool,
        action: hitl.action,
        tool_call_id: hitl.tool_call_id,
        allowed_decisions: hitl.allowed_decisions,
        before_day: map_get(before_hitl, "day"),
        after_day: map_get(after_hitl, "day"),
        mutation_before_approval: before_hitl != after_hitl,
        reject_decision: map_get(reject_result, :decision),
        after_reject_day: map_get(after_reject, "day"),
        mutation_after_reject: before_hitl != after_reject
      },
      checks: checks
    }
  end

  defp hitl_interrupt(hitl_fun, state) do
    case hitl_fun.(state) do
      {:interrupt, pending} ->
        case get_in(pending, [:interrupt_data, :action_requests]) do
          [%{arguments: action, tool_call_id: tool_call_id} | _rest] ->
            {:ok,
             %{
               tool: pending.tool,
               action: action,
               tool_call_id: tool_call_id,
               allowed_decisions: pending.allowed_decisions,
               runtime_context: pending
             }}

          other ->
            {:error, {:invalid_hitl_action_requests, other}}
        end

      {:error, reason} ->
        {:error, {:hitl_failed, reason}}

      other ->
        {:error, {:hitl_did_not_interrupt, other}}
    end
  end

  defp resume_rejection(resume_fun, pending) do
    case resume_fun.(pending, :reject) do
      {:ok, %{decision: :rejected, mutated: false} = result} -> {:ok, result}
      {:error, reason} -> {:error, {:hitl_reject_resume_failed, reason}}
      other -> {:error, {:invalid_hitl_reject_resume, other}}
    end
  end

  defp reset_state(reset_fun) do
    case reset_fun.() do
      {:ok, %{"state" => state}} when is_map(state) -> {:ok, state}
      {:error, reason} -> {:error, {:reset_failed, reason}}
      other -> {:error, {:invalid_reset_response, other}}
    end
  end

  defp current_state(state_fun) do
    case state_fun.() do
      {:ok, %{"state" => state}} when is_map(state) -> {:ok, state}
      {:error, reason} -> {:error, {:state_failed, reason}}
      other -> {:error, {:invalid_state_response, other}}
    end
  end

  defp map_get(map, key, default \\ nil) when is_map(map) do
    Map.get(map, key, Map.get(map, alternate_key(key), default))
  end

  defp alternate_key(key) when is_atom(key), do: Atom.to_string(key)

  defp alternate_key(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end
end
