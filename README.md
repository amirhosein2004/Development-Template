# Git Conventions Guide

This project follows structured conventions for commits, branches, and Git workflow to maintain clear, traceable history.

## Quick Start

### Commit Format
```
<type>(<scope>): <subject>
```

### Branch Format
```
<type>/<scope>
```

### Types (in order of priority)
1. **document** - Documentation updates
2. **bugfix** - Bug fixes
3. **test** - Test additions/modifications
4. **CICD** - CI/CD pipeline changes
5. **feature** - New features
6. **maintenance** - Refactoring, optimization, dependencies

### Scopes
- `root` - Project root level
- `helpers` - helpers/ directory
- `migrations` - migrations/ directory
- `src_v2_app_comments` - src/v2/app_comments/
- `src_v2_manager` - src/v2/manager/
- `src_v2_app_comments_data_model` - src/v2/app_comments/data_models/

## Examples

### Feature
```
feature(src_v2_app_comments): add pagination support to comments listing
```

### Bug Fix
```
bugfix(src_v2_manager): resolve authentication token validation error
```

### Documentation
```
document(root): update GUIDE.md with v2 API architecture details
```

### Testing
```
test(src_v2_app_comments_data_model): add unit tests for config validation
```

### CI/CD
```
CICD(root): update Dockerfile-cloud base image to python:3.12
```

### Maintenance
```
maintenance(src_v2_app_comments): optimize comment fetching with query caching
```

## Workflow Example

```bash
# Create feature branch
git checkout -b feature/src_v2_app_comments

# Make changes
git add .
git commit -m "feature(src_v2_app_comments): add new feature"

# Push to remote
git push -u origin feature/src_v2_app_comments
```

## Key Rules

- **Type selection:** Check types in priority order, select first match
- **Smallest scope:** Use most specific scope applicable
- **One concern per commit:** Each commit addresses single concern
- **Atomic commits:** Changes should be logically complete
- **Reference issues:** Include related issue numbers in commit body

## Documentation

- **Commit Message Convention.md** - Detailed commit message rules
- **Branch Naming Convention.md** - Branch naming standards
- **Git Commands Reference.md** - Common Git commands
