---
name: docker-container-hardening
description: Audit a Dockerfile and container runtime configuration for security vulnerabilities and hardening gaps; produce prioritised findings with remediated examples following CIS Docker Benchmark and NIST guidelines.
tags: [docker, containers, security, hardening, devops]
version: 1.0.0
---

# Docker Container Hardening

## When to use
- Reviewing a new or modified Dockerfile before merging.
- Hardening an existing container image for production deployment.
- Auditing a `docker-compose.yml` or Kubernetes pod spec for runtime security issues.
- Preparing a container workload for compliance review (CIS, PCI-DSS, SOC 2).

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `dockerfile` | ✅ | Dockerfile content or path |
| `compose_or_k8s` | optional | `docker-compose.yml` or Kubernetes manifest for runtime review |
| `context` | optional | Base image in use, language runtime, environment (dev/prod) |

## Procedure

1. **Check base image**:
   - Use minimal, well-maintained base images (e.g. `distroless`, `alpine`, `slim` variants).
   - Pin the base image to an exact digest or specific version tag (not `latest`).
   - Prefer official images from Docker Hub or a private registry with vulnerability scanning.
2. **Check user** — The container must not run as `root`. Verify a non-root `USER` is set before the final `CMD`/`ENTRYPOINT`.
3. **Check secrets in image layers** — No `ARG` or `ENV` containing passwords, API keys, or tokens. Use runtime secrets injection (Docker secrets, Kubernetes secrets, AWS SSM).
4. **Minimise attack surface**:
   - Use multi-stage builds to exclude build tools, source code, and test dependencies from the final image.
   - Remove package manager caches: `apt-get clean && rm -rf /var/lib/apt/lists/*`.
   - Do not install `curl`, `wget`, or `ssh` in production images unless required.
5. **Filesystem hardening**:
   - Use `COPY` instead of `ADD` (unless tar extraction is needed).
   - Mark application directories read-only where possible; use volumes for writable state.
6. **Health check** — Add a `HEALTHCHECK` instruction so the orchestrator can detect unhealthy containers.
7. **Runtime configuration** (docker-compose / K8s):
   - Set `read_only: true` or `readOnlyRootFilesystem: true` where possible.
   - Drop all Linux capabilities and add back only what is needed: `cap_drop: [ALL]`, `cap_add: [NET_BIND_SERVICE]`.
   - Set resource limits (`memory`, `cpu`) to prevent resource exhaustion.
   - Disable privilege escalation: `allow_privilege_escalation: false` / `no-new-privileges: true`.
8. **Assign severity and produce report** in the output format below.

## Output format

````
## Summary
<Brief overview of the image/service and overall posture>

## Findings

### Critical
- **[Dockerfile:line]** <Issue>. **Remediation**: <specific fix or snippet>.

### High
- **[Dockerfile:line]** <Issue>. **Remediation**: <guidance>.

### Medium / Low
- **[Dockerfile:line]** <Issue>. **Recommendation**: <guidance>.

## Hardened Dockerfile snippet
```dockerfile
<key hardened sections>
```
````

## Common pitfalls
- `RUN apt-get install` without `--no-install-recommends` pulls in unnecessary packages that increase the attack surface.
- `COPY . .` in multi-stage builds may copy `.env` files, credentials, or test fixtures into the image — use `.dockerignore`.
- Layers created by `RUN` that set an environment variable with a secret are *not* removed by a later `RUN unset`; the secret remains in the layer history.
- `--privileged` in docker-compose or K8s effectively bypasses the container security model; almost never acceptable in production.

## Examples

### Example 1 — Running as root

**Input**:
```dockerfile
FROM node:20
WORKDIR /app
COPY . .
RUN npm ci
CMD ["node", "server.js"]
```

**Finding**:
````
### High
- **Dockerfile:5** No USER instruction; container runs as root.
  **Remediation**: Add a non-root user:
  ```dockerfile
  RUN addgroup --system app && adduser --system --ingroup app app
  USER app
  ```
````

### Example 2 — Secret in ENV

**Input**:
```dockerfile
ENV DATABASE_PASSWORD=supersecret123
```

**Finding**:
```
### Critical
- **Dockerfile:3** Database password hard-coded in ENV; it will be visible in `docker inspect` and image history.
  **Remediation**: Remove the ENV instruction. Inject the secret at runtime:
  - Docker: `docker run -e DATABASE_PASSWORD=$DATABASE_PASSWORD ...`
  - Kubernetes: use a `Secret` volume or `envFrom secretRef`.
  - AWS ECS: use Secrets Manager integration in the task definition.
```

### Example 3 — Hardened multi-stage example

```dockerfile
# Stage 1: build
FROM node:20-alpine AS builder
WORKDIR /build
COPY package*.json ./
RUN npm ci --only=production
COPY src/ ./src/

# Stage 2: runtime
FROM gcr.io/distroless/nodejs20-debian12
WORKDIR /app
COPY --from=builder /build/node_modules ./node_modules
COPY --from=builder /build/src ./src
USER nonroot
HEALTHCHECK --interval=30s --timeout=5s CMD ["/nodejs/bin/node", "src/healthcheck.js"]
CMD ["src/server.js"]
```
