defmodule ProteinLoop.Agent.ModelStatus do
  @moduledoc """
  Reports configuration and reachability for the OpenAI-compatible model endpoint.

  The harness can run without a model endpoint because deterministic stubs keep
  the demo safe. This module makes the optional Gemma boundary visible without
  blocking dashboard startup.
  """

  alias ProteinLoop.Agent.EndpointUrl

  def snapshot(opts \\ []) do
    model = model(opts)

    case endpoint(opts) do
      {:ok, endpoint} ->
        status(
          :not_checked,
          endpoint,
          model,
          true,
          false,
          nil,
          "Endpoint configured; check not run"
        )

      {:error, _reason} ->
        status(
          :not_configured,
          nil,
          model,
          false,
          false,
          nil,
          "Set GEMMA_ENDPOINT to enable model proposals"
        )
    end
  end

  def check(opts \\ []) do
    model = model(opts)

    with {:ok, endpoint} <- endpoint(opts) do
      request_fun = Keyword.get(opts, :request_fun, &Req.get/2)
      headers = auth_headers(opts)
      timeout = Keyword.get(opts, :receive_timeout, 5_000)

      case request_fun.(models_url(endpoint), headers: headers, receive_timeout: timeout) do
        {:ok, %{status: response_status, body: body}} when response_status in 200..299 ->
          status(
            :ok,
            endpoint,
            model,
            true,
            true,
            model_count(body),
            "Endpoint returned /v1/models"
          )

        {:ok, %{status: response_status}} when response_status in [401, 403] ->
          status(
            :auth_required,
            endpoint,
            model,
            true,
            true,
            nil,
            "Endpoint reachable; API key is required or rejected"
          )

        {:ok, %{status: response_status}} ->
          status(
            :http_error,
            endpoint,
            model,
            true,
            true,
            nil,
            "Endpoint reached with HTTP #{response_status}"
          )

        {:error, reason} ->
          status(
            :unreachable,
            endpoint,
            model,
            true,
            false,
            nil,
            "Endpoint unreachable: #{inspect(reason)}"
          )
      end
    else
      {:error, _reason} -> snapshot(opts)
    end
  end

  defp endpoint(opts) do
    endpoint = Keyword.get(opts, :endpoint, Application.get_env(:proteinloop, :gemma_endpoint))

    case endpoint do
      value when is_binary(value) and value != "" -> {:ok, String.trim_trailing(value, "/")}
      _ -> {:error, :gemma_endpoint_not_configured}
    end
  end

  defp model(opts) do
    Keyword.get(opts, :model, Application.get_env(:proteinloop, :gemma_model, "gemma"))
  end

  defp auth_headers(opts) do
    case Keyword.get(opts, :api_key, Application.get_env(:proteinloop, :gemma_api_key)) do
      nil -> []
      "" -> []
      key -> [{"authorization", "Bearer #{key}"}]
    end
  end

  defp models_url(endpoint), do: EndpointUrl.api_url(endpoint, "models")

  defp model_count(%{"data" => data}) when is_list(data), do: length(data)
  defp model_count(_body), do: nil

  defp status(status, endpoint, model, configured, reachable, model_count, detail) do
    %{
      status: status,
      label: label(status),
      endpoint: endpoint,
      model: model,
      configured?: configured,
      reachable?: reachable,
      model_count: model_count,
      detail: detail
    }
  end

  defp label(:not_checked), do: "not checked"
  defp label(:not_configured), do: "not configured"
  defp label(:ok), do: "reachable"
  defp label(:auth_required), do: "auth required"
  defp label(:http_error), do: "HTTP error"
  defp label(:unreachable), do: "unreachable"
end
