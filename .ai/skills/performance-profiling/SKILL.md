---
name: performance-profiling
description: Profile and optimise a service or code path for CPU, memory, or latency regressions; identify bottlenecks with concrete, measurable improvement steps.
tags: [performance, profiling, optimisation, latency, cpu, memory]
version: 1.0.0
---

# Performance Profiling

## When to use
- Investigating a latency spike, high CPU usage, or memory growth reported in production or staging.
- Validating that a new feature does not introduce performance regressions.
- Running a proactive performance review before a high-traffic event or capacity change.
- After receiving an alert that SLO/SLI targets are at risk.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `code` or `service` | ✅ | Code path, module, or service name to profile |
| `symptom` | ✅ | Observed issue: `high-cpu`, `high-memory`, `high-latency`, `throughput-drop`, `memory-leak` |
| `metrics` | optional | Current measurements (p50/p95/p99 latency, CPU %, heap size, request rate) |
| `profiling_data` | optional | Flame graphs, heap dumps, trace spans, or profiler output |
| `context` | optional | Recent code changes, dependency updates, or traffic pattern changes |

## Procedure

1. **Reproduce the symptom** — Confirm the issue is reproducible with a minimal test case or by replicating the production load pattern in a lower environment. Record baseline metrics.
2. **Choose profiling strategy** — Select the appropriate tool based on the symptom:
   - CPU: language profiler (e.g. `py-spy`, `async-profiler`, `pprof`, `dotnet-trace`)
   - Memory / leaks: heap profiler or allocation tracker (e.g. `memray`, `heaptrack`, `dotnet-gcdump`, `jmap`)
   - Latency: distributed trace (OpenTelemetry) + slow-query log + async profiler wall-clock mode
   - I/O: `strace`, `perf`, or APM tool (Datadog, Dynatrace, New Relic)
3. **Collect profiling data** — Run the profiler under representative load for at least 60 seconds. Capture flame graphs for CPU; heap snapshots (before/after GC) for memory.
4. **Identify the hotspot** — From the flame graph or top-N allocation report, find the function(s) consuming the largest share of CPU or memory. Note the call chain.
5. **Root-cause analysis** — Determine *why* the hotspot is expensive:
   - Algorithmic complexity (O(n²) loops, missing index, repeated full scans)
   - Excessive allocations / GC pressure (large temporary objects, boxing, string concatenation in loops)
   - Blocking I/O on the hot path (synchronous DB calls, missing async, N+1 queries)
   - Lock contention (shared mutable state, wide critical sections)
   - Missing caching (repeated expensive computation or DB reads)
6. **Propose optimisations** — For each root cause, suggest a concrete, testable fix. Order by expected impact vs. implementation effort.
7. **Estimate impact** — Where possible, provide a rough estimate of expected improvement (e.g. "removing the N+1 query should reduce p99 latency from 800 ms to ~150 ms based on query plan").
8. **Validate the fix** — After applying the optimisation, re-run the same profiling workload and compare before/after metrics. Confirm the hotspot is gone or reduced.
9. **Check for regressions** — Ensure the optimisation does not break correctness (run tests) or shift the bottleneck elsewhere.
10. **Document findings** — Record baseline, optimisation applied, and post-fix metrics in the PR or incident report.

## Output format

```
## Profiling summary
- **Symptom**: <observed issue>
- **Baseline**: <key metrics before optimisation>
- **Profiling tool used**: <tool + version>

## Hotspots identified

| Rank | Function / Query | Type | % CPU / Alloc / Time | Call chain |
|---|---|---|---|---|
| 1 | `<function>` | cpu / alloc / io | <value> | `<caller → callee>` |

## Root causes

1. **<Hotspot name>** — <Explanation of why it is expensive>.

## Recommended optimisations

### 1. <Optimisation title>
- **Root cause addressed**: <hotspot>
- **Change**: <concrete description or code snippet>
- **Expected impact**: <estimated improvement>
- **Effort**: low / medium / high

## After-fix metrics
- <key metrics after optimisation, or "pending validation">

## Risks and regressions to watch
- <Any correctness or secondary-performance risk from the proposed changes>
```

## Common pitfalls
- Do not optimise without measuring first — always establish a reproducible baseline.
- Profiling in production under real load gives the most accurate data, but use a sampling profiler with low overhead (< 2% CPU).
- Avoid micro-optimising non-hotspot code; focus on the top 1–3 contributors to the observed symptom.
- Memory leaks require multiple heap snapshots over time, not a single snapshot.
- Check GC logs before blaming application code — GC pressure is often the symptom of allocation patterns, not the root cause.
- Ensure test load is representative; a benchmark that only tests one endpoint will miss cross-service bottlenecks.

## Examples

### Example 1 — N+1 query causing high latency

**Input**:
- Symptom: `high-latency` on `/api/orders` endpoint (p99 = 2.1 s)
- Trace: 150 individual `SELECT * FROM products WHERE id = ?` per request

**Output**:
```
## Hotspots identified
| Rank | Function / Query | Type | % CPU / Alloc / Time | Call chain |
|---|---|---|---|---|
| 1 | `SELECT * FROM products WHERE id = ?` | io | 87% of request time | `OrderController → OrderService → ProductRepository` |

## Root causes
1. **N+1 query in OrderService** — For each order line item, a separate product query is issued.
   A 150-item order produces 150 sequential DB round-trips.

## Recommended optimisations
### 1. Batch product lookup
- **Change**: Replace per-item query with `SELECT * FROM products WHERE id = ANY($1)` using the full list of IDs collected upfront.
- **Expected impact**: 150 round-trips → 1; estimated p99 drop from 2.1 s to ~80 ms.
- **Effort**: low
```

### Example 2 — Memory leak from uncleared event listeners

**Input**:
- Symptom: `memory-leak`; heap grows 50 MB/hour, never released
- Heap snapshot diff: 40 000 `EventEmitter` instances retained

**Output**:
```
## Hotspots identified
| Rank | Function / Query | Type | % CPU / Alloc / Time | Call chain |
|---|---|---|---|---|
| 1 | `EventEmitter` instances | alloc | 95% of heap growth | `WebSocketServer → ConnectionHandler` |

## Root causes
1. **Missing removeListener in ConnectionHandler** — Each WebSocket connection registers a listener on a shared emitter but never removes it on disconnect, causing the closure and all its references to be retained.

## Recommended optimisations
### 1. Remove listener on connection close
- **Change**: Add `emitter.removeListener('event', handler)` (or use `emitter.once`) inside the `close` event handler of each connection.
- **Expected impact**: Heap growth eliminated.
- **Effort**: low
```
