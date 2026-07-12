defmodule ProteinLoop.AMDExperimentEvidenceTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.AMDExperimentEvidence

  @submission Path.expand("../../../submission", __DIR__)

  test "loads the imported AMD notebook submission artifacts" do
    snapshot =
      AMDExperimentEvidence.load(
        Path.join(@submission, "amd-notebook-gemma-evidence.json"),
        Path.join(@submission, "amd-gemma-policy-search.json"),
        Path.join(@submission, "amd-gemma-product-evaluation.json"),
        Path.join(@submission, "amd-gemma-repair-evaluation.json")
      )

    assert snapshot.available?, "AMD evidence unavailable: #{inspect(snapshot.error)}"
    assert snapshot.model == "google/gemma-4-E2B-it"
    assert snapshot.search.reward_delta == 71.092
    assert snapshot.search.selected.final_state["ammonia_mg_l"] == 0.7228
    assert snapshot.product_evaluation.safe_rate_lift == 0.8
    assert snapshot.product_evaluation.protected_biomass_kg == 103.1
    assert snapshot.repair_evaluation.scenario_count == 20
    assert snapshot.repair_evaluation.first_safe_rate == 0.1
    assert snapshot.repair_evaluation.repair_safe_rate == 1.0
    assert snapshot.repair_evaluation.combined_model_safe_rate == 1.0
    assert snapshot.repair_evaluation.rescue_count == 18
    assert snapshot.repair_evaluation.fallback_count == 0
    assert snapshot.repair_evaluation.model_request_count == 139
    assert snapshot.repair_evaluation.total_tokens == 60_385
    assert snapshot.repair_evaluation.protected_biomass_kg == 420.648
  end

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

  test "loads and validates the multi-scenario AMD product evaluation" do
    {runtime_path, search_path} = write_evidence_pair()
    product_path = temp_path("product")
    File.write!(product_path, Jason.encode!(product_evidence()))
    on_exit(fn -> File.rm(product_path) end)

    snapshot = AMDExperimentEvidence.load(runtime_path, search_path, product_path)

    assert snapshot.available?
    assert snapshot.product_evaluation.scenario_count == 5
    assert snapshot.product_evaluation.first_safe_rate == 0.2
    assert snapshot.product_evaluation.selected_safe_rate == 1.0
    assert snapshot.product_evaluation.rescue_count == 4
    assert snapshot.product_evaluation.fallback_count == 3
    assert snapshot.product_evaluation.protected_biomass_kg == 103.1
    assert snapshot.product_evaluation.latency_p50_ms == 654.344
  end

  test "loads and validates bounded verifier-feedback repair evidence" do
    {runtime_path, search_path} = write_evidence_pair()
    product_path = temp_path("product")
    repair_path = temp_path("repair")
    File.write!(product_path, Jason.encode!(product_evidence()))
    File.write!(repair_path, Jason.encode!(repair_evidence()))

    on_exit(fn ->
      File.rm(product_path)
      File.rm(repair_path)
    end)

    snapshot = AMDExperimentEvidence.load(runtime_path, search_path, product_path, repair_path)

    assert snapshot.available?
    assert snapshot.repair_evaluation.scenario_count == 20
    assert snapshot.repair_evaluation.first_safe_count == 2
    assert snapshot.repair_evaluation.repair_safe_count == 20
    assert snapshot.repair_evaluation.rescue_count == 18
    assert snapshot.repair_evaluation.one_revision_count == 17
    assert snapshot.repair_evaluation.multi_revision_count == 1
    assert snapshot.repair_evaluation.max_observed_repairs == 2
    assert snapshot.repair_evaluation.fallback_count == 0
    assert snapshot.repair_evaluation.completion_tokens_per_second == 99.793
    assert snapshot.repair_evaluation.latency_p50_ms == 655.522
    assert snapshot.repair_evaluation.weight_updates? == false
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
        "initial_state" => %{
          "ammonia_mg_l" => 2.4,
          "dissolved_oxygen_mg_l" => 4.8
        },
        "baseline" => %{"accepted" => true, "reward" => 113.0589},
        "selected" => selected,
        "candidates" => [unsafe_candidate(), selected, safe_candidate(2, "balanced", 160.0)]
      }
    }
  end

  defp product_evidence do
    %{
      "schema_version" => 1,
      "checked_at" => "2026-07-11T23:10:00Z",
      "provider" => "amd_hackathon_notebook",
      "model" => "google/gemma-4-E2B-it",
      "method" => "multi_scenario_verifier_guided_best_of_n",
      "claim" => "product outcome evaluation; inference only; no model weight updates",
      "scenario_count" => 5,
      "candidates_per_scenario" => 6,
      "summary" => %{
        "scenario_count" => 5,
        "model_candidate_count" => 30,
        "first_proposal_safe_rate" => 0.2,
        "selected_plan_safe_rate" => 1.0,
        "safe_rate_lift" => 0.8,
        "search_rescue_count" => 4,
        "search_improvement_count" => 4,
        "gemma_safe_scenario_count" => 2,
        "deterministic_fallback_count" => 3,
        "mean_reward_delta_vs_naive" => 180.3907,
        "protected_aquatic_biomass_kg" => 103.1,
        "unsafe_control_rejection_rate" => 1.0,
        "generation_latency_ms" => %{"sample_count" => 30, "p50" => 654.344, "p95" => 716.535}
      },
      "scenarios" =>
        Enum.map(1..5, fn index ->
          %{"name" => "scenario #{index}", "fallback_used" => index > 2}
        end),
      "checks" => %{
        "all_scenarios_evaluated" => true,
        "no_weight_updates" => true,
        "safe_plan_selected_every_time" => true,
        "search_not_worse_than_first_on_safety" => true,
        "unsafe_controls_rejected" => true
      }
    }
  end

  defp repair_evidence do
    %{
      "schema_version" => 1,
      "checked_at" => "2026-07-12T02:09:00Z",
      "provider" => "amd_hackathon_notebook",
      "model" => "google/gemma-4-E2B-it",
      "method" => "twenty_scenario_verifier_feedback_repair",
      "claim" => "inference-time repair and search; no training or model weight updates",
      "scenario_count" => 20,
      "variants_per_base_scenario" => 4,
      "independent_candidates_per_scenario" => 6,
      "max_repairs" => 3,
      "generation_errors" => [],
      "summary" => %{
        "scenario_count" => 20,
        "first_answer_safe_count" => 2,
        "first_answer_safe_rate" => 0.1,
        "repair_path_safe_count" => 20,
        "repair_path_safe_rate" => 1.0,
        "best_of_n_safe_count" => 9,
        "best_of_n_safe_rate" => 0.45,
        "combined_model_safe_count" => 20,
        "combined_model_safe_rate" => 1.0,
        "final_system_safe_count" => 20,
        "final_system_safe_rate" => 1.0,
        "repair_rescue_count" => 18,
        "deterministic_fallback_count" => 0,
        "deterministic_fallback_rate" => 0.0,
        "unsafe_control_rejection_rate" => 1.0,
        "protected_aquatic_biomass_kg" => 420.648,
        "mean_reward_delta_vs_naive" => 221.7244,
        "model_request_count" => 139,
        "token_usage" => %{
          "prompt_tokens" => 51_211,
          "completion_tokens" => 9_174,
          "total_tokens" => 60_385
        },
        "request_latency_ms" => %{
          "sample_count" => 139,
          "p50" => 655.522,
          "p95" => 729.105
        },
        "observed_completion_tokens_per_second" => 99.793
      },
      "scenarios" =>
        Enum.map(1..20, fn index ->
          repair_count =
            cond do
              index <= 2 -> 0
              index == 20 -> 2
              true -> 1
            end

          %{
            "name" => "scenario #{index}",
            "first_answer_safe" => index <= 2,
            "repair_path_safe" => true,
            "combined_model_safe" => true,
            "final_system_safe" => true,
            "repair_rescued_first_rejection" => index > 2,
            "fallback_used" => false,
            "unsafe_control_rejected" => true,
            "repair_trace" => %{
              "max_repairs" => 3,
              "repair_count" => repair_count,
              "weight_updates" => false
            }
          }
        end),
      "checks" => %{
        "all_scenarios_evaluated" => true,
        "repair_attempts_bounded" => true,
        "unsafe_controls_rejected" => true,
        "safe_plan_selected_every_time" => true,
        "combined_model_not_worse_than_first" => true,
        "fallback_usage_disclosed" => true,
        "token_usage_reported" => true,
        "no_weight_updates" => true
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
      },
      "final_state" => %{
        "ammonia_mg_l" => 0.85,
        "dissolved_oxygen_mg_l" => 5.5058,
        "collapsed" => false
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
