defmodule ProteinLoop.TestNRF9151Evidence do
  def snapshot do
    %{
      available?: true,
      captured_at: "2026-07-10T15:39:20.063217+00:00",
      simulated?: false,
      sequence: 100,
      capture_mode: "read_only_posix_serial",
      flash_or_reset_invoked?: false,
      ft: %{
        role: "FT",
        peer_role: "PT",
        field_role: "community gateway/controller",
        jlink_id: "1051223739",
        serial_port: "/dev/cu.usbmodem0010512237391",
        sent?: true,
        received?: true
      },
      pt: %{
        role: "PT",
        peer_role: "FT",
        field_role: "tank sensor edge node",
        jlink_id: "1051239227",
        serial_port: "/dev/cu.usbmodem0010512392271",
        sent?: true,
        received?: true
      },
      error: nil
    }
  end
end

defmodule ProteinLoop.TestDectSimulatorClient do
  def trigger_ammonia_spike do
    if owner = Application.get_env(:proteinloop, :test_dect_owner) do
      send(owner, :dect_replay_requested)
    end

    state =
      ProteinLoop.SimulatorClient.fallback_state()
      |> Map.merge(%{
        "ammonia_mg_l" => 3.8,
        "dissolved_oxygen_mg_l" => 3.2,
        "last_event" => "ammonia_spike"
      })

    {:ok, %{"state" => state}}
  end
end
