defmodule ProteinLoop.Agent.LoopRunnerTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.LoopRunner

  defmodule CompletingSimulator do
    @state %{
      "day" => 0,
      "ammonia_mg_l" => 0.4,
      "dissolved_oxygen_mg_l" => 6.8,
      "aquatic_biomass_kg" => 14.5,
      "collapsed" => false
    }

    def state, do: {:ok, %{"state" => @state}}

    def step(_action) do
      {:ok,
       %{
         "state" => %{@state | "day" => 3},
         "reward" => 130.5,
         "verification" => %{"ok" => true, "violations" => []}
       }}
    end
  end

  defmodule RejectingSimulator do
    @state %{
      "day" => 0,
      "ammonia_mg_l" => 0.4,
      "dissolved_oxygen_mg_l" => 6.8,
      "aquatic_biomass_kg" => 14.5,
      "collapsed" => false
    }

    def state, do: {:ok, %{"state" => @state}}

    def step(_action) do
      {:error,
       %{
         status: 400,
         body: %{
           "error" => "unsafe action",
           "verification" => %{"ok" => false, "violations" => ["feed_kg exceeds limit"]}
         }
       }}
    end
  end

  defmodule StalledSimulator do
    @state %{
      "day" => 0,
      "ammonia_mg_l" => 0.4,
      "dissolved_oxygen_mg_l" => 6.8,
      "aquatic_biomass_kg" => 14.5,
      "collapsed" => false
    }

    def state, do: {:ok, %{"state" => @state}}

    def step(_action) do
      {:ok,
       %{
         "state" => @state,
         "reward" => 100.0,
         "verification" => %{"ok" => true, "violations" => []}
       }}
    end
  end

  test "returns structured until_tool completion after verifier-accepted mutation" do
    assert {:ok, result} =
             LoopRunner.run(
               simulator: CompletingSimulator,
               target_day: 3,
               until_tool: "close_cycle"
             )

    assert result.tool_result["tool"] == "close_cycle"
    assert result.tool_result["content"]["final_day"] == 3
    assert result.reward == 130.5

    assert Enum.map(result.steps, & &1.name) == [
             "call_llm",
             "verify_ecosystem_safety",
             "execute_tools",
             "until_tool"
           ]
  end

  test "unsafe proposal stops at verify_ecosystem_safety and preserves state" do
    assert {:rejected, result} =
             LoopRunner.run(
               simulator: RejectingSimulator,
               provider: :stub_unsafe,
               target_day: 3
             )

    assert result.state == result.original_state
    assert hd(result.verification["violations"]) =~ "feed_kg"
    assert Enum.map(result.steps, & &1.name) == ["call_llm", "verify_ecosystem_safety"]
    refute Enum.any?(result.steps, &(&1.name == "execute_tools"))
  end

  test "max run guard stops loops without target progress" do
    assert {:error, result} =
             LoopRunner.run(simulator: StalledSimulator, target_day: 3, max_runs: 2)

    assert result.reason == :max_runs_exceeded
    assert result.runs == 2
    assert List.last(result.steps).name == "check_max_runs"
  end
end
