---
name: repo-onboarding-discovery
description: Rapidly map an unfamiliar repository — entry points, module boundaries, key configuration, and safe change paths — to enable a new contributor to become productive within one session.
tags: [onboarding, discovery, codebase, navigation, documentation, new-contributor]
version: 1.0.0
---

# Repo Onboarding & Discovery

## When to use
- A developer joins a project and needs to understand the codebase quickly.
- You are assigned to a legacy or unfamiliar repository and need a rapid orientation.
- Generating or updating an onboarding guide or "Getting Started" document.
- Preparing a codebase map before a large refactoring or architecture change.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `repo` | ✅ | Repository root path or URL |
| `context` | optional | Role of the new contributor (backend, frontend, DevOps, data) |
| `focus` | optional | Specific area to map: `architecture`, `data-flow`, `testing`, `deployment`, `config` |

## Procedure

1. **Read top-level files** — Start with `README.md`, `CONTRIBUTING.md`, `AGENTS.md`, `CODEOWNERS`, `LICENSE`, and any `.ai/` or `.kiro/` directory. These establish intent, conventions, and ownership.
2. **Map the directory structure** — List the top 2 levels of the source tree. Identify:
   - Source directories (`src/`, `lib/`, `app/`, `packages/`)
   - Test directories (`tests/`, `__tests__/`, `spec/`)
   - Config files (`.env.example`, `config/`, `settings/`)
   - Infrastructure code (`infra/`, `terraform/`, `k8s/`, `.github/workflows/`)
3. **Identify the entry points** — Locate the main application entry point(s):
   - `main()` / `index.js` / `app.py` / `Program.cs` / `cmd/*/main.go`
   - HTTP server start-up
   - CLI command definitions
   - Lambda/Function handlers
4. **Trace a critical path** — Follow one representative request or workflow end-to-end (e.g. an API call from HTTP handler → service layer → repository → database). List the files and functions involved.
5. **Map key modules and their responsibilities** — Produce a short bullet list of the 5–10 most important packages/modules and what each does.
6. **Identify configuration and secrets** — List environment variables, feature flags, and config files. Note which are required to run locally.
7. **Document how to run locally** — Extract or verify the commands needed to:
   - Install dependencies
   - Start the service
   - Run the test suite
   - Lint / format code
8. **Document how to deploy** — Note the CI/CD pipeline (GitHub Actions, Jenkins, etc.), deploy commands, and environments (dev, staging, production).
9. **Identify "how to change X safely"** — For the most common change types (add an endpoint, add a DB migration, add a feature flag), write a brief numbered checklist.
10. **Flag known complexity or gotchas** — Note any areas that are unusually complex, poorly tested, or have known issues that a new contributor should be aware of.

## Output format

```
## Repository overview
- **Purpose**: <one-sentence description>
- **Primary language(s)**: <languages>
- **Framework(s)**: <frameworks>
- **Team/Owner**: <from CODEOWNERS or README>

## Directory map
```
<top-2-level tree with annotations>
```

## Entry points
- `<file>:<line>` — <description>

## Critical path: <scenario>
1. `<file>` → `<function>` — <what it does>
2. ...

## Key modules
| Module / Package | Responsibility |
|---|---|
| `<path>` | <description> |

## Configuration
| Variable | Required | Default | Description |
|---|---|---|---|

## How to run locally
```bash
# Install dependencies
<command>

# Start the service
<command>

# Run tests
<command>
```

## How to deploy
- **CI/CD**: <tool and link>
- **Deploy command**: <command or "automatic on merge to main">
- **Environments**: <dev / staging / production>

## Common change playbooks
### Add a new API endpoint
1. <step>
2. <step>

### Add a database migration
1. <step>

## Known complexity / gotchas
- <area>: <note>
```

## Common pitfalls
- Do not just copy the README — validate that the "how to run" commands actually work in the current state of the repo.
- Pay attention to `.env.example` vs. actual required environment variables; missing env vars are the most common source of local-setup friction.
- Large monorepos may have per-package README files that override the root-level instructions — check all packages the contributor will work in.
- Avoid mapping every file; focus on the 20% of the codebase responsible for 80% of the work.
- Flag circular dependencies or undocumented global state — these are common sources of confusion for new contributors.

## Examples

### Example 1 — Node.js REST API

**Input**: Repository at `/path/to/order-service`

**Output** (excerpt):
```
## Repository overview
- **Purpose**: HTTP REST service managing customer orders
- **Primary language**: TypeScript (Node.js 20)
- **Framework**: Express 4 + TypeORM

## Entry points
- `src/index.ts:1` — bootstraps Express, registers routes, connects to DB

## Critical path: POST /orders
1. `src/routes/orders.ts` → `createOrder` handler — validates request body
2. `src/services/OrderService.ts` → `create()` — applies business rules, calls PaymentService
3. `src/repositories/OrderRepository.ts` → `save()` — persists to PostgreSQL

## How to run locally
```bash
cp .env.example .env  # fill in DB_URL and PAYMENT_API_KEY
npm install
npm run db:migrate
npm run dev
```

## Known complexity / gotchas
- `OrderService.create()` contains 300+ lines with mixed business and persistence logic — refactoring planned in Q3.
- Integration tests require a running PostgreSQL instance; use `docker-compose up -d db` first.
```
