---
name: api-design
description: Design or review a REST, GraphQL, or gRPC API for consistency, usability, security, and evolvability; produce an OpenAPI/schema document or structured review with actionable recommendations.
tags: [api, rest, graphql, grpc, design, openapi]
version: 1.0.0
---

# API Design

## When to use
- Designing a new API from requirements or user stories.
- Reviewing an existing OpenAPI spec, GraphQL schema, or Protobuf definition.
- Evaluating whether a proposed API is consistent with existing APIs in the project.
- Refactoring an API to improve usability before a major release.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `requirements` or `spec` | ✅ | User stories, existing API spec, or description of the resource |
| `api_style` | optional | `rest`, `graphql`, or `grpc` (default: `rest`) |
| `existing_apis` | optional | Other API specs in the project for consistency reference |
| `constraints` | optional | Auth model, versioning strategy, pagination style |

## Procedure

1. **Identify resources and actions** — List the domain entities and the operations callers need to perform on them.
2. **Define resource URLs (REST) / types (GraphQL) / messages (gRPC)**:
   - REST: use plural nouns for collections (`/users`, `/orders`), avoid verbs in paths.
   - Use consistent casing: `kebab-case` for URL segments, `camelCase` for JSON fields.
3. **Map HTTP methods (REST)**:
   - `GET` — read without side effects.
   - `POST` — create or trigger an action.
   - `PUT` / `PATCH` — full / partial replace.
   - `DELETE` — remove.
4. **Design request/response schemas**:
   - Use consistent field naming across all endpoints.
   - Include `id`, `createdAt`, `updatedAt` on all resources.
   - Wrap collections in an envelope: `{ "data": [...], "pagination": { ... } }`.
5. **Define error model** — Use standard HTTP status codes; return a consistent error body:
   ```json
   { "error": { "code": "VALIDATION_ERROR", "message": "...", "details": [...] } }
   ```
6. **Design pagination** — Prefer cursor-based (`cursor`, `limit`) over offset for large collections.
7. **Plan versioning** — Prefer URL versioning (`/v1/`) for REST; deprecation notices in headers.
8. **Security** — Specify authentication (Bearer JWT, API key, OAuth2 scopes), rate limiting headers, and CORS policy.
9. **Produce OpenAPI 3.1 snippet or structured review** in the output format below.

## Output format

### For new API design
```yaml
# OpenAPI 3.1 snippet (or structured description)
openapi: "3.1.0"
paths:
  /resource:
    ...
```

### For API review
```
## Summary
<What the API does and overall quality>

## Issues

### Breaking / Critical
- **[Endpoint]** <Issue>. **Recommendation**: <fix>.

### Consistency / Usability
- **[Endpoint]** <Issue>. **Recommendation**: <fix>.

### Security
- **[Endpoint]** <Issue>. **Recommendation**: <fix>.
```

## Common pitfalls
- Do not use verbs in REST resource paths (`/getUsers` → `/users`).
- Do not expose internal IDs (DB auto-increment integers) as primary resource identifiers; use UUIDs or opaque strings.
- Do not silently ignore unknown query parameters; return `400 Bad Request` for unsupported parameters when strict validation is required.
- Do not return `200 OK` with an error body; use appropriate 4xx/5xx status codes.
- Avoid deeply nested resources (> 2 levels); flatten with query parameters instead.

## Examples

### Example 1 — REST resource design

**Requirements**: CRUD for blog posts

**Output**:
```
GET    /v1/posts              → list posts (paginated)
POST   /v1/posts              → create post
GET    /v1/posts/{id}         → get post
PATCH  /v1/posts/{id}         → partial update
DELETE /v1/posts/{id}         → delete post
GET    /v1/posts/{id}/comments → list comments for post
POST   /v1/posts/{id}/comments → add comment
```

### Example 2 — Error consistency review

**Issue**: API returns `{ "message": "not found" }` on some endpoints and `{ "error": "404" }` on others.

**Recommendation**: Standardise to a single error envelope:
```json
{ "error": { "code": "NOT_FOUND", "message": "Resource not found", "requestId": "abc123" } }
```
Return `404` HTTP status for all not-found cases.
