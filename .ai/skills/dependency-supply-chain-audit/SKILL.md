---
name: dependency-supply-chain-audit
description: Audit project dependencies for known vulnerabilities, outdated packages, insecure pinning, licence risks, and software supply-chain threats; produce an actionable remediation plan.
tags: [security, dependencies, supply-chain, sbom, sca, licences, vulnerability]
version: 1.0.0
---

# Dependency & Supply Chain Audit

## When to use
- Before a production release or major version bump.
- After a public supply-chain incident (e.g. a compromised package in your dependency tree).
- Running a periodic security sweep (recommended: at least monthly).
- When onboarding a new open-source library or third-party SDK.
- As part of a compliance or security audit requiring an SBOM.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `manifest` | ✅ | Dependency manifest file(s): `package.json`, `requirements.txt`, `go.mod`, `*.csproj`, `pom.xml`, `Gemfile`, etc. |
| `lockfile` | optional | Lock file (`package-lock.json`, `yarn.lock`, `poetry.lock`, `Pipfile.lock`, etc.) |
| `context` | optional | Ecosystem, runtime version, deployment environment (cloud, on-prem, air-gapped) |
| `focus` | optional | Specific concern: `vulnerabilities`, `licences`, `pinning`, `sbom`, `typosquatting` |

## Procedure

1. **Inventory dependencies** — List all direct and transitive dependencies with their declared versions. Note whether a lockfile is present and up-to-date.
2. **Check version pinning** — Verify dependencies are pinned to exact versions or commit SHAs in the lockfile. Flag ranges (`^`, `~`, `>=`) that could pull in unreviewed updates.
3. **Scan for known vulnerabilities** — Run the ecosystem's SCA tool:
   - Node.js: `npm audit` / `yarn audit`
   - Python: `pip-audit` or `safety check`
   - Go: `govulncheck ./...`
   - .NET: `dotnet list package --vulnerable`
   - Java: `mvn dependency-check:check` (OWASP)
   - Ruby: `bundle audit`
   - Generic: `trivy fs .` or `grype .`
4. **Check for outdated packages** — Identify packages that are multiple major versions behind their latest release; flag those with active CVEs in older versions.
5. **Assess licence risk** — Catalogue licences for all direct dependencies. Flag:
   - GPL/AGPL/LGPL (copyleft) in a proprietary product.
   - Unlicensed or custom-licence packages.
   - Dual-licensed packages where the commercial restriction may apply.
6. **Check for typosquatting and suspicious packages** — Look for packages with names very similar to popular packages, very few downloads, or recently published with a sudden spike in usage.
7. **Review CI/CD supply chain** — Check GitHub Actions, Docker base images, and build-time scripts for:
   - Actions pinned to a full commit SHA (`uses: actions/checkout@abc1234`).
   - Base images tagged with a digest (`FROM node:20@sha256:...`).
   - Use of `curl | bash` or untrusted script sources in CI.
8. **Generate SBOM** (if requested) — Produce a CycloneDX or SPDX SBOM:
   ```bash
   # CycloneDX for Node
   npx @cyclonedx/cyclonedx-npm --output sbom.json
   # Syft (generic)
   syft . -o spdx-json > sbom.spdx.json
   ```
9. **Assign severity** to each finding: `critical` (actively exploited CVE or GPL in proprietary code), `high` (high-CVSS CVE, unpinned lockfile in production), `medium`, `low`.
10. **Produce the report** in the output format below.

## Output format

```
## Dependency inventory summary
- **Total direct**: <n>
- **Total transitive**: <n> (if determinable)
- **Lockfile present**: yes / no
- **Scan tool(s) used**: <tools>

## Findings

### Critical
- **[Package@version]** <CVE or issue>. **Remediation**: upgrade to `<safe-version>` or replace with `<alternative>`.

### High
- **[Package@version]** <Issue>. **Remediation**: <action>.

### Medium / Low
- **[Package@version]** <Issue>. **Remediation**: <action>.

## Licence risk summary
| Package | Licence | Risk | Action |
|---|---|---|---|

## Pinning gaps
| File | Line | Current | Recommended |
|---|---|---|---|

## CI/CD supply chain findings
- <Finding with file and line>

## SBOM
<Path to generated SBOM file, or "not generated">

## Recommended scan commands
```bash
<commands to reproduce the scan>
```
```

## Common pitfalls
- Transitive vulnerabilities are often higher risk than direct ones — do not skip them.
- A lockfile with unpinned ranges in the manifest can still introduce drift between `npm install` runs if the lockfile is not committed.
- Licence risk depends on *how* the package is used (bundled vs. linked, SAAS vs. distributed binary) — note the usage context.
- Do not rely on a single SCA tool; different tools have different CVE database coverage.
- GitHub Actions that use `uses: org/action@main` are vulnerable to branch-takeover; always pin to a SHA.
- Removing a vulnerable package is safer than suppressing the alert if an alternative exists.

## Examples

### Example 1 — Critical CVE in a direct dependency

**Input** (`package.json` with `"lodash": "^4.17.0"`)

**Output**:
```
### Critical
- **lodash@4.17.0** CVE-2021-23337 (CVSS 7.2): prototype pollution via `_.merge`.
  **Remediation**: Upgrade to `lodash@4.17.21` (patched). Run `npm update lodash`.
```

### Example 2 — Unpinned GitHub Action

**Input** (`.github/workflows/ci.yml`):
```yaml
- uses: actions/checkout@v4
```

**Output**:
```
## CI/CD supply chain findings
- **.github/workflows/ci.yml:12** `actions/checkout` is pinned to a mutable tag `v4`.
  A tag can be moved to a different (potentially malicious) commit.
  **Remediation**: Pin to the full SHA: `uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2`
```
