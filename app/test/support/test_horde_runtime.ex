defmodule ProteinLoop.TestHordeRuntime do
  def cluster_status do
    %{
      node: "proteinloop_web@web",
      connected_nodes: ["proteinloop_peer@peer", "proteinloop_web@web"],
      distribution: :horde,
      horde: %{members: :participation},
      managed_agents: ["probe-api"]
    }
  end

  def start_probe(opts) do
    notify({:start_probe, opts})

    {:ok,
     %{
       agent_id: Keyword.fetch!(opts, :agent_id),
       owner_node: "proteinloop_peer@peer",
       state_token: Keyword.fetch!(opts, :state_token),
       state_fingerprint: "fingerprint-api"
     }}
  end

  def snapshot(agent_id) do
    notify({:snapshot, agent_id})

    {:ok,
     %{
       agent_id: agent_id,
       owner_node: "proteinloop_peer@peer",
       state_token: "token-api",
       state_fingerprint: "fingerprint-api"
     }}
  end

  def delete_probe(agent_id) do
    notify({:delete_probe, agent_id})
    :ok
  end

  defp notify(message) do
    if owner = Application.get_env(:proteinloop, :test_horde_owner) do
      send(owner, message)
    end
  end
end
