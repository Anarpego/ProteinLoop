defmodule ProteinLoopWeb.SystemSceneTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias ProteinLoopWeb.SystemScene

  test "explains a stable tank without requiring chemistry knowledge" do
    html = render_scene(%{"ammonia_mg_l" => 0.4, "dissolved_oxygen_mg_l" => 9.0})

    assert html =~ "Healthy"
    assert html =~ "Tank animals can feed and breathe normally"
    assert html =~ "Waste in the water"
    assert html =~ "Air the animals can breathe"
  end

  test "explains a warning state and its immediate priority" do
    html = render_scene(%{"ammonia_mg_l" => 1.8, "dissolved_oxygen_mg_l" => 5.5})

    assert html =~ "Needs attention"
    assert html =~ "Waste is building up"
    assert html =~ "Reduce feed, increase aeration"
  end

  test "explains a critical state with direct action" do
    html = render_scene(%{"ammonia_mg_l" => 6.0, "dissolved_oxygen_mg_l" => 3.2})

    assert html =~ "Immediate action"
    assert html =~ "Tank animals are in danger"
    assert html =~ "Stop feeding, maximize aeration"
    assert html =~ "Dangerous"
    assert html =~ "Too low"
  end

  defp render_scene(state) do
    render_component(&SystemScene.system_scene/1,
      id: "test-system-scene",
      state:
        Map.merge(
          %{
            "fish_biomass_kg" => 12.0,
            "prawn_biomass_kg" => 2.5,
            "plant_biomass_kg" => 5.0,
            "duckweed_kg" => 3.0,
            "chicken_count" => 6,
            "eggs_count" => 2
          },
          state
        )
    )
  end
end
