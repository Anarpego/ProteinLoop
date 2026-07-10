defmodule ProteinLoop.Agent.HordeRuntime do
  @moduledoc """
  Runs a verifier-gated Sagents supervisor as a Horde-managed `AgentServer`.

  The probe is intentionally a real model cycle. Completion persists the
  canonical Sagents state before a Docker node is stopped for failover proof.
  """

  alias LangChain.Message
  alias Sagents.AgentServer
  alias Sagents.AgentsDynamicSupervisor
  alias Sagents.State

  alias ProteinLoop.Agent.HordePersistence
  alias ProteinLoop.Agent.SagentsRuntime
  alias ProteinLoop.SimulatorClient

  @default_timeout 120_000

  def start_probe(opts \\ []) do
    distribution =
      Keyword.get(opts, :distribution, Application.get_env(:sagents, :distribution, :local))

    if distribution == :horde do
      do_start_probe(opts)
    else
      {:error, :horde_not_enabled}
    end
  end

  def build_probe(ecosystem_state, opts \\ []) when is_map(ecosystem_state) do
    agent_id = Keyword.get_lazy(opts, :agent_id, &unique_agent_id/0)
    state_token = Keyword.get_lazy(opts, :state_token, &unique_state_token/0)

    agent =
      SagentsRuntime.build_supervisor_agent(
        ecosystem_state,
        Keyword.put(opts, :agent_id, agent_id)
      )

    state =
      State.new!(%{
        messages: [
          Message.new_user!(
            "Run one conservative ProteinLoop cycle and call close_cycle exactly once. " <>
              "Failover checkpoint: #{state_token}. Current state: #{Jason.encode!(ecosystem_state)}"
          )
        ],
        metadata: %{
          "state_token" => state_token,
          "probe_kind" => "horde_failover",
          "created_on_node" => to_string(node())
        }
      })

    {agent, state, %{agent_id: agent_id, state_token: state_token}}
  end

  def snapshot(agent_id) when is_binary(agent_id) do
    with {:ok, agent_metadata} <- AgentServer.get_metadata(agent_id),
         exported when is_map(exported) <- AgentServer.export_state(agent_id),
         {:ok, persistence} <- HordePersistence.metadata(agent_id) do
      state = exported["state"] || %{}
      metadata = state["metadata"] || %{}

      {:ok,
       %{
         agent_id: agent_id,
         owner_node: agent_metadata.node |> to_string(),
         observer_node: to_string(node()),
         connected_nodes: connected_nodes(),
         distribution: Application.get_env(:sagents, :distribution, :local),
         status: agent_metadata.status,
         state_token: metadata["state_token"],
         state_fingerprint: HordePersistence.canonical_fingerprint(exported),
         message_count: length(state["messages"] || []),
         persistence: persistence
       }}
    else
      {:error, _reason} = error -> error
      other -> {:error, {:invalid_probe_snapshot, other}}
    end
  catch
    :exit, reason -> {:error, {:probe_unavailable, reason}}
  end

  def await_probe(agent_id, timeout \\ @default_timeout, opts \\ []) do
    deadline = System.monotonic_time(:millisecond) + timeout
    await_status(agent_id, deadline, false, opts)
  end

  def delete_probe(agent_id) when is_binary(agent_id) do
    if AgentServer.running?(agent_id) do
      AgentsDynamicSupervisor.stop_agent(agent_id)
    end

    HordePersistence.delete(agent_id)
  end

  def cluster_status do
    %{
      node: to_string(node()),
      connected_nodes: connected_nodes(),
      distribution: Application.get_env(:sagents, :distribution, :local),
      horde: Application.get_env(:sagents, :horde, []) |> Map.new(),
      managed_agents: AgentServer.list_running_agents() |> Enum.sort()
    }
  end

  defp do_start_probe(opts) do
    state_fun = Keyword.get(opts, :state_fun, &SimulatorClient.state/0)

    start_agent_fun =
      Keyword.get(opts, :start_agent_fun, &AgentsDynamicSupervisor.start_agent_sync/1)

    execute_fun = Keyword.get(opts, :execute_fun, &AgentServer.execute/1)
    await_fun = Keyword.get(opts, :await_fun, &await_probe/2)
    stop_agent_fun = Keyword.get(opts, :stop_agent_fun, &AgentsDynamicSupervisor.stop_agent/1)
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    with {:ok, %{"state" => ecosystem_state}} <- state_fun.(),
         {agent, state, metadata} <- build_probe(ecosystem_state, opts),
         {:ok, _pid} <-
           start_agent_fun.(
             agent_id: metadata.agent_id,
             agent: agent,
             initial_state: state,
             conversation_id: metadata.agent_id,
             agent_persistence: HordePersistence,
             inactivity_timeout: nil,
             startup_timeout: 15_000
           ) do
      execute_and_await(metadata.agent_id, timeout, execute_fun, await_fun, stop_agent_fun)
    else
      {:error, _reason} = error -> error
      other -> {:error, {:invalid_probe_start_result, other}}
    end
  end

  defp execute_and_await(agent_id, timeout, execute_fun, await_fun, stop_agent_fun) do
    result =
      with :ok <- execute_fun.(agent_id),
           {:ok, snapshot} <- await_fun.(agent_id, timeout) do
        {:ok, snapshot}
      else
        {:error, _reason} = error -> error
        other -> {:error, {:invalid_probe_execution_result, other}}
      end

    case result do
      {:ok, _snapshot} = success ->
        success

      {:error, _reason} = error ->
        _ = stop_agent_fun.(agent_id)
        error
    end
  end

  defp await_status(agent_id, deadline, observed_running?, opts) do
    status_fun = Keyword.get(opts, :status_fun, &AgentServer.get_status/1)

    case status_fun.(agent_id) do
      :running ->
        wait_or_timeout(agent_id, deadline, true, opts)

      :idle when observed_running? ->
        snapshot_fun(opts).(agent_id)

      :idle ->
        case snapshot_fun(opts).(agent_id) do
          {:ok, _snapshot} = completed -> completed
          {:error, _reason} -> wait_or_timeout(agent_id, deadline, false, opts)
        end

      :error ->
        {:error, {:probe_execution_failed, AgentServer.get_info(agent_id).error}}

      :interrupted ->
        {:error, :probe_unexpectedly_interrupted}

      :not_running ->
        wait_or_timeout(agent_id, deadline, observed_running?, opts)

      status ->
        {:error, {:unexpected_probe_status, status}}
    end
  end

  defp wait_or_timeout(agent_id, deadline, observed_running?, opts) do
    if System.monotonic_time(:millisecond) < deadline do
      Process.sleep(100)
      await_status(agent_id, deadline, observed_running?, opts)
    else
      {:error, {:probe_timeout, agent_id}}
    end
  end

  defp snapshot_fun(opts), do: Keyword.get(opts, :snapshot_fun, &snapshot/1)

  defp connected_nodes do
    [node() | Node.list()]
    |> Enum.map(&to_string/1)
    |> Enum.sort()
  end

  defp unique_agent_id do
    "proteinloop-horde-probe-#{System.unique_integer([:positive, :monotonic])}"
  end

  defp unique_state_token do
    :crypto.strong_rand_bytes(18)
    |> Base.url_encode64(padding: false)
  end
end
