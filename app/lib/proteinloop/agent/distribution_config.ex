defmodule ProteinLoop.Agent.DistributionConfig do
  @moduledoc """
  Parses and applies the runtime Sagents distribution configuration.

  Local mode remains the default. Horde node names come only from trusted
  deployment environment variables and are validated before becoming atoms.
  """

  @node_pattern ~r/^[A-Za-z0-9_.-]+@[A-Za-z0-9_.-]+$/

  def parse(env \\ System.get_env()) when is_map(env) do
    distribution = parse_distribution(Map.get(env, "SAGENTS_DISTRIBUTION", "local"))
    members = parse_members(Map.get(env, "SAGENTS_HORDE_MEMBERS", "participation"))
    partition = blank_to_nil(Map.get(env, "SAGENTS_HORDE_PARTITION"))

    if partition && members != :participation do
      raise ArgumentError,
            "SAGENTS_HORDE_PARTITION requires participation-based Horde membership"
    end

    horde =
      if partition do
        [members: members, partition: partition]
      else
        [members: members]
      end

    %{
      distribution: distribution,
      horde: horde,
      peers: parse_peers(Map.get(env, "CLUSTER_PEERS"))
    }
  end

  def configure!(env \\ System.get_env()) do
    config = parse(env)
    Application.put_env(:sagents, :distribution, config.distribution)
    Application.put_env(:sagents, :horde, config.horde)
    Application.put_env(:proteinloop, :cluster_peers, config.peers)
    config
  end

  defp parse_distribution(value) do
    case value |> to_string() |> String.trim() |> String.downcase() do
      "local" -> :local
      "horde" -> :horde
      other -> raise ArgumentError, "invalid SAGENTS_DISTRIBUTION: #{inspect(other)}"
    end
  end

  defp parse_members(value) do
    case value |> to_string() |> String.trim() |> String.downcase() do
      "participation" -> :participation
      "auto" -> :auto
      other -> raise ArgumentError, "invalid SAGENTS_HORDE_MEMBERS: #{inspect(other)}"
    end
  end

  defp parse_peers(nil), do: []
  defp parse_peers(""), do: []

  defp parse_peers(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn peer ->
      if byte_size(peer) <= 255 and Regex.match?(@node_pattern, peer) do
        String.to_atom(peer)
      else
        raise ArgumentError, "invalid CLUSTER_PEERS node name: #{inspect(peer)}"
      end
    end)
    |> Enum.uniq()
  end

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end
end
