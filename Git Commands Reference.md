# Git Commands Reference

This document contains frequently used Git commands for common development tasks.

## Basic Setup

### Configure Git User
```bash
git config --global user.name "[name]"
git config --global user.email "[email]"
```

### View Configuration
```bash
git config --list
```

## Branch Management

### Create a New Branch
```bash
git branch <branch-name>
```

### Create and Switch to New Branch
```bash
git checkout -b <branch-name>
# or (Git 2.23+)
git switch -c <branch-name>
```

### List Local Branches
```bash
git branch
```

### List All Branches (Local + Remote)
```bash
git branch -a
```

### Switch to a Branch
```bash
git checkout <branch-name>
# or (Git 2.23+)
git switch <branch-name>
```

### Delete a Local Branch
```bash
git branch -d <branch-name>
# Force delete (if not merged)
git branch -D <branch-name>
```

### Delete a Remote Branch
```bash
git push origin --delete <branch-name>
```

### Rename a Branch
```bash
# Rename current branch
git branch -m <new-branch-name>
# Rename specific branch
git branch -m <old-branch-name> <new-branch-name>
```

## Staging and Committing

### Check Status
```bash
git status
```

### Stage All Changes
```bash
git add .
```

### Stage Specific File
```bash
git add <file-path>
```

### Unstage Changes
```bash
git reset <file-path>
```

### Commit Changes
```bash
git commit -m "<type>(<scope>): <subject>"
```

### Commit with Body and Footer
```bash
git commit
# Opens editor for multi-line commit message
```

### Amend Last Commit
```bash
git commit --amend
# Without changing commit message
git commit --amend --no-edit
```

### View Commit History
```bash
git log
# One line per commit
git log --oneline
# With graph visualization
git log --graph --oneline --all
```

## Remote Management

### List Remote Repositories
```bash
git remote -v
```

### Add Remote Repository
```bash
git remote add <remote-name> <repository-url>
```

### Remove Remote Repository
```bash
git remote remove <remote-name>
```

### Rename Remote
```bash
git remote rename <old-name> <new-name>
```

### View Remote Details
```bash
git remote show <remote-name>
```

## Pushing and Pulling

### Push to Remote
```bash
git push <remote-name> <branch-name>
# Example
git push origin feature/src_v2_app_comments
```

### Push All Branches
```bash
git push <remote-name> --all
```

### Push with Upstream Tracking
```bash
git push -u <remote-name> <branch-name>
```

### Pull from Remote
```bash
git pull <remote-name> <branch-name>
```

### Fetch from Remote (without merging)
```bash
git fetch <remote-name>
```

### Force Push (Use with Caution)
```bash
git push --force <remote-name> <branch-name>
# Safer alternative
git push --force-with-lease <remote-name> <branch-name>
```

## Stashing

### Stash Changes
```bash
git stash
# With description
git stash save "<description>"
```

### List Stashes
```bash
git stash list
```

### Apply Stash
```bash
git stash apply
# Apply specific stash
git stash apply stash@{0}
```

### Pop Stash (Apply and Remove)
```bash
git stash pop
```

### Delete Stash
```bash
git stash drop stash@{0}
```

## Merging and Rebasing

### Merge Branch
```bash
git merge <branch-name>
```

### Rebase Current Branch
```bash
git rebase <branch-name>
```

### Abort Merge/Rebase
```bash
git merge --abort
git rebase --abort
```

## Viewing Changes

### View Unstaged Changes
```bash
git diff
```

### View Staged Changes
```bash
git diff --staged
```

### View Changes in Specific File
```bash
git diff <file-path>
```

### View Changes Between Branches
```bash
git diff <branch-1> <branch-2>
```

## Undoing Changes

### Discard Changes in Working Directory
```bash
git checkout -- <file-path>
# or (Git 2.23+)
git restore <file-path>
```

### Discard All Changes
```bash
git reset --hard HEAD
```

### Revert a Commit (Create new commit)
```bash
git revert <commit-hash>
```

### Reset to Previous Commit
```bash
# Soft reset (keep changes staged)
git reset --soft HEAD~1
# Mixed reset (keep changes unstaged)
git reset --mixed HEAD~1
# Hard reset (discard changes)
git reset --hard HEAD~1
```

## Useful Aliases

Add these to your Git config for faster commands:

```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual 'log --graph --oneline --all'
```

## Common Workflows

### Create and Push a New Feature Branch
```bash
git checkout -b feature/src_v2_app_comments
# Make changes
git add .
git commit -m "feature(src_v2_app_comments): add new feature"
git push -u origin feature/src_v2_app_comments
```

### Update Branch from Main
```bash
git fetch origin
git rebase origin/main
# or merge
git merge origin/main
```

### Clean Up Local Branches
```bash
# Delete merged branches
git branch --merged | grep -v "\*" | xargs -n 1 git branch -d
```

### Sync Fork with Upstream
```bash
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```
