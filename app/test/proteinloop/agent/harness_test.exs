defmodule ProteinLoop.Agent.HarnessTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.Harness

  defmodule AcceptingSimulator do
    def state do
      {:ok,
       %{
         "state" => %{
           "ammonia_mg_l" => 0.4,
           "dissolved_oxygen_mg_l" => 6.7,
           "aquatic_biomass_kg" => 14.5
         }
       }}
    end

    def step(action) do
      {:ok,
       %{
         "state" => %{"day" => 1, "ammonia_mg_l" => 0.35},
         "reward" => 125.0,
         "verification" => %{"ok" => true, "violations" => []},
         "action" => action
       }}
    end
  end

  defmodule RejectingSimulator do
    def state do
      {:ok,
       %{
         "state" => %{
           "ammonia_mg_l" => 0.4,
           "dissolved_oxygen_mg_l" => 6.7,
           "aquatic_biomass_kg" => 14.5
         }
       }}
    end

    def step(_action) do
      {:error,
       %{
         status: 400,
         body: %{
           "error" => "unsafe action",
           "verification" => %{
             "ok" => false,
             "violations" => ["feed_kg 4.000 exceeds safe daily limit 0.508"]
           }
         }
       }}
    end
  end

  test "accepted proposal returns verifier evidence and new state" do
    trace_path = tmp_path("accepted.jsonl")

    assert {:ok, result} =
             Harness.run(
               simulator: AcceptingSimulator,
               provider: :stub_safe,
               trace_path: trace_path
             )

    assert result.accepted?
    assert result.reward == 125.0
    assert result.verification["ok"]
    assert result.trace.count == 1
    assert File.read!(trace_path) =~ ~s("accepted":true)
  end

  test "rejected proposal keeps original state and returns violations" do
    trace_path = tmp_path("rejected.jsonl")

    assert {:rejected, result} =
             Harness.run(
               simulator: RejectingSimulator,
               provider: :stub_unsafe,
               trace_path: trace_path
             )

    refute result.accepted?
    assert result.state == result.original_state
    assert hd(result.verification["violations"]) =~ "feed_kg"
    assert result.trace.count == 1
    assert File.read!(trace_path) =~ ~s("accepted":false)
  end

  defp tmp_path(name) do
    Path.join([
      System.tmp_dir!(),
      "proteinloop-#{System.system_time(:nanosecond)}-#{System.unique_integer([:positive, :monotonic])}",
      name
    ])
  end
end
