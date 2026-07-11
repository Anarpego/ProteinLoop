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
        tensor_latency_ms: 494.447,
        endpoint_latency_ms: 12_400.5
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
        reward_delta: 69.3611,
        baseline_reward: 113.0589,
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
      reward: 182.42,
      action: %{
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
      }
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
      search: nil,
      error: "AMD experiment evidence file was not found"
    }
  end
end
