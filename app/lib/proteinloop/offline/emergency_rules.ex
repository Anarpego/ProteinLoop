defmodule ProteinLoop.Offline.EmergencyRules do
  @moduledoc """
  Deterministic English fallback guidance for degraded producer operation.

  These rules are intentionally simple enough to run without cloud model access.
  """

  def evaluate(state) when is_map(state) do
    ammonia = number(state, "ammonia_mg_l")
    oxygen = number(state, "dissolved_oxygen_mg_l")
    collapsed? = Map.get(state, "collapsed", false)

    cond do
      collapsed? or ammonia >= 3.0 or oxygen < 3.5 ->
        %{
          severity: :critical,
          label: "emergency",
          message:
            "Do not feed. Start maximum aeration, use a verified partial water change, and call the community technician.",
          action: "stop feeding"
        }

      ammonia >= 1.5 or oxygen < 5.0 ->
        %{
          severity: :warning,
          label: "attention",
          message:
            "Reduce feed, increase aeration, and check the water smell and color during the next few hours.",
          action: "watch closely"
        }

      true ->
        %{
          severity: :stable,
          label: "stable",
          message:
            "Normal routine. Keep the daily check and do not increase feed without a new reading.",
          action: "follow routine"
        }
    end
  end

  defp number(map, key) do
    case Map.get(map, key) do
      value when is_integer(value) -> value * 1.0
      value when is_float(value) -> value
      value when is_binary(value) -> parse_number(value)
      _ -> 0.0
    end
  end

  defp parse_number(value) do
    case Float.parse(value) do
      {number, _rest} -> number
      :error -> 0.0
    end
  end
end
