defmodule ProteinLoop.Agent.DemoCascade do
  @moduledoc """
  One-click demo sequence for the core ProteinLoop pitch.

  The sequence intentionally includes a verifier rejection before a safe
  recovery action so judges can see the harness boundary doing real work.
  """

  alias ProteinLoop.Agent.Harness
  alias ProteinLoop.Agent.TraceStore
  alias ProteinLoop.SimulatorClient

  def run(opts \\ []) do
    simulator = Keyword.get(opts, :simulator, SimulatorClient)

    with {:ok, %{"state" => reset_state}} <- simulator.reset(),
         {:ok, %{"state" => spike_state}} <- simulator.trigger_ammonia_spike(),
         {:rejected, unsafe_result} <-
           Harness.run(Keyword.merge(opts, simulator: simulator, provider: :stub_unsafe)),
         {:ok, safe_result} <-
           Harness.run(Keyword.merge(opts, simulator: simulator, provider: :stub_safe)) do
      {:ok,
       %{
         reset_state: reset_state,
         spike_state: spike_state,
         unsafe_result: unsafe_result,
         safe_result: safe_result,
         final_state: safe_result.state,
         trace_status: TraceStore.status(opts)
       }}
    end
  end
end
