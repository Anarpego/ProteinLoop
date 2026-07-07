defmodule ProteinLoop.Agent.MeshEvidence do
  @moduledoc """
  Evidence packet for the deterministic self-healing mesh demo.

  The packet is generated from the same mesh model used by the dashboard so
  submission artifacts and UI behavior stay aligned.
  """

  alias ProteinLoop.Agent.Mesh

  def build do
    initial = Mesh.initial()
    failed = Mesh.fail_edge_node(initial, "edge-tank-a")
    recovered = Mesh.recover_node(failed, "edge-tank-a")

    migrated_agents =
      initial.agents
      |> Enum.filter(&(&1.node_id == "edge-tank-a"))
      |> Enum.map(fn before ->
        after_migration = Enum.find(failed.agents, &(&1.id == before.id))
        after_recovery = Enum.find(recovered.agents, &(&1.id == before.id))

        %{
          id: before.id,
          label: before.label,
          from_node: before.node_id,
          migrated_to: after_migration.node_id,
          node_after_recovery: after_recovery.node_id,
          state_token: after_migration.state_token,
          state_token_preserved?: after_migration.state_token == before.state_token,
          identity_preserved?: after_migration.label == before.label,
          migrations: after_migration.migrations
        }
      end)

    %{
      title: "ProteinLoop self-healing mesh evidence",
      failed_node: "edge-tank-a",
      checks: %{
        failed_node_offline?: node_online?(failed, "edge-tank-a") == false,
        all_agents_left_failed_node?: Enum.all?(failed.agents, &(&1.node_id != "edge-tank-a")),
        migration_count: failed.migration_count,
        state_tokens_preserved?: Enum.all?(migrated_agents, & &1.state_token_preserved?),
        identities_preserved?: Enum.all?(migrated_agents, & &1.identity_preserved?),
        recovered_node_online?: node_online?(recovered, "edge-tank-a"),
        agents_stay_on_migrated_nodes_after_recovery?:
          Enum.all?(migrated_agents, &(&1.node_after_recovery == &1.migrated_to))
      },
      initial: snapshot(initial),
      after_failure: snapshot(failed),
      after_recovery: snapshot(recovered),
      migrated_agents: migrated_agents
    }
  end

  def to_jsonable(packet) when is_map(packet), do: jsonable(packet)

  def render_markdown(packet) do
    checks = packet.checks

    lines = [
      "# ProteinLoop Mesh Evidence",
      "",
      "Generated from the deterministic Elixir mesh model used by the operator dashboard.",
      "",
      "## Summary",
      "",
      "- Failed node: #{packet.failed_node}.",
      "- Migration count: #{checks.migration_count}.",
      "- Failed node offline: #{checks.failed_node_offline?}.",
      "- Agents left failed node: #{checks.all_agents_left_failed_node?}.",
      "- State tokens preserved: #{checks.state_tokens_preserved?}.",
      "- Recovered node online: #{checks.recovered_node_online?}.",
      "",
      "## Migrated Agents",
      ""
    ]

    agent_lines =
      Enum.map(packet.migrated_agents, fn agent ->
        "- #{agent.label}: #{agent.from_node} -> #{agent.migrated_to}; token #{agent.state_token}; migrations #{agent.migrations}."
      end)

    event_lines = [
      "",
      "## Events",
      "",
      "- After failure: #{Enum.join(packet.after_failure.events, " | ")}",
      "- After recovery: #{Enum.join(packet.after_recovery.events, " | ")}",
      ""
    ]

    Enum.join(lines ++ agent_lines ++ event_lines, "\n")
  end

  defp snapshot(mesh) do
    %{
      nodes: mesh.nodes,
      agents: mesh.agents,
      events: mesh.events,
      migration_count: mesh.migration_count,
      failed_node: mesh.failed_node
    }
  end

  defp node_online?(mesh, node_id) do
    Enum.any?(mesh.nodes, &(&1.id == node_id and &1.online?))
  end

  defp jsonable(value) when is_map(value) do
    Map.new(value, fn {key, nested} -> {json_key(key), jsonable(nested)} end)
  end

  defp jsonable(value) when is_list(value), do: Enum.map(value, &jsonable/1)
  defp jsonable(value) when is_tuple(value), do: Tuple.to_list(value) |> jsonable()
  defp jsonable(value), do: value

  defp json_key(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> String.trim_trailing("?")
  end

  defp json_key(key), do: key
end
