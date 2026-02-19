# Branch Naming Convention

This project follows a structured branch naming convention that aligns with the commit message convention to maintain consistency across Git workflow.

## Format

```
<type>/<scope>
```

or for review branches:

```
review-<date>
```

## Components

### Type
Use the same types as commit messages:
- **feature/** - New features
- **bugfix/** - Bug fixes
- **test/** - Test additions
- **document/** - Documentation updates
- **maintenance/** - Refactoring, optimization, dependencies
- **CICD/** - CI/CD pipeline changes

### Scope
Use the same scopes as commit messages (most specific applicable):
- **root** - Project root level changes
- **helpers** - Changes in `helpers/` directory
- **migrations** - Changes in `migrations/` directory
- **src_v2_app_comments** - Changes in `src/v2/app_comments/`
- **src_v2_manager** - Changes in `src/v2/manager/`
- **src_v2_app_comments_data_model** - Changes in `src/v2/app_comments/data_models/`

### Date (Optional)
- Format: `YYYYMMDD` (e.g., `20260213` for February 13, 2026)
- Use only in review branches to track when review was requested

## Examples

```
feature/src_v2_app_comments
bugfix/src_v2_manager
document/root
test/src_v2_app_comments_data_model
maintenance/src_v2_app_comments
CICD/root

# Review branches
review-20260213
review-20260219
review-20260225
```

## Guidelines

1. **Consistency:** Branch name should match the commit type/scope
2. **Lowercase:** Always use lowercase letters
3. **Simple format:** Use only type and scope separated by forward slash
4. **Delete after merge:** Remove branch after PR is merged
5. **One feature per branch:** Each branch should address a single concern

## Review Branch Usage

- Use `review-<date>` when a branch is ready for review
- Date indicates when the branch was submitted for review (format: YYYYMMDD)
- Helps track review queue and deadlines
