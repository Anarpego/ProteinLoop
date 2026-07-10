defmodule ProteinLoop.Agent.MeshTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.Mesh

  test "agents on a failed edge node migrate to online nodes" do
    mesh = Mesh.initial()
    assert length(mesh.agents) == 5
    assert Enum.any?(mesh.agents, &(&1.id == "freshwater-prawn"))

    failed = Mesh.fail_edge_node(mesh, "edge-tank-a")

    refute Enum.find(failed.nodes, &(&1.id == "edge-tank-a")).online?
    refute Enum.any?(failed.agents, &(&1.node_id == "edge-tank-a"))
    assert failed.migration_count == 2
    assert Enum.any?(failed.events, &String.contains?(&1, "agents migrated"))
  end

  test "agent identity and state token survive migration" do
    mesh = Mesh.initial()
    fish_before = Enum.find(mesh.agents, &(&1.id == "fish-tank"))

    failed = Mesh.fail_edge_node(mesh, "edge-tank-a")
    fish_after = Enum.find(failed.agents, &(&1.id == "fish-tank"))

    assert fish_after.label == fish_before.label
    assert fish_after.state_token == fish_before.state_token
    assert fish_after.migrations == fish_before.migrations + 1
  end

  test "recovering a node marks it online without moving agents back" do
    mesh =
      Mesh.initial()
      |> Mesh.fail_edge_node("edge-tank-a")
      |> Mesh.recover_node("edge-tank-a")

    assert Enum.find(mesh.nodes, &(&1.id == "edge-tank-a")).online?
    refute Enum.any?(mesh.agents, &(&1.node_id == "edge-tank-a"))
    assert Enum.any?(mesh.events, &String.contains?(&1, "recovered"))
  end
end
