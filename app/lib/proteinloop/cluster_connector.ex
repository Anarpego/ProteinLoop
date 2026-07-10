defmodule ProteinLoop.ClusterConnector do
  @moduledoc """
  Maintains explicit BEAM peer connections for the local two-node Horde demo.

  Production platforms may replace this with their own cluster discovery. With
  no configured peers the process is inert.
  """

  use GenServer

  @default_interval 1_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  def status(server \\ __MODULE__), do: GenServer.call(server, :status)

  def reconcile(peers, opts \\ []) when is_list(peers) do
    self_node = Keyword.get(opts, :self_node, node())
    connected_nodes = Keyword.get(opts, :connected_nodes, Node.list())
    connect_fun = Keyword.get(opts, :connect_fun, &Node.connect/1)

    remote_peers = peers |> Enum.uniq() |> Enum.reject(&(&1 == self_node))
    already_connected = Enum.filter(remote_peers, &(&1 in connected_nodes))
    missing = remote_peers -- already_connected

    newly_connected =
      Enum.filter(missing, fn peer ->
        connect_fun.(peer) == true
      end)

    connected = (already_connected ++ newly_connected) |> Enum.uniq() |> Enum.sort()

    %{
      peers: remote_peers |> Enum.sort(),
      connected: connected,
      missing: (remote_peers -- connected) |> Enum.sort()
    }
  end

  @impl true
  def init(opts) do
    if Node.alive?(), do: :net_kernel.monitor_nodes(true, node_type: :visible)

    state = %{
      peers: Keyword.get(opts, :peers, []),
      interval: Keyword.get(opts, :interval, @default_interval),
      connected: [],
      missing: []
    }

    send(self(), :reconcile)
    {:ok, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, Map.put(state, :node, node()), state}
  end

  @impl true
  def handle_info(:reconcile, state) do
    result = reconcile(state.peers)
    Process.send_after(self(), :reconcile, state.interval)

    {:noreply,
     state
     |> Map.put(:connected, result.connected)
     |> Map.put(:missing, result.missing)}
  end

  def handle_info({_event, _node, _info}, state), do: {:noreply, state}
  def handle_info({_event, _node}, state), do: {:noreply, state}
  def handle_info(_message, state), do: {:noreply, state}
end
