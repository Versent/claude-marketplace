# API Rule Template

This template generates `.claude/rules/api.md` for projects.

---

## Template Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `{{API_STYLE}}` | Discovery questions | REST, GraphQL, gRPC |
| `{{VERSIONING_STRATEGY}}` | Discovery questions | URL, Header, etc. |
| `{{ERROR_FORMAT}}` | Discovery questions | Error response structure |
| `{{AUTH_HEADER}}` | Discovery questions | Authorization header format |

---

## Default Template

```markdown
---
paths: "**/api/**,**/routes/**,**/handlers/**"
---

# API Guidelines

## REST Conventions

- Use nouns for resources, verbs for actions
- Use proper HTTP methods:
  - GET: Read (idempotent)
  - POST: Create
  - PUT: Full update
  - PATCH: Partial update
  - DELETE: Remove
- Return appropriate status codes:
  - 200: Success
  - 201: Created
  - 204: No Content
  - 400: Bad Request
  - 401: Unauthorized
  - 403: Forbidden
  - 404: Not Found
  - 500: Server Error

## Request/Response

- Use JSON for request and response bodies
- Include Content-Type headers
- Use consistent response format:
  ```json
  {
    "data": {},
    "meta": {},
    "errors": []
  }
  ```

## Pagination

- Use cursor-based pagination for large datasets
- Include pagination metadata:
  ```json
  {
    "data": [],
    "meta": {
      "cursor": "abc123",
      "hasMore": true
    }
  }
  ```

## Versioning

- Version APIs in the URL: `/api/v1/`
- Maintain backward compatibility within versions
- Document breaking changes

## Error Handling

- Use consistent error format:
  ```json
  {
    "errors": [{
      "code": "VALIDATION_ERROR",
      "message": "Email is required",
      "field": "email"
    }]
  }
  ```
- Include request ID for debugging
- Don't expose internal errors to clients

## Documentation

- Document all endpoints with OpenAPI/Swagger
- Include request/response examples
- Document error codes and messages
- Keep documentation in sync with code
```

---

## GraphQL Variations

```markdown
## GraphQL Guidelines

- Use meaningful type names
- Implement proper error handling
- Use DataLoader for N+1 prevention
- Implement pagination with Relay connections
- Use input types for mutations
- Document with schema descriptions
```

---

## gRPC Variations

```markdown
## gRPC Guidelines

- Define services in .proto files
- Use proper field numbering
- Implement proper error codes
- Use streaming appropriately
- Version proto files carefully
- Generate clients from proto
```

---

## Paths Frontmatter

```yaml
paths: "**/api/**,**/routes/**,**/handlers/**"
```
