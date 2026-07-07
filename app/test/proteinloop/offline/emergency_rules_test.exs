defmodule ProteinLoop.Offline.EmergencyRulesTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Offline.EmergencyRules

  test "stable state gives routine guidance" do
    guidance = EmergencyRules.evaluate(%{"ammonia_mg_l" => 0.4, "dissolved_oxygen_mg_l" => 6.8})

    assert guidance.severity == :stable
    assert guidance.label == "estable"
    assert guidance.message =~ "Rutina normal"
  end

  test "warning chemistry asks producer to watch closely" do
    guidance = EmergencyRules.evaluate(%{"ammonia_mg_l" => 1.8, "dissolved_oxygen_mg_l" => 5.5})

    assert guidance.severity == :warning
    assert guidance.label == "atencion"
    assert guidance.action == "vigilar de cerca"
  end

  test "critical chemistry gives direct emergency instructions" do
    guidance = EmergencyRules.evaluate(%{"ammonia_mg_l" => 4.0, "dissolved_oxygen_mg_l" => 3.2})

    assert guidance.severity == :critical
    assert guidance.label == "emergencia"
    assert guidance.message =~ "No alimente"
    assert guidance.message =~ "llame al tecnico comunitario"
  end
end
