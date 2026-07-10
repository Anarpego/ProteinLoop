defmodule ProteinLoop.ProducerMessage do
  @moduledoc """
  Deterministic English message packet for SMS or WhatsApp handoff.

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
      language: "en",
      approval_required: not is_nil(pending),
      severity: guidance.severity,
      label: guidance.label,
      text: render_text(state, action, guidance, pending)
    }
  end

  def render_text(state, action, guidance, pending \\ nil)
      when is_map(state) and is_map(action) and is_map(guidance) do
    [
      "ProteinLoop producer",
      headline(pending, action),
      status_line(state),
      action_line(action),
      "Offline fallback: #{guidance.message}",
      "Reply: APPROVE, HALF, or REJECT."
    ]
    |> Enum.join("\n")
  end

  defp headline(nil, action), do: instruction(action)
  defp headline(%{prompt: prompt}, _action), do: "Approval required: #{prompt}"
  defp headline(%{"prompt" => prompt}, _action), do: "Approval required: #{prompt}"
  defp headline(_pending, action), do: "Approval required: #{instruction(action)}"

  defp instruction(%{"note" => "critical_ammonia_recovery"}) do
    "The main tank needs maximum aeration and a verified partial water change."
  end

  defp instruction(%{"note" => "ammonia_stabilization"}) do
    "The main tank needs less feed and more aeration."
  end

  defp instruction(%{"note" => "oxygen_recovery"}) do
    "The main tank needs more aeration before normal feeding resumes."
  end

  defp instruction(%{"note" => "producer_irreversible_harvest"}) do
    "The agent proposes an irreversible harvest and water-change action."
  end

  defp instruction(_action), do: "The system is ready for the normal routine."

  defp status_line(state) do
    ammonia = rounded(Map.get(state, "ammonia_mg_l", 0))
    oxygen = rounded(Map.get(state, "dissolved_oxygen_mg_l", 0))
    day = Map.get(state, "day", 0)

    "Status: day #{day}, waste ammonia #{ammonia} mg/L, breathing oxygen #{oxygen} mg/L."
  end

  defp action_line(action) do
    feed = rounded(Map.get(action, "feed_kg", 0))
    aeration = rounded(Map.get(action, "aeration_hours", 0))
    exchange = rounded(number(Map.get(action, "water_exchange_fraction", 0)) * 100)
    harvest = rounded(Map.get(action, "duckweed_harvest_kg", 0))

    "Action: feed #{feed} kg, aeration #{aeration} h, water exchange #{exchange}%, harvest #{harvest} kg."
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
