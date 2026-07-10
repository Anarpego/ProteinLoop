defmodule ProteinLoop.TestDemoCascade do
  def run do
    reset_state = ProteinLoop.SimulatorClient.fallback_state()

    spike_state =
      Map.merge(reset_state, %{
        "ammonia_mg_l" => 3.8,
        "dissolved_oxygen_mg_l" => 3.2,
        "last_event" => "ammonia_spike"
      })

    final_state =
      Map.merge(spike_state, %{
        "day" => 1,
        "ammonia_mg_l" => 0.9,
        "dissolved_oxygen_mg_l" => 6.4,
        "last_event" => "verified_recovery"
      })

    {:ok,
     %{
       reset_state: reset_state,
       spike_state: spike_state,
       unsafe_result: %{
         reward: -120.0,
         verification: %{
           "ok" => false,
           "violations" => ["Feed exceeds the safe recovery limit."],
           "warnings" => []
         }
       },
       safe_result: %{
         accepted?: true,
         action: %{
           "feed_kg" => 0.0,
           "aeration_hours" => 24.0,
           "water_exchange_fraction" => 0.05,
           "duckweed_harvest_kg" => 0.0
         },
         metadata: %{rationale: "Deterministic oxygen-first recovery."},
         reward: 203.7,
         verification: %{"ok" => true, "violations" => [], "warnings" => []},
         state: final_state
       },
       final_state: final_state,
       trace_status: %{available?: true}
     }}
  end
end
