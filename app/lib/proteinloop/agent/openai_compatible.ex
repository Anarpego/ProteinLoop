defmodule ProteinLoop.Agent.OpenAICompatible do
  @moduledoc """
  OpenAI-compatible chat-completions boundary for AMD-hosted Gemma or fallback APIs.

  The endpoint is configured by `GEMMA_ENDPOINT`. The client expects the model
  to return one JSON object matching the simulator action contract.
  """

  @system_prompt """
  You operate ProteinLoop, a small aquaponic protein loop.
  Return exactly one JSON object and no prose.
  Required keys: feed_kg, aeration_hours, water_exchange_fraction, duckweed_harvest_kg, note.
  Keep actions conservative. The deterministic harness may reject unsafe actions.
  """

  def propose(state, opts \\ []) when is_map(state) do
    with {:ok, endpoint} <- endpoint(opts),
         {:ok, response} <- request_action(endpoint, state, opts),
         {:ok, action} <- parse_action(response) do
      {:ok, action,
       %{
         provider: :openai_compatible,
         rationale: "model action parsed from OpenAI-compatible chat response"
       }}
    end
  end

  def parse_action(%{"choices" => [%{"message" => %{"content" => content}} | _]}) do
    parse_action(content)
  end

  def parse_action(content) when is_binary(content) do
    content
    |> strip_code_fence()
    |> Jason.decode()
    |> case do
      {:ok, action} when is_map(action) -> normalize_action(action)
      {:ok, _other} -> {:error, :model_response_not_an_action_object}
      {:error, reason} -> {:error, {:invalid_model_json, reason}}
    end
  end

  def parse_action(_content), do: {:error, :missing_model_content}

  defp request_action(endpoint, state, opts) do
    api_key = Keyword.get(opts, :api_key, Application.get_env(:proteinloop, :gemma_api_key))
    model = Keyword.get(opts, :model, Application.get_env(:proteinloop, :gemma_model, "gemma"))

    headers =
      case api_key do
        nil -> []
        "" -> []
        key -> [{"authorization", "Bearer #{key}"}]
      end

    body = %{
      "model" => model,
      "temperature" => 0.1,
      "messages" => [
        %{"role" => "system", "content" => @system_prompt},
        %{
          "role" => "user",
          "content" => "Current simulator state JSON: #{Jason.encode!(state)}"
        }
      ]
    }

    case Req.post(chat_url(endpoint), json: body, headers: headers, receive_timeout: 20_000) do
      {:ok, %{status: status, body: response_body}} when status in 200..299 ->
        {:ok, response_body}

      {:ok, %{status: status, body: response_body}} ->
        {:error, {:model_http_error, status, response_body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp endpoint(opts) do
    endpoint = Keyword.get(opts, :endpoint, Application.get_env(:proteinloop, :gemma_endpoint))

    case endpoint do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, :gemma_endpoint_not_configured}
    end
  end

  defp chat_url(endpoint) do
    endpoint
    |> String.trim_trailing("/")
    |> Kernel.<>("/v1/chat/completions")
  end

  defp normalize_action(action) do
    with {:ok, feed_kg} <- fetch_number(action, "feed_kg"),
         {:ok, aeration_hours} <- fetch_number(action, "aeration_hours"),
         {:ok, water_exchange_fraction} <- fetch_number(action, "water_exchange_fraction"),
         {:ok, duckweed_harvest_kg} <- fetch_number(action, "duckweed_harvest_kg") do
      {:ok,
       %{
         "feed_kg" => feed_kg,
         "aeration_hours" => aeration_hours,
         "water_exchange_fraction" => water_exchange_fraction,
         "duckweed_harvest_kg" => duckweed_harvest_kg,
         "note" => Map.get(action, "note", "model_proposal") |> to_string()
       }}
    end
  end

  defp fetch_number(map, key) do
    case Map.get(map, key) || Map.get(map, String.to_atom(key)) do
      value when is_integer(value) -> {:ok, value * 1.0}
      value when is_float(value) -> {:ok, value}
      value when is_binary(value) -> parse_float(value, key)
      _ -> {:error, {:missing_or_invalid_number, key}}
    end
  end

  defp parse_float(value, key) do
    case Float.parse(value) do
      {number, ""} -> {:ok, number}
      _ -> {:error, {:missing_or_invalid_number, key}}
    end
  end

  defp strip_code_fence(content) do
    content
    |> String.trim()
    |> String.replace_prefix("```json", "")
    |> String.replace_prefix("```", "")
    |> String.replace_suffix("```", "")
    |> String.trim()
  end
end
