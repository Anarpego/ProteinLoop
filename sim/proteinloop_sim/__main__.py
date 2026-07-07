"""Command line interface for the ProteinLoop simulator."""

from __future__ import annotations

import argparse
import json

from .api import run_server
from .policies import naive_policy, run_policy, safety_policy
from .rlvr import evaluate_policies
from .trace_summary import summarize_trace_file


def main() -> None:
    parser = argparse.ArgumentParser(prog="proteinloop-sim")
    subparsers = parser.add_subparsers(dest="command")

    demo = subparsers.add_parser("demo", help="compare naive and safety policies")
    demo.add_argument("--days", type=int, default=10)
    demo.add_argument("--spike-day", type=int, default=1)

    serve = subparsers.add_parser("serve", help="run JSON HTTP simulator API")
    serve.add_argument("--host", default="127.0.0.1")
    serve.add_argument("--port", type=int, default=8000)

    traces = subparsers.add_parser("traces", help="summarize harness JSONL traces")
    traces.add_argument("--path", default="app/priv/traces/harness.jsonl")

    subparsers.add_parser("rlvr", help="score baseline and candidate policies")

    args = parser.parse_args()
    command = args.command or "demo"

    if command == "serve":
        run_server(host=args.host, port=args.port)
        return

    if command == "traces":
        summary = summarize_trace_file(args.path)
        print(json.dumps(summary.to_dict(), indent=2, sort_keys=True))
        return

    if command == "rlvr":
        evaluation = evaluate_policies()
        print(json.dumps(evaluation.to_dict(), indent=2, sort_keys=True))
        return

    if command == "demo":
        naive = run_policy(
            naive_policy,
            days=args.days,
            spike_day=args.spike_day,
            validate=False,
        )
        safety = run_policy(
            safety_policy,
            days=args.days,
            spike_day=args.spike_day,
            validate=True,
        )
        payload = {
            "naive": {
                "state": naive.state.to_dict(),
                "reward": naive.verifier.reward(naive.state),
            },
            "safety": {
                "state": safety.state.to_dict(),
                "reward": safety.verifier.reward(safety.state),
            },
        }
        print(json.dumps(payload, indent=2, sort_keys=True))
        return

    parser.error(f"unknown command: {command}")


if __name__ == "__main__":
    main()
