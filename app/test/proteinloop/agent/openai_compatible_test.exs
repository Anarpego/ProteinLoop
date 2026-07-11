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

  test "uses a configurable inference timeout and output budget" do
    caller = self()

    request_fun = fn url, options ->
      send(caller, {:request, url, options})

      {:ok,
       %{
         status: 200,
         body: %{
           "choices" => [
             %{
               "message" => %{
                 "content" =>
                   ~s({"feed_kg":0.0,"aeration_hours":24,"water_exchange_fraction":0.3,"duckweed_harvest_kg":0,"note":"recovery"})
               }
             }
           ]
         }
       }}
    end

    assert {:ok, action, metadata} =
             OpenAICompatible.propose(
               %{"ammonia_mg_l" => 3.2},
               endpoint: "http://127.0.0.1:8001",
               model: "google/gemma-4-E2B-it",
               receive_timeout: 120_000,
               max_tokens: 1024,
               request_fun: request_fun
             )

    assert action["aeration_hours"] == 24.0
    assert metadata.provider == :openai_compatible

    assert_receive {:request, "http://127.0.0.1:8001/v1/chat/completions", options}
    assert options[:receive_timeout] == 120_000
    assert options[:json]["max_tokens"] == 1024
    assert options[:json]["model"] == "google/gemma-4-E2B-it"
    assert options[:json]["chat_template_kwargs"] == %{"enable_thinking" => false}
    assert options[:json]["response_format"] == %{"type" => "json_object"}

    system_prompt = options[:json]["messages"] |> hd() |> Map.fetch!("content")
    assert system_prompt =~ "feed_kg must be between 0 and 0.25"
    assert system_prompt =~ "water_exchange_fraction must be between 0 and 0.30"
    assert system_prompt =~ "simulator verifier remains authoritative"
  end

  test "uses a versioned endpoint without duplicating the v1 path" do
    caller = self()

    request_fun = fn url, _options ->
      send(caller, {:request_url, url})

      {:ok,
       %{
         status: 200,
         body: %{
           "choices" => [
             %{
               "message" => %{
                 "content" =>
                   ~s({"feed_kg":0,"aeration_hours":24,"water_exchange_fraction":0.3,"duckweed_harvest_kg":0,"note":"recovery"})
               }
             }
           ]
         }
       }}
    end

    assert {:ok, _action, _metadata} =
             OpenAICompatible.propose(
               %{"ammonia_mg_l" => 2.75},
               endpoint: "http://gemma:8001/v1",
               request_fun: request_fun
             )

    assert_receive {:request_url, "http://gemma:8001/v1/chat/completions"}
  end
end
