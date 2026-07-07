defmodule ProteinLoop.Agent.ActionProposerTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.ActionProposer

  @state %{
    "ammonia_mg_l" => 4.0,
    "dissolved_oxygen_mg_l" => 4.5,
    "aquatic_biomass_kg" => 14.5
  }

  test "safe stub emits recovery action for critical ammonia" do
    assert {:ok, action, metadata} = ActionProposer.propose(@state, provider: :stub_safe)

    assert action["feed_kg"] == 0.0
    assert action["aeration_hours"] == 24.0
    assert action["water_exchange_fraction"] == 0.30
    assert metadata.provider == :stub_safe
  end

  test "unsafe stub emits an intentionally rejectable overfeed action" do
    assert {:ok, action, metadata} = ActionProposer.propose(@state, provider: :stub_unsafe)

    assert action["feed_kg"] == 4.0
    assert metadata.provider == :stub_unsafe
  end
end
