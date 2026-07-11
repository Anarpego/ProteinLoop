defmodule ProteinLoop.AMDExperimentEvidence do
  @moduledoc """
  Loads and validates the credential-free AMD notebook experiment artifacts.

  The snapshot is a captured replay, not a claim that the temporary notebook
  endpoint is still connected to the public application.
  """

  @provider "amd_hackathon_notebook"
  @default_runtime_path Path.expand(
                          "../../../submission/amd-notebook-gemma-evidence.json",
                          __DIR__
                        )
  @default_search_path Path.expand(
                         "../../../submission/amd-gemma-policy-search.json",
                         __DIR__
                       )

  def snapshot do
    runtime_path =
      System.get_env("AMD_NOTEBOOK_EVIDENCE_PATH", @default_runtime_path)

    search_path =
      System.get_env("AMD_POLICY_SEARCH_EVIDENCE_PATH", @default_search_path)

    load(runtime_path, search_path)
  end

  def load(runtime_path, search_path) when is_binary(runtime_path) and is_binary(search_path) do
    with {:ok, runtime_evidence} <- read_json(runtime_path),
         {:ok, search_evidence} <- read_json(search_path),
         :ok <- validate_runtime(runtime_evidence),
         :ok <- validate_search(search_evidence),
         :ok <- validate_pair(runtime_evidence, search_evidence) do
      available(runtime_evidence, search_evidence)
    else
      {:error, reason} -> unavailable(reason)
    end
  end

  defp read_json(path) do
    with {:ok, body} <- File.read(path),
         {:ok, evidence} when is_map(evidence) <- Jason.decode(body) do
      {:ok, evidence}
    else
      {:ok, _other} -> {:error, "AMD evidence must be a JSON object"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_runtime(%{
         "schema_version" => 1,
         "provider" => @provider,
         "model" => model,
         "runtime" => runtime,
         "checks" => checks
       })
       when is_binary(model) and model != "" and is_map(runtime) and is_list(checks) do
    required_runtime =
      runtime["gpu_available"] == true and runtime["gpu_tensor_test"] == true and
        is_binary(runtime["rocm_version"]) and runtime["rocm_version"] != "" and
        is_binary(runtime["vllm_version"]) and runtime["vllm_version"] != "" and
        is_number(runtime["gpu_memory_gib"]) and runtime["gpu_memory_gib"] >= 12 and
        is_map(runtime["hardware"]) and
        String.starts_with?(to_string(runtime["hardware"]["architecture"]), "gfx")

    cond do
      checks == [] -> {:error, "AMD runtime checks are missing"}
      not Enum.all?(checks, &(&1["ok"] == true)) -> {:error, "AMD runtime checks did not pass"}
      not required_runtime -> {:error, "AMD runtime proof is incomplete"}
      true -> :ok
    end
  end

  defp validate_runtime(_evidence),
    do: {:error, "AMD runtime evidence has an invalid provider, model, or schema"}

  defp validate_search(%{
         "schema_version" => 1,
         "provider" => @provider,
         "model" => model,
         "generated_model_candidates" => generated,
         "checks" => checks,
         "search" => search
       })
       when is_binary(model) and model != "" and is_integer(generated) and generated > 0 and
              is_map(checks) and is_map(search) do
    selected = search["selected"]

    required_search =
      search["method"] == "verifier_guided_best_of_n" and search["weight_updates"] == false and
        is_integer(search["candidate_count"]) and search["candidate_count"] > 0 and
        is_integer(search["safe_count"]) and search["safe_count"] > 0 and
        is_integer(search["rejected_count"]) and search["rejected_count"] > 0 and
        is_number(search["reward_delta_vs_naive"]) and search["reward_delta_vs_naive"] > 0 and
        is_list(search["candidates"]) and is_map(selected) and selected["accepted"] == true and
        is_map(selected["action"])

    cond do
      map_size(checks) == 0 ->
        {:error, "AMD policy-search checks are missing"}

      not Enum.all?(checks, fn {_name, passed} -> passed == true end) ->
        {:error, "AMD policy-search checks did not pass"}

      not required_search ->
        {:error, "AMD verifier-guided search proof is incomplete"}

      true ->
        :ok
    end
  end

  defp validate_search(_evidence),
    do: {:error, "AMD policy-search evidence has an invalid provider, model, or schema"}

  defp validate_pair(runtime, search) do
    cond do
      runtime["provider"] != search["provider"] ->
        {:error, "AMD evidence provider mismatch"}

      runtime["model"] != search["model"] ->
        {:error, "AMD evidence model mismatch"}

      true ->
        :ok
    end
  end

  defp available(runtime_evidence, search_evidence) do
    runtime = runtime_evidence["runtime"]
    hardware = runtime["hardware"]
    search = search_evidence["search"]
    selected = search["selected"]
    selected_index = selected["index"]

    %{
      available?: true,
      captured_at: search_evidence["checked_at"] || runtime_evidence["checked_at"],
      provider: runtime_evidence["provider"],
      model: runtime_evidence["model"],
      public_runtime: "self-hosted CPU fallback",
      experiment_runtime: "Act-II AMD notebook GPU",
      error: nil,
      runtime: %{
        pytorch_version: runtime["pytorch_version"],
        rocm_version: runtime["rocm_version"],
        vllm_version: runtime["vllm_version"],
        architecture: hardware["architecture"],
        compute_units: hardware["compute_units"],
        gpu_memory_gib: runtime["gpu_memory_gib"],
        tensor_latency_ms: runtime["gpu_tensor_latency_ms"],
        endpoint_latency_ms:
          get_in(runtime_evidence, ["benchmark", "endpoint_validation_latency_ms"])
      },
      search: %{
        method: search["method"],
        claim: search["claim"],
        weight_updates?: search["weight_updates"],
        requested_count: search_evidence["requested_model_candidates"],
        generated_count: search_evidence["generated_model_candidates"],
        candidate_count: search["candidate_count"],
        safe_count: search["safe_count"],
        rejected_count: search["rejected_count"],
        parse_error_count: search["parse_error_count"],
        reward_delta: search["reward_delta_vs_naive"],
        baseline_reward: get_in(search, ["baseline", "reward"]),
        selected: normalize_candidate(selected, selected_index),
        candidates: Enum.map(search["candidates"], &normalize_candidate(&1, selected_index))
      }
    }
  end

  defp normalize_candidate(candidate, selected_index) do
    %{
      index: candidate["index"],
      source: candidate["source"] || "model",
      strategy: candidate["strategy"] || "unnamed strategy",
      accepted?: candidate["accepted"] == true,
      selected?: candidate["index"] == selected_index,
      violations: candidate["violations"] || [],
      warnings: candidate["warnings"] || [],
      reward: candidate["reward"],
      action: candidate["action"] || %{}
    }
  end

  defp unavailable(reason) do
    %{
      available?: false,
      captured_at: nil,
      provider: nil,
      model: nil,
      public_runtime: "self-hosted CPU fallback",
      experiment_runtime: nil,
      runtime: nil,
      search: nil,
      error: format_error(reason)
    }
  end

  defp format_error(:enoent), do: "AMD experiment evidence file was not found"
  defp format_error(%Jason.DecodeError{}), do: "AMD experiment evidence is not valid JSON"
  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(reason), do: inspect(reason)
end
