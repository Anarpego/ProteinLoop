defmodule ProteinLoop.Offline.EmergencyRulesTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Offline.EmergencyRules

  test "stable state gives routine guidance" do
    guidance = EmergencyRules.evaluate(%{"ammonia_mg_l" => 0.4, "dissolved_oxygen_mg_l" => 6.8})

    assert guidance.severity == :stable
    assert guidance.label == "stable"
    assert guidance.message =~ "Normal routine"
    assert guidance.action == "follow routine"
  end

  test "warning chemistry asks producer to watch closely" do
    guidance = EmergencyRules.evaluate(%{"ammonia_mg_l" => 1.8, "dissolved_oxygen_mg_l" => 5.5})

    assert guidance.severity == :warning
    assert guidance.label == "attention"
    assert guidance.message =~ "Reduce feed"
    assert guidance.action == "watch closely"
  end

  test "critical chemistry gives direct emergency instructions" do
    guidance = EmergencyRules.evaluate(%{"ammonia_mg_l" => 4.0, "dissolved_oxygen_mg_l" => 3.2})

    assert guidance.severity == :critical
    assert guidance.label == "emergency"
    assert guidance.message =~ "Do not feed"
    assert guidance.message =~ "community technician"
    assert guidance.action == "stop feeding"
  end
end
