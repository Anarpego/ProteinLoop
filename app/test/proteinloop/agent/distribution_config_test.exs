defmodule ProteinLoop.Agent.DistributionConfigTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.DistributionConfig

  test "defaults to single-node local distribution" do
    assert DistributionConfig.parse(%{}) == %{
             distribution: :local,
             horde: [members: :participation],
             peers: []
           }
  end

  test "parses participation-scoped Horde peers and partition" do
    config =
      DistributionConfig.parse(%{
        "SAGENTS_DISTRIBUTION" => "horde",
        "SAGENTS_HORDE_MEMBERS" => "participation",
        "SAGENTS_HORDE_PARTITION" => "proteinloop-demo",
        "CLUSTER_PEERS" => "proteinloop_peer@peer, proteinloop_web@web"
      })

    assert config.distribution == :horde
    assert config.horde == [members: :participation, partition: "proteinloop-demo"]
    assert config.peers == [:proteinloop_peer@peer, :proteinloop_web@web]
  end

  test "accepts Horde auto membership without a partition" do
    config =
      DistributionConfig.parse(%{
        "SAGENTS_DISTRIBUTION" => "horde",
        "SAGENTS_HORDE_MEMBERS" => "auto"
      })

    assert config.horde == [members: :auto]
  end

  test "rejects invalid distribution and peer values" do
    assert_raise ArgumentError, ~r/SAGENTS_DISTRIBUTION/, fn ->
      DistributionConfig.parse(%{"SAGENTS_DISTRIBUTION" => "remote"})
    end

    assert_raise ArgumentError, ~r/CLUSTER_PEERS/, fn ->
      DistributionConfig.parse(%{
        "SAGENTS_DISTRIBUTION" => "horde",
        "CLUSTER_PEERS" => "not a node"
      })
    end

    assert_raise ArgumentError, ~r/partition/i, fn ->
      DistributionConfig.parse(%{
        "SAGENTS_DISTRIBUTION" => "horde",
        "SAGENTS_HORDE_MEMBERS" => "auto",
        "SAGENTS_HORDE_PARTITION" => "invalid-with-auto"
      })
    end
  end
end
