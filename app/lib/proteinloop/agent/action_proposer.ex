defmodule ProteinLoop.Agent.ActionProposer do
  @moduledoc """
  Produces structured ecosystem actions for the harness.

  The model may propose actions later, but this module always returns plain
  maps matching the simulator action contract.
  """

  alias ProteinLoop.Agent.OpenAICompatible
  alias ProteinLoop.SimulatorClient

  @unsafe_action %{
    "feed_kg" => 4.0,
    "aeration_hours" => 2.0,
    "water_exchange_fraction" => 0.0,
    "duckweed_harvest_kg" => 0.0,
    "note" => "unsafe_overfeed_demo"
  }

  def propose(state, opts \\ []) when is_map(state) do
    provider =
      opts
      |> Keyword.get(:provider, Application.get_env(:proteinloop, :agent_provider, :stub_safe))
      |> normalize_provider()

    case provider do
      :stub_safe ->
        {:ok, SimulatorClient.proposed_action(state),
         %{
           provider: :stub_safe,
           rationale: "deterministic safe stub based on ammonia and oxygen"
         }}

      :stub_unsafe ->
        {:ok, @unsafe_action,
         %{
           provider: :stub_unsafe,
           rationale: "intentional overfeeding proposal for harness rejection demo"
         }}

      :openai_compatible ->
        OpenAICompatible.propose(state, opts)
    end
  end

  defp normalize_provider(provider) when is_atom(provider), do: provider

  defp normalize_provider(provider) when is_binary(provider) do
    provider
    |> String.downcase()
    |> String.replace("-", "_")
    |> String.to_existing_atom()
  rescue
    ArgumentError -> :stub_safe
  end

  defp normalize_provider(_provider), do: :stub_safe
end
