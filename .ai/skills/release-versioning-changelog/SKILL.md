---
name: release-versioning-changelog
description: Execute a complete release workflow — determine the next SemVer version, generate a structured changelog, create and push a git tag, and draft release notes — following project conventions.
tags: [release, semver, changelog, tagging, versioning, release-notes]
version: 1.0.0
---

# Release Versioning & Changelog

## When to use
- Cutting a new release (patch, minor, or major) from a main or release branch.
- Generating a changelog from commit history or PR list before publishing a release.
- Reviewing or correcting an existing versioning scheme for SemVer compliance.
- Setting up an automated release pipeline from scratch.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `commits` or `prs` | ✅ | Commit log (`git log`) or merged PR list since the last release |
| `current_version` | ✅ | Current version string (e.g. `1.4.2`) |
| `branch` | optional | Branch to release from (default: `main`) |
| `context` | optional | Project name, changelog format preference (`keepachangelog`, `conventional commits`) |
| `pre_release` | optional | Pre-release identifier if applicable (e.g. `alpha`, `beta`, `rc.1`) |

## Procedure

1. **Determine version bump type** — Analyse commits or PR titles using Conventional Commits or the project's commit convention:
   - `feat!:` or `BREAKING CHANGE:` → **major** bump (`X+1.0.0`)
   - `feat:` or new feature PR → **minor** bump (`X.Y+1.0`)
   - `fix:`, `perf:`, `docs:`, `chore:` → **patch** bump (`X.Y.Z+1`)
   - If no convention is used, infer from PR labels or descriptions.
2. **Calculate the next version** — Apply the bump to `current_version`. If `pre_release` is specified, append it (e.g. `2.0.0-rc.1`). Validate that the resulting string is valid SemVer 2.0.0.
3. **Group commits/PRs into changelog categories**:
   - `Breaking Changes` (major bump triggers)
   - `Features` (new capabilities)
   - `Bug Fixes`
   - `Performance Improvements`
   - `Documentation`
   - `Chores / Maintenance` (deps, CI, tooling)
   - Omit merge commits, version-bump commits, and automated dependency PRs from the user-facing changelog.
4. **Draft the changelog entry** — Follow the [Keep a Changelog](https://keepachangelog.com) format. Each entry should be human-readable: describe the *what* and *why*, not just the commit SHA.
5. **Update the `CHANGELOG.md`** — Prepend the new section above the previous release. Keep existing entries intact.
6. **Update version references** — Update `package.json`, `pyproject.toml`, `*.csproj`, `Chart.yaml`, or equivalent version files. Use the project's existing tooling (`npm version`, `poetry version`, etc.) when available.
7. **Create and push the git tag** — Tag format: `v<version>` (e.g. `v2.1.0`). Annotated tag preferred:
   ```bash
   git tag -a v2.1.0 -m "Release v2.1.0"
   git push origin v2.1.0
   ```
8. **Draft release notes** — Write a short (3–5 sentence) summary for the GitHub/GitLab release page, highlighting the most important changes for end users.
9. **Verify the release** — Confirm the tag is visible, CI runs on the tag, and any release artefacts (packages, Docker images) are published successfully.
10. **Communicate the release** — If the project has a changelog digest, mailing list, or Slack channel, post a summary.

## Output format

```
## Next version
`<current_version>` → `<next_version>`
- **Bump type**: major / minor / patch
- **Reason**: <brief justification>

## Changelog entry

### [<next_version>] — <YYYY-MM-DD>

#### Breaking Changes
- <description> (#<PR or commit>)

#### Features
- <description> (#<PR or commit>)

#### Bug Fixes
- <description> (#<PR or commit>)

#### Chores
- <description> (#<PR or commit>)

## Release notes (for GitHub/GitLab release page)
<3–5 sentence summary for end users>

## Commands to execute
```bash
# Update version file
<tool-specific version bump command>

# Commit and tag
git add CHANGELOG.md <version-file>
git commit -m "chore: release v<next_version>"
git tag -a v<next_version> -m "Release v<next_version>"
git push origin main --tags
```
```

## Common pitfalls
- Do not skip the `CHANGELOG.md` update — it is the primary audit trail for what changed and why.
- Annotated tags (`-a`) are preferred over lightweight tags because they carry a message and a tagger identity.
- Never reuse or move existing tags — it breaks reproducibility and confuses package registries.
- For pre-releases, use the SemVer pre-release syntax (`1.0.0-rc.1`) rather than suffixes like `1.0.0-RC` which are not SemVer-compliant.
- Verify that the tag triggers CI and that release artefacts are published before announcing the release.
- Keep changelog entries user-facing: translate technical commit messages into benefit-oriented language.

## Examples

### Example 1 — Minor release from Conventional Commits

**Input**:
- `current_version`: `1.3.0`
- Commits since last release:
  - `feat: add dark mode toggle`
  - `fix: prevent crash on empty search results`
  - `chore: update ESLint to v9`

**Output**:
```
## Next version
`1.3.0` → `1.4.0`
- **Bump type**: minor
- **Reason**: One `feat:` commit present; no breaking changes.

## Changelog entry

### [1.4.0] — 2025-06-15

#### Features
- Add dark mode toggle to the user preferences panel (#142)

#### Bug Fixes
- Fix crash when search results are empty (#145)

#### Chores
- Upgrade ESLint to v9 (#143)
```

### Example 2 — Patch hotfix release

**Input**:
- `current_version`: `2.0.1`
- Commits: `fix: correct off-by-one in pagination offset`

**Output**:
```
## Next version
`2.0.1` → `2.0.2`
- **Bump type**: patch
- **Reason**: Single bug fix; no new features or breaking changes.

## Commands to execute
```bash
git add CHANGELOG.md package.json
git commit -m "chore: release v2.0.2"
git tag -a v2.0.2 -m "Release v2.0.2"
git push origin main --tags
```
```
