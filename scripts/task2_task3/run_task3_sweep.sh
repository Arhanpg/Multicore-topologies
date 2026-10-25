#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BOOKSIM="$ROOT/src/booksim"
OUT="$ROOT/results/task3"
mkdir -p "$OUT/raw"
printf 'topology\trouting\tvcs\ttraffic\tinjection_rate\tlatency\tthroughput\tstatus\n' > "$OUT/task3_results.tsv"
for topology in mesh torus; do
  for routing in baseline hacr; do
    for traffic in uniform transpose bitcomp hotspot\(0\); do
      for rate in 0.02 0.05 0.10 0.15 0.20 0.30; do
        if [ "$topology" = mesh ] && [ "$routing" = baseline ]; then
          config="$ROOT/configs/task3/mesh_dor_4x4_vc4.conf"
          route_name=dor
        elif [ "$topology" = mesh ]; then
          config="$ROOT/configs/task3/hacr_mesh_4x4_vc4.conf"
          route_name=hacr_min_adapt
        elif [ "$routing" = baseline ]; then
          config="$ROOT/configs/task3/torus_dim_order_4x4_vc4.conf"
          route_name=dim_order
        else
          config="$ROOT/configs/task3/hacr_torus_4x4_vc4.conf"
          route_name=hacr_min_adapt
        fi
        log="$OUT/raw/${topology}_${routing}_${traffic//[()]/}_${rate//./p}.log"
        timeout "${SIM_TIMEOUT_SECONDS:-30}" "$BOOKSIM" "$config" \
          traffic="$traffic" injection_rate="$rate" > "$log" 2>&1
        status=1
        if grep -q "Packet latency average = .*samples" "$log" &&
           grep -q "Accepted packet rate average = .*samples" "$log" &&
           ! grep -Eq "Simulation unstable|Too many sample periods|Assertion|Invalid routing|Average latency for class .* exceeded" "$log"; then
          status=0
        fi
        python3 "$ROOT/results/parse_results.py" "$log" "$topology" "$route_name" 4 \
          "$traffic" "$rate" "$status" >> "$OUT/task3_results.tsv"
      done
    done
  done
done
