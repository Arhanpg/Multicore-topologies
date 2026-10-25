#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BOOKSIM="$ROOT/src/booksim"
RAW="$ROOT/results/raw"
DATA="$ROOT/results/adaptive_results.tsv"

mkdir -p "$RAW"
printf 'routing\tsize\tvcs\ttraffic\tinjection_rate\tlatency\tthroughput\tstatus\n' > "$DATA"

for routing in dor adaptive_xy_yx; do
  for size in 4 8; do
    for traffic in uniform transpose bitcomp hotspot\(0\); do
      for rate in 0.02 0.05 0.10 0.15 0.20 0.30; do
        tag="adaptive_${routing}_${size}x${size}_vc4_${traffic//[()]/}_${rate//./p}"
        log="$RAW/${tag}.log"
        "$BOOKSIM" "$ROOT/runfiles/meshconfig" \
          topology=mesh k="$size" n=2 routing_function="$routing" num_vcs=4 \
          traffic="$traffic" injection_rate="$rate" packet_size=1 \
          sample_period=200 warmup_periods=1 sim_count=1 > "$log" 2>&1
        status=$?
        python3 "$ROOT/results/parse_results.py" "$log" "$routing" \
          "${size}x${size}" 4 "$traffic" "$rate" "$status" >> "$DATA"
      done
    done
  done
done
