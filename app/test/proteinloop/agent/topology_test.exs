defmodule ProteinLoop.Agent.TopologyTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.Topology

  test "critical ammonia raises fish tank and supervisor risk" do
    topology =
      Topology.from_state(%{
        "ammonia_mg_l" => 4.2,
        "dissolved_oxygen_mg_l" => 4.0,
        "nitrate_mg_l" => 35.0,
        "plant_biomass_kg" => 5.0,
        "duckweed_kg" => 3.0,
        "chicken_count" => 6,
        "collapsed" => false
      })

    fish = Enum.find(topology, &(&1.name == "Fish tank agent"))
    supervisor = Enum.find(topology, &(&1.name == "Supervisor agent"))

    assert fish.status == :critical
    assert fish.focus == "ammonia control"
    assert supervisor.status == :critical
    assert supervisor.tension > 0.8
  end

  test "stable state keeps subsystem agents non-critical" do
    topology =
      Topology.from_state(%{
        "ammonia_mg_l" => 0.35,
        "dissolved_oxygen_mg_l" => 6.8,
        "nitrate_mg_l" => 35.0,
        "plant_biomass_kg" => 5.0,
        "duckweed_kg" => 3.0,
        "chicken_count" => 6,
        "collapsed" => false
      })

    assert length(topology) == 4
    refute Enum.any?(topology, &(&1.status == :critical))
    assert Enum.all?(topology, &is_float(&1.tension))
  end
end
