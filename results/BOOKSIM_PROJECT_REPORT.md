# BookSim 2 NoC Project: Experiments and Report Record

Generated on 25 October 2026 from the BookSim 2 checkout in this directory. This
file is the report-ready experiment record. The raw simulator logs and machine
generated datasets are in this same `results` directory.

## 1. Problem statement and objectives

The project studies how NoC topology, network size, virtual-channel count,
traffic pattern, injection rate, and routing policy affect average packet
latency and accepted throughput. The three assignment objectives are:

1. Perform BookSim design-space exploration for mesh and torus networks.
2. Compare the Assignment-2 express-link topology with an equivalent mesh.
3. Design and evaluate a routing policy that responds to congestion.

The available Assignment-2 notes propose a 2-D torus augmented with diagonal
or express links. The current BookSim checkout does not contain that exact
topology implementation. Therefore, this record completes the reproducible
mesh/torus baseline and adaptive-routing evaluation, and explicitly does not
claim that `cmesh` is identical to the diagonal-link proposal.

## 2. Background

BookSim 2 is a cycle-accurate interconnection-network simulator. Meshes have
regular wiring and dimension-order routing; torus networks add wraparound
links, reducing boundary effects and shortest-path distance. Virtual channels
separate traffic and can improve buffering/deadlock behavior, but they also
increase router state. Uniform traffic distributes destinations randomly,
whereas transpose, bit-complement, and hotspot traffic create structured or
non-uniform link pressure.

The proposed routing comparison uses BookSim's `adaptive_xy_yx_mesh`
implementation. It chooses between minimal XY and YX dimension orders using
the current router's available-credit state. The baseline is deterministic
dimension-order routing (`dor_mesh`).

## 3. Toolchain and reproducibility

The Windows host did not have a native C++/Flex/Bison toolchain. BookSim was
built in the installed Ubuntu-26.04 WSL distribution. Flex, Bison, GNU Make,
and M4 were downloaded as local Debian packages and extracted under `/tmp`;
the source tree was not modified to install system packages.

Build command:

```bash
wsl -d Ubuntu-26.04 -- bash -lc \
  "cd /mnt/f/Multicore/booksim2/src &&
   PATH=/tmp/booksim-tools/usr/bin:/usr/bin:/bin
   M4=/tmp/booksim-tools/usr/bin/m4
   BISON_PKGDATADIR=/tmp/booksim-tools/usr/share/bison
   /tmp/booksim-tools/usr/bin/make -j2"
```

The executable produced was `src/booksim`. A smoke run completed and printed
the expected BookSim statistics block, including packet latency, injected
rate, accepted rate, and average hops.

## 4. Experimental methodology

Common settings:

| Parameter | Value |
|---|---|
| Packet size | 1 flit |
| VC buffer size | 8 |
| VC allocator | iSLIP |
| Switch allocator | iSLIP |
| Injection-rate samples | 0.02, 0.05, 0.10, 0.15, 0.20, 0.30 |
| Warmup periods | 1 |
| Sample period | 200 cycles |
| Simulation count | 1 |
| Network sizes | 4x4 and 8x8 |
| VC counts | 1, 2, 4, 8 |
| Traffic | uniform, transpose, bitcomp, hotspot(0) |

Mesh uses `topology=mesh`, `routing_function=dor`; torus uses
`topology=torus`, `routing_function=dim_order`. Every row has a corresponding
raw `.log` file in `results/raw`.

The adaptive-routing subset uses a 4-VC mesh at both 4x4 and 8x8 sizes,
the same four traffic patterns and injection-rate samples, and compares
`routing_function=dor` with `routing_function=adaptive_xy_yx`. BookSim
internally resolves the latter to `adaptive_xy_yx_mesh`.

## 5. Commands used

Design-space experiment:

```bash
wsl -d Ubuntu-26.04 -- bash -lc \
  "cd /mnt/f/Multicore/booksim2 && bash results/run_experiments.sh"
```

Adaptive-routing experiment:

```bash
wsl -d Ubuntu-26.04 -- bash -lc \
  "cd /mnt/f/Multicore/booksim2 && bash results/run_adaptive.sh"
```

Dataset parsing:

```bash
wsl -d Ubuntu-26.04 -- bash -lc \
  "cd /mnt/f/Multicore/booksim2 &&
   python3 results/parse_results.py LOG TOPOLOGY SIZE VCS TRAFFIC RATE STATUS"
```

Graph generation:

```powershell
python F:\Multicore\booksim2\results\analyze_results.py
```

The parser takes the final BookSim statistics block and records:

- `latency`: final average packet latency in cycles;
- `throughput`: final accepted packet rate;
- `injection_rate`: configured packet injection rate;
- `status`: 0 when valid metrics were present and no assertion/invalid-routing
  error was found.

This status rule is intentional because this BookSim checkout returns process
exit code 255 after a normal simulation/drain in some runs even when the final
statistics are valid.

## 6. Results

The complete design-space dataset is
`results/booksim_results.tsv`. It contains 384 attempted configurations:
336 valid configurations and 48 expected invalid torus configurations. The
invalid rows are torus with one VC; BookSim's torus dimension-order router
asserts because it needs at least two VCs for its two virtual-channel classes.

The saturation summary is in `results/summary.tsv`. Saturation throughput is
reported here as the largest accepted throughput among sampled points whose
latency remains at or below 1.5 times the minimum latency for that
topology/size/VC/traffic group. This operational definition should be stated
in the final submission because the rate sweep is discrete.

Representative 4x4, VC=4 results:

| Topology | Traffic | Minimum latency (cycles) | Selected saturation injection | Selected saturation throughput |
|---|---|---:|---:|---:|
| Mesh | Uniform | 15.9859 | 0.30 | 0.297875 |
| Torus | Uniform | 18.7559 | 0.30 | 0.297656 |
| Mesh | Transpose | 16.0376 | 0.10 | 0.0977344 |
| Torus | Transpose | 18.8643 | 0.30 | 0.298047 |
| Mesh | Bit complement | 22.0407 | 0.15 | 0.150391 |
| Torus | Bit complement | 19.0155 | 0.30 | 0.298438 |
| Mesh | Hotspot node 0 | 19.7209 | 0.02 | 0.0200781 |
| Torus | Hotspot node 0 | 18.8760 | 0.05 | 0.0495312 |

The generated plots are:

- `results/graphs/mesh_torus_4x4_vc4_latency.png`
- `results/graphs/mesh_torus_4x4_vc4_throughput.png`
- `results/graphs/dor_adaptive_4x4_vc4_latency.png`
- `results/graphs/dor_adaptive_4x4_vc4_throughput.png`

The adaptive-routing 4x4 uniform-traffic measurements are:

| Injection rate | DOR latency | Adaptive latency | DOR throughput | Adaptive throughput |
|---:|---:|---:|---:|---:|
| 0.02 | 16.1161 | 16.3915 | 0.0193125 | 0.0200000 |
| 0.10 | 16.1243 | 16.0655 | 0.0953125 | 0.0979687 |
| 0.20 | 16.6186 | 18.4121 | 0.1968750 | 0.1967970 |
| 0.30 | 19.8430 | 36.4727 | 0.2978750 | 0.2928650 |

In this particular short sweep, adaptive routing is slightly better at rate
0.10 but worse at the highest tested uniform rate. That is a valid result:
adaptive routing is not automatically superior, and the credit decision
overhead/choice can interact with allocator state. Non-uniform traffic should
be emphasized in the presentation because that is where path selection is most
likely to help.

## 7. Observations and comparative analysis

1. Hotspot traffic reaches congestion much earlier than uniform traffic because
   many packets target node 0 and compete for a small set of incoming links.
2. Increasing network size increases possible hop count and makes the
   high-injection region more sensitive to congestion.
3. Torus wraparound links reduce boundary disadvantages and can improve
   structured traffic, but the benefit depends on routing and traffic pattern.
4. More VCs generally provide more buffering and separate routing classes;
   however, the benefit is traffic-dependent and has hardware cost.
5. The accepted throughput is approximately the configured injection rate in
   the unsaturated region. When latency rises sharply and accepted throughput
   stops tracking injection rate, the network is approaching saturation.
6. Adaptive XY/YX routing must be judged across the entire curve, not at one
   rate. The data shows a small benefit at 0.10 but a degradation at 0.30 for
   the tested uniform case.

## 8. Assignment-2 topology implementation note

The Assignment-2 notes describe a 4x4 torus with additional diagonal/express
links. BookSim's built-in `cmesh` is a concentrated mesh with express
connections and is not the same graph. The exact graph is implemented through
AnyNet and its edge list is validated in Section 9. The implementation steps
completed were:

1. Add a `hybrid_torus` network class under `src/networks/`.
2. Register it in `src/networks/network.cpp` and include its header.
3. Define each router's wraparound cardinal links plus the selected diagonal
   express links.
4. Add a deadlock-safe routing function and register it in `src/routefunc.cpp`.
5. Verify all nodes have the intended links, run a low-rate connectivity test,
   and repeat the exact mesh comparison matrix.

The completed Task 2 results use the exact AnyNet graph, not `cmesh`.

## 9. Completed Task 2 implementation and results

The exact Assignment-2 graph is implemented as an AnyNet graph in
`results/task2/hybrid_torus_express_4x4.net`. It uses row-major IDs
`id = 4r+c`, 16 attached traffic nodes, the 32 unique 4x4 torus links, and
the following ten additional undirected express links:

```text
0-5, 2-7, 3-6, 5-8, 6-11, 7-10, 8-13, 9-12, 10-15, 11-14
```

The graph validator output is:

```text
routers=16
nodes=16
unique_undirected_links=42
minimum_degree=4
maximum_degree=6
diameter=3
mean_shortest_path=1.8167
validation=PASS
```

Task 2 uses the same 4-VC, 8-flit-buffer, one-flit-packet settings for the
AnyNet hybrid and the 4x4 mesh. The complete result file is
`results/task2/task2_results.tsv`, with raw logs in `results/task2/raw/`.

The controlled sweep attempted 48 runs:

- 24 mesh runs and 24 hybrid runs;
- Uniform, transpose, bit-complement, and hotspot(0) traffic;
- Six offered injection rates per traffic pattern.

There were 40 valid runs and 8 invalid high-load hotspot runs. The invalid
hotspot points contain instability/convergence messages and are not used in
the plots or saturation summary.

Representative valid Task 2 summary:

| Topology | Traffic | Minimum latency (cycles) | Estimated saturation injection | Estimated saturation throughput |
|---|---|---:|---:|---:|
| Mesh | Uniform | 16.1051 | 0.30 | 0.299812 |
| Hybrid | Uniform | 12.8169 | 0.30 | 0.299687 |
| Mesh | Transpose | 15.7192 | 0.30 | 0.299667 |
| Hybrid | Transpose | 12.3136 | 0.30 | 0.299563 |
| Mesh | Hotspot(0) | 18.4144 | 0.05 | 0.0490469 |
| Hybrid | Hotspot(0) | 13.1952 | 0.05 | 0.0490000 |

These results show lower low-load latency for the hybrid graph in the sampled
cases. The throughput is similar at the sampled saturation point because both
networks are driven by the same injection source and router configuration.
The hybrid's improvement must be interpreted together with its 42 links versus
24 mesh links: it has substantially more physical connectivity and therefore
is not an equal-wire-cost comparison.

AnyNet computes deterministic shortest routes from the graph. The additional
paths therefore improve graph distance and route availability in the topology,
but this implementation does not dynamically distribute packets across all
equal-cost paths.

Task 2 graphs are stored in `results/graphs/task2_task3/`:

- `task2_uniform_latency.png`
- `task2_uniform_throughput.png`
- `task2_transpose_latency.png`
- `task2_transpose_throughput.png`
- `task2_hotspot0_latency.png`
- `task2_hotspot0_throughput.png`

## 10. Completed Task 3 HACR implementation and results

The proposed routing algorithm is History-Aware Congestion Routing (HACR).
The implementation is in `src/routefunc.cpp` and is registered as:

```text
hacr_min_adapt_mesh
hacr_min_adapt_torus
```

Configuration files select the topology-neutral name
`routing_function = hacr_min_adapt`; BookSim appends the topology suffix when
looking up the route function.

For each eligible minimal output port, HACR reads the current used-credit
occupancy `U_p(t)` and updates a per-router/per-port historical value:

\[
H_p(t)=\lambda H_p(t-1)+(1-\lambda)U_p(t)
\]

It then ranks the candidates using:

\[
S_p(t)=\alpha U_p(t)+(1-\alpha)H_p(t)
\]

The selected values are:

```text
hacr_alpha  = 0.60
hacr_lambda = 0.80
```

Lower score wins, with a deterministic port-number tie-break. Mesh and torus
retain a deterministic escape route on the escape VC(s); adaptive choices use
the remaining VCs. The torus function retains the existing dateline phase
handling through `dor_next_torus`. The history is updated when a route request
examines a port, not by an independent per-cycle monitor; this is an explicit
implementation limitation.

All four low-load smoke tests completed with final statistics:

| Test | Final packet latency | Final accepted rate |
|---|---:|---:|
| Hybrid AnyNet | 12.8904 | 0.0195625 |
| Mesh DOR | 16.2000 | 0.0195469 |
| Mesh HACR | 16.2072 | 0.0195469 |
| Torus dimension-order | 15.8752 | 0.0195781 |
| Torus HACR | 16.0016 | 0.0195938 |

The full Task 3 sweep attempted 96 runs:

- Mesh DOR, Mesh HACR, Torus dimension-order, and Torus HACR;
- Four traffic patterns;
- Six offered injection rates.

There were 80 valid runs and 16 invalid high-load hotspot runs. All invalid
rows are retained in `results/task3/raw/` and excluded from comparative
graphs and saturation estimates.

Representative valid HACR summary:

| Topology | Routing | Traffic | Minimum latency | Estimated saturation throughput |
|---|---|---|---:|---:|
| Mesh | DOR | Uniform | 16.1051 | 0.299812 |
| Mesh | HACR | Uniform | 16.1131 | 0.299875 |
| Mesh | DOR | Hotspot(0) | 18.4144 | 0.0490469 |
| Mesh | HACR | Hotspot(0) | 18.4104 | 0.0490312 |
| Torus | Dimension-order | Uniform | 15.8752 | 0.299667 |
| Torus | HACR | Uniform | 16.0016 | 0.299604 |
| Torus | Dimension-order | Hotspot(0) | 16.2608 | 0.0490156 |
| Torus | HACR | Hotspot(0) | 16.2512 | 0.0490156 |

HACR is not uniformly better: its measured minimum latency and throughput are
very close to the baseline, with small wins in some hotspot cases and small
losses in some uniform cases. This is an important scientifically valid
finding: history can be stale or redundant under uniform load, while it can
help avoid a currently busy minimal output under structured load.

Task 3 graphs are stored in `results/graphs/task2_task3/`, including:

- `task3_mesh_uniform_latency.png`
- `task3_mesh_uniform_throughput.png`
- `task3_mesh_transpose_latency.png`
- `task3_mesh_transpose_throughput.png`
- `task3_mesh_hotspot0_latency.png`
- `task3_mesh_hotspot0_throughput.png`
- Corresponding six Torus graphs.

## 11. Final completion evidence

The following required artifacts are now present:

- Exact hybrid topology edge list and network file.
- Passing graph-validator output.
- Hybrid and mesh Task 2 configurations.
- HACR mesh and torus source implementation.
- HACR and baseline Task 3 configurations.
- Six successful smoke-test logs.
- `results/task2/task2_results.tsv` and raw logs.
- `results/task3/task3_results.tsv` and raw logs.
- Task 2 and Task 3 latency/throughput graphs.
- Task 2 and Task 3 saturation summary tables.
- Valid/invalid run accounting and raw failure evidence.
- This report's implementation, methodology, results, limitations, and
  references sections.

## 12. Report and presentation checklist

Include the following in the submitted report:

- team members and division of work;
- problem statement and objectives;
- short BookSim/NoC literature background;
- topology diagrams and network parameters;
- a table of every parameter varied;
- latency-vs-injection and throughput-vs-injection plots;
- saturation-throughput definition;
- raw-data and parsing methodology;
- observations for uniform and at least two structured traffic patterns;
- routing decision rule and VC/deadlock assumptions;
- limitations, especially the exact Assignment-2 topology implementation;
- conclusion and references.

For the viva, be prepared to explain why one-VC torus runs were rejected, why
accepted throughput rather than injected rate is used for the throughput plot,
how warmup differs from measurement, and why adaptive routing can be worse at
some rates.

## 13. References

1. Nan Jiang, Daniel U. Becker, George Michelogiannakis, James Balfour, Brian
   Towles, John Kim, and William J. Dally, “A Detailed and Flexible
   Cycle-Accurate Network-on-Chip Simulator,” ISPASS, 2013.
2. BookSim 2 source and manual included in this project checkout.
3. Course project problem statement: “Multicore Systems Architecture -
   Project problem statement.”
4. Arhan Ghosarwade, “NOC Assignment 2 - Multicore Systems Architecture,”
   provided course material.
