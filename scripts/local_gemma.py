"""Install and manage ProteinLoop's local OpenAI-compatible Gemma 4 server."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import shutil
import signal
import subprocess
import sys
import tarfile
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
STATE_DIR = ROOT / ".local-gemma"
DOWNLOAD_DIR = STATE_DIR / "downloads"
RUNTIME_ROOT = STATE_DIR / "runtime"
CACHE_DIR = STATE_DIR / "cache"
PID_FILE = STATE_DIR / "llama-server.pid"
LOG_FILE = STATE_DIR / "llama-server.log"
LOCAL_EVIDENCE_PATH = ROOT / "outputs" / "local-gemma-evidence.json"

LLAMA_CPP_RELEASE = "b9946"
MODEL_REPO = "google/gemma-4-E2B-it-qat-q4_0-gguf"
MODEL_SELECTOR = f"{MODEL_REPO}:Q4_0"
SERVED_MODEL = "google/gemma-4-E2B-it"
DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 8001
DEFAULT_CONTEXT_SIZE = 8192
DEFAULT_WAIT_SECONDS = 1800


@dataclass(frozen=True)
class RuntimeRelease:
    tag: str
    archive_name: str
    url: str
    sha256: str


RUNTIME_RELEASES = {
    ("Darwin", "arm64"): RuntimeRelease(
        tag=LLAMA_CPP_RELEASE,
        archive_name=f"llama-{LLAMA_CPP_RELEASE}-bin-macos-arm64.tar.gz",
        url=(
            "https://github.com/ggml-org/llama.cpp/releases/download/"
            f"{LLAMA_CPP_RELEASE}/llama-{LLAMA_CPP_RELEASE}-bin-macos-arm64.tar.gz"
        ),
        sha256="d51d0ab59f0f44282c532449bb1d0098367e3b9429d20b8d7e7ab270eaa2393f",
    )
}


def runtime_release(system: str | None = None, machine: str | None = None) -> RuntimeRelease:
    system = system or platform.system()
    machine = (machine or platform.machine()).lower()
    if machine == "aarch64":
        machine = "arm64"

    try:
        return RUNTIME_RELEASES[(system, machine)]
    except KeyError as exc:
        raise RuntimeError(
            f"unsupported local Gemma platform: {system}/{machine}; "
            "this slice currently supports Apple Silicon macOS"
        ) from exc


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verify_checksum(path: Path, expected: str) -> None:
    actual = sha256_file(path)
    if actual.lower() != expected.lower():
        raise ValueError(
            f"checksum mismatch for {path.name}: expected {expected}, got {actual}"
        )


def download_file(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    partial = destination.with_name(f"{destination.name}.part")
    request = urllib.request.Request(url, headers={"user-agent": "ProteinLoop-local-gemma/1"})
    try:
        with urllib.request.urlopen(request, timeout=60) as response, partial.open("wb") as output:
            shutil.copyfileobj(response, output, length=1024 * 1024)
        partial.replace(destination)
    finally:
        if partial.exists():
            partial.unlink()


def safe_extract(archive: Path, destination: Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    destination_root = destination.resolve()
    with tarfile.open(archive, "r:gz") as bundle:
        for member in bundle.getmembers():
            target = (destination / member.name).resolve()
            if target != destination_root and destination_root not in target.parents:
                raise ValueError(f"unsafe archive path: {member.name}")
        bundle.extractall(destination)


def find_server(runtime_dir: Path) -> Path | None:
    candidates = sorted(
        path for path in runtime_dir.rglob("llama-server") if path.is_file()
    )
    return candidates[0] if candidates else None


def installed_server(release: RuntimeRelease | None = None) -> Path | None:
    release = release or runtime_release()
    return find_server(RUNTIME_ROOT / release.tag)


def install_runtime(release: RuntimeRelease | None = None) -> Path:
    release = release or runtime_release()
    existing = installed_server(release)
    if existing:
        print(f"llama.cpp {release.tag} already installed: {existing.relative_to(ROOT)}")
        return existing

    archive = DOWNLOAD_DIR / release.archive_name
    if archive.exists():
        try:
            verify_checksum(archive, release.sha256)
        except ValueError:
            archive.unlink()

    if not archive.exists():
        print(f"downloading llama.cpp {release.tag} for Apple Silicon")
        download_file(release.url, archive)
    verify_checksum(archive, release.sha256)

    destination = RUNTIME_ROOT / release.tag
    temporary = RUNTIME_ROOT / f".{release.tag}.installing"
    if temporary.exists():
        shutil.rmtree(temporary)
    safe_extract(archive, temporary)
    server = find_server(temporary)
    if not server:
        shutil.rmtree(temporary)
        raise RuntimeError(f"{release.archive_name} does not contain llama-server")

    if destination.exists():
        shutil.rmtree(destination)
    temporary.replace(destination)
    server = find_server(destination)
    if not server:
        raise RuntimeError("llama-server disappeared after installation")
    server.chmod(server.stat().st_mode | 0o111)
    print(f"installed llama.cpp {release.tag}: {server.relative_to(ROOT)}")
    return server


def build_server_command(
    server: Path,
    *,
    host: str = DEFAULT_HOST,
    port: int = DEFAULT_PORT,
    context_size: int = DEFAULT_CONTEXT_SIZE,
) -> list[str]:
    return [
        str(server),
        "-hf",
        MODEL_SELECTOR,
        "--alias",
        SERVED_MODEL,
        "--host",
        host,
        "--port",
        str(port),
        "--ctx-size",
        str(context_size),
        "--n-gpu-layers",
        "all",
        "--jinja",
        "--reasoning",
        "off",
        "--reasoning-budget",
        "0",
    ]


def build_check_command(
    python: str = sys.executable,
    *,
    host: str = DEFAULT_HOST,
    port: int = DEFAULT_PORT,
) -> list[str]:
    return [
        python,
        str(ROOT / "scripts" / "validate_gemma_endpoint.py"),
        "--endpoint",
        endpoint_url(host, port),
        "--model",
        SERVED_MODEL,
        "--timeout",
        "120",
        "--evidence-file",
        str(LOCAL_EVIDENCE_PATH),
    ]


def endpoint_url(host: str, port: int) -> str:
    return f"http://{host}:{port}"


def server_environment() -> dict[str, str]:
    environment = os.environ.copy()
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    environment["LLAMA_CACHE"] = str(CACHE_DIR)
    environment["HF_HOME"] = str(CACHE_DIR / "huggingface")
    return environment


def read_pid(path: Path = PID_FILE) -> int | None:
    try:
        pid = int(path.read_text(encoding="utf-8").strip())
    except (FileNotFoundError, ValueError):
        return None
    return pid if pid > 1 else None


def pid_is_running(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def model_ids(host: str, port: int, timeout: float = 2.0) -> list[str]:
    request = urllib.request.Request(f"{endpoint_url(host, port)}/v1/models")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
        return []

    data = payload.get("data") if isinstance(payload, dict) else None
    if not isinstance(data, list):
        return []
    return [item["id"] for item in data if isinstance(item, dict) and isinstance(item.get("id"), str)]


def model_is_ready(host: str, port: int) -> bool:
    return SERVED_MODEL in model_ids(host, port)


def tail_log(lines: int = 30) -> str:
    try:
        contents = LOG_FILE.read_text(encoding="utf-8", errors="replace").splitlines()
    except FileNotFoundError:
        return ""
    return "\n".join(contents[-lines:])


def wait_until_ready(
    pid: int,
    host: str,
    port: int,
    wait_seconds: int,
    *,
    process: subprocess.Popen | None = None,
) -> bool:
    started = time.monotonic()
    next_update = started
    while time.monotonic() - started < wait_seconds:
        exit_code = process.poll() if process is not None else None
        if exit_code is not None or (process is None and not pid_is_running(pid)):
            detail = f" with exit code {exit_code}" if exit_code is not None else ""
            print(f"llama-server exited{detail} before becoming ready", file=sys.stderr)
            log_tail = tail_log()
            if log_tail:
                print(log_tail, file=sys.stderr)
            if read_pid() == pid:
                PID_FILE.unlink(missing_ok=True)
            return False
        if model_is_ready(host, port):
            print(f"local Gemma ready: {endpoint_url(host, port)}/v1")
            return True
        now = time.monotonic()
        if now >= next_update:
            elapsed = int(now - started)
            print(
                f"waiting for Gemma 4 model download/load ({elapsed}s); "
                f"log: {LOG_FILE.relative_to(ROOT)}",
                flush=True,
            )
            next_update = now + 15
        time.sleep(2)

    print(
        f"local Gemma is still starting after {wait_seconds}s; "
        f"inspect {LOG_FILE.relative_to(ROOT)}",
        file=sys.stderr,
    )
    return False


def start_server(host: str, port: int, context_size: int, wait_seconds: int) -> int:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    pid = read_pid()
    if pid and pid_is_running(pid):
        print(f"llama-server already running with pid {pid}")
        if model_is_ready(host, port):
            print(f"local Gemma ready: {endpoint_url(host, port)}/v1")
            return 0
        return 0 if wait_until_ready(pid, host, port, wait_seconds) else 1
    if pid:
        PID_FILE.unlink(missing_ok=True)

    server = install_runtime()
    command = build_server_command(
        server,
        host=host,
        port=port,
        context_size=context_size,
    )
    with LOG_FILE.open("a", encoding="utf-8") as log:
        log.write(f"\n=== starting {time.strftime('%Y-%m-%d %H:%M:%S')} ===\n")
        log.flush()
        process = subprocess.Popen(
            command,
            cwd=ROOT,
            env=server_environment(),
            stdin=subprocess.DEVNULL,
            stdout=log,
            stderr=subprocess.STDOUT,
            start_new_session=True,
        )
    PID_FILE.write_text(f"{process.pid}\n", encoding="utf-8")
    print(f"started llama-server with pid {process.pid}")
    return (
        0
        if wait_until_ready(
            process.pid,
            host,
            port,
            wait_seconds,
            process=process,
        )
        else 1
    )


def show_status(host: str, port: int) -> int:
    pid = read_pid()
    if not pid or not pid_is_running(pid):
        print("local Gemma stopped")
        return 1
    ids = model_ids(host, port)
    if SERVED_MODEL in ids:
        print(f"local Gemma healthy: pid={pid} endpoint={endpoint_url(host, port)}/v1")
        print(f"model={SERVED_MODEL}")
        return 0
    print(f"local Gemma starting: pid={pid} log={LOG_FILE.relative_to(ROOT)}")
    return 1


def stop_server(wait_seconds: int = 15) -> int:
    pid = read_pid()
    if not pid:
        print("local Gemma already stopped")
        return 0
    if not pid_is_running(pid):
        PID_FILE.unlink(missing_ok=True)
        print("removed stale local Gemma pid file")
        return 0

    os.kill(pid, signal.SIGTERM)
    deadline = time.monotonic() + wait_seconds
    while time.monotonic() < deadline and pid_is_running(pid):
        time.sleep(0.25)
    if pid_is_running(pid):
        os.kill(pid, signal.SIGKILL)
    PID_FILE.unlink(missing_ok=True)
    print(f"stopped local Gemma pid {pid}")
    return 0


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default=DEFAULT_HOST)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("install", help="Install the pinned llama.cpp runtime.")

    start = subparsers.add_parser("start", help="Start and wait for local Gemma.")
    start.add_argument("--context-size", type=int, default=DEFAULT_CONTEXT_SIZE)
    start.add_argument("--wait-seconds", type=int, default=DEFAULT_WAIT_SECONDS)

    subparsers.add_parser("status", help="Check the managed server and model endpoint.")
    subparsers.add_parser("stop", help="Stop the managed local server.")
    subparsers.add_parser("check", help="Validate live inference and write local evidence.")

    command = subparsers.add_parser("print-command", help="Print the resolved server command.")
    command.add_argument("--context-size", type=int, default=DEFAULT_CONTEXT_SIZE)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    if args.command == "install":
        install_runtime()
        return 0
    if args.command == "start":
        return start_server(args.host, args.port, args.context_size, args.wait_seconds)
    if args.command == "status":
        return show_status(args.host, args.port)
    if args.command == "stop":
        return stop_server()
    if args.command == "check":
        return subprocess.run(build_check_command(host=args.host, port=args.port), cwd=ROOT).returncode
    if args.command == "print-command":
        server = installed_server() or RUNTIME_ROOT / LLAMA_CPP_RELEASE / "llama-server"
        print(" ".join(build_server_command(server, host=args.host, port=args.port, context_size=args.context_size)))
        return 0
    raise AssertionError(f"unhandled command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
