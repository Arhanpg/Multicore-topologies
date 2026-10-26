#!/usr/bin/env python3
import re
import sys


def last_float(pattern: str, text: str):
    values = re.findall(pattern, text, re.MULTILINE)
    return values[-1] if values else "NA"


def main() -> int:
    if len(sys.argv) != 8:
        raise SystemExit("usage: parse_results.py LOG TOPOLOGY SIZE VCS TRAFFIC RATE STATUS")
    log, topology, size, vcs, traffic, rate, status = sys.argv[1:]
    text = open(log, encoding="utf-8", errors="replace").read()
    latency = last_float(r"Packet latency average = ([0-9.eE+-]+)", text)
    throughput = last_float(r"Accepted packet rate average\s*=\s*([0-9.eE+-]+)", text)
    print(
        "\t".join(
            (topology, size, vcs, traffic, rate, latency, throughput, status)
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
