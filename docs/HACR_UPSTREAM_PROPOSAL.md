# HACR: history-aware minimal adaptive routing for BookSim 2

This document describes an experimental routing extension developed in the
[Multicore-topologies](https://github.com/Arhanpg/Multicore-topologies) project.
It is intended for review as a possible contribution to BookSim 2. It is not a
claim that the algorithm is formally deadlock-free or that it universally
outperforms existing routing methods.

## Motivation

Minimal adaptive routing can choose among legal minimal output directions
using current router state. A decision based only on instantaneous occupancy
may be sensitive to transient variation. History-Aware Congestion Routing
(HACR) experiments with a smoothed port-congestion estimate to combine current
occupancy with recent observed occupancy.

## Scoring rule

For router output port p, let U_p(t) be the router's current used-credit
measurement and H_p(t) be a per-router, per-port exponentially smoothed value:

    H_p(t) = lambda * H_p(t-1) + (1 - lambda) * U_p(t)

The current implementation ranks candidate ports using:

    S_p(t) = alpha * U_p(t) + (1 - alpha) * H_p(t)

The port with the smallest score is preferred. Exact score ties are broken by
port number for deterministic behavior. The default experimental settings are
alpha = 0.60 and lambda = 0.80; both are configuration values in the working
implementation.

## Scope of the current prototype

The working repository contains separate Mesh and Torus routing functions.
They restrict candidates to minimal productive directions and keep a
deterministic escape option, with a Torus-specific escape phase. The prototype
maintains congestion history in process-global state keyed by router ID and
output port and updates it when a routing decision evaluates a candidate.

This is a research prototype, not yet a generally validated upstream feature.
In particular, correctness depends on BookSim's VC assignments, packet phases,
topology-specific routing invariants, and whether the escape paths satisfy the
required channel-dependency constraints. A successful compilation and smoke
test are not a formal deadlock-freedom proof. Upstream reviewers should review
these invariants and the state lifetime/threading assumptions before merge.

## Evaluation record

The originating project includes scripts and TSV result tables for 4x4 Mesh and
Torus tests using Uniform, Transpose, Bit Complement, and hotspot(0) traffic,
at injection rates 0.02, 0.05, 0.10, 0.15, 0.20, and 0.30. Some high-load
hotspot cases are flagged as unstable by the measurement script and must not
be treated as valid steady-state results.

Reproduce measurements using the configurations and scripts in the originating
repository rather than relying solely on pre-generated plots:

- https://github.com/Arhanpg/Multicore-topologies/tree/main/configs/task3
- https://github.com/Arhanpg/Multicore-topologies/tree/main/scripts/task2_task3
- https://github.com/Arhanpg/Multicore-topologies/tree/main/results/task3

## Reproducibility

The current project source is based on BookSim 2 revision
28f43299f1706a3160ffac721ca461d74eb6e618. Apply the HACR code changes to a clean
checkout of that revision, build with the documented toolchain, and run the
smoke tests before interpreting a result. Record compiler/tool versions and
the exact source revision when publishing results.

## Known limitations and work for upstream review

- No formal proof of deadlock freedom is included.
- The congestion history is updated during route evaluation rather than by a
  cycle-synchronous monitor.
- Global history state would need a considered reset/lifetime policy if several
  networks or simulations were instantiated in one process.
- The selection score and tie-break policy need focused tests.
- The reported parameter sweep uses one simulation count per point, and
  instability at high hotspot load limits conclusions near saturation.
- The separate Assignment-2 Hybrid topology is modeled as an AnyNet experiment;
  it is not part of this HACR routing change.

## Citation

BookSim 2 should be cited according to its upstream README:

Nan Jiang, Daniel U. Becker, George Michelogiannakis, James Balfour, Brian
Towles, John Kim, and William J. Dally. “A Detailed and Flexible Cycle-Accurate
Network-on-Chip Simulator.” Proceedings of the 2013 IEEE International
Symposium on Performance Analysis of Systems and Software (ISPASS), 2013.
