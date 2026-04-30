---
name: documentation-adr-writer
description: Write, update, or review technical documentation and Architecture Decision Records (ADRs); ensure content is clear, complete, and consistent with the codebase and project conventions.
tags: [documentation, adr, readme, runbook, technical-writing, decisions]
version: 1.0.0
---

# Documentation & ADR Writer

## When to use
- Writing a new ADR to record an important architecture or technology decision.
- Reviewing or updating an existing ADR that is stale or incomplete.
- Writing or improving a `README.md`, runbook, or onboarding guide.
- Ensuring a module's inline documentation (docstrings, JSDoc, OpenAPI descriptions) is consistent and complete.
- Generating documentation from code when none exists.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `type` | ✅ | Document type: `adr`, `readme`, `runbook`, `inline-docs`, `api-docs` |
| `content` | ✅ | Code, existing draft, or topic to document |
| `context` | optional | Project name, audience, existing doc conventions, related ADR numbers |
| `decision` | optional (for ADR) | The specific decision to record (title, options considered, rationale) |

## Procedure

### For ADRs

1. **Assign an ADR number** — Use the next sequential number in the `docs/adr/` or `adr/` directory (e.g. `ADR-0042`).
2. **Capture the context** — Describe the forces at play: the problem, constraints, non-goals, and why a decision is needed now.
3. **List the options considered** — At least 2–3 alternatives with a brief description of each.
4. **State the decision** — One clear, unambiguous sentence starting with "We will …".
5. **Document the rationale** — Explain *why* the chosen option is preferred over the alternatives. Reference data, benchmarks, or team constraints.
6. **Record consequences** — List both positive outcomes and trade-offs or risks accepted.
7. **Set status** — `Proposed`, `Accepted`, `Deprecated`, or `Superseded by ADR-XXXX`.
8. **Link related ADRs** — Reference any prior decisions this supersedes or depends on.

### For README / runbook / inline docs

1. **Identify the audience** — Developer, operator, end user, or new contributor.
2. **Structure the document** — Use the appropriate template for the document type (see output format).
3. **Write for the audience's mental model** — Use active voice, concrete examples, and avoid jargon not defined in the same document.
4. **Validate completeness** — Check that "How to run", "How to test", "How to deploy", and "How to troubleshoot" are all answered where relevant.
5. **Add code examples** — Every command in a README must be runnable as written; every code snippet must be syntactically correct.
6. **Check for staleness** — Verify that referenced file paths, commands, and version numbers match the current codebase.

## Output format

### ADR

```markdown
# ADR-<number>: <Title>

**Date**: <YYYY-MM-DD>
**Status**: Proposed | Accepted | Deprecated | Superseded by ADR-<n>
**Deciders**: <team or individuals>

## Context
<Problem, forces, constraints, and why a decision is needed>

## Options considered

### Option 1: <Name>
<Brief description, pros, cons>

### Option 2: <Name>
<Brief description, pros, cons>

### Option 3: <Name> *(chosen)*
<Brief description, pros, cons>

## Decision
We will <chosen approach>.

## Rationale
<Why this option is preferred; data, benchmarks, or constraints that drove the decision>

## Consequences
**Positive:**
- <outcome>

**Negative / trade-offs:**
- <trade-off accepted>

## Related decisions
- ADR-<n>: <title>
```

### README (minimal structure)

```markdown
# <Project Name>

> <One-sentence description>

## Requirements
- <runtime / tool> `>=<version>`

## Installation
```bash
<install command>
```

## Usage
```bash
<run command>
```

## Configuration
| Variable | Default | Description |
|---|---|---|

## Development
```bash
<test / lint / build commands>
```

## Contributing
<Link to CONTRIBUTING.md or brief instructions>

## Licence
<Licence name and link>
```

## Common pitfalls
- ADRs should record *why*, not just *what* — the rationale is the most valuable part and the most commonly omitted.
- Never delete or modify an accepted ADR retroactively; instead, create a new ADR that supersedes it.
- README commands that are not tested against the actual repo will quickly become stale — prefer scripts or `make` targets that are also used in CI.
- Avoid documenting implementation details that change frequently; document the interface and behaviour instead.
- Do not duplicate content that already exists in code comments or OpenAPI specs — link to the authoritative source.
- Use relative links in Markdown (`./docs/adr/`) rather than absolute URLs to keep docs portable.

## Examples

### Example 1 — ADR for choosing a message queue

**Input**: Team is deciding between RabbitMQ and Kafka for an event-driven service.

**Output**:
```markdown
# ADR-0007: Event Streaming — Kafka over RabbitMQ

**Date**: 2025-03-12
**Status**: Accepted
**Deciders**: Platform team

## Context
OrderService needs to publish domain events consumed by 4 downstream services.
Current volume: ~500 events/s with spikes to 5 000 events/s.
We need durable, replayable events for audit and recovery.

## Options considered

### Option 1: RabbitMQ
Mature, simple routing model. Does not natively support log retention or replay.
Requires separate tooling for event sourcing.

### Option 2: Kafka *(chosen)*
Distributed log with configurable retention. Supports replay, consumer groups, and scales horizontally.
Higher operational complexity; requires a team to own the cluster or use a managed service.

## Decision
We will use Apache Kafka (managed via Confluent Cloud) for domain event streaming.

## Rationale
Replay capability is a hard requirement for the audit service.
At 5 000 events/s peak, Kafka's throughput headroom is far larger than RabbitMQ's.
Confluent Cloud removes the operational burden.

## Consequences
**Positive:**
- Events are replayable for up to 7 days.
- Consumer groups allow independent service scaling.

**Negative / trade-offs:**
- Monthly cost of ~$200 for Confluent Cloud basic tier.
- Developers must learn Kafka consumer group semantics.
```

### Example 2 — Updating a stale README command

**Input** (existing README):
```bash
npm run start:dev
```
Script no longer exists; correct command is `npm run dev`.

**Output**: Replace `npm run start:dev` with `npm run dev` and verify the command in `package.json` before committing.
