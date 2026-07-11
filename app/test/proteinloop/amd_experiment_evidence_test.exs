defmodule ProteinLoop.AMDExperimentEvidenceTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.AMDExperimentEvidence

  test "loads matching AMD runtime and verifier-search evidence" do
    {runtime_path, search_path} = write_evidence_pair()

    snapshot = AMDExperimentEvidence.load(runtime_path, search_path)

    assert snapshot.available?
    assert snapshot.provider == "amd_hackathon_notebook"
    assert snapshot.model == "google/gemma-4-E2B-it"
    assert snapshot.runtime.rocm_version == "7.2.53211"
    assert snapshot.runtime.vllm_version == "0.20.2rc1.dev15+g321fa2d6d"
    assert snapshot.runtime.architecture == "gfx1100"
    assert snapshot.runtime.gpu_memory_gib == 47.98
    assert snapshot.search.generated_count == 6
    assert snapshot.search.safe_count == 3
    assert snapshot.search.rejected_count == 4
    assert snapshot.search.reward_delta == 69.3611
    assert snapshot.search.weight_updates? == false
    assert snapshot.search.selected.strategy == "oxygen-first emergency recovery"
    assert snapshot.search.selected.action["aeration_hours"] == 18.0
    assert Enum.any?(snapshot.search.candidates, &(&1.source == "control_unsafe"))
  end

  test "rejects mismatched provider or model claims" do
    {runtime_path, search_path} =
      write_evidence_pair(search_changes: %{"model" => "different/model"})

    snapshot = AMDExperimentEvidence.load(runtime_path, search_path)

    refute snapshot.available?
    assert snapshot.error =~ "model"
  end

  test "rejects failed runtime or policy-search checks" do
    {runtime_path, search_path} =
      write_evidence_pair(
        runtime_changes: %{
          "checks" => [
            %{"name" => "AMD GPU available", "ok" => false, "detail" => "0 device(s)"}
          ]
        }
      )

    refute AMDExperimentEvidence.load(runtime_path, search_path).available?

    {runtime_path, search_path} =
      write_evidence_pair(
        search_changes: %{
          "checks" => %{
            "amd_gemma_generated_candidates" => true,
            "unsafe_control_rejected" => false,
            "safe_candidate_selected" => true,
            "positive_reward_delta_vs_naive" => true,
            "no_weight_update_claim_is_explicit" => true
          }
        }
      )

    refute AMDExperimentEvidence.load(runtime_path, search_path).available?
  end

  test "returns unavailable evidence for missing or malformed files" do
    missing = Path.join(System.tmp_dir!(), "missing-amd-#{System.unique_integer([:positive])}")
    malformed = temp_path("malformed")
    File.write!(malformed, "{not-json")

    refute AMDExperimentEvidence.load(missing, missing <> "-search").available?
    refute AMDExperimentEvidence.load(malformed, malformed).available?
  end

  defp write_evidence_pair(options \\ []) do
    runtime_path = temp_path("runtime")
    search_path = temp_path("search")

    runtime = Map.merge(runtime_evidence(), Keyword.get(options, :runtime_changes, %{}))
    search = Map.merge(search_evidence(), Keyword.get(options, :search_changes, %{}))

    File.write!(runtime_path, Jason.encode!(runtime))
    File.write!(search_path, Jason.encode!(search))

    on_exit(fn ->
      File.rm(runtime_path)
      File.rm(search_path)
    end)

    {runtime_path, search_path}
  end

  defp runtime_evidence do
    %{
      "schema_version" => 1,
      "checked_at" => "2026-07-11T22:30:00Z",
      "provider" => "amd_hackathon_notebook",
      "model" => "google/gemma-4-E2B-it",
      "benchmark" => %{"endpoint_validation_latency_ms" => 12_400.5},
      "runtime" => %{
        "pytorch_version" => "2.10.0+git8514f05",
        "rocm_version" => "7.2.53211",
        "vllm_version" => "0.20.2rc1.dev15+g321fa2d6d",
        "gpu_available" => true,
        "gpu_count" => 1,
        "gpu_memory_gib" => 47.98,
        "gpu_tensor_test" => true,
        "gpu_tensor_latency_ms" => 494.447,
        "hardware" => %{
          "architecture" => "gfx1100",
          "compute_units" => 96,
          "vram_mb" => 49_136,
          "vram_type" => "GDDR6"
        }
      },
      "checks" => [
        %{"name" => "models endpoint", "ok" => true, "detail" => "1 model(s)"},
        %{"name" => "chat action contract", "ok" => true, "detail" => "valid action"},
        %{"name" => "AMD GPU available", "ok" => true, "detail" => "1 device(s)"}
      ]
    }
  end

  defp search_evidence do
    selected = safe_candidate(1, "oxygen-first emergency recovery", 182.42)

    %{
      "schema_version" => 1,
      "checked_at" => "2026-07-11T22:35:00Z",
      "provider" => "amd_hackathon_notebook",
      "model" => "google/gemma-4-E2B-it",
      "requested_model_candidates" => 6,
      "generated_model_candidates" => 6,
      "generation_errors" => [],
      "checks" => %{
        "amd_gemma_generated_candidates" => true,
        "unsafe_control_rejected" => true,
        "safe_candidate_selected" => true,
        "positive_reward_delta_vs_naive" => true,
        "no_weight_update_claim_is_explicit" => true
      },
      "search" => %{
        "method" => "verifier_guided_best_of_n",
        "weight_updates" => false,
        "claim" => "inference-time policy search; no RL training or fine-tuning",
        "candidate_count" => 7,
        "safe_count" => 3,
        "rejected_count" => 4,
        "parse_error_count" => 0,
        "reward_delta_vs_naive" => 69.3611,
        "baseline" => %{"accepted" => true, "reward" => 113.0589},
        "selected" => selected,
        "candidates" => [unsafe_candidate(), selected, safe_candidate(2, "balanced", 160.0)]
      }
    }
  end

  defp safe_candidate(index, strategy, reward) do
    %{
      "index" => index,
      "source" => "amd_hosted_gemma",
      "strategy" => strategy,
      "accepted" => true,
      "violations" => [],
      "warnings" => [],
      "reward" => reward,
      "action" => %{
        "feed_kg" => 0.04,
        "aeration_hours" => 18.0,
        "water_exchange_fraction" => 0.2,
        "duckweed_harvest_kg" => 1.0,
        "note" => "Prioritize oxygen while reducing waste load."
      }
    }
  end

  defp unsafe_candidate do
    %{
      "index" => 0,
      "source" => "control_unsafe",
      "strategy" => "deliberate verifier control",
      "accepted" => false,
      "violations" => ["aeration_hours must be at most 24"],
      "warnings" => [],
      "reward" => nil,
      "action" => %{
        "feed_kg" => 2.0,
        "aeration_hours" => 30.0,
        "water_exchange_fraction" => 0.6,
        "duckweed_harvest_kg" => 12.0,
        "note" => "deliberately unsafe control"
      }
    }
  end

  defp temp_path(label) do
    Path.join(
      System.tmp_dir!(),
      "proteinloop-amd-#{label}-#{System.unique_integer([:positive])}.json"
    )
  end
end
