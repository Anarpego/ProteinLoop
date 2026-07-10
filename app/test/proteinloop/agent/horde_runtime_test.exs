defmodule ProteinLoop.Agent.HordeRuntimeTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.HordePersistence
  alias ProteinLoop.Agent.HordeRuntime
  alias ProteinLoop.Agent.SafetyMode
  alias ProteinLoop.TestChatModel

  test "builds a stable managed probe around the verifier-gated supervisor" do
    {agent, state, metadata} =
      HordeRuntime.build_probe(initial_state(),
        agent_id: "proteinloop-horde-probe-test",
        state_token: "state-token-test",
        model_factory: model_factory(),
        verify_fun: &safe_verify/1,
        step_fun: &accepted_step/1
      )

    assert agent.agent_id == "proteinloop-horde-probe-test"
    assert agent.mode == SafetyMode
    assert state.metadata["state_token"] == "state-token-test"
    assert state.metadata["probe_kind"] == "horde_failover"
    assert metadata.agent_id == agent.agent_id
    assert metadata.state_token == "state-token-test"
  end

  test "starts and executes the probe through managed Sagents APIs" do
    owner = self()
    expected = %{agent_id: "probe-managed", owner_node: "peer@host", state_token: "token-managed"}

    assert {:ok, ^expected} =
             HordeRuntime.start_probe(
               distribution: :horde,
               agent_id: "probe-managed",
               state_token: "token-managed",
               state_fun: fn -> {:ok, %{"state" => initial_state()}} end,
               model_factory: model_factory(),
               verify_fun: &safe_verify/1,
               step_fun: &accepted_step/1,
               start_agent_fun: fn options ->
                 send(owner, {:managed_start, options})
                 {:ok, self()}
               end,
               execute_fun: fn agent_id ->
                 send(owner, {:managed_execute, agent_id})
                 :ok
               end,
               await_fun: fn agent_id, timeout ->
                 send(owner, {:managed_await, agent_id, timeout})
                 {:ok, expected}
               end
             )

    assert_receive {:managed_start, options}
    assert options[:agent_id] == "probe-managed"
    assert options[:agent_persistence] == HordePersistence
    assert options[:inactivity_timeout] == nil
    assert options[:initial_state].metadata["state_token"] == "token-managed"
    assert_receive {:managed_execute, "probe-managed"}
    assert_receive {:managed_await, "probe-managed", 120_000}
  end

  test "refuses to claim real Horde evidence while distribution is local" do
    assert {:error, :horde_not_enabled} =
             HordeRuntime.start_probe(
               distribution: :local,
               state_fun: fn -> flunk("state must not be requested") end
             )
  end

  test "stops a managed probe when execution fails after startup" do
    owner = self()

    assert {:error, :execution_failed} =
             HordeRuntime.start_probe(
               distribution: :horde,
               agent_id: "probe-cleanup",
               state_fun: fn -> {:ok, %{"state" => initial_state()}} end,
               model_factory: model_factory(),
               verify_fun: &safe_verify/1,
               step_fun: &accepted_step/1,
               start_agent_fun: fn _options -> {:ok, self()} end,
               execute_fun: fn _agent_id -> {:error, :execution_failed} end,
               stop_agent_fun: fn agent_id ->
                 send(owner, {:managed_stop, agent_id})
                 :ok
               end
             )

    assert_receive {:managed_stop, "probe-cleanup"}
  end

  test "recognizes a probe that completes before the first status poll" do
    expected = %{agent_id: "probe-fast", status: :idle}

    assert {:ok, ^expected} =
             HordeRuntime.await_probe("probe-fast", 50,
               status_fun: fn "probe-fast" -> :idle end,
               snapshot_fun: fn "probe-fast" -> {:ok, expected} end
             )
  end

  defp model_factory do
    fn tool_name -> TestChatModel.new(tool_name, safe_action()) end
  end

  defp safe_verify(action) do
    {:ok,
     %{
       "action" => action,
       "verification" => %{"ok" => true, "violations" => [], "warnings" => []}
     }}
  end

  defp accepted_step(action) do
    {:ok,
     %{
       "action" => action,
       "state" => Map.put(initial_state(), "day", 1),
       "reward" => 202.0,
       "verification" => %{"ok" => true, "violations" => [], "warnings" => []}
     }}
  end

  defp safe_action do
    %{
      "feed_kg" => 0.1,
      "aeration_hours" => 12.0,
      "water_exchange_fraction" => 0.1,
      "duckweed_harvest_kg" => 0.2,
      "note" => "horde probe"
    }
  end

  defp initial_state do
    %{
      "day" => 0,
      "ammonia_mg_l" => 0.35,
      "dissolved_oxygen_mg_l" => 6.8,
      "duckweed_kg" => 3.0,
      "collapsed" => false
    }
  end
end
