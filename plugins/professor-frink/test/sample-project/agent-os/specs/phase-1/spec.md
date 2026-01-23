# Sample Project Specification

## Overview

This is a sample TypeScript project for testing Professor Frink's autonomous task execution.

## Goals

1. Create a minimal but complete TypeScript project
2. Demonstrate proper project structure
3. Include testing and linting

## Technical Stack

- **Runtime:** Node.js 18+
- **Language:** TypeScript 5.x
- **Testing:** Jest or Vitest
- **Linting:** ESLint

## Architecture

```
sample-project/
├── src/
│   ├── index.ts      # Main entry point
│   ├── utils.ts      # Utility functions
│   └── cli.ts        # CLI entry point
├── test/
│   └── utils.test.ts # Unit tests
├── package.json
├── tsconfig.json
├── .eslintrc.json
└── README.md
```

## Coding Standards

- Use strict TypeScript mode
- All functions must have JSDoc comments
- Prefer const over let
- Use meaningful variable names
- Keep functions small and focused

## Testing Strategy

- Unit tests for all utility functions
- Test files co-located with source or in test/
- Minimum 80% code coverage target
