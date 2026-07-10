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

  test "builds English SMS WhatsApp packet with approval options" do
    packet = ProducerMessage.build(@stable_state, @action)

    assert packet.channel == "sms_whatsapp"
    assert packet.language == "en"
    refute packet.approval_required
    assert packet.text =~ "ProteinLoop producer"
    assert packet.text =~ "Status: day 4"
    assert packet.text =~ "Reply: APPROVE, HALF, or REJECT."
  end

  test "pending irreversible request is marked as approval required" do
    pending = %{
      pending: %{
        prompt: "Tank 2 is ready to harvest. Continue?",
        action: Map.put(@action, "note", "producer_irreversible_harvest")
      }
    }

    packet = ProducerMessage.build(@stable_state, @action, pending)

    assert packet.approval_required
    assert packet.text =~ "Approval required"
    assert packet.text =~ "Tank 2"
  end

  test "critical state includes offline emergency guidance" do
    packet =
      ProducerMessage.build(
        %{@stable_state | "ammonia_mg_l" => 3.4, "dissolved_oxygen_mg_l" => 3.0},
        @action
      )

    assert packet.severity == :critical
    assert packet.text =~ "Do not feed"
    assert packet.text =~ "community technician"
  end
end
