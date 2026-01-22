# Summarize Skill

Summarize code files, documentation, or any text content concisely.

## Skill Instructions

When asked to summarize content:

1. **Identify the type** of content (code, docs, config, etc.)
2. **Extract key points**:
   - For code: main functions, classes, dependencies, purpose
   - For docs: key concepts, instructions, important notes
   - For config: what it configures, notable settings
3. **Structure the summary**:
   - One-line TL;DR
   - Bullet points for main components/sections
   - Notable details or caveats

## Output Format

```
## Summary: [filename or topic]

**TL;DR**: [One sentence summary]

### Key Points
- Point 1
- Point 2
- Point 3

### Notable Details
- Any important caveats, dependencies, or considerations
```

## Example

For a Python file with an API client:

```
## Summary: api_client.py

**TL;DR**: HTTP client wrapper for the Acme API with retry logic and auth handling.

### Key Points
- `AcmeClient` class - main interface for API calls
- Automatic token refresh on 401 responses
- Exponential backoff retry (3 attempts max)
- Supports both sync and async operations

### Notable Details
- Requires `ACME_API_KEY` environment variable
- Rate limited to 100 requests/minute
```
