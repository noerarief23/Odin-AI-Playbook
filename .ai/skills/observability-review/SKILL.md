---
name: observability-review
description: Review a service or system for observability gaps — structured logging, metrics, distributed tracing, dashboards, and alerting — and produce prioritised recommendations to achieve production readiness.
tags: [observability, logging, metrics, tracing, alerting, monitoring, dashboards]
version: 1.0.0
---

# Observability Review

## When to use
- Before promoting a new service to production.
- After an incident where lack of visibility hampered diagnosis or resolution.
- Auditing an existing service as part of a production-readiness review.
- Evaluating whether SLO/SLI coverage is sufficient for reliability goals.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `code` or `service` | ✅ | Service source code, config files, or service name to review |
| `context` | optional | Architecture overview, existing monitoring tools (Datadog, Prometheus, CloudWatch, etc.) |
| `focus` | optional | Specific pillar to prioritise: `logging`, `metrics`, `tracing`, `alerting`, `dashboards` |

## Procedure

1. **Inventory existing observability** — List what is already in place: logging library, metrics SDK/agent, tracing instrumentation, dashboard links, and alert rules.
2. **Review logging** — Check for:
   - Structured logging (JSON or key-value) vs. unstructured plain text.
   - Consistent log levels (`DEBUG`, `INFO`, `WARN`, `ERROR`).
   - Correlation IDs / trace IDs propagated across service boundaries.
   - Sensitive data (PII, tokens, passwords) absent from logs.
   - Log volume management (sampling, rate limiting for DEBUG in production).
3. **Review metrics** — Check for:
   - RED metrics on every public endpoint: Request rate, Error rate, Duration (latency).
   - USE metrics for infrastructure: Utilisation, Saturation, Errors.
   - Custom business metrics (e.g. orders processed, payments failed).
   - Metric cardinality hygiene (no unbounded label values like user IDs).
4. **Review distributed tracing** — Check for:
   - Trace context propagation (W3C TraceContext or B3) across service calls.
   - Key operations instrumented as spans (DB queries, outbound HTTP, queue publish/consume).
   - Sampling strategy configured (head-based or tail-based).
5. **Review dashboards** — Check for:
   - Service-level dashboard covering RED metrics, error rates, and SLO burn rate.
   - Infrastructure dashboard (CPU, memory, network, disk).
   - Runbook links on each dashboard panel.
6. **Review alerting** — Check for:
   - Alerts on SLO breach or burn rate (not just raw thresholds).
   - Actionable alert descriptions with runbook links.
   - Alert routing to the correct on-call team.
   - Absence of alert fatigue signals (flapping, noisy low-severity alerts).
7. **Assess SLO/SLI coverage** — Confirm that availability and latency SLIs are defined, measured, and have corresponding error-budget alerts.
8. **Assign severity** to each gap: `critical` (blind spot that will delay incident response), `high` (significant gap), `medium` (improvement), `low` (nice-to-have).
9. **Produce the report** in the output format below.

## Output format

```
## Observability inventory
- **Logging**: <library/format in use, or "none">
- **Metrics**: <SDK/agent in use, or "none">
- **Tracing**: <instrumentation in use, or "none">
- **Dashboards**: <tool and link, or "none">
- **Alerting**: <tool and coverage summary, or "none">

## Findings

### Critical
- **[Pillar / Service]** <Gap>. **Recommendation**: <concrete action>.

### High
- **[Pillar / Service]** <Gap>. **Recommendation**: <concrete action>.

### Medium
- **[Pillar / Service]** <Gap>. **Recommendation**: <concrete action>.

### Low / Informational
- **[Pillar / Service]** <Observation>. **Recommendation**: <suggestion>.

## SLO/SLI coverage
| SLI | Target | Currently measured? | Alert exists? |
|---|---|---|---|

## Quick wins
<Bullet list of improvements achievable in < 1 day>
```

## Common pitfalls
- Logging everything at `INFO` is not the same as structured observability; check that logs are queryable and parseable.
- High-cardinality metric labels (e.g. `user_id`, `request_id`) will explode Prometheus/TSDB storage — flag these explicitly.
- Tracing without sampling configured defaults to 100% trace collection, which can overwhelm the backend at scale.
- Alerts that page on absolute thresholds (e.g. "latency > 500 ms") tend to create alert fatigue; prefer SLO burn-rate alerts.
- Do not confuse availability dashboards (uptime) with latency dashboards — both are required.
- PII in logs is a compliance risk (GDPR, HIPAA); always flag it as `critical`.

## Examples

### Example 1 — Unstructured logging with no correlation ID

**Input** (Node.js log):
```javascript
console.log("Processing order " + orderId + " for user " + userId);
```

**Output**:
```
### High
- **Logging / OrderService** Logs are unstructured plain strings; they cannot be reliably queried in a log aggregation tool.
  **Recommendation**: Switch to a structured logger (e.g. pino, winston with JSON transport):
  `logger.info({ orderId, userId }, 'Processing order');`
  Add a `traceId` field pulled from the incoming request context to enable cross-service correlation.
```

### Example 2 — Missing error-rate alert

**Input** (Prometheus alert rules — no alert on HTTP 5xx rate)

**Output**:
```
### Critical
- **Alerting / PaymentService** No alert exists for elevated HTTP 5xx error rate.
  A payment processing outage could go undetected until a customer complaint.
  **Recommendation**: Add a burn-rate alert on the error SLO:
  ```yaml
  alert: PaymentServiceErrorBudgetBurn
  expr: |
    sum(rate(http_requests_total{service="payment",status=~"5.."}[5m]))
    / sum(rate(http_requests_total{service="payment"}[5m])) > 0.01
  for: 2m
  ```
```
