import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.validate_gemma_endpoint import (
    chat_request,
    extract_model_ids,
    join_url,
    model_is_advertised,
    normalize_endpoint,
    parse_chat_action,
    validate_action,
)


class GemmaEndpointValidatorTests(unittest.TestCase):
    def test_normalize_endpoint_accepts_base_or_v1_url(self):
        self.assertEqual(normalize_endpoint(" https://gemma.example.com/ "), "https://gemma.example.com")
        self.assertEqual(normalize_endpoint("https://gemma.example.com/v1"), "https://gemma.example.com")

        with self.assertRaises(ValueError):
            normalize_endpoint("gemma.example.com")

    def test_join_url_handles_slashes(self):
        self.assertEqual(
            join_url("https://gemma.example.com", "/v1/models"),
            "https://gemma.example.com/v1/models",
        )

    def test_extract_model_ids_reads_openai_compatible_payload(self):
        payload = {"data": [{"id": "google/gemma-4-E4B-it"}, {"ignored": True}]}

        self.assertEqual(extract_model_ids(payload), ["google/gemma-4-E4B-it"])

    def test_model_advertised_accepts_exact_or_suffix_match(self):
        model_ids = ["accounts/team/models/google/gemma-4-E4B-it", "other-model"]

        self.assertTrue(model_is_advertised("google/gemma-4-E4B-it", model_ids))
        self.assertTrue(model_is_advertised("accounts/team/models/google/gemma-4-E4B-it", model_ids))
        self.assertFalse(model_is_advertised("google/gemma-4-27B-it", model_ids))

    def test_parse_chat_action_strips_json_code_fence(self):
        payload = {
            "choices": [
                {
                    "message": {
                        "content": '```json\n{"feed_kg":0.1,"aeration_hours":12,"water_exchange_fraction":0.1,"duckweed_harvest_kg":1,"note":"ok"}\n```'
                    }
                }
            ]
        }

        action = parse_chat_action(payload)

        self.assertEqual(action["note"], "ok")
        self.assertTrue(validate_action(action).ok)

    def test_validate_action_rejects_missing_or_non_numeric_fields(self):
        missing = validate_action({"feed_kg": 0.1})
        invalid = validate_action(
            {
                "feed_kg": 0.1,
                "aeration_hours": "many",
                "water_exchange_fraction": 0.1,
                "duckweed_harvest_kg": 1,
            }
        )

        self.assertFalse(missing.ok)
        self.assertIn("missing", missing.detail)
        self.assertFalse(invalid.ok)
        self.assertIn("non-numeric", invalid.detail)

    def test_chat_request_uses_model_and_requires_action_contract(self):
        request = chat_request("google/gemma-4-E4B-it")

        self.assertEqual(request["model"], "google/gemma-4-E4B-it")
        self.assertIn("feed_kg", request["messages"][0]["content"])


if __name__ == "__main__":
    unittest.main()
