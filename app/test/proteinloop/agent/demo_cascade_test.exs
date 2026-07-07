defmodule ProteinLoop.Agent.DemoCascadeTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.DemoCascade

  defmodule DemoSimulator do
    def reset do
      {:ok, %{"state" => %{"day" => 0, "ammonia_mg_l" => 0.35}}}
    end

    def trigger_ammonia_spike do
      {:ok, %{"state" => state()}}
    end

    def state do
      {:ok,
       %{
         "state" => %{
           "day" => 0,
           "ammonia_mg_l" => 4.6,
           "dissolved_oxygen_mg_l" => 4.4,
           "aquatic_biomass_kg" => 14.5
         }
       }}
    end

    def step(%{"feed_kg" => feed_kg}) when feed_kg > 1.0 do
      {:error,
       %{
         status: 400,
         body: %{
           "error" => "unsafe action",
           "verification" => %{
             "ok" => false,
             "violations" => ["feed_kg exceeds safe daily limit"]
           }
         }
       }}
    end

    def step(_action) do
      {:ok,
       %{
         "state" => %{"day" => 1, "ammonia_mg_l" => 2.5},
         "reward" => 88.0,
         "verification" => %{"ok" => true, "violations" => []}
       }}
    end
  end

  test "runs reset, spike, unsafe rejection, and safe recovery" do
    trace_path = tmp_path("cascade.jsonl")

    assert {:ok, result} =
             DemoCascade.run(simulator: DemoSimulator, trace_path: trace_path)

    refute result.unsafe_result.accepted?
    assert result.safe_result.accepted?
    assert result.safe_result.reward == 88.0
    assert result.final_state["ammonia_mg_l"] == 2.5
    assert result.trace_status.count == 2
  end

  defp tmp_path(name) do
    Path.join([
      System.tmp_dir!(),
      "proteinloop-#{System.system_time(:nanosecond)}-#{System.unique_integer([:positive, :monotonic])}",
      name
    ])
  end
end
