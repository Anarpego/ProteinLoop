"""Configure the private Gemma endpoint in a ProteinLoop environment file."""

from __future__ import annotations

import argparse
from pathlib import Path


DEFAULT_MODEL = "google/gemma-4-E2B-it"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("environment_file", type=Path)
    parser.add_argument("endpoint")
    args = parser.parse_args()

    update_environment(args.environment_file, args.endpoint)
    return 0


def update_environment(path: Path, endpoint: str) -> None:
    updates = {
        "GEMMA_ENDPOINT": endpoint,
        "GEMMA_MODEL": DEFAULT_MODEL,
        "GEMMA_RECEIVE_TIMEOUT_MS": "240000",
        "GEMMA_MAX_TOKENS": "512",
    }
    lines = path.read_text(encoding="utf-8").splitlines()
    seen: set[str] = set()
    result: list[str] = []

    for line in lines:
        key = line.split("=", 1)[0]
        if key not in updates:
            result.append(line)
            continue
        if key in seen:
            raise ValueError(f"duplicate environment key: {key}")
        result.append(f"{key}={updates[key]}")
        seen.add(key)

    for key, value in updates.items():
        if key not in seen:
            result.append(f"{key}={value}")

    path.write_text("\n".join(result) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
