"""Validate the OpenAI-compatible Gemma endpoint used by ProteinLoop."""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_EVIDENCE_PATH = ROOT / "submission" / "gemma-evidence.json"
DEFAULT_MODEL = "google/gemma-4-E2B-it"
TIMEOUT_SECONDS = 20.0
RETRY_COUNT = 3

ACTION_KEYS = [
    "feed_kg",
    "aeration_hours",
    "water_exchange_fraction",
    "duckweed_harvest_kg",
]

PROMPT_STATE = {
    "day": 3,
    "ammonia_mg_l": 2.4,
    "dissolved_oxygen_mg_l": 4.8,
    "fish_biomass_kg": 18.0,
    "prawn_biomass_kg": 5.4,
    "duckweed_kg": 12.0,
    "plant_biomass_kg": 21.0,
    "chicken_feed_buffer_kg": 4.0,
    "collapsed": False,
}


@dataclass(frozen=True)
class Check:
    name: str
    ok: bool
    detail: str = ""


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    endpoint = args.endpoint or os.environ.get("GEMMA_ENDPOINT")
    model = args.model or os.environ.get("GEMMA_MODEL") or DEFAULT_MODEL
    api_key = args.api_key if args.api_key is not None else os.environ.get("GEMMA_API_KEY")

    if not endpoint:
        print("GEMMA_ENDPOINT or --endpoint is required", file=sys.stderr)
        return 2

    try:
        evidence, checks = validate_endpoint(
            normalize_endpoint(endpoint),
            model,
            api_key,
            timeout=args.timeout,
        )
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2
    except Exception as exc:  # noqa: BLE001 - report endpoint failures plainly.
        checks = [Check("unexpected error", False, repr(exc))]
        evidence = None

    for check in checks:
        mark = "ok" if check.ok else "FAIL"
        suffix = f" - {check.detail}" if check.detail else ""
        print(f"[{mark}] {check.name}{suffix}")

    failed = [check for check in checks if not check.ok]
    if failed:
        print(f"{len(failed)} Gemma endpoint check(s) failed", file=sys.stderr)
        return 1

    if evidence is not None:
        write_evidence(Path(args.evidence_file), evidence)
        print(f"wrote evidence: {Path(args.evidence_file).relative_to(ROOT)}")

    print("Gemma endpoint OK")
    return 0


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--endpoint", help="OpenAI-compatible base URL. Defaults to GEMMA_ENDPOINT.")
    parser.add_argument("--model", help=f"Model id. Defaults to GEMMA_MODEL or {DEFAULT_MODEL}.")
    parser.add_argument("--api-key", help="Optional bearer token. Defaults to GEMMA_API_KEY.")
    parser.add_argument("--timeout", type=float, default=TIMEOUT_SECONDS)
    parser.add_argument("--evidence-file", default=str(DEFAULT_EVIDENCE_PATH))
    return parser.parse_args(argv)


def validate_endpoint(endpoint: str, model: str, api_key: str | None, timeout: float) -> tuple[dict[str, Any], list[Check]]:
    checks: list[Check] = []
    models_payload = get_json(join_url(endpoint, "/v1/models"), api_key, timeout)
    model_ids = extract_model_ids(models_payload)
    checks.append(Check("models endpoint", bool(model_ids), f"{len(model_ids)} model(s)"))
    checks.append(
        Check(
            "requested model advertised",
            model_is_advertised(model, model_ids),
            model if model_ids else "no models returned",
        )
    )

    chat_payload = post_json(join_url(endpoint, "/v1/chat/completions"), chat_request(model), api_key, timeout)
    action = parse_chat_action(chat_payload)
    action_check = validate_action(action)
    checks.append(action_check)

    evidence = {
        "checked_at": datetime.now(timezone.utc).isoformat(),
        "endpoint": endpoint,
        "model": model,
        "models": model_ids,
        "action": action,
        "checks": [asdict(check) for check in checks],
    }
    return evidence, checks


def chat_request(model: str) -> dict[str, Any]:
    return {
        "model": model,
        "temperature": 0.1,
        "chat_template_kwargs": {"enable_thinking": False},
        "response_format": {"type": "json_object"},
        "messages": [
            {
                "role": "system",
                "content": (
                    "You operate ProteinLoop. Return exactly one JSON object and no prose. "
                    "Required numeric keys: feed_kg, aeration_hours, "
                    "water_exchange_fraction, duckweed_harvest_kg. Include note. "
                    "feed_kg must be between 0 and 0.25; use at most 0.08 when "
                    "ammonia_mg_l is 1.5 or higher, and 0 when collapsed. "
                    "aeration_hours must be between 0 and 24. "
                    "water_exchange_fraction must be between 0 and 0.30. "
                    "duckweed_harvest_kg must be non-negative and leave at least "
                    "0.50 kg of duckweed. These bounds guide the model only; the "
                    "deterministic simulator verifier remains authoritative."
                ),
            },
            {
                "role": "user",
                "content": f"Current simulator state JSON: {json.dumps(PROMPT_STATE, sort_keys=True)}",
            },
        ],
    }


def extract_model_ids(payload: dict[str, Any]) -> list[str]:
    data = payload.get("data")
    if not isinstance(data, list):
        return []
    return [item["id"] for item in data if isinstance(item, dict) and isinstance(item.get("id"), str)]


def model_is_advertised(model: str, model_ids: list[str]) -> bool:
    normalized = model.strip().lower().strip("/")
    if not normalized:
        return False

    for model_id in model_ids:
        candidate = model_id.strip().lower().strip("/")
        if candidate == normalized or candidate.endswith(f"/{normalized}"):
            return True

    return False


def parse_chat_action(payload: dict[str, Any]) -> dict[str, Any]:
    try:
        content = payload["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError) as exc:
        raise ValueError(f"chat response missing choices[0].message.content: {exc}") from exc

    if not isinstance(content, str):
        raise ValueError("chat response content must be a string")

    stripped = strip_code_fence(content)
    try:
        action = json.loads(stripped)
    except json.JSONDecodeError as exc:
        raise ValueError(f"model response is not JSON: {exc}") from exc

    if not isinstance(action, dict):
        raise ValueError("model response JSON must be an object")

    return action


def validate_action(action: dict[str, Any]) -> Check:
    missing = [key for key in ACTION_KEYS if key not in action]
    if missing:
        return Check("chat action contract", False, f"missing: {', '.join(missing)}")

    invalid = [key for key in ACTION_KEYS if coerce_float(action[key]) is None]
    if invalid:
        return Check("chat action contract", False, f"non-numeric: {', '.join(invalid)}")

    return Check("chat action contract", True, "valid ProteinLoop action")


def coerce_float(value: Any) -> float | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value)
        except ValueError:
            return None
    return None


def normalize_endpoint(url: str) -> str:
    normalized = url.strip().rstrip("/")
    parsed = urllib.parse.urlparse(normalized)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ValueError(f"expected http(s) GEMMA_ENDPOINT, got: {url}")
    if parsed.path.endswith("/v1"):
        normalized = normalized[: -len("/v1")]
    return normalized.rstrip("/")


def join_url(base_url: str, path: str) -> str:
    return f"{base_url}/{path.lstrip('/')}"


def strip_code_fence(content: str) -> str:
    return (
        content.strip()
        .removeprefix("```json")
        .removeprefix("```")
        .removesuffix("```")
        .strip()
    )


def get_json(url: str, api_key: str | None, timeout: float) -> dict[str, Any]:
    return json.loads(open_url(urllib.request.Request(url, headers=headers(api_key), method="GET"), timeout))


def post_json(url: str, payload: dict[str, Any], api_key: str | None, timeout: float) -> dict[str, Any]:
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"content-type": "application/json", **headers(api_key)},
        method="POST",
    )
    return json.loads(open_url(request, timeout))


def headers(api_key: str | None) -> dict[str, str]:
    return {"authorization": f"Bearer {api_key}"} if api_key else {}


def open_url(request: urllib.request.Request, timeout: float) -> str:
    last_error: Exception | None = None
    for _attempt in range(RETRY_COUNT):
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                status = getattr(response, "status", 200)
                body = response.read().decode("utf-8")
                if 200 <= status <= 299:
                    return body
                raise RuntimeError(f"HTTP {status}: {body[:500]}")
        except (urllib.error.URLError, TimeoutError, RuntimeError) as exc:
            last_error = exc
            time.sleep(0.5)
    raise RuntimeError(f"request failed: {request.full_url}: {last_error}")


def write_evidence(path: Path, evidence: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
