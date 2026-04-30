---
name: architecture-review
description: Review a system or service architecture end-to-end for correctness, scalability, security posture, and operational readiness; produce prioritised findings with concrete recommendations.
tags: [architecture, design, scalability, system-design, trade-offs]
version: 1.0.0
---

# Architecture Review

## When to use
- Before starting implementation of a new service, platform component, or significant feature.
- Reviewing an architecture design document (ADD), RFC, or system diagram.
- Evaluating an existing system for refactoring, scaling, or migration planning.
- Post-incident to check whether architectural gaps contributed to the failure.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `design` | ✅ | Architecture document, diagram description, RFC, or system overview |
| `context` | optional | Business requirements, SLOs, team constraints, existing tech stack |
| `focus` | optional | Specific concern to prioritise: `scalability`, `security`, `cost`, `resilience`, `data-flow` |

## Procedure

1. **Understand the goal** — Summarise the system's purpose, primary users, and key quality attributes (availability, latency, throughput, consistency).
2. **Map components and boundaries** — Enumerate services, datastores, queues, external dependencies, and the boundaries between them (sync vs. async, public vs. internal).
3. **Trace data flows** — Follow at least the critical read and write paths end-to-end; identify where data is transformed, stored, or leaves the system.
4. **Review scalability and performance** — Check for stateless/stateful design, horizontal vs. vertical scale assumptions, potential bottlenecks (single DB writer, in-process caches, synchronous fan-outs), and missing pagination or rate limiting.
5. **Review resilience and failure modes** — Check for single points of failure, missing retries/timeouts/circuit breakers, cascading failure risks, and lack of bulkheads or fallback paths.
6. **Review security posture** — Verify authentication/authorisation at each boundary, data encryption in transit and at rest, network segmentation, secrets management, and blast radius of a compromised component.
7. **Review operational readiness** — Confirm observability (logs, metrics, traces, alerts), deployment strategy (blue/green, canary, feature flags), rollback plan, and runbook existence.
8. **Review data model and consistency** — Check data ownership per service, eventual vs. strong consistency trade-offs, migration strategy, and backup/restore plan.
9. **Identify trade-offs** — For each significant design decision, note the alternative considered and why the chosen approach is preferred (or flag if the rationale is missing).
10. **Assign severity** to each finding: `critical` (blocks launch), `high` (must be resolved before GA), `medium` (should be addressed), `low` (nice-to-have improvement).
11. **Produce the report** in the output format below.

## Output format

```
## Summary
<3–5 sentence overview: what is being built, primary quality attributes, overall assessment>

## Component map
<Bullet list of major components and their responsibilities>

## Findings

### Critical
- **[Component/Section]** <Finding>. **Recommendation**: <concrete action>.

### High
- **[Component/Section]** <Finding>. **Recommendation**: <concrete action>.

### Medium
- **[Component/Section]** <Finding>. **Recommendation**: <concrete action>.

### Low / Informational
- **[Component/Section]** <Observation>. **Recommendation**: <suggestion>.

## Trade-off log
| Decision | Chosen approach | Alternative | Rationale / Missing rationale |
|---|---|---|---|

## Open questions
- <Question that must be answered before proceeding>
```

## Common pitfalls
- Do not review implementation details (code style, variable names) — stay at the component and interface level.
- Avoid proposing wholesale rewrites; prefer incremental, concrete improvements.
- If the design document is incomplete, list the missing information as open questions rather than making assumptions.
- Do not conflate availability (uptime) with durability (data safety); treat them as separate concerns.
- Check consistency requirements explicitly — "we use a DB" is not enough; verify read-after-write and cross-service consistency guarantees.

## Examples

### Example 1 — Missing resilience at a service boundary

**Input** (architecture excerpt):
```
OrderService calls PaymentService synchronously via HTTP.
If PaymentService is slow, OrderService waits indefinitely.
```

**Output**:
```
### High
- **OrderService → PaymentService** No timeout or circuit breaker on the synchronous HTTP call.
  If PaymentService degrades, OrderService threads will exhaust and the entire order flow will stall.
  **Recommendation**: Add a 2–5 s timeout and a circuit breaker (e.g. Resilience4j, Polly).
  Consider making the payment step asynchronous via a queue if strict synchrony is not required.
```

### Example 2 — Single point of failure in data layer

**Input**:
```
All services write to a single PostgreSQL primary. No read replicas. No failover configured.
```

**Output**:
```
### Critical
- **Data layer** Single PostgreSQL primary with no read replicas and no automated failover.
  A primary failure causes complete write outage with no automatic recovery.
  **Recommendation**: Configure streaming replication with at least one read replica and enable
  automatic failover (e.g. Patroni, AWS RDS Multi-AZ). Route read-heavy queries to the replica.
```
