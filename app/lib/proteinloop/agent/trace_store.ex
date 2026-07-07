defmodule ProteinLoop.Agent.TraceStore do
  @moduledoc """
  JSONL trace storage for harness proposal/verifier outcomes.

  These traces are intentionally plain JSON so Python RLVR tooling can consume
  them later without Phoenix-specific code.
  """

  def append(result, opts \\ []) when is_map(result) do
    path = trace_path(opts)
    entry = to_entry(result)

    with :ok <- File.mkdir_p(Path.dirname(path)),
         {:ok, encoded} <- Jason.encode(entry),
         :ok <- File.write(path, encoded <> "\n", [:append]) do
      {:ok, %{path: path, entry: entry, count: count(path)}}
    end
  end

  def status(opts \\ []) do
    path = trace_path(opts)
    %{path: path, count: count(path)}
  end

  def recent(limit \\ 5, opts \\ []) do
    path = trace_path(opts)

    case File.read(path) do
      {:ok, contents} ->
        entries =
          contents
          |> String.split("\n", trim: true)
          |> Enum.reverse()
          |> Enum.take(limit)
          |> Enum.flat_map(&decode_line/1)

        {:ok, entries}

      {:error, :enoent} ->
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def count(path \\ trace_path()) do
    case File.read(path) do
      {:ok, contents} ->
        contents
        |> String.split("\n", trim: true)
        |> length()

      {:error, :enoent} ->
        0

      {:error, _reason} ->
        0
    end
  end

  defp to_entry(result) do
    %{
      "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "provider" => result.metadata.provider |> to_string(),
      "accepted" => result.accepted?,
      "original_state" => result.original_state,
      "action" => result.action,
      "verification" => result.verification,
      "state" => result.state,
      "reward" => result.reward,
      "metadata" => stringify_keys(result.metadata)
    }
  end

  defp decode_line(line) do
    case Jason.decode(line) do
      {:ok, entry} -> [entry]
      {:error, _reason} -> []
    end
  end

  defp trace_path(opts \\ []) do
    Keyword.get(opts, :trace_path) ||
      Application.get_env(:proteinloop, :trace_path) ||
      Path.expand("../../priv/traces/harness.jsonl", __DIR__)
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(list) when is_list(list), do: Enum.map(list, &stringify_keys/1)
  defp stringify_keys(value) when is_atom(value), do: to_string(value)
  defp stringify_keys(value), do: value
end
