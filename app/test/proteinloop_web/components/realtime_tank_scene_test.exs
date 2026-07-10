defmodule ProteinLoopWeb.RealtimeTankSceneTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias ProteinLoopWeb.RealtimeTankScene

  test "renders an accessible real-time tank driven by simulator values" do
    html =
      render_component(&RealtimeTankScene.realtime_tank_scene/1,
        id: "test-realtime-tank",
        state: state(),
        controls: true
      )

    assert html =~ ~s(phx-hook="RealtimeTank")
    assert html =~ ~s(data-ammonia="0.4")
    assert html =~ ~s(data-oxygen="6.8")
    assert html =~ ~s(data-health="stable")
    assert html =~ ~s(data-fish-model-url="/models/barramundi-fish.glb")
    assert html =~ ~s(data-prawn-texture-url="/models/greasyback-shrimp.jpeg")
    assert html =~ ~s(data-tank-canvas)
    assert html =~ ~s(data-tank-fullscreen)
    assert html =~ "Open tank full screen"
    assert html =~ ~s(role="img")
    assert html =~ ~s(aria-labelledby="test-realtime-tank-description")
    assert html =~ "Animated fish and freshwater prawn tank"
    assert html =~ "Live tank simulation"
    assert html =~ "Simulate water emergency"
    assert html =~ "Waste in water"
    assert html =~ "Breathing oxygen"
    assert html =~ "Plant loop"
    assert html =~ "duckweed"
    refute html =~ "protein-loop-system.svg"
    refute html =~ "<img"
  end

  test "is read-only by default for producer reuse" do
    html =
      render_component(&RealtimeTankScene.realtime_tank_scene/1,
        id: "test-read-only-tank",
        state: state()
      )

    assert html =~ ~s(phx-hook="RealtimeTank")
    assert html =~ ~s(data-tank-fallback)
    assert html =~ ~s(data-tank-fullscreen)
    refute html =~ ~s(phx-click="spike")
    refute html =~ ~s(phx-click="reset")
  end

  test "encodes critical chemistry for the renderer and readable fallback" do
    html =
      render_component(&RealtimeTankScene.realtime_tank_scene/1,
        id: "test-critical-tank",
        state:
          state()
          |> Map.put("day", 4)
          |> Map.put("ammonia_mg_l", 3.8)
          |> Map.put("dissolved_oxygen_mg_l", 3.2)
      )

    assert html =~ ~s(data-day="4")
    assert html =~ ~s(data-ammonia="3.8")
    assert html =~ ~s(data-oxygen="3.2")
    assert html =~ ~s(data-health="critical")
    assert html =~ "Tank animals are in danger"
    assert html =~ "Dangerous waste"
    assert html =~ "Low oxygen"
  end

  defp state do
    %{
      "day" => 0,
      "ammonia_mg_l" => 0.4,
      "dissolved_oxygen_mg_l" => 6.8,
      "fish_biomass_kg" => 12.0,
      "prawn_biomass_kg" => 2.5,
      "plant_biomass_kg" => 5.0,
      "duckweed_kg" => 3.0,
      "collapsed" => false,
      "last_event" => "initialized"
    }
  end
end
