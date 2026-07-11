defmodule ProteinLoop.Agent.ModelStatusTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.ModelStatus

  test "snapshot reports missing endpoint without network access" do
    status = ModelStatus.snapshot(endpoint: nil, model: "gemma")

    assert status.status == :not_configured
    refute status.configured?
    refute status.reachable?
    assert status.model == "gemma"
  end

  test "snapshot reports configured endpoint before check" do
    status = ModelStatus.snapshot(endpoint: "http://model.local/", model: "gemma")

    assert status.status == :not_checked
    assert status.configured?
    refute status.reachable?
    assert status.endpoint == "http://model.local"
  end

  test "check reports reachable OpenAI-compatible models endpoint" do
    request_fun = fn "http://model.local/v1/models", _opts ->
      {:ok, %{status: 200, body: %{"data" => [%{"id" => "gemma"}]}}}
    end

    status = ModelStatus.check(endpoint: "http://model.local", request_fun: request_fun)

    assert status.status == :ok
    assert status.reachable?
    assert status.model_count == 1
  end

  test "check uses a versioned endpoint without duplicating the v1 path" do
    caller = self()

    request_fun = fn url, _options ->
      send(caller, {:request_url, url})
      {:ok, %{status: 200, body: %{"data" => []}}}
    end

    assert %{status: :ok} =
             ModelStatus.check(endpoint: "http://gemma:8001/v1", request_fun: request_fun)

    assert_receive {:request_url, "http://gemma:8001/v1/models"}
  end

  test "check treats auth failures as reachable" do
    request_fun = fn _url, _opts -> {:ok, %{status: 401, body: %{"error" => "missing key"}}} end

    status = ModelStatus.check(endpoint: "http://model.local", request_fun: request_fun)

    assert status.status == :auth_required
    assert status.configured?
    assert status.reachable?
  end

  test "check reports unreachable endpoint" do
    request_fun = fn _url, _opts -> {:error, :econnrefused} end

    status = ModelStatus.check(endpoint: "http://model.local", request_fun: request_fun)

    assert status.status == :unreachable
    assert status.configured?
    refute status.reachable?
  end
end
