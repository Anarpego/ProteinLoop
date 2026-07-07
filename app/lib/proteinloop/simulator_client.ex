defmodule ProteinLoop.SimulatorClient do
  @moduledoc """
  Client for the Python simulator API.

  The simulator is the deterministic verifier source of truth. The Phoenix app
  uses this module only through JSON-compatible maps so the contract remains
  easy to replace with Sagents later.
  """

  @critical_action %{
    "feed_kg" => 0.0,
    "aeration_hours" => 24.0,
    "water_exchange_fraction" => 0.30,
    "duckweed_harvest_kg" => 0.0,
    "note" => "critical_ammonia_recovery"
  }

  @balanced_action %{
    "feed_kg" => 0.22,
    "aeration_hours" => 9.0,
    "water_exchange_fraction" => 0.0,
    "duckweed_harvest_kg" => 0.15,
    "note" => "balanced_growth"
  }

  def state do
    request(:get, "/state")
  end

  def rlvr_evaluation do
    request(:get, "/rlvr/evaluation")
  end

  def rlvr_training do
    request(:get, "/rlvr/training")
  end

  def anomaly_forecast do
    request(:get, "/forecast/anomaly")
  end

  def reset do
    request(:post, "/reset", %{})
  end

  def trigger_ammonia_spike do
    request(:post, "/scenario/ammonia_spike", %{})
  end

  def safety_step do
    request(:post, "/policy/safety_step", %{})
  end

  def step(action) when is_map(action) do
    request(:post, "/step", %{"action" => action})
  end

  def proposed_action(state) when is_map(state) do
    ammonia = number(state, "ammonia_mg_l")
    oxygen = number(state, "dissolved_oxygen_mg_l")

    cond do
      ammonia >= 3.0 ->
        @critical_action

      ammonia >= 1.5 ->
        %{
          "feed_kg" => 0.08,
          "aeration_hours" => 18.0,
          "water_exchange_fraction" => 0.15,
          "duckweed_harvest_kg" => 0.0,
          "note" => "ammonia_stabilization"
        }

      oxygen < 5.0 ->
        %{
          "feed_kg" => 0.18,
          "aeration_hours" => 18.0,
          "water_exchange_fraction" => 0.05,
          "duckweed_harvest_kg" => 0.0,
          "note" => "oxygen_recovery"
        }

      true ->
        @balanced_action
    end
  end

  def fallback_state do
    %{
      "day" => 0,
      "water_volume_l" => 1000.0,
      "ammonia_mg_l" => 0.35,
      "nitrate_mg_l" => 35.0,
      "dissolved_oxygen_mg_l" => 6.8,
      "ph" => 7.2,
      "temperature_c" => 26.0,
      "fish_biomass_kg" => 12.0,
      "prawn_biomass_kg" => 2.5,
      "duckweed_kg" => 3.0,
      "plant_biomass_kg" => 5.0,
      "chicken_count" => 6,
      "eggs_count" => 0.0,
      "stress_days" => 0,
      "collapsed" => false,
      "mortality_events" => %{"fish" => 0, "prawn" => 0, "chicken" => 0},
      "last_event" => "simulator_unavailable",
      "aquatic_biomass_kg" => 14.5,
      "edible_biomass_kg" => 19.5
    }
  end

  def fallback_rlvr_evaluation(reason \\ :simulator_unavailable) do
    %{
      "available" => false,
      "error" => inspect(reason),
      "baseline_policy" => "naive",
      "candidate_policy" => "safety",
      "scenario_count" => 0,
      "average_reward_delta" => nil,
      "recovered_scenarios" => 0,
      "collapse_avoidance_rate" => nil,
      "scenarios" => []
    }
  end

  def fallback_rlvr_training(reason \\ :simulator_unavailable) do
    %{
      "available" => false,
      "error" => inspect(reason),
      "method" => "deterministic_candidate_search",
      "baseline_policy" => "seed_low_input",
      "iteration_count" => 0,
      "initial_reward" => nil,
      "best_reward" => nil,
      "improvement" => nil,
      "best_policy" => %{"name" => "pending"},
      "iterations" => []
    }
  end

  def fallback_anomaly_forecast(reason \\ :simulator_unavailable) do
    %{
      "available" => false,
      "error" => inspect(reason),
      "risk_level" => "offline",
      "collapsed" => false,
      "first_critical_day" => nil,
      "max_ammonia_mg_l" => nil,
      "min_oxygen_mg_l" => nil,
      "recommendation" => "Simulator unavailable; use manual water-quality checks.",
      "timeline" => []
    }
  end

  defp request(method, path, body \\ nil) do
    if Application.get_env(:proteinloop, :simulator_http_enabled, true) do
      do_request(method, path, body)
    else
      {:error, :simulator_http_disabled}
    end
  end

  defp do_request(method, path, body) do
    options =
      [
        method: method,
        url: simulator_url(path),
        receive_timeout: 2_000
      ]
      |> maybe_put_json(body)

    case Req.request(options) do
      {:ok, %{status: status, body: response_body}} when status in 200..299 ->
        {:ok, response_body}

      {:ok, %{status: status, body: response_body}} ->
        {:error, %{status: status, body: response_body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_put_json(options, nil), do: options
  defp maybe_put_json(options, body), do: Keyword.put(options, :json, body)

  defp simulator_url(path) do
    :proteinloop
    |> Application.get_env(:simulator_url, "http://127.0.0.1:8000")
    |> String.trim_trailing("/")
    |> Kernel.<>(path)
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
