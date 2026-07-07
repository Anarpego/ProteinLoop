defmodule ProteinLoop.Agent.MeshEvidenceTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.MeshEvidence

  test "build reports migration and preserved state tokens" do
    packet = MeshEvidence.build()

    assert packet.checks.failed_node_offline?
    assert packet.checks.all_agents_left_failed_node?
    assert packet.checks.migration_count == 2
    assert packet.checks.state_tokens_preserved?
    assert packet.checks.identities_preserved?
    assert length(packet.migrated_agents) == 2
  end

  test "build reports node recovery without moving agents back" do
    packet = MeshEvidence.build()

    assert packet.checks.recovered_node_online?
    assert packet.checks.agents_stay_on_migrated_nodes_after_recovery?
  end

  test "jsonable converts atom keys and question mark keys" do
    jsonable = MeshEvidence.build() |> MeshEvidence.to_jsonable()

    assert jsonable["checks"]["state_tokens_preserved"] == true
    assert jsonable["checks"]["recovered_node_online"] == true
  end

  test "markdown contains migrated agents" do
    markdown = MeshEvidence.build() |> MeshEvidence.render_markdown()

    assert markdown =~ "ProteinLoop Mesh Evidence"
    assert markdown =~ "Fish tank agent"
    assert markdown =~ "edge-tank-a ->"
  end
end
