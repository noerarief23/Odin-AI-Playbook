---
title: Architecture Guidelines
---

# Architecture Guidelines

These guidelines describe the preferred architectural patterns for this project. Kiro should follow them when proposing new components, services, or integrations.

## Guiding Principles

1. **Separation of concerns** — keep business logic, I/O, and presentation in distinct layers.
2. **Dependency inversion** — depend on abstractions (interfaces, protocols); inject concrete implementations.
3. **Twelve-Factor App** — configuration via environment variables; stateless processes; explicit dependencies.
4. **Security by default** — least-privilege, defense-in-depth, encrypt data at rest and in transit.

## Layered Structure (recommended)

```
Handler / Controller   ← HTTP, CLI, event triggers
       ↓
   Use Cases           ← Business logic, orchestration
       ↓
  Domain Models        ← Pure value objects, entities, rules
       ↓
  Repositories / Gateways  ← Database, external APIs, file system
```

Each layer depends only on layers below it; inner layers have no knowledge of outer layers.

## AWS Integration Patterns

- Use **IAM roles** (not long-lived access keys) for all AWS service access.
- Prefer **managed services** (RDS, DynamoDB, SQS, SNS, S3) over self-managed alternatives.
- Use **AWS SDK v3** (Node), **boto3** (Python), or **AWS SDK for Go v2** with context propagation.
- Tag all resources with `Project`, `Environment`, and `Owner` tags.

## API Design

- Follow REST conventions: nouns for resources, HTTP verbs for actions.
- Version APIs via URL prefix (`/v1/`) or header (`Accept-Version`).
- Return standard HTTP status codes; include a machine-readable `error` field in error responses.
- Document APIs with OpenAPI 3.x; keep the spec co-located with the code.

## Observability

- Emit structured logs (see Coding Standards).
- Expose `/health` (liveness) and `/ready` (readiness) endpoints.
- Use AWS CloudWatch or OpenTelemetry for metrics and traces.
- Define alerts for error rate, latency p99, and queue depth thresholds.
