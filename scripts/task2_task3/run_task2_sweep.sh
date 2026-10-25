#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BOOKSIM="$ROOT/src/booksim"
OUT="$ROOT/results/task2"
mkdir -p "$OUT/raw"
printf 'topology\tsize\tvcs\ttraffic\tinjection_rate\tlatency\tthroughput\tstatus\n' > "$OUT/task2_results.tsv"
for topology in mesh hybrid; do
  for traffic in uniform transpose bitcomp hotspot\(0\); do
    for rate in 0.02 0.05 0.10 0.15 0.20 0.30; do
      if [ "$topology" = mesh ]; then
        config="$ROOT/configs/task2/mesh_4x4_comparison.conf"
        tag="mesh"
      else
        config="$ROOT/configs/task2/hybrid_anynet_4x4.conf"
        tag="hybrid"
      fi
      log="$OUT/raw/${tag}_${traffic//[()]/}_${rate//./p}.log"
      timeout "${SIM_TIMEOUT_SECONDS:-30}" "$BOOKSIM" "$config" \
        traffic="$traffic" injection_rate="$rate" > "$log" 2>&1
      status=1
      if grep -q "Packet latency average = .*samples" "$log" &&
         grep -q "Accepted packet rate average = .*samples" "$log" &&
         ! grep -Eq "Simulation unstable|Too many sample periods|Assertion|Invalid routing|Average latency for class .* exceeded" "$log"; then
        status=0
      fi
      python3 "$ROOT/results/parse_results.py" "$log" "$topology" 4x4 4 \
        "$traffic" "$rate" "$status" >> "$OUT/task2_results.tsv"
    done
  done
done
