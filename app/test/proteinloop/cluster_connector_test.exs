defmodule ProteinLoop.ClusterConnectorTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.ClusterConnector

  test "connects only missing remote peers" do
    owner = self()
    peers = [:web@web, :peer@peer, :observer@observer]

    result =
      ClusterConnector.reconcile(peers,
        self_node: :web@web,
        connected_nodes: [:observer@observer],
        connect_fun: fn peer ->
          send(owner, {:connect, peer})
          peer == :peer@peer
        end
      )

    assert_receive {:connect, :peer@peer}
    refute_receive {:connect, :web@web}
    refute_receive {:connect, :observer@observer}
    assert result.connected == [:observer@observer, :peer@peer]
    assert result.missing == []
  end

  test "reports peers that remain unavailable" do
    result =
      ClusterConnector.reconcile([:peer@peer],
        self_node: :web@web,
        connected_nodes: [],
        connect_fun: fn _peer -> false end
      )

    assert result.connected == []
    assert result.missing == [:peer@peer]
  end
end
