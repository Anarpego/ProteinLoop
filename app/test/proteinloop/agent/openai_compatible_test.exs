defmodule ProteinLoop.Agent.OpenAICompatibleTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.OpenAICompatible

  test "parses JSON action from OpenAI-compatible chat response" do
    response = %{
      "choices" => [
        %{
          "message" => %{
            "content" =>
              ~s({"feed_kg":0.08,"aeration_hours":18,"water_exchange_fraction":0.15,"duckweed_harvest_kg":0,"note":"ammonia_stabilization"})
          }
        }
      ]
    }

    assert {:ok, action} = OpenAICompatible.parse_action(response)
    assert action["feed_kg"] == 0.08
    assert action["aeration_hours"] == 18.0
    assert action["note"] == "ammonia_stabilization"
  end

  test "parses fenced JSON action" do
    content = """
    ```json
    {"feed_kg": "0.0", "aeration_hours": 24, "water_exchange_fraction": 0.3, "duckweed_harvest_kg": 0, "note": "critical"}
    ```
    """

    assert {:ok, action} = OpenAICompatible.parse_action(content)
    assert action["feed_kg"] == 0.0
    assert action["water_exchange_fraction"] == 0.3
  end

  test "returns clear error for non-json content" do
    assert {:error, {:invalid_model_json, _reason}} = OpenAICompatible.parse_action("feed less")
  end
end
