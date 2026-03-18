---
name: cicd-troubleshooting
description: Diagnose and fix failing CI/CD pipelines (GitHub Actions, GitLab CI, Jenkins, CircleCI, or similar) by analysing logs, identifying root causes, and producing a minimal fix.
tags: [ci, cd, devops, pipelines, github-actions]
version: 1.0.0
---

# CI/CD Troubleshooting

## When to use
- A CI/CD pipeline is failing and the cause is unclear.
- A previously passing pipeline started failing after a change.
- A deployment workflow is stuck, timing out, or producing unexpected results.
- You need to optimise or harden a pipeline configuration.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `logs` | ✅ | Failing job log (or relevant excerpt) |
| `pipeline_config` | ✅ | Workflow file (`.github/workflows/*.yml`, `Jenkinsfile`, `.gitlab-ci.yml`, etc.) |
| `context` | optional | Recent changes (commits, dependency updates) that preceded the failure |
| `platform` | optional | CI platform (default: infer from config file) |

## Procedure

1. **Identify the failing step** — Find the first `ERROR`, `FAILED`, or non-zero exit code in the log.
2. **Classify the failure type** — Common categories:
   - *Dependency* — package install/fetch failed (network, version conflict, missing registry auth).
   - *Build* — compiler/transpiler error (syntax, missing file, wrong Node/Python/Go version).
   - *Test* — one or more tests failed (logic regression, environment mismatch, flaky test).
   - *Auth/Permissions* — missing secret, expired token, insufficient IAM role.
   - *Timeout* — step exceeded time limit (slow test, infinite loop, waiting for resource).
   - *Infrastructure* — runner out of disk/memory, Docker daemon unavailable.
   - *Config* — YAML syntax error, undefined variable, wrong branch/trigger rule.
3. **Correlate with recent changes** — Check if the failure started after a specific commit, dependency bump, or config change.
4. **Propose fix** — Write the minimal change to the pipeline config or source code that resolves the root cause.
5. **Suggest prevention** — Recommend caching, pinned action versions, retry logic, or alerts to prevent recurrence.
6. **Produce output** in the format below.

## Output format

```
## Failing step
<Step name and line number in the log>

## Failure type
<Classification from the list above>

## Root cause
<One-sentence description>

## Fix
```yaml  (or diff)
<Minimal change to workflow file or source>
```

## Prevention
<Recommendation to avoid recurrence>
```

## Common pitfalls
- Do not suggest adding `continue-on-error: true` to hide failures — fix the underlying cause.
- When the failure is a flaky test, identify *why* it is flaky (timing, shared state, missing mock) rather than retrying blindly.
- Pin third-party GitHub Actions to a full commit SHA, not a mutable tag (e.g. `actions/checkout@v4` → `actions/checkout@abc1234`).
- Secrets must never be echoed in logs; if a step prints a secret, rotate it immediately.

## Examples

### Example 1 — Missing Node version

**Log excerpt**:
```
Error: The engine "node" is incompatible with this module. Expected version ">=18". Got "16.20.0"
npm ERR! code ENOTSUP
```

**Output**:
```
## Failing step
`npm install` (step 3)

## Failure type
Build — Node version mismatch

## Root cause
The runner uses Node 16 but the project requires Node ≥ 18.

## Fix
```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
```

## Prevention
Pin the Node version in `.nvmrc` and read it in the workflow:
`node-version-file: '.nvmrc'`
```

### Example 2 — Expired AWS credentials

**Log excerpt**:
```
Error: ExpiredTokenException: The security token included in the request is expired
```

**Output**:
```
## Failing step
`aws s3 sync` (deploy step)

## Failure type
Auth/Permissions — expired AWS token

## Root cause
The static AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY stored as repo secrets have expired or been rotated.

## Fix
Replace static credentials with OIDC-based auth (no long-lived secrets):
```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/github-deploy
    aws-region: us-east-1
```

## Prevention
Migrate fully to OIDC; remove static credential secrets from the repository.
```
