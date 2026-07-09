"""Validate production environment values for the public demo Compose profile."""

from __future__ import annotations

import ipaddress
import os
import sys
import urllib.parse
from dataclasses import dataclass


PLACEHOLDER_FRAGMENTS = [
    "replace",
    "changeme",
    "secret",
    "example",
    "placeholder",
]

EXPECTED_SIMULATOR_URL = "http://simulator:8000"


@dataclass(frozen=True)
class Check:
    name: str
    ok: bool
    detail: str = ""


def main() -> int:
    checks = validate_env(os.environ)

    for check in checks:
        mark = "ok" if check.ok else "FAIL"
        suffix = f" - {check.detail}" if check.detail else ""
        print(f"[{mark}] {check.name}{suffix}")

    failed = [check for check in checks if not check.ok]
    if failed:
        print(f"{len(failed)} public environment check(s) failed", file=sys.stderr)
        return 1

    print("public environment OK")
    return 0


def validate_env(env: dict[str, str]) -> list[Check]:
    phx_host = env.get("PHX_HOST", "")
    return [
        validate_phx_host(phx_host),
        validate_secret_key_base(env.get("SECRET_KEY_BASE", "")),
        validate_port(env.get("PUBLIC_PORT", "")),
        validate_simulator_url(env.get("SIMULATOR_URL", "")),
    ]


def validate_phx_host(host: str) -> Check:
    stripped = host.strip()
    if not stripped:
        return Check("PHX_HOST", False, "set PHX_HOST to the public hostname")
    if not is_public_hostname(stripped):
        return Check("PHX_HOST", False, f"expected public hostname, got {host!r}")
    return Check("PHX_HOST", True, stripped)


def is_public_hostname(host: str) -> bool:
    normalized = host.strip().strip("[]").lower()
    if not normalized or normalized == "localhost" or normalized.endswith(".localhost"):
        return False

    try:
        address = ipaddress.ip_address(normalized)
    except ValueError:
        return "." in normalized and " " not in normalized

    return not (
        address.is_loopback
        or address.is_private
        or address.is_link_local
        or address.is_multicast
        or address.is_reserved
        or address.is_unspecified
    )


def validate_secret_key_base(value: str) -> Check:
    stripped = value.strip()
    if not stripped:
        return Check("SECRET_KEY_BASE", False, "set SECRET_KEY_BASE with mix phx.gen.secret or equivalent")
    if len(stripped) < 64:
        return Check("SECRET_KEY_BASE", False, "must be at least 64 characters")
    lowered = stripped.lower()
    if any(fragment in lowered for fragment in PLACEHOLDER_FRAGMENTS):
        return Check("SECRET_KEY_BASE", False, "looks like a placeholder")
    return Check("SECRET_KEY_BASE", True, f"{len(stripped)} characters")


def validate_port(value: str) -> Check:
    stripped = value.strip()
    if not stripped:
        return Check("PUBLIC_PORT", True, "default 80")
    try:
        port = int(stripped)
    except ValueError:
        return Check("PUBLIC_PORT", False, f"expected integer, got {value!r}")
    if port < 1 or port > 65535:
        return Check("PUBLIC_PORT", False, "must be between 1 and 65535")
    return Check("PUBLIC_PORT", True, str(port))


def validate_simulator_url(value: str) -> Check:
    stripped = value.strip() or EXPECTED_SIMULATOR_URL
    if stripped != EXPECTED_SIMULATOR_URL:
        return Check("SIMULATOR_URL", False, f"expected {EXPECTED_SIMULATOR_URL}, got {value!r}")

    parsed = urllib.parse.urlparse(stripped)
    if parsed.scheme != "http" or parsed.netloc != "simulator:8000":
        return Check("SIMULATOR_URL", False, f"invalid simulator URL {value!r}")

    return Check("SIMULATOR_URL", True, stripped)


if __name__ == "__main__":
    raise SystemExit(main())
