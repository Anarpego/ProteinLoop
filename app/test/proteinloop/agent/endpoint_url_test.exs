defmodule ProteinLoop.Agent.EndpointUrlTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.Agent.EndpointUrl

  test "builds OpenAI-compatible paths from an unversioned server base" do
    assert EndpointUrl.api_url("http://gemma:8001", "models") ==
             "http://gemma:8001/v1/models"

    assert EndpointUrl.api_url("http://gemma:8001/", "chat/completions") ==
             "http://gemma:8001/v1/chat/completions"
  end

  test "does not duplicate an existing v1 path" do
    assert EndpointUrl.api_url("http://gemma:8001/v1", "models") ==
             "http://gemma:8001/v1/models"

    assert EndpointUrl.api_url(
             "https://api.fireworks.ai/inference/v1/",
             "chat/completions"
           ) ==
             "https://api.fireworks.ai/inference/v1/chat/completions"
  end
end
