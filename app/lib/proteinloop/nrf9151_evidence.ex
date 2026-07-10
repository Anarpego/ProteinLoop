defmodule ProteinLoop.NRF9151Evidence do
  @moduledoc """
  Loads the latest read-only, two-board DECT NR+ evidence artifact.

  The artifact proves radio transport only. Sensor values remain owned by the
  simulator until firmware emits the separate ProteinLoop telemetry contract.
  """

  @default_path Path.expand("../../../submission/nrf9151-live-evidence.json", __DIR__)

  def snapshot do
    System.get_env("NRF9151_EVIDENCE_PATH", @default_path)
    |> load()
  end

  def load(path) when is_binary(path) do
    with {:ok, body} <- File.read(path),
         {:ok, evidence} <- Jason.decode(body),
         :ok <- validate_physical_capture(evidence),
         {:ok, sequence} <- matching_sequence(evidence),
         {:ok, ft} <- board(evidence, "FT"),
         {:ok, pt} <- board(evidence, "PT") do
      %{
        available?: true,
        captured_at: evidence["generated_at"],
        simulated?: false,
        sequence: sequence,
        capture_mode: get_in(evidence, ["capture", "mode"]),
        flash_or_reset_invoked?: get_in(evidence, ["capture", "flash_or_reset_invoked"]),
        ft: ft,
        pt: pt,
        error: nil
      }
    else
      {:error, reason} -> unavailable(reason)
      :error -> unavailable("invalid DECT evidence")
    end
  end

  defp validate_physical_capture(%{
         "ok" => true,
         "simulated" => false,
         "capture" => %{
           "mode" => "read_only_posix_serial",
           "flash_or_reset_invoked" => false
         }
       }),
       do: :ok

  defp validate_physical_capture(%{"simulated" => true}),
    do: {:error, "DECT evidence is simulated"}

  defp validate_physical_capture(_evidence),
    do: {:error, "DECT evidence is not a passing read-only physical capture"}

  defp matching_sequence(evidence) do
    with ft_to_pt when is_list(ft_to_pt) <- get_in(evidence, ["peer_exchanges", "ft_to_pt"]),
         pt_to_ft when is_list(pt_to_ft) <- get_in(evidence, ["peer_exchanges", "pt_to_ft"]) do
      common =
        ft_to_pt
        |> MapSet.new()
        |> MapSet.intersection(MapSet.new(pt_to_ft))
        |> Enum.filter(&is_integer/1)

      case common do
        [] -> {:error, "DECT evidence has no matching bidirectional sequence"}
        sequences -> {:ok, Enum.max(sequences)}
      end
    else
      _other -> {:error, "DECT evidence has invalid peer exchanges"}
    end
  end

  defp board(%{"boards" => boards}, role) when is_list(boards) do
    case Enum.find(boards, &(&1["detected_role"] == role)) do
      %{"jlink_id" => jlink_id, "serial_port" => serial_port} = board
      when is_binary(jlink_id) and is_binary(serial_port) ->
        expected_peer = if role == "FT", do: "PT", else: "FT"

        if board["ok"] == true and board["role_matches"] == true and
             board["peer_role"] == expected_peer and board["sent_local"] == true and
             board["received_peer"] == true do
          {:ok,
           %{
             role: role,
             peer_role: board["peer_role"],
             field_role: board["field_role"],
             jlink_id: jlink_id,
             serial_port: serial_port,
             sent?: true,
             received?: true
           }}
        else
          {:error, "DECT #{role} board did not pass role, send, and receive checks"}
        end

      _other ->
        {:error, "DECT evidence is missing the #{role} board"}
    end
  end

  defp board(_evidence, role), do: {:error, "DECT evidence is missing the #{role} board"}

  defp unavailable(reason) do
    %{
      available?: false,
      captured_at: nil,
      simulated?: nil,
      sequence: nil,
      capture_mode: nil,
      flash_or_reset_invoked?: nil,
      ft: nil,
      pt: nil,
      error: format_error(reason)
    }
  end

  defp format_error(:enoent), do: "DECT evidence file was not found"
  defp format_error(%Jason.DecodeError{}), do: "DECT evidence is not valid JSON"
  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(reason), do: inspect(reason)
end
