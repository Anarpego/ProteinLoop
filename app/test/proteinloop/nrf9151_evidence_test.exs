defmodule ProteinLoop.NRF9151EvidenceTest do
  use ExUnit.Case, async: true

  alias ProteinLoop.NRF9151Evidence

  test "loads the latest matching physical FT/PT exchange" do
    path = temp_evidence_path()

    File.write!(
      path,
      Jason.encode!(%{
        "generated_at" => "2026-07-10T15:39:20.063217+00:00",
        "ok" => true,
        "simulated" => false,
        "capture" => %{
          "mode" => "read_only_posix_serial",
          "flash_or_reset_invoked" => false
        },
        "peer_exchanges" => %{
          "ft_to_pt" => [98, 100],
          "pt_to_ft" => [99, 100]
        },
        "boards" => [
          board("FT", "1051223739", "/dev/cu.usbmodem0010512237391", "PT"),
          board("PT", "1051239227", "/dev/cu.usbmodem0010512392271", "FT")
        ]
      })
    )

    snapshot = NRF9151Evidence.load(path)

    assert snapshot.available?
    refute snapshot.simulated?
    assert snapshot.sequence == 100
    assert snapshot.capture_mode == "read_only_posix_serial"
    refute snapshot.flash_or_reset_invoked?
    assert snapshot.ft.jlink_id == "1051223739"
    assert snapshot.ft.peer_role == "PT"
    assert snapshot.pt.jlink_id == "1051239227"
    assert snapshot.pt.peer_role == "FT"

    File.rm(path)
  end

  test "returns an unavailable snapshot for malformed or missing evidence" do
    malformed = temp_evidence_path()
    File.write!(malformed, "{not-json")

    refute NRF9151Evidence.load(malformed).available?
    refute NRF9151Evidence.load(malformed <> ".missing").available?

    File.rm(malformed)
  end

  test "rejects evidence without a matching bidirectional sequence" do
    path = temp_evidence_path()

    File.write!(
      path,
      Jason.encode!(%{
        "generated_at" => "2026-07-10T15:39:20.063217+00:00",
        "ok" => true,
        "simulated" => false,
        "capture" => %{
          "mode" => "read_only_posix_serial",
          "flash_or_reset_invoked" => false
        },
        "peer_exchanges" => %{"ft_to_pt" => [100], "pt_to_ft" => [101]},
        "boards" => [
          board("FT", "1051223739", "/dev/cu.ft", "PT"),
          board("PT", "1051239227", "/dev/cu.pt", "FT")
        ]
      })
    )

    snapshot = NRF9151Evidence.load(path)
    refute snapshot.available?
    assert snapshot.error =~ "matching bidirectional sequence"

    File.rm(path)
  end

  test "rejects a capture that invoked flash or reset" do
    path = temp_evidence_path()

    File.write!(
      path,
      Jason.encode!(%{
        "generated_at" => "2026-07-10T15:39:20.063217+00:00",
        "ok" => true,
        "simulated" => false,
        "capture" => %{
          "mode" => "read_only_posix_serial",
          "flash_or_reset_invoked" => true
        },
        "peer_exchanges" => %{"ft_to_pt" => [100], "pt_to_ft" => [100]},
        "boards" => [
          board("FT", "1051223739", "/dev/cu.ft", "PT"),
          board("PT", "1051239227", "/dev/cu.pt", "FT")
        ]
      })
    )

    snapshot = NRF9151Evidence.load(path)
    refute snapshot.available?
    assert snapshot.error =~ "read-only"

    File.rm(path)
  end

  test "rejects a board that did not receive its peer" do
    path = temp_evidence_path()
    pt = board("PT", "1051239227", "/dev/cu.pt", "FT") |> Map.put("received_peer", false)

    File.write!(
      path,
      Jason.encode!(%{
        "generated_at" => "2026-07-10T15:39:20.063217+00:00",
        "ok" => true,
        "simulated" => false,
        "capture" => %{
          "mode" => "read_only_posix_serial",
          "flash_or_reset_invoked" => false
        },
        "peer_exchanges" => %{"ft_to_pt" => [100], "pt_to_ft" => [100]},
        "boards" => [board("FT", "1051223739", "/dev/cu.ft", "PT"), pt]
      })
    )

    snapshot = NRF9151Evidence.load(path)
    refute snapshot.available?
    assert snapshot.error =~ "PT board did not pass"

    File.rm(path)
  end

  defp board(role, jlink_id, serial_port, peer_role) do
    %{
      "detected_role" => role,
      "expected_role" => role,
      "peer_role" => peer_role,
      "field_role" =>
        if(role == "FT", do: "community gateway/controller", else: "tank sensor edge node"),
      "jlink_id" => jlink_id,
      "serial_port" => serial_port,
      "sent_local" => true,
      "received_peer" => true,
      "role_matches" => true,
      "ok" => true
    }
  end

  defp temp_evidence_path do
    Path.join(System.tmp_dir!(), "proteinloop-nrf9151-#{System.unique_integer([:positive])}.json")
  end
end
