defmodule ProteinLoop.Agent.HordePersistenceTest do
  use ExUnit.Case, async: false

  alias ProteinLoop.Agent.HordePersistence

  setup do
    previous = Application.get_env(:proteinloop, :sagents_state_dir)

    directory =
      Path.join(System.tmp_dir!(), "proteinloop-horde-#{System.unique_integer([:positive])}")

    Application.put_env(:proteinloop, :sagents_state_dir, directory)

    on_exit(fn ->
      File.rm_rf!(directory)

      if previous do
        Application.put_env(:proteinloop, :sagents_state_dir, previous)
      else
        Application.delete_env(:proteinloop, :sagents_state_dir)
      end
    end)

    %{directory: directory}
  end

  test "persists and restores Sagents state with migration metadata" do
    state_data = serialized_state("checkpoint-a", "2026-07-10T00:00:00Z")

    context = %{
      agent_id: "probe/../../unsafe",
      conversation_id: "probe-1",
      lifecycle: :on_completion
    }

    assert :ok = HordePersistence.persist_state(nil, state_data, context)
    assert {:ok, ^state_data} = HordePersistence.load_state(nil, Map.delete(context, :lifecycle))

    assert {:ok, metadata} = HordePersistence.metadata(context.agent_id)
    assert metadata.agent_id == context.agent_id
    assert metadata.persist_count == 1
    assert metadata.restore_count == 1
    assert metadata.last_lifecycle == "on_completion"
    assert metadata.last_restored_node == to_string(node())
    assert metadata.fingerprint == HordePersistence.canonical_fingerprint(state_data)
  end

  test "canonical fingerprint ignores serializer timestamps but detects state changes" do
    first = serialized_state("checkpoint-a", "2026-07-10T00:00:00Z")
    later = serialized_state("checkpoint-a", "2026-07-10T00:01:00Z")
    changed = serialized_state("checkpoint-b", "2026-07-10T00:01:00Z")

    assert HordePersistence.canonical_fingerprint(first) ==
             HordePersistence.canonical_fingerprint(later)

    refute HordePersistence.canonical_fingerprint(first) ==
             HordePersistence.canonical_fingerprint(changed)
  end

  test "uses an isolated hashed path and rejects corrupt persistence", %{directory: directory} do
    agent_id = "../../outside/probe"
    path = HordePersistence.storage_path(agent_id)

    assert Path.dirname(path) == directory
    refute Path.basename(path) =~ "outside"

    File.mkdir_p!(directory)
    File.write!(path, "not-json")

    assert {:error, {:invalid_persisted_state, _reason}} =
             HordePersistence.load_state(nil, %{agent_id: agent_id, conversation_id: nil})

    assert {:error, {:invalid_persisted_state, _reason}} =
             HordePersistence.persist_state(nil, serialized_state("checkpoint-a", "now"), %{
               agent_id: agent_id,
               conversation_id: nil,
               lifecycle: :on_completion
             })
  end

  defp serialized_state(token, serialized_at) do
    %{
      "version" => 2,
      "serialized_at" => serialized_at,
      "state" => %{
        "messages" => [],
        "todos" => [],
        "metadata" => %{"state_token" => token}
      }
    }
  end
end
