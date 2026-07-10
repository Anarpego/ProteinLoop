defmodule ProteinLoop.Agent.Topology do
  @moduledoc """
  Deterministic subsystem-agent topology for the operator demo.

  These cards are advisory and intentionally do not execute actions. The
  harness remains the only path that can mutate simulator state.
  """

  def from_state(state) when is_map(state) do
    [
      fish_tank(state),
      freshwater_prawn(state),
      hydroponia(state),
      duckweed_chickens(state),
      supervisor(state)
    ]
  end

  defp fish_tank(state) do
    ammonia = number(state, "ammonia_mg_l")
    oxygen = number(state, "dissolved_oxygen_mg_l")

    cond do
      ammonia >= 3.0 ->
        agent(
          "Fish tank agent",
          :critical,
          "ammonia control",
          "Stop feeding, maximize aeration, exchange water through verifier",
          ammonia / 5.5
        )

      oxygen < 5.0 ->
        agent(
          "Fish tank agent",
          :warning,
          "oxygen recovery",
          "Increase aeration before routine feeding",
          (5.0 - oxygen) / 3.0
        )

      true ->
        agent("Fish tank agent", :stable, "growth", "Maintain balanced feed and oxygen", 0.12)
    end
  end

  defp freshwater_prawn(state) do
    ammonia = number(state, "ammonia_mg_l")
    oxygen = number(state, "dissolved_oxygen_mg_l")

    cond do
      ammonia >= 3.0 or oxygen < 3.5 ->
        agent(
          "Freshwater prawn agent",
          :critical,
          "benthic survival",
          "Protect oxygen and shelter capacity before allocating feed",
          0.9
        )

      oxygen < 5.0 ->
        agent(
          "Freshwater prawn agent",
          :warning,
          "oxygen competition",
          "Defer feed and increase aeration for the lower water column",
          0.58
        )

      true ->
        agent(
          "Freshwater prawn agent",
          :stable,
          "prawn growth",
          "Maintain conservative feed allocation and dissolved oxygen",
          0.14
        )
    end
  end

  defp hydroponia(state) do
    nitrate = number(state, "nitrate_mg_l")
    plants = number(state, "plant_biomass_kg")

    cond do
      nitrate < 12.0 ->
        agent(
          "Hydroponia agent",
          :warning,
          "nutrient scarcity",
          "Preserve nitrate for plant recovery",
          0.45
        )

      nitrate > 80.0 ->
        agent(
          "Hydroponia agent",
          :warning,
          "nutrient load",
          "Use plant uptake before adding feed",
          0.55
        )

      true ->
        agent(
          "Hydroponia agent",
          :stable,
          "plant uptake",
          "Plants can absorb current nitrate load",
          min(0.3, plants / 30.0)
        )
    end
  end

  defp duckweed_chickens(state) do
    duckweed = number(state, "duckweed_kg")
    chickens = number(state, "chicken_count")

    cond do
      duckweed < 1.2 ->
        agent(
          "Duckweed/chickens agent",
          :warning,
          "protein buffer",
          "Pause duckweed harvest until mat regrows",
          0.48
        )

      duckweed > 8.0 ->
        agent(
          "Duckweed/chickens agent",
          :warning,
          "surface cover",
          "Harvest duckweed for hens without starving filtration",
          0.42
        )

      true ->
        agent(
          "Duckweed/chickens agent",
          :stable,
          "egg support",
          "Harvest lightly for #{round(chickens)} hens",
          0.18
        )
    end
  end

  defp supervisor(state) do
    collapsed? = Map.get(state, "collapsed") == true
    ammonia = number(state, "ammonia_mg_l")
    oxygen = number(state, "dissolved_oxygen_mg_l")

    cond do
      collapsed? ->
        agent(
          "Supervisor agent",
          :critical,
          "collapse response",
          "Lock risky actions and show recovery plan",
          1.0
        )

      ammonia >= 3.0 or oxygen < 3.5 ->
        agent(
          "Supervisor agent",
          :critical,
          "risk arbitration",
          "Prioritize tank recovery over biomass growth",
          0.86
        )

      ammonia >= 1.5 or oxygen < 5.0 ->
        agent(
          "Supervisor agent",
          :warning,
          "resource arbitration",
          "Throttle feed while recovery agents stabilize chemistry",
          0.56
        )

      true ->
        agent(
          "Supervisor agent",
          :stable,
          "balanced loop",
          "All subsystem recommendations can remain advisory",
          0.16
        )
    end
  end

  defp agent(name, status, focus, recommendation, tension) do
    %{
      name: name,
      status: status,
      focus: focus,
      recommendation: recommendation,
      tension: tension |> max(0.0) |> min(1.0) |> Float.round(2)
    }
  end

  defp number(map, key) do
    case Map.get(map, key) do
      value when is_integer(value) -> value * 1.0
      value when is_float(value) -> value
      value when is_binary(value) -> String.to_float(value)
      _ -> 0.0
    end
  end
end
