---
name: incident-response
description: Triage, contain, investigate, and resolve a production incident; produce a timeline, action log, and post-mortem draft following the ITSM/SRE incident lifecycle.
tags: [incident, sre, operations, postmortem, oncall]
version: 1.0.0
---

# Incident Response

## When to use
- A production alert has fired and the on-call engineer needs a structured process.
- A customer-reported outage or data issue needs investigation.
- Writing a post-mortem after an incident is resolved.
- Reviewing an existing incident log for completeness.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `alert` or `symptom` | ✅ | Alert message, error rate, or symptom description |
| `logs` | optional | Relevant log excerpts, metric snapshots, or trace IDs |
| `runbooks` | optional | Existing runbook links or content |
| `services` | optional | Affected service(s) and their dependency map |

## Procedure

### Phase 1: Triage (< 5 minutes)
1. **Acknowledge the alert** — Record start time and who is handling it.
2. **Assess severity** — Classify:
   - *SEV-1*: full outage or data loss affecting all users.
   - *SEV-2*: major feature broken or significant subset of users affected.
   - *SEV-3*: degraded performance or minor feature broken.
3. **Notify stakeholders** — Page the on-call lead for SEV-1/2; post a brief update in the incident channel.

### Phase 2: Contain (as fast as possible)
4. **Stop the bleeding** — Apply the fastest available mitigation even if it is temporary:
   - Roll back the last deployment.
   - Disable a feature flag.
   - Redirect traffic to a healthy region/instance.
   - Rate-limit or block a bad actor.
5. **Confirm mitigation** — Verify metrics/error rates are recovering before declaring containment.

### Phase 3: Investigate
6. **Identify the trigger** — Correlate the incident start time with: recent deployments, config changes, traffic spikes, dependency outages, or cron jobs.
7. **Trace root cause** — Use logs, traces, and metrics to pinpoint the failing component and the specific condition that caused it.
8. **Document findings** — Log every hypothesis tested and its result in the incident channel.

### Phase 4: Resolve
9. **Apply permanent fix** — Deploy the fix through the normal pipeline (or emergency bypass for SEV-1).
10. **Verify resolution** — Confirm all key metrics have returned to normal; run smoke tests.
11. **Declare incident resolved** — Record end time; notify stakeholders.

### Phase 5: Post-mortem
12. **Draft post-mortem** within 48 hours using the output format below.

## Output format

### Incident status update (during incident)
```
**[HH:MM UTC]** Incident update
- Severity: SEV-<n>
- Status: <Investigating / Mitigated / Resolved>
- Affected: <services/users>
- Current action: <what is being done right now>
```

### Post-mortem draft
```
## Incident Post-Mortem: <Title>

**Date**: YYYY-MM-DD
**Severity**: SEV-<n>
**Duration**: <X hours Y minutes>
**Author(s)**: <names>

## Summary
<2–4 sentences: what happened, who was affected, how it was resolved>

## Timeline
| Time (UTC) | Event |
|---|---|
| HH:MM | Alert fired |
| HH:MM | On-call acknowledged |
| HH:MM | Mitigation applied |
| HH:MM | Root cause identified |
| HH:MM | Incident resolved |

## Root cause
<Technical description of the root cause>

## Contributing factors
- <Factor 1>
- <Factor 2>

## Impact
- Users affected: <count or %>
- Duration: <X min>
- Data loss: <yes/no, description>

## Action items
| Action | Owner | Due date |
|---|---|---|
| <Fix root cause> | <team> | YYYY-MM-DD |
| <Add alerting> | <team> | YYYY-MM-DD |
| <Update runbook> | <team> | YYYY-MM-DD |
```

## Common pitfalls
- Do not spend more than 5 minutes on root cause investigation before applying a containment measure — stop the bleeding first.
- Do not assign blame in the post-mortem; focus on systems, processes, and conditions.
- Do not close the incident until metrics have been normal for at least 10 minutes.
- Action items without owners and due dates are never completed — always assign both.

## Examples

### Example 1 — Database connection exhaustion

**Alert**: `db_connection_pool_wait_time > 5s` for 3 minutes.

**Status update**:
```
[14:32 UTC] SEV-2 — DB connection pool exhausted on api-service.
Status: Investigating.
Action: Checking slow query log; preparing to restart api-service pods.
```

**Root cause**: A missing database index caused a full-table scan on every request after a data migration increased the table to 10M rows. Connection pool exhausted as queries took 30s instead of <1ms.

**Action items**:
1. Add index on `orders.user_id` — DBA team — today.
2. Add query timeout of 5s to prevent runaway queries — Backend team — this sprint.
3. Add alert for queries > 1s in production — Observability team — this sprint.

### Example 2 — Deployment rollback

**Trigger**: Error rate spiked from 0.1% to 45% at 09:15 UTC, 3 minutes after a deployment.

**Containment**: `kubectl rollout undo deployment/api-service` — error rate back to 0.1% within 90 seconds.
