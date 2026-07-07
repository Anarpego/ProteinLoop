defmodule ProteinLoop.Agent.TraceStoreTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.TraceStore

  test "appends valid JSONL trace entries" do
    path = tmp_path("trace_store.jsonl")

    result = %{
      accepted?: true,
      action: %{"feed_kg" => 0.1},
      metadata: %{provider: :stub_safe, rationale: "test"},
      original_state: %{"day" => 0},
      state: %{"day" => 1},
      reward: 120.0,
      verification: %{"ok" => true, "violations" => []}
    }

    assert {:ok, trace} = TraceStore.append(result, trace_path: path)
    assert trace.count == 1
    assert trace.path == path

    [line] = File.read!(path) |> String.split("\n", trim: true)
    assert {:ok, decoded} = Jason.decode(line)
    assert decoded["accepted"]
    assert decoded["metadata"]["provider"] == "stub_safe"
  end

  test "status returns zero count for missing trace file" do
    path = tmp_path("missing.jsonl")

    assert %{path: ^path, count: 0} = TraceStore.status(trace_path: path)
  end

  test "recent returns latest decoded entries first" do
    path = tmp_path("recent.jsonl")

    append_entry(path, %{"timestamp" => "1", "provider" => "stub_safe", "accepted" => true})
    append_entry(path, %{"timestamp" => "2", "provider" => "stub_unsafe", "accepted" => false})
    append_entry(path, %{"timestamp" => "3", "provider" => "stub_safe", "accepted" => true})

    assert {:ok, [latest, previous]} = TraceStore.recent(2, trace_path: path)
    assert latest["timestamp"] == "3"
    assert previous["timestamp"] == "2"
  end

  test "recent returns empty list for missing file" do
    assert {:ok, []} = TraceStore.recent(5, trace_path: tmp_path("missing-recent.jsonl"))
  end

  defp tmp_path(name) do
    Path.join([
      System.tmp_dir!(),
      "proteinloop-#{System.system_time(:nanosecond)}-#{System.unique_integer([:positive, :monotonic])}",
      name
    ])
  end

  defp append_entry(path, entry) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, Jason.encode!(entry) <> "\n", [:append])
  end
end
