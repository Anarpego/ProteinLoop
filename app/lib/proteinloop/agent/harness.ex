defmodule ProteinLoop.Agent.Harness do
  @moduledoc """
  Agent harness that routes proposed actions through the simulator verifier.

  The harness never mutates ecosystem state directly. Simulator `/step` is the
  verifier and executor boundary.
  """

  alias ProteinLoop.Agent.ActionProposer
  alias ProteinLoop.Agent.TraceStore
  alias ProteinLoop.SimulatorClient

  def run(opts \\ []) do
    simulator = Keyword.get(opts, :simulator, SimulatorClient)

    with {:ok, %{"state" => state}} <- simulator.state(),
         {:ok, action, metadata} <- ActionProposer.propose(state, opts) do
      execute(simulator, state, action, metadata, opts)
    end
  end

  defp execute(simulator, original_state, action, metadata, opts) do
    case simulator.step(action) do
      {:ok, %{"state" => state, "reward" => reward, "verification" => verification}} ->
        result =
          %{
            accepted?: true,
            action: action,
            metadata: metadata,
            original_state: original_state,
            state: state,
            reward: reward,
            verification: verification
          }
          |> record_trace(opts)

        {:ok, result}

      {:error, %{body: %{"verification" => verification} = body}} ->
        result =
          %{
            accepted?: false,
            action: action,
            metadata: metadata,
            original_state: original_state,
            state: original_state,
            reward: nil,
            verification: verification,
            error: body
          }
          |> record_trace(opts)

        {:rejected, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp record_trace(result, opts) do
    case TraceStore.append(result, opts) do
      {:ok, trace} -> Map.put(result, :trace, trace)
      {:error, reason} -> Map.put(result, :trace_error, reason)
    end
  end
end
