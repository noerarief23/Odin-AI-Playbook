---
name: terraform-iac-review
description: Review Terraform modules and configurations for correctness, security, cost, and adherence to IaC best practices; produce prioritised findings with remediation examples.
tags: [terraform, iac, infrastructure, security, devops]
version: 1.0.0
---

# Terraform IaC Review

## When to use
- Reviewing a Terraform PR before applying to staging or production.
- Auditing existing Terraform modules for security or compliance issues.
- Onboarding infrastructure code to a new security baseline.
- Migrating Terraform to a newer provider or module structure.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `tf_files` | ✅ | Terraform files (`.tf`) or directory path |
| `plan_output` | optional | Output of `terraform plan` to check for unexpected changes |
| `context` | optional | Cloud provider, environment (dev/staging/prod), compliance requirements |

## Procedure

1. **Check module structure** — Verify the module follows standard layout: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`. Confirm `required_providers` and `required_version` are pinned.
2. **Security checks**:
   - Storage: no public S3 buckets, GCS buckets, or Azure blobs unless explicitly intended.
   - Networking: security groups/NACLs do not allow `0.0.0.0/0` on sensitive ports (22, 3389, DB ports).
   - IAM: no `*` actions or `*` resources in IAM policies; apply least-privilege.
   - Encryption: storage and database volumes use encryption at rest; transit uses TLS.
   - Secrets: no plain-text passwords, keys, or tokens in `.tf` files — use `data "aws_secretsmanager_secret_version"` or equivalent.
3. **State management** — Confirm remote state backend is configured with state locking (DynamoDB for S3, GCS versioning, etc.). State file must not be stored in the repo.
4. **Provider and module version pinning** — All providers and module sources must pin exact or constrained versions, not `latest` or unpinned.
5. **Resource tagging** — Required tags (e.g. `environment`, `team`, `cost-center`) are applied to all taggable resources.
6. **Naming conventions** — Resource names follow the project's convention (e.g. `<env>-<service>-<resource>`).
7. **Destroy protection** — Critical resources (databases, state buckets) have `prevent_destroy = true` in their lifecycle block.
8. **Review `terraform plan` output** (if provided) — Flag unexpected destroy/replace operations, especially for stateful resources.
9. **Assign severity and produce report** in the output format below.

## Output format

```
## Summary
<Brief overview of what the Terraform config provisions>

## Findings

### Critical
- **[file.tf:line]** <Issue>. **Remediation**: <specific HCL fix>.

### High
- **[file.tf:line]** <Issue>. **Remediation**: <guidance>.

### Medium / Low
- **[file.tf:line]** <Issue>. **Remediation**: <guidance>.

## Plan review (if plan provided)
<Notable changes, unexpected destroys, or confirms LGTM>
```

## Common pitfalls
- Do not approve a `terraform apply` that replaces a production database without a verified backup and downtime window.
- `count = 0` and `for_each = {}` are common ways to disable resources without deleting them — verify intent.
- Module sources using `git` refs should pin to a tag or commit SHA, not a branch name.
- `terraform fmt` and `terraform validate` should pass before review; fail fast on formatting issues.

## Examples

### Example 1 — Public S3 bucket

**Input** (HCL):
```hcl
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id
  block_public_acls   = false
  block_public_policy = false
}
```

**Finding**:
```
### Critical
- **s3.tf:3-6** S3 public access block is disabled, potentially exposing bucket contents publicly.
  **Remediation**:
  ```hcl
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
  ```
```

### Example 2 — Missing destroy protection

**Input**:
```hcl
resource "aws_rds_instance" "main" {
  identifier = "prod-db"
  # no lifecycle block
}
```

**Finding**:
```
### High
- **rds.tf:1** Production RDS instance has no `prevent_destroy` lifecycle rule.
  **Remediation**:
  ```hcl
  lifecycle {
    prevent_destroy = true
  }
  ```
```
