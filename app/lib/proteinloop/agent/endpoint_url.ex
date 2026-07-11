defmodule ProteinLoop.Agent.EndpointUrl do
  @moduledoc false

  def api_url(endpoint, resource) when is_binary(endpoint) and is_binary(resource) do
    uri = URI.parse(String.trim(endpoint))
    base_path = uri.path |> normalize_path() |> ensure_version_path()
    resource_path = String.trim_leading(resource, "/")

    %{uri | path: base_path <> "/" <> resource_path}
    |> URI.to_string()
  end

  defp normalize_path(nil), do: ""
  defp normalize_path(path), do: String.trim_trailing(path, "/")

  defp ensure_version_path(path) do
    if path == "/v1" or String.ends_with?(path, "/v1") do
      path
    else
      path <> "/v1"
    end
  end
end
