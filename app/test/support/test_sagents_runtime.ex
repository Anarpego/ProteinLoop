defmodule ProteinLoop.TestSagentsRuntime do
  def status do
    %{
      framework: "sagents",
      framework_version: "0.9.0",
      langchain_version: "0.9.2",
      distribution: :local,
      execution_mode: ProteinLoop.Agent.SafetyMode,
      termination: "until_tool_success",
      subagents: ["fish-tank", "freshwater-prawn", "hydroponia", "duckweed-chickens"],
      agent_count: 5,
      hitl_tool: "irreversible_cycle",
      endpoint_configured?: true,
      model: "google/gemma-4-E2B-it"
    }
  end

  def run do
    maybe_pause(:run)
    action = action()

    {:ok,
     %{
       framework: "sagents",
       framework_version: "0.9.0",
       langchain_version: "0.9.2",
       distribution: :local,
       execution_mode: ProteinLoop.Agent.SafetyMode,
       termination: "until_tool_success",
       tool: "close_cycle",
       action: action,
       state: Map.merge(ProteinLoop.SimulatorClient.fallback_state(), %{"day" => 1}),
       reward: 203.7,
       verification: %{"ok" => true, "violations" => [], "warnings" => []},
       subagents:
         Enum.map(
           ["fish-tank", "freshwater-prawn", "hydroponia", "duckweed-chickens"],
           &%{name: &1, report: %{"status" => "stable"}}
         )
     }}
  end

  def request_irreversible(_state) do
    maybe_pause(:hitl)

    {:interrupt,
     %{
       tool: "irreversible_cycle",
       allowed_decisions: [:approve, :edit, :reject],
       interrupt_data: %{
         action_requests: [
           %{
             arguments: action(),
             tool_call_id: "hitl-call-1",
             tool_name: "irreversible_cycle"
           }
         ]
       }
     }}
  end

  def resume_irreversible(context, decision, edited_action \\ nil) do
    if owner = Map.get(context, :owner) do
      send(owner, {:sagents_resumed, decision, edited_action})
    end

    case decision do
      :reject ->
        {:ok, %{decision: :rejected, action: action(), mutated: false}}

      _ ->
        applied_action = edited_action || action()

        {:ok,
         %{
           decision: if(decision == :approve, do: :approved, else: :edited),
           action: applied_action,
           state: Map.merge(ProteinLoop.SimulatorClient.fallback_state(), %{"day" => 1}),
           reward: 201.5,
           verification: %{"ok" => true, "violations" => [], "warnings" => []},
           mutated: true
         }}
    end
  end

  def action do
    %{
      "feed_kg" => 0.1,
      "aeration_hours" => 12.0,
      "water_exchange_fraction" => 0.15,
      "duckweed_harvest_kg" => 0.5,
      "note" => "test Sagents action"
    }
  end

  defp maybe_pause(kind) do
    case Application.get_env(:proteinloop, :test_sagents_runtime_pause) do
      {^kind, owner} when is_pid(owner) ->
        send(owner, {:test_sagents_runtime_started, kind, self()})

        receive do
          {:continue_test_sagents_runtime, ^kind} -> :ok
        after
          1_000 -> :ok
        end

      _other ->
        :ok
    end
  end
end
