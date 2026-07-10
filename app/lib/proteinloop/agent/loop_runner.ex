defmodule ProteinLoop.Agent.LoopRunner do
  @moduledoc """
  Deterministic offline loop fallback retained for tests and judge rehearsal.

  Sagents exposes agent execution as explicit steps. This module mirrors the
  project-specific contract without requiring live model credentials:
  propose, verify through the simulator boundary, execute, then terminate via
  a structured `until_tool` result.
  """

  alias ProteinLoop.Agent.ActionProposer
  alias ProteinLoop.SimulatorClient

  @default_until_tool "close_cycle"

  def run(opts \\ []) do
    simulator = Keyword.get(opts, :simulator, SimulatorClient)
    provider = Keyword.get(opts, :provider, :stub_safe)
    target_day = Keyword.get(opts, :target_day, 3)
    max_runs = Keyword.get(opts, :max_runs, 8)
    until_tool = Keyword.get(opts, :until_tool, @default_until_tool)

    with {:ok, %{"state" => state}} <- simulator.state() do
      do_run(simulator, state, %{
        provider: provider,
        target_day: target_day,
        max_runs: max_runs,
        until_tool: until_tool,
        runs: 0,
        steps: [],
        rewards: []
      })
    end
  end

  defp do_run(simulator, state, context) do
    cond do
      target_reached?(state, context) ->
        complete(state, context)

      context.runs >= context.max_runs ->
        halt_max_runs(state, context)

      true ->
        propose_and_continue(simulator, state, context)
    end
  end

  defp complete(state, context) do
    tool_result = tool_result(context.until_tool, state, context)

    {:ok,
     %{
       state: state,
       tool_result: tool_result,
       steps: Enum.reverse([step(:until_tool, :completed, tool_result) | context.steps]),
       runs: context.runs,
       reward: List.first(context.rewards)
     }}
  end

  defp halt_max_runs(state, context) do
    {:error,
     %{
       reason: :max_runs_exceeded,
       state: state,
       steps:
         Enum.reverse([
           step(:check_max_runs, :halted, %{max_runs: context.max_runs}) | context.steps
         ]),
       runs: context.runs
     }}
  end

  defp propose_and_continue(simulator, state, context) do
    case ActionProposer.propose(state, provider: context.provider) do
      {:ok, action, metadata} ->
        context =
          context
          |> bump_run()
          |> add_step(:call_llm, :proposed, %{provider: metadata.provider, note: action["note"]})

        verify_and_execute(simulator, state, action, metadata, context)

      {:error, reason} ->
        {:error,
         %{
           reason: reason,
           state: state,
           steps:
             Enum.reverse(add_step(context, :call_llm, :error, %{reason: inspect(reason)}).steps),
           runs: context.runs
         }}
    end
  end

  defp target_reached?(state, context) do
    context.runs > 0 and is_number(context.target_day) and
      Map.get(state, "day", 0) >= context.target_day
  end

  defp verify_and_execute(simulator, original_state, action, metadata, context) do
    case simulator.step(action) do
      {:ok, %{"state" => state, "reward" => reward, "verification" => verification}} ->
        context =
          context
          |> add_step(:verify_ecosystem_safety, :accepted, %{verification: verification})
          |> add_step(:execute_tools, :mutated, %{reward: reward})
          |> add_reward(reward)

        do_run(simulator, state, context)

      {:error, %{body: %{"verification" => verification} = body}} ->
        {:rejected,
         %{
           accepted?: false,
           action: action,
           metadata: metadata,
           original_state: original_state,
           state: original_state,
           reward: nil,
           verification: verification,
           error: body,
           steps:
             context
             |> add_step(:verify_ecosystem_safety, :rejected, %{verification: verification})
             |> Map.fetch!(:steps)
             |> Enum.reverse(),
           runs: context.runs
         }}

      {:error, reason} ->
        {:error,
         %{
           reason: reason,
           state: original_state,
           steps:
             context
             |> add_step(:verify_ecosystem_safety, :error, %{reason: inspect(reason)})
             |> Map.fetch!(:steps)
             |> Enum.reverse(),
           runs: context.runs
         }}
    end
  end

  defp bump_run(context), do: Map.update!(context, :runs, &(&1 + 1))

  defp add_reward(context, reward), do: Map.update!(context, :rewards, &[reward | &1])

  defp add_step(context, name, status, details) do
    Map.update!(context, :steps, &[step(name, status, details) | &1])
  end

  defp step(name, status, details) do
    %{
      name: Atom.to_string(name),
      status: Atom.to_string(status),
      details: details
    }
  end

  defp tool_result(tool_name, state, context) do
    %{
      "tool" => tool_name,
      "content" => %{
        "final_day" => state["day"],
        "collapsed" => state["collapsed"] || false,
        "target_day" => context.target_day,
        "runs" => context.runs,
        "latest_reward" => List.first(context.rewards)
      }
    }
  end
end
