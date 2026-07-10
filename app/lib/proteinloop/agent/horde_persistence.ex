defmodule ProteinLoop.Agent.HordePersistence do
  @moduledoc """
  Shared, atomic JSON persistence for Sagents agents managed by Horde.

  Both Docker agent nodes mount the same state directory. Agent identifiers are
  hashed before becoming filenames, and writes use same-directory atomic rename.
  """

  @behaviour Sagents.AgentPersistence

  @schema_version 1

  @impl true
  def persist_state(_scope, state_data, context) when is_map(state_data) do
    agent_id = Map.fetch!(context, :agent_id)

    with_lock(agent_id, fn ->
      with {:ok, previous} <- read_packet_or_default(agent_id) do
        packet =
          %{
            "schema_version" => @schema_version,
            "agent_id" => agent_id,
            "conversation_id" => Map.get(context, :conversation_id),
            "state_data" => state_data,
            "fingerprint" => canonical_fingerprint(state_data),
            "persist_count" => integer(previous["persist_count"]),
            "restore_count" => integer(previous["restore_count"]),
            "interrupted" => previous["interrupted"] == true,
            "last_lifecycle" => context |> Map.fetch!(:lifecycle) |> Atom.to_string(),
            "last_persisted_node" => to_string(node()),
            "last_persisted_at" => timestamp(),
            "last_restored_node" => previous["last_restored_node"],
            "last_restored_at" => previous["last_restored_at"]
          }
          |> Map.update!("persist_count", &(&1 + 1))

        write_packet(agent_id, packet)
      end
    end)
  end

  @impl true
  def load_state(_scope, context) do
    agent_id = Map.fetch!(context, :agent_id)

    with_lock(agent_id, fn ->
      with {:ok, packet} <- read_packet(agent_id),
           :ok <- validate_packet(packet, agent_id) do
        restored =
          packet
          |> Map.update("restore_count", 1, &(integer(&1) + 1))
          |> Map.put("last_restored_node", to_string(node()))
          |> Map.put("last_restored_at", timestamp())

        case write_packet(agent_id, restored) do
          :ok -> {:ok, packet["state_data"]}
          {:error, _reason} = error -> error
        end
      end
    end)
  end

  @impl true
  def set_interrupted(_scope, context, interrupted?) when is_boolean(interrupted?) do
    agent_id = Map.fetch!(context, :agent_id)

    with_lock(agent_id, fn ->
      with {:ok, packet} <- read_packet(agent_id),
           :ok <- validate_packet(packet, agent_id) do
        packet
        |> Map.put("interrupted", interrupted?)
        |> write_packet_for(agent_id)
      end
    end)
  end

  def metadata(agent_id) when is_binary(agent_id) do
    with {:ok, packet} <- read_packet(agent_id),
         :ok <- validate_packet(packet, agent_id) do
      {:ok,
       %{
         agent_id: packet["agent_id"],
         conversation_id: packet["conversation_id"],
         fingerprint: packet["fingerprint"],
         persist_count: integer(packet["persist_count"]),
         restore_count: integer(packet["restore_count"]),
         interrupted: packet["interrupted"] == true,
         last_lifecycle: packet["last_lifecycle"],
         last_persisted_node: packet["last_persisted_node"],
         last_persisted_at: packet["last_persisted_at"],
         last_restored_node: packet["last_restored_node"],
         last_restored_at: packet["last_restored_at"]
       }}
    end
  end

  def delete(agent_id) when is_binary(agent_id) do
    with_lock(agent_id, fn ->
      case File.rm(storage_path(agent_id)) do
        :ok -> :ok
        {:error, :enoent} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  def storage_path(agent_id) when is_binary(agent_id) do
    digest = :crypto.hash(:sha256, agent_id) |> Base.encode16(case: :lower)
    Path.join(state_directory(), "#{digest}.json")
  end

  def canonical_fingerprint(state_data) when is_map(state_data) do
    canonical_state = Map.get(state_data, "state", Map.get(state_data, :state, state_data))

    canonical_state
    |> canonicalize()
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp state_directory do
    Application.get_env(
      :proteinloop,
      :sagents_state_dir,
      Path.expand("../../../priv/sagents-state", __DIR__)
    )
  end

  defp read_packet_or_default(agent_id) do
    case read_packet(agent_id) do
      {:ok, packet} -> {:ok, packet}
      {:error, :not_found} -> {:ok, %{}}
      {:error, _reason} = error -> error
    end
  end

  defp read_packet(agent_id) do
    case File.read(storage_path(agent_id)) do
      {:ok, contents} ->
        case Jason.decode(contents) do
          {:ok, packet} when is_map(packet) -> {:ok, packet}
          {:ok, _other} -> {:error, {:invalid_persisted_state, :not_an_object}}
          {:error, reason} -> {:error, {:invalid_persisted_state, reason}}
        end

      {:error, :enoent} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_packet(packet, agent_id) do
    cond do
      packet["schema_version"] != @schema_version ->
        {:error, {:invalid_persisted_state, :unsupported_schema}}

      packet["agent_id"] != agent_id ->
        {:error, {:invalid_persisted_state, :agent_mismatch}}

      not is_map(packet["state_data"]) ->
        {:error, {:invalid_persisted_state, :missing_state}}

      true ->
        :ok
    end
  end

  defp write_packet_for(packet, agent_id), do: write_packet(agent_id, packet)

  defp write_packet(agent_id, packet) do
    path = storage_path(agent_id)
    directory = Path.dirname(path)

    with :ok <- File.mkdir_p(directory),
         {:ok, encoded} <- Jason.encode(packet, pretty: true) do
      temporary =
        path <>
          ".tmp-#{System.unique_integer([:positive, :monotonic])}-#{System.os_time(:nanosecond)}"

      case File.write(temporary, encoded <> "\n", [:binary]) do
        :ok ->
          case File.rename(temporary, path) do
            :ok ->
              :ok

            {:error, reason} ->
              File.rm(temporary)
              {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp with_lock(agent_id, fun) do
    case :global.trans({__MODULE__, agent_id}, fun) do
      {:aborted, reason} -> {:error, {:persistence_lock_aborted, reason}}
      result -> result
    end
  end

  defp canonicalize(map) when is_map(map) do
    {:map,
     map
     |> Enum.map(fn {key, value} -> {to_string(key), canonicalize(value)} end)
     |> Enum.sort_by(&elem(&1, 0))}
  end

  defp canonicalize(list) when is_list(list), do: {:list, Enum.map(list, &canonicalize/1)}

  defp canonicalize(tuple) when is_tuple(tuple),
    do: {:tuple, tuple |> Tuple.to_list() |> Enum.map(&canonicalize/1)}

  defp canonicalize(atom) when is_atom(atom), do: {:atom, Atom.to_string(atom)}
  defp canonicalize(value), do: value

  defp integer(value) when is_integer(value), do: value
  defp integer(_value), do: 0

  defp timestamp,
    do: DateTime.utc_now() |> DateTime.truncate(:millisecond) |> DateTime.to_iso8601()
end
