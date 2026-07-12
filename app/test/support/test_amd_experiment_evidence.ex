defmodule ProteinLoop.TestAMDExperimentEvidence do
  def snapshot do
    %{
      available?: true,
      captured_at: "2026-07-11T22:35:00Z",
      provider: "amd_hackathon_notebook",
      model: "google/gemma-4-E2B-it",
      public_runtime: "self-hosted CPU fallback",
      experiment_runtime: "Act-II AMD notebook GPU",
      error: nil,
      runtime: %{
        pytorch_version: "2.10.0+git8514f05",
        rocm_version: "7.2.53211",
        vllm_version: "0.20.2rc1.dev15+g321fa2d6d",
        architecture: "gfx1100",
        compute_units: 96,
        gpu_memory_gib: 47.98,
        tensor_latency_ms: 320.237,
        endpoint_latency_ms: 12_400.5
      },
      product_evaluation: %{
        scenario_count: 5,
        candidates_per_scenario: 6,
        model_candidate_count: 30,
        first_safe_rate: 0.2,
        selected_safe_rate: 1.0,
        safe_rate_lift: 0.8,
        rescue_count: 4,
        improvement_count: 4,
        gemma_safe_scenario_count: 2,
        fallback_count: 3,
        mean_reward_delta_vs_naive: 180.3907,
        protected_biomass_kg: 103.1,
        unsafe_control_rejection_rate: 1.0,
        latency_p50_ms: 644.384,
        latency_p95_ms: 714.654,
        scenarios: []
      },
      repair_evaluation: %{
        scenario_count: 20,
        variants_per_base_scenario: 4,
        independent_candidates_per_scenario: 6,
        max_repairs: 3,
        first_safe_count: 2,
        first_safe_rate: 0.1,
        repair_safe_count: 20,
        repair_safe_rate: 1.0,
        best_of_n_safe_rate: 0.45,
        combined_model_safe_rate: 1.0,
        final_system_safe_rate: 1.0,
        rescue_count: 18,
        fallback_count: 0,
        fallback_rate: 0.0,
        one_revision_count: 17,
        multi_revision_count: 1,
        max_observed_repairs: 2,
        protected_biomass_kg: 420.648,
        mean_reward_delta_vs_naive: 221.7244,
        model_request_count: 139,
        prompt_tokens: 51_211,
        completion_tokens: 9_174,
        total_tokens: 60_385,
        completion_tokens_per_second: 99.793,
        latency_p50_ms: 655.522,
        latency_p95_ms: 729.105,
        generation_error_count: 0,
        weight_updates?: false
      },
      search: %{
        method: "verifier_guided_best_of_n",
        claim: "inference-time policy search; no RL training or fine-tuning",
        weight_updates?: false,
        requested_count: 6,
        generated_count: 6,
        candidate_count: 7,
        safe_count: 3,
        rejected_count: 4,
        parse_error_count: 0,
        reward_delta: 71.092,
        baseline_reward: 113.0589,
        initial_state: %{
          "ammonia_mg_l" => 2.4,
          "dissolved_oxygen_mg_l" => 4.8
        },
        selected: selected_candidate(),
        candidates: [unsafe_candidate(), selected_candidate(), alternate_candidate()]
      }
    }
  end

  defp selected_candidate do
    %{
      index: 1,
      source: "amd_hosted_gemma",
      strategy: "oxygen-first emergency recovery",
      accepted?: true,
      selected?: true,
      violations: [],
      warnings: [],
      reward: 313.3456,
      action: %{
        "feed_kg" => 0.04,
        "aeration_hours" => 8.0,
        "water_exchange_fraction" => 0.25,
        "duckweed_harvest_kg" => 0.0,
        "note" => "Increase aeration to address low dissolved oxygen."
      },
      final_state: %{
        "ammonia_mg_l" => 0.7228,
        "dissolved_oxygen_mg_l" => 5.6742,
        "collapsed" => false
      }
    }
  end

  defp unsafe_candidate do
    %{
      index: 0,
      source: "control_unsafe",
      strategy: "deliberate verifier control",
      accepted?: false,
      selected?: false,
      violations: ["aeration_hours must be at most 24"],
      warnings: [],
      reward: nil,
      action: %{
        "feed_kg" => 2.0,
        "aeration_hours" => 30.0,
        "water_exchange_fraction" => 0.6,
        "duckweed_harvest_kg" => 12.0,
        "note" => "deliberately unsafe control"
      },
      final_state: nil
    }
  end

  defp alternate_candidate do
    %{
      index: 2,
      source: "amd_hosted_gemma",
      strategy: "balanced water and feed recovery",
      accepted?: true,
      selected?: false,
      violations: [],
      warnings: [],
      reward: 160.0,
      action: %{
        "feed_kg" => 0.05,
        "aeration_hours" => 16.0,
        "water_exchange_fraction" => 0.15,
        "duckweed_harvest_kg" => 0.8,
        "note" => "Balance oxygen, water exchange, and feed reserve."
      },
      final_state: %{
        "ammonia_mg_l" => 1.1,
        "dissolved_oxygen_mg_l" => 5.0,
        "collapsed" => false
      }
    }
  end
end

defmodule ProteinLoop.TestUnavailableAMDExperimentEvidence do
  def snapshot do
    %{
      available?: false,
      captured_at: nil,
      provider: nil,
      model: nil,
      public_runtime: "self-hosted CPU fallback",
      experiment_runtime: nil,
      runtime: nil,
      product_evaluation: nil,
      repair_evaluation: nil,
      search: nil,
      error: "AMD experiment evidence file was not found"
    }
  end
end
