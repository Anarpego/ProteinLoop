defmodule ProteinLoop.Offline.EmergencyRules do
  @moduledoc """
  Deterministic Spanish fallback guidance for degraded producer operation.

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
          label: "emergencia",
          message:
            "No alimente. Active aireacion fuerte, cambie agua verificada y llame al tecnico comunitario.",
          action: "detener alimento"
        }

      ammonia >= 1.5 or oxygen < 5.0 ->
        %{
          severity: :warning,
          label: "atencion",
          message:
            "Reduzca alimento, suba aireacion y revise olor/color del agua en las proximas horas.",
          action: "vigilar de cerca"
        }

      true ->
        %{
          severity: :stable,
          label: "estable",
          message:
            "Rutina normal. Mantenga observacion diaria y no aumente alimento sin nueva lectura.",
          action: "seguir rutina"
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
