defmodule ProteinLoop.Agent.SagentsRuntimeTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.SagentsRuntime
  alias ProteinLoop.Agent.SafetyMode
  alias ProteinLoop.TestChatModel

  test "builds a real Sagents supervisor with SubAgent and HITL middleware" do
    agent =
      SagentsRuntime.build_supervisor_agent(initial_state(),
        agent_id: "stable-supervisor-id",
        model_factory: model_factory(),
        verify_fun: &safe_verify/1,
        step_fun: &accepted_step/1
      )

    assert %Sagents.Agent{mode: SafetyMode} = agent
    assert agent.agent_id == "stable-supervisor-id"

    status = SagentsRuntime.describe(agent)
    assert status.framework == "sagents"
    assert status.version == "0.9.0"
    assert status.distribution == :local
    assert status.execution_mode == SafetyMode
    assert status.until_tool == "close_cycle"

    assert status.subagents == [
             "fish-tank",
             "freshwater-prawn",
             "hydroponia",
             "duckweed-chickens"
           ]

    assert status.agent_count == 5

    assert status.hitl_tools == ["irreversible_cycle"]
  end

  test "reports an accurate runtime status without calling the model" do
    status =
      SagentsRuntime.status(
        endpoint: "http://127.0.0.1:8001",
        model: "google/gemma-4-E2B-it"
      )

    assert status.framework == "sagents"
    assert status.framework_version == "0.9.0"
    assert status.langchain_version == "0.9.2"
    assert status.execution_mode == SafetyMode
    assert status.distribution == :local
    assert status.endpoint_configured?
    assert status.model == "google/gemma-4-E2B-it"
    assert status.termination == "until_tool_success"
    assert status.subagent_runtime == Sagents.SubAgent

    assert status.subagents == [
             "fish-tank",
             "freshwater-prawn",
             "hydroponia",
             "duckweed-chickens"
           ]

    assert status.agent_count == 5
  end

  test "runs four subsystem agents and completes through until_tool_success" do
    assert {:ok, result} =
             SagentsRuntime.run(
               state_fun: fn -> {:ok, %{"state" => initial_state()}} end,
               model_factory: model_factory(),
               verify_fun: &safe_verify/1,
               step_fun: &accepted_step/1
             )

    assert result.framework == "sagents"
    assert result.termination == "until_tool_success"
    assert result.tool == "close_cycle"
    assert result.action == safe_action()
    assert result.verification["ok"]
    assert result.state["day"] == 1
    assert result.reward == 202.0

    assert Enum.map(result.subagents, & &1.name) == [
             "fish-tank",
             "freshwater-prawn",
             "hydroponia",
             "duckweed-chickens"
           ]

    assert Enum.all?(result.subagents, &(&1.runtime == Sagents.SubAgent))
  end

  test "emits progress from real observation, agent, verifier, and mutation boundaries" do
    owner = self()
    progress_fun = fn event -> send(owner, {:sagents_progress, event}) end

    assert {:ok, _result} =
             SagentsRuntime.run(
               state_fun: fn -> {:ok, %{"state" => initial_state()}} end,
               model_factory: model_factory(),
               verify_fun: &safe_verify/1,
               step_fun: &accepted_step/1,
               progress_fun: progress_fun
             )

    assert_receive {:sagents_progress,
                    {:state_observed,
                     %{
                       day: 0,
                       ammonia_mg_l: 0.35,
                       dissolved_oxygen_mg_l: 6.8
                     }}}

    specialist_events =
      for _index <- 1..8 do
        assert_receive {:sagents_progress, event}
        event
      end

    assert MapSet.new(for {:specialist_started, name} <- specialist_events, do: name) ==
             MapSet.new([
               "fish-tank",
               "freshwater-prawn",
               "hydroponia",
               "duckweed-chickens"
             ])

    completed =
      for {:specialist_completed, name, report} <- specialist_events,
          into: %{},
          do: {name, report}

    assert map_size(completed) == 4

    assert completed["fish-tank"]["recommendation"] ==
             "preserve oxygen and nutrient balance"

    assert_receive {:sagents_progress, {:supervisor_started, %{specialist_count: 4}}}
    assert_receive {:sagents_progress, {:verification_started, action}}
    assert action == safe_action()

    assert_receive {:sagents_progress,
                    {:verification_completed, %{ok: true, violations: [], warnings: []}}}

    assert_receive {:sagents_progress, {:action_application_started, action}}
    assert action == safe_action()

    assert_receive {:sagents_progress,
                    {:action_application_completed,
                     %{day: 1, ammonia_mg_l: 0.35, dissolved_oxygen_mg_l: 6.8, reward: 202.0}}}
  end

  test "propagates the operator mission to every model and preserves the before state" do
    mission = "Recover water quality while protecting fish and prawn survival."

    assert {:ok, result} =
             SagentsRuntime.run(
               mission: mission,
               state_fun: fn -> {:ok, %{"state" => initial_state()}} end,
               model_factory: model_factory(observer: self()),
               verify_fun: &safe_verify/1,
               step_fun: &accepted_step/1
             )

    assert result.mission == mission
    assert result.before_state == initial_state()

    calls =
      for _index <- 1..5 do
        assert_receive {:test_chat_model_call, tool_name, messages}
        {tool_name, messages}
      end

    assert Enum.count(calls, fn {tool_name, _messages} ->
             tool_name == "report_recommendation"
           end) == 4

    assert Enum.count(calls, fn {tool_name, _messages} -> tool_name == "close_cycle" end) == 1

    assert Enum.all?(calls, fn {_tool_name, messages} ->
             inspect(messages) =~ mission
           end)
  end

  test "returns the named subsystem failure without crashing the orchestrator" do
    failing_factory = fn
      "report_recommendation" -> TestChatModel.failing("subsystem unavailable")
      tool_name -> model_factory().(tool_name)
    end

    assert {:error,
            {:subsystem_agent_failed,
             {"fish-tank", %LangChain.LangChainError{type: "test_model_error"}}}} =
             SagentsRuntime.run(
               state_fun: fn -> {:ok, %{"state" => initial_state()}} end,
               model_factory: failing_factory,
               verify_fun: &safe_verify/1,
               step_fun: &accepted_step/1
             )
  end

  test "uses deterministic local inference settings" do
    agent =
      SagentsRuntime.build_supervisor_agent(initial_state(),
        endpoint: "http://127.0.0.1:8001",
        model: "google/gemma-4-E2B-it",
        verify_fun: &safe_verify/1,
        step_fun: &accepted_step/1
      )

    assert agent.model.temperature == 0.0
    assert agent.model.stream == false
    assert agent.model.parallel_tool_calls == false
  end

  test "uses a versioned endpoint without duplicating the v1 path" do
    agent =
      SagentsRuntime.build_supervisor_agent(initial_state(),
        endpoint: "http://gemma:8001/v1",
        model: "google/gemma-4-E2B-it",
        verify_fun: &safe_verify/1,
        step_fun: &accepted_step/1
      )

    assert agent.model.endpoint == "http://gemma:8001/v1/chat/completions"
  end

  test "irreversible requests expose no alternate simulator mutation tool" do
    agent =
      SagentsRuntime.build_supervisor_agent(initial_state(),
        supervisor_tool: "irreversible_cycle",
        model_factory: model_factory(),
        verify_fun: &safe_verify/1,
        step_fun: &accepted_step/1
      )

    tool_names = Enum.map(agent.tools, & &1.name)

    assert "irreversible_cycle" in tool_names
    refute "close_cycle" in tool_names
  end

  test "HITL interrupts an irreversible tool before simulator mutation" do
    owner = self()

    assert {:interrupt, pending} =
             SagentsRuntime.request_irreversible(initial_state(),
               model_factory: model_factory(),
               verify_fun: &safe_verify/1,
               step_fun: fn action ->
                 send(owner, {:mutated, action})
                 accepted_step(action)
               end
             )

    assert pending.tool == "irreversible_cycle"
    assert pending.allowed_decisions == [:approve, :edit, :reject]
    assert pending.interrupt_data.action_requests != []
    refute_received {:mutated, _action}
  end

  test "HITL approval resumes through Sagents and mutates exactly once" do
    owner = self()

    assert {:interrupt, pending} =
             SagentsRuntime.request_irreversible(initial_state(),
               model_factory: model_factory(),
               verify_fun: &safe_verify/1,
               step_fun: fn action ->
                 send(owner, {:mutated, action})
                 accepted_step(action)
               end
             )

    assert {:ok, result} = SagentsRuntime.resume_irreversible(pending, :approve)
    assert result.decision == :approved
    assert result.action["water_exchange_fraction"] == 0.2
    assert_receive {:mutated, _action}
    refute_receive {:mutated, _action}
  end

  test "HITL edit executes the producer action and rejection never mutates" do
    owner = self()

    runtime_opts = [
      model_factory: model_factory(),
      verify_fun: &safe_verify/1,
      step_fun: fn action ->
        send(owner, {:mutated, action})
        accepted_step(action)
      end
    ]

    assert {:interrupt, edit_pending} =
             SagentsRuntime.request_irreversible(initial_state(), runtime_opts)

    edited = %{safe_action() | "water_exchange_fraction" => 0.05}
    assert {:ok, edit_result} = SagentsRuntime.resume_irreversible(edit_pending, :edit, edited)
    assert edit_result.decision == :edited
    assert edit_result.action == edited
    assert_receive {:mutated, ^edited}

    assert {:interrupt, reject_pending} =
             SagentsRuntime.request_irreversible(initial_state(), runtime_opts)

    assert {:ok, reject_result} =
             SagentsRuntime.resume_irreversible(reject_pending, :reject)

    assert reject_result.decision == :rejected
    refute reject_result.mutated
    refute_receive {:mutated, _action}
  end

  test "HITL rejects an unsafe producer edit before tool execution" do
    owner = self()

    verify_fun = fn action ->
      if action["feed_kg"] <= 0.25 do
        safe_verify(action)
      else
        {:ok,
         %{
           "action" => action,
           "verification" => %{
             "ok" => false,
             "violations" => ["feed_kg exceeds safe daily limit"],
             "warnings" => []
           }
         }}
      end
    end

    assert {:interrupt, pending} =
             SagentsRuntime.request_irreversible(initial_state(),
               model_factory: model_factory(),
               verify_fun: verify_fun,
               step_fun: fn action ->
                 send(owner, {:mutated, action})
                 accepted_step(action)
               end
             )

    unsafe_edit = %{safe_action() | "feed_kg" => 4.0}

    assert {:error, {:unsafe_edited_action, verification}} =
             SagentsRuntime.resume_irreversible(pending, :edit, unsafe_edit)

    refute verification["ok"]
    refute_receive {:mutated, _action}
  end

  defp model_factory(opts \\ []) do
    observer = Keyword.get(opts, :observer)

    fn
      "report_recommendation" ->
        TestChatModel.new(
          "report_recommendation",
          %{
            "status" => "stable",
            "recommendation" => "preserve oxygen and nutrient balance",
            "resource_request" => "balanced"
          },
          observer: observer
        )

      "close_cycle" ->
        TestChatModel.new("close_cycle", safe_action(), observer: observer)

      "irreversible_cycle" ->
        TestChatModel.new(
          "irreversible_cycle",
          %{
            safe_action()
            | "water_exchange_fraction" => 0.2,
              "duckweed_harvest_kg" => 0.4,
              "note" => "requires producer approval"
          },
          observer: observer
        )
    end
  end

  defp safe_verify(action) do
    {:ok,
     %{
       "action" => action,
       "verification" => %{"ok" => true, "violations" => [], "warnings" => []}
     }}
  end

  defp accepted_step(_action) do
    {:ok,
     %{
       "state" => Map.put(initial_state(), "day", 1),
       "reward" => 202.0,
       "verification" => %{"ok" => true, "violations" => [], "warnings" => []}
     }}
  end

  defp safe_action do
    %{
      "feed_kg" => 0.1,
      "aeration_hours" => 12.0,
      "water_exchange_fraction" => 0.15,
      "duckweed_harvest_kg" => 0.2,
      "note" => "safe Sagents cycle"
    }
  end

  defp initial_state do
    %{
      "day" => 0,
      "ammonia_mg_l" => 0.35,
      "dissolved_oxygen_mg_l" => 6.8,
      "duckweed_kg" => 3.0,
      "aquatic_biomass_kg" => 14.5,
      "collapsed" => false
    }
  end
end
