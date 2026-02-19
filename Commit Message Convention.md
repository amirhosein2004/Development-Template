# Commit Message Convention

This FastAPI template project follows a structured commit message convention to maintain clear, consistent, and traceable Git history. All commits must adhere to this standard.

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Components

### Type
The type must be one of the following (check in this order and select the first match):

| Type | Usage |
|------|-------|
| **document** | Documentation updates (README, GUIDE, docstrings, comments) |
| **bugfix** | Bug fix (resolves existing issues) |
| **test** | Test additions or modifications (unit tests, integration tests) |
| **CICD** | CI/CD pipeline configuration changes (cloud-build.yaml, Dockerfile, docker-compose.yml, etc.) |
| **feature** | New feature addition (creates new functionality) |
| **maintenance** | Maintenance tasks (dependencies, refactoring, code quality, performance improvements, style changes) |

**Selection Rule:** When categorizing a commit, check types in the order listed above and choose the first one that matches.

### Scope
The scope identifies the part of the project affected. Use the most specific (smallest) scope applicable:

- **root** - Project root level changes
- **helpers** - Changes in `helpers/` directory
- **migrations** - Changes in `migrations/` directory
- **src_v2_app_comments** - Changes in `src/v2/app_comments/`
- **src_v2_manager** - Changes in `src/v2/manager/`
- **src_v2_app_comments_data_model** - Changes in `src/v2/app_comments/data_models/`

**Note:** Always use the smallest/most specific scope that accurately describes the change location.

### Subject
- Use imperative mood ("add" not "added" or "adds")
- Do not capitalize the first letter
- No period (.) at the end
- Maximum 50 characters
- Be specific and descriptive

### Body (Optional)
- Wrap at 72 characters
- Explain **what** and **why**, not **how**
- Separate paragraphs with blank lines
- Reference related issues or PRs: `Fixes #123`, `Relates to #456`

### Footer (Optional)
- Break-breaking changes: `BREAKING CHANGE: description`
- Close related issues: `Closes #123`, `Fixes #456`

## Examples

### Feature Addition
```
feature(src_v2_app_comments): add pagination support to comments listing

Implement offset-based pagination for the comments endpoint to improve
performance when dealing with large datasets. Added `limit` and `offset`
query parameters to the fetch endpoint.

Fixes #42
```

### Bug Fix
```
bugfix(src_v2_manager): resolve authentication token validation error

The JWT validation was failing due to incorrect expiration time comparison.
Updated the comparison logic to properly handle timezone-aware datetime objects.
```

### Documentation
```
document(root): update GUIDE.md with v2 API architecture details

Added section explaining the new v2 module structure and migration path from v1.
```

### Testing
```
test(src_v2_app_comments_data_model): add unit tests for config validation

Added comprehensive test coverage for the configuration validation logic
including edge cases and error scenarios.
```

### CI/CD Infrastructure
```
CICD(root): update Dockerfile-cloud base image to python:3.12

Updated to the latest stable Python version to align with project requirements.
```

### Maintenance & Performance
```
maintenance(src_v2_app_comments): optimize comment fetching with query caching

Implemented Redis caching for comment list queries to reduce database load
and improve response time by 40%. Refactored database query logic for better reusability.
```

### Maintenance & Refactoring
```
maintenance(src_v2_manager): extract connection pooling logic

Separated database connection pooling into a dedicated module to improve
testability and reusability across different database adapters.
```

## Guidelines

1. **Type selection order:** Check types in the specified order (document → bugfix → test → feature → CICD → maintenance) and select the first match
2. **Smallest scope:** Always use the most specific scope that accurately describes the change location
3. **One concern per commit:** Each commit should address a single, well-defined concern
4. **Atomic commits:** Changes should be logically complete and independently meaningful
5. **Reference tracking:** Always reference related issues, PRs, or tickets in the footer
6. **Template usage:** Projects derived from this template should follow this convention consistently
