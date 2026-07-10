import json
import tempfile
import unittest
from pathlib import Path

from scripts.horde_failover_test import build_evidence, owner_service, render_markdown
from scripts.validate_submission_artifacts import horde_evidence_ok


class HordeFailoverEvidenceTests(unittest.TestCase):
    def test_owner_service_maps_the_two_demo_nodes(self):
        self.assertEqual(owner_service("proteinloop_web@web"), "web")
        self.assertEqual(owner_service("proteinloop_peer@peer"), "peer")

        with self.assertRaises(ValueError):
            owner_service("unexpected@node")

    def test_build_evidence_requires_real_owner_change_and_state_restore(self):
        before = snapshot(
            owner="proteinloop_web@web",
            token="token-a",
            fingerprint="fingerprint-a",
            persist_count=1,
            restore_count=0,
        )
        after = snapshot(
            owner="proteinloop_peer@peer",
            token="token-a",
            fingerprint="fingerprint-a",
            persist_count=1,
            restore_count=1,
        )
        cluster_before = cluster_status(["proteinloop_peer@peer", "proteinloop_web@web"])
        cluster_rejoined = cluster_status(["proteinloop_peer@peer", "proteinloop_web@web"])

        evidence = build_evidence(
            agent_id="probe-1",
            stopped_service="web",
            before=before,
            after=after,
            cluster_before=cluster_before,
            cluster_rejoined=cluster_rejoined,
        )

        self.assertTrue(evidence["ok"])
        self.assertTrue(all(evidence["checks"].values()))
        self.assertTrue(evidence["checks"]["managed_agent_registered_before"])

        changed = dict(after)
        changed["state_fingerprint"] = "different"
        failed = build_evidence(
            agent_id="probe-1",
            stopped_service="web",
            before=before,
            after=changed,
            cluster_before=cluster_before,
            cluster_rejoined=cluster_rejoined,
        )

        self.assertFalse(failed["ok"])
        self.assertFalse(failed["checks"]["state_fingerprint_preserved"])

        unregistered = build_evidence(
            agent_id="probe-1",
            stopped_service="web",
            before=before,
            after=after,
            cluster_before={**cluster_before, "managed_agents": []},
            cluster_rejoined=cluster_rejoined,
        )

        self.assertFalse(unregistered["ok"])
        self.assertFalse(unregistered["checks"]["managed_agent_registered_before"])

    def test_submission_validator_requires_every_real_failover_check(self):
        evidence = build_evidence(
            agent_id="probe-1",
            stopped_service="web",
            before=snapshot("proteinloop_web@web", "token-a", "fingerprint-a", 1, 0),
            after=snapshot("proteinloop_peer@peer", "token-a", "fingerprint-a", 2, 1),
            cluster_before=cluster_status(["proteinloop_peer@peer", "proteinloop_web@web"]),
            cluster_rejoined=cluster_status(["proteinloop_peer@peer", "proteinloop_web@web"]),
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            json_path = Path(temp_dir) / "horde-evidence.json"
            md_path = Path(temp_dir) / "horde-evidence.md"
            json_path.write_text(json.dumps(evidence), encoding="utf-8")
            md_path.write_text(render_markdown(evidence), encoding="utf-8")

            self.assertTrue(horde_evidence_ok(json_path, md_path))

            evidence["checks"]["state_restored_on_survivor"] = False
            json_path.write_text(json.dumps(evidence), encoding="utf-8")

            self.assertFalse(horde_evidence_ok(json_path, md_path))


def snapshot(owner, token, fingerprint, persist_count, restore_count):
    return {
        "agent_id": "probe-1",
        "distribution": "horde",
        "owner_node": owner,
        "state_token": token,
        "state_fingerprint": fingerprint,
        "persistence": {
            "persist_count": persist_count,
            "restore_count": restore_count,
            "last_restored_node": owner if restore_count else None,
        },
    }


def cluster_status(nodes):
    return {
        "distribution": "horde",
        "connected_nodes": nodes,
        "managed_agents": ["probe-1"],
    }


if __name__ == "__main__":
    unittest.main()
