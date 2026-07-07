defmodule ProteinLoop.SimulatorClientTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.SimulatorClient

  test "critical ammonia proposes a recovery action" do
    action =
      SimulatorClient.proposed_action(%{"ammonia_mg_l" => 4.2, "dissolved_oxygen_mg_l" => 4.0})

    assert action["feed_kg"] == 0.0
    assert action["aeration_hours"] == 24.0
    assert action["water_exchange_fraction"] == 0.30
  end

  test "fallback state has dashboard fields" do
    state = SimulatorClient.fallback_state()

    assert state["ammonia_mg_l"]
    assert state["dissolved_oxygen_mg_l"]
    assert state["mortality_events"]["fish"] == 0
  end

  test "fallback rlvr evaluation has dashboard fields" do
    evaluation = SimulatorClient.fallback_rlvr_evaluation(:offline)

    refute evaluation["available"]
    assert evaluation["baseline_policy"] == "naive"
    assert evaluation["candidate_policy"] == "safety"
    assert evaluation["scenarios"] == []
  end

  test "fallback anomaly forecast has dashboard fields" do
    forecast = SimulatorClient.fallback_anomaly_forecast(:offline)

    refute forecast["available"]
    assert forecast["risk_level"] == "offline"
    assert forecast["timeline"] == []
    assert forecast["recommendation"] =~ "Simulator unavailable"
  end
end
