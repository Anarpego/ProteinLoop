defmodule ProteinLoop.ProducerMessageTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.ProducerMessage

  @stable_state %{
    "day" => 4,
    "ammonia_mg_l" => 0.7,
    "dissolved_oxygen_mg_l" => 6.4,
    "collapsed" => false
  }

  @action %{
    "feed_kg" => 0.12,
    "aeration_hours" => 8.0,
    "water_exchange_fraction" => 0.1,
    "duckweed_harvest_kg" => 0.2,
    "note" => "ammonia_stabilization"
  }

  test "builds Spanish SMS WhatsApp packet with approval options" do
    packet = ProducerMessage.build(@stable_state, @action)

    assert packet.channel == "sms_whatsapp"
    assert packet.language == "es"
    refute packet.approval_required
    assert packet.text =~ "ProteinLoop productor"
    assert packet.text =~ "Estado: dia 4"
    assert packet.text =~ "Responda: APROBAR, MITAD o RECHAZAR."
  end

  test "pending irreversible request is marked as approval required" do
    pending = %{
      pending: %{
        prompt: "El tanque 2 esta listo para cosechar. Procedo?",
        action: Map.put(@action, "note", "producer_irreversible_harvest")
      }
    }

    packet = ProducerMessage.build(@stable_state, @action, pending)

    assert packet.approval_required
    assert packet.text =~ "Aprobacion requerida"
    assert packet.text =~ "tanque 2"
  end

  test "critical state includes offline emergency guidance" do
    packet =
      ProducerMessage.build(
        %{@stable_state | "ammonia_mg_l" => 3.4, "dissolved_oxygen_mg_l" => 3.0},
        @action
      )

    assert packet.severity == :critical
    assert packet.text =~ "No alimente"
    assert packet.text =~ "tecnico comunitario"
  end
end
