## Quick Reference

This workspace follows structured Git conventions to maintain clear, traceable history across the project.

### Three Key Documents:

1. **Commit Message Convention** - How to write commit messages
2. **Branch Naming Convention** - How to name branches
3. **Git Commands Reference** - Common Git commands

### What You Need to Know:

- **Commit Format:** `<type>(<scope>): <subject>`
- **Branch Format:** `<type>/<scope>`
- **Types:** document, bugfix, test, CICD, feature, maintenance
- **Scopes:** root, helpers, migrations, src_v2_app_comments, src_v2_manager, src_v2_app_comments_data_model

### Example Workflow:

```bash
# Create feature branch
git checkout -b feature/src_v2_app_comments

# Make changes and commit
git add .
git commit -m "feature(src_v2_app_comments): add pagination support"

# Push to remote
git push -u origin feature/src_v2_app_comments
```

For detailed information, refer to the specific convention documents.


