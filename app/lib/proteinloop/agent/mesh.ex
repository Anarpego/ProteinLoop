defmodule ProteinLoop.Agent.Mesh do
  @moduledoc """
  Deterministic self-healing mesh simulation for the operator demo.

  This is a local, testable model of the behavior we want to show before adding
  real distributed Erlang/Horde coordination.
  """

  @edge_node "edge-tank-a"

  def initial do
    %{
      nodes: [
        %{id: "edge-tank-a", label: "Edge tank A", role: "sensor/actuator", online?: true},
        %{id: "edge-tank-b", label: "Edge tank B", role: "backup controller", online?: true},
        %{id: "cloud-loop", label: "Cloud loop", role: "supervisor", online?: true}
      ],
      agents: [
        agent("fish-tank", "Fish tank agent", "edge-tank-a"),
        agent("hydroponia", "Hydroponia agent", "edge-tank-a"),
        agent("duckweed-chickens", "Duckweed/chickens agent", "edge-tank-b"),
        agent("supervisor", "Supervisor agent", "cloud-loop")
      ],
      events: ["mesh initialized"],
      migration_count: 0,
      failed_node: nil
    }
  end

  def fail_edge_node(mesh, node_id \\ @edge_node) do
    if node_online?(mesh, node_id) do
      {agents, migrated} = migrate_agents(mesh.agents, node_id, online_node_ids(mesh, node_id))

      mesh
      |> Map.put(:nodes, set_node_status(mesh.nodes, node_id, false))
      |> Map.put(:agents, agents)
      |> Map.put(:failed_node, node_id)
      |> Map.update!(:migration_count, &(&1 + migrated))
      |> add_event("#{migrated} agents migrated from #{node_id}")
    else
      add_event(mesh, "#{node_id} already offline")
    end
  end

  def recover_node(mesh, node_id \\ @edge_node) do
    if node_exists?(mesh, node_id) do
      mesh
      |> Map.put(:nodes, set_node_status(mesh.nodes, node_id, true))
      |> Map.put(:failed_node, nil)
      |> add_event("#{node_id} recovered and ready")
    else
      add_event(mesh, "#{node_id} not found")
    end
  end

  def reset, do: initial()

  defp agent(id, label, node_id) do
    %{
      id: id,
      label: label,
      node_id: node_id,
      status: :running,
      state_token: "#{id}:state:v1",
      migrations: 0
    }
  end

  defp migrate_agents(agents, failed_node_id, []), do: {mark_stranded(agents, failed_node_id), 0}

  defp migrate_agents(agents, failed_node_id, online_node_ids) do
    agents
    |> Enum.map_reduce(0, fn agent, count ->
      if agent.node_id == failed_node_id do
        target = Enum.at(online_node_ids, rem(count, length(online_node_ids)))

        {%{agent | node_id: target, status: :running, migrations: agent.migrations + 1},
         count + 1}
      else
        {agent, count}
      end
    end)
  end

  defp mark_stranded(agents, failed_node_id) do
    Enum.map(agents, fn agent ->
      if agent.node_id == failed_node_id, do: %{agent | status: :stranded}, else: agent
    end)
  end

  defp online_node_ids(mesh, failed_node_id) do
    mesh.nodes
    |> Enum.filter(&(&1.online? and &1.id != failed_node_id))
    |> Enum.map(& &1.id)
  end

  defp node_online?(mesh, node_id), do: Enum.any?(mesh.nodes, &(&1.id == node_id and &1.online?))
  defp node_exists?(mesh, node_id), do: Enum.any?(mesh.nodes, &(&1.id == node_id))

  defp set_node_status(nodes, node_id, online?) do
    Enum.map(nodes, fn node ->
      if node.id == node_id, do: %{node | online?: online?}, else: node
    end)
  end

  defp add_event(mesh, event) do
    Map.update!(mesh, :events, fn events -> Enum.take([event | events], 5) end)
  end
end
