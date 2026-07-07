defmodule ProteinLoop.ProducerMessage do
  @moduledoc """
  Deterministic Spanish message packet for SMS or WhatsApp handoff.

  This is intentionally provider-free. The app can display or copy the text
  without depending on a messaging vendor during the hackathon demo.
  """

  alias ProteinLoop.Offline.EmergencyRules

  def build(state, action, approval_queue \\ %{pending: nil})
      when is_map(state) and is_map(action) and is_map(approval_queue) do
    guidance = EmergencyRules.evaluate(state)
    pending = Map.get(approval_queue, :pending) || Map.get(approval_queue, "pending")
    action = pending_action(pending, action)

    %{
      channel: "sms_whatsapp",
      language: "es",
      approval_required: not is_nil(pending),
      severity: guidance.severity,
      label: guidance.label,
      text: render_text(state, action, guidance, pending)
    }
  end

  def render_text(state, action, guidance, pending \\ nil)
      when is_map(state) and is_map(action) and is_map(guidance) do
    [
      "ProteinLoop productor",
      headline(pending, action),
      status_line(state),
      action_line(action),
      "Respaldo offline: #{guidance.message}",
      "Responda: APROBAR, MITAD o RECHAZAR."
    ]
    |> Enum.join("\n")
  end

  defp headline(nil, action), do: instruction(action)
  defp headline(%{prompt: prompt}, _action), do: "Aprobacion requerida: #{prompt}"
  defp headline(%{"prompt" => prompt}, _action), do: "Aprobacion requerida: #{prompt}"
  defp headline(_pending, action), do: "Aprobacion requerida: #{instruction(action)}"

  defp instruction(%{"note" => "critical_ammonia_recovery"}) do
    "El tanque necesita aireacion fuerte y cambio parcial de agua."
  end

  defp instruction(%{"note" => "ammonia_stabilization"}) do
    "El tanque necesita menos alimento y mas aireacion."
  end

  defp instruction(%{"note" => "oxygen_recovery"}) do
    "El tanque necesita mas aireacion antes de alimentar normal."
  end

  defp instruction(%{"note" => "producer_irreversible_harvest"}) do
    "El agente propone una accion irreversible de cosecha y cambio de agua."
  end

  defp instruction(_action), do: "El sistema esta listo para rutina normal."

  defp status_line(state) do
    ammonia = rounded(Map.get(state, "ammonia_mg_l", 0))
    oxygen = rounded(Map.get(state, "dissolved_oxygen_mg_l", 0))
    day = Map.get(state, "day", 0)

    "Estado: dia #{day}, amonio #{ammonia} mg/L, oxigeno #{oxygen} mg/L."
  end

  defp action_line(action) do
    feed = rounded(Map.get(action, "feed_kg", 0))
    aeration = rounded(Map.get(action, "aeration_hours", 0))
    exchange = rounded(number(Map.get(action, "water_exchange_fraction", 0)) * 100)
    harvest = rounded(Map.get(action, "duckweed_harvest_kg", 0))

    "Accion: alimento #{feed} kg, aireacion #{aeration} h, agua #{exchange}%, cosecha #{harvest} kg."
  end

  defp pending_action(%{action: action}, _fallback) when is_map(action), do: action
  defp pending_action(%{"action" => action}, _fallback) when is_map(action), do: action
  defp pending_action(_pending, fallback), do: fallback

  defp rounded(value) when is_integer(value), do: value
  defp rounded(value) when is_float(value), do: Float.round(value, 2)
  defp rounded(value) when is_binary(value), do: value
  defp rounded(_value), do: 0

  defp number(value) when is_integer(value), do: value * 1.0
  defp number(value) when is_float(value), do: value

  defp number(value) when is_binary(value) do
    case Float.parse(value) do
      {number, _rest} -> number
      :error -> 0.0
    end
  end

  defp number(_value), do: 0.0
end
