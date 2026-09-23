# Chapter 6: Source Code Management (Tags, Branches, & Stash)

## Table of Contents

* Introduction
* Tags: Marking Specific Versions
* Branches: Working in Parallel
* Temporary Change Management with git stash and git pop
* Guided Exercises
* Explorational Exercises
* Summary
* Answers to Guided Exercises
* Answers to Explorational Exercises

---

## Introduction

As enterprise applications scale, managing source code requires more than basic linear commits. Engineering teams must isolate parallel feature development, maintain production hotfix lanes, tag immutable software releases, and context-switch quickly without losing uncommitted local work.

This chapter covers intermediate Git mechanisms: **Tags** for milestone management, **Branches** for parallel workflow isolation, and the **Git Stash** workspace buffer for temporary change management.

---

## Tags: Marking Specific Versions

Tags are reference pointers that mark specific historical commits in a repository's execution path. While branches move dynamically with each new commit, tags are static, immutable references, making them ideal for release milestones (e.g., Semantic Versioning `v1.0.0`, production deployments, audit points).

```
         TAG: v1.0.0 (Immutable Reference)
              |
              v
[Commit A] -> [Commit B] -> [Commit C] (main branch pointer)

```

### Types of Tags

* **Lightweight Tags:** Simple pointers referencing a specific commit SHA (essentially a fixed branch pointer).
* **Annotated Tags:** Stored as full checksummed objects in the Git database. They contain the tagger's name, email, timestamp, tagging message payload, and optional cryptographic GPG signatures. Annotated tags are standard for enterprise software releases.

```bash
# Create a lightweight tag
git tag v1.0.0-lw

# Create an annotated release tag with message metadata
git tag -a v1.0.0 -m "release: baseline v1.0.0 production build"

# Push a specific tag to remote origin
git push origin v1.0.0

# Push all local tags to remote origin
git push origin --tags

```

---

## Branches: Working in Parallel

Branches allow developers to diverge from the main line of execution to work on features, bug fixes, or experimental designs without stability risks to production code.

```
                  +-- [Feature Branch: feature/login] -- [Commit 1] -- [Commit 2]
                  |                                                        |
[Main Branch] -- [Base Commit] --------------------------------------------+-- [Merge Commit]

```

### Core Branching Mechanics

In Git, a branch is simply a lightweight, 41-byte pointer file located in `.git/refs/heads/` that contains the 40-character SHA-1 hash of its latest commit. Creating a branch adds a new pointer without duplicating file contents or source code.

* **Creating and Switching Branches:**

```bash
# Create a new feature branch
git branch feature/user-auth

# Switch active working context to the new branch
git checkout feature/user-auth

# Create and switch in a single step (modern Git)
git switch -c feature/user-auth

```

* **Merging Branches:**

```bash
# Switch to target integration branch
git checkout main

# Perform standard merge
git merge feature/user-auth

# Force a explicit merge commit (preserving historical branch topology)
git merge --no-ff feature/user-auth -m "merge: integrate user-auth feature branch"

```

* **Branch Cleanup:**

```bash
# Delete a fully merged topic branch
git branch -d feature/user-auth

# Force-delete an unmerged topic branch
git branch -D feature/user-auth

```

---

## Temporary Change Management with git stash and git pop

When working on a feature, emergency hotfix requests or context switches often arise before local changes are ready for a structured commit. Stash acts as a temporary stack where uncommitted working directory and staging index changes can be safely stored and retrieved later.

```
+---------------------+     git stash      +-------------------+
| Working Directory / | -----------------> |   Stash Stack     |
| Staging Index       | <----------------- | (stash@{0}, etc.) |
+---------------------+     git stash pop  +-------------------+

```

### Essential Stash Operations

* **Saving Changes to Stash:**

```bash
# Save uncommitted tracked changes to the stash stack
git stash

# Save with a descriptive message identifier
git stash save "WIP: auth middleware token validation logic"

# Include untracked files in the stash
git stash -u

```

* **Inspecting and Applying Stashes:**

```bash
# List all stashed changes currently stored in the repository
git stash list

# Re-apply the latest stashed changes AND remove them from the stash stack
git stash pop

# Re-apply stashed changes while keeping them on the stack
git stash apply stash@{0}

# Drop a specific stash entry
git stash drop stash@{0}

```

---

## Guided Exercises

### Exercise 6.1: Implementing Branching Workflows and Release Tagging

**Scenario:** Create a stable release branch workflow, isolate a feature on a topic branch, merge it back using non-fast-forward tracking, and apply an annotated Semantic Versioning tag.

**Step-by-Step Execution:**

1. Create a workspace directory and initialize a Git repository:

```bash
mkdir enterprise-branch-lab && cd enterprise-branch-lab
git init
git branch -M main

```

2. Generate baseline configuration and commit:

```bash
echo "# Enterprise Application Engine" > README.md
git add README.md
git commit -m "chore: initial baseline commit"

```

3. Create and switch to a new feature branch `feature/payment-gateway`:

```bash
git checkout -b feature/payment-gateway

```

4. Implement feature changes and record commits:

```bash
echo "func ProcessPayment() bool { return true }" > payment.go
git add payment.go
git commit -m "feat(payment): implement payment processing logic"

```

5. Return to `main` branch and perform a non-fast-forward merge (`--no-ff`) to preserve branch history:

```bash
git checkout main
git merge --no-ff feature/payment-gateway -m "merge: integrate payment gateway feature"

```

6. Apply an annotated release tag to the merge commit:

```bash
git tag -a v1.1.0 -m "release: v1.1.0 adding payment processing support"

```

7. Inspect the commit graph and verify tag alignment:

```bash
git log --oneline --graph --decorate --all

```

---

### Exercise 6.2: Managing Interruptions with Git Stash

**Scenario:** Simulate an urgent production bug intervention mid-feature development by stashing active uncommitted changes, switching contexts to execute a hotfix, and returning to restore the working state.

**Step-by-Step Execution:**

1. Modify `payment.go` on your active working directory without committing:

```bash
echo "// WIP: adding fraud detection check" >> payment.go
git status

```

2. An urgent hotfix request arrives. Stash active uncommitted changes with a message:

```bash
git stash save "WIP: fraud check development"
git status

```

*Observation:* Working directory is clean.

3. Create a hotfix branch from `main` to address the critical incident:

```bash
git checkout -b hotfix/null-pointer
echo "// Critical fix applied" >> payment.go
git add payment.go
git commit -m "fix: resolve critical null pointer exception"

```

4. Merge the hotfix back into `main`:

```bash
git checkout main
git merge --no-ff hotfix/null-pointer -m "merge: resolve null pointer critical bug"
git branch -d hotfix/null-pointer

```

5. Restore active feature work from the stash stack:

```bash
git stash pop

```

6. Verify that local uncommitted changes are restored to `payment.go`:

```bash
git status
cat payment.go

```

---

## Explorational Exercises

### Exercise 1: Fast-Forward vs. Non-Fast-Forward Merging Analysis

Create two separate local testing repositories (`repo-ff` and `repo-noff`).

1. In `repo-ff`, create a branch, commit new code, switch back to `main`, and execute `git merge <branch>`.
2. In `repo-noff`, perform the same actions but execute `git merge --no-ff <branch>`.
3. Compare `git log --graph --oneline` output across both repositories. Explain why enterprise DevOps teams often enforce non-fast-forward merges on main integration branches.

### Exercise 2: Resolving Stash Conflicts

1. Create a tracking file `config.json` committed to `main`.
2. Modify `config.json` locally, then stash the modification (`git stash`).
3. On `main`, edit and commit a conflicting change to the same line in `config.json`.
4. Run `git stash pop` and observe the merge conflict result.
5. Document the step-by-step resolution path required to reconcile the stash conflict and finalize working directory state.

---

## Summary

* **Tags** mark fixed release milestones in a repository history. Annotated tags store tagger identity, timestamp, and message metadata, making them ideal for version releases.
* **Branches** isolate feature development, bug fixes, and operational releases without affecting code on standard integration paths.
* **Fast-Forward Merges** advance branch pointers linearly without creating new commits. **Non-Fast-Forward (`--no-ff`) Merges** create explicit merge commits, preserving explicit visual record of topic branch development.
* **Git Stash** provides a temporary buffer to hold uncommitted working directory and index modifications, enabling rapid context switching during critical maintenance tasks.

---

## Answers to Guided Exercises

### Answer to Exercise 6.1

Executing `git merge --no-ff feature/payment-gateway` creates an explicit merge commit that keeps the historical scope of the feature branch intact inside the commit log graph. Tagging the resulting commit (`v1.1.0`) attaches an immutable version reference to that state.

### Answer to Exercise 6.2

* Running `git stash save` moves uncommitted working directory modifications off into `.git/refs/stash`, restoring working tree files back to a clean baseline state matching `HEAD`.
* After completing the emergency hotfix merge on `main`, running `git stash pop` re-applies the uncommitted changes back to the working directory and removes the corresponding entry from the stash stack.

---

## Answers to Explorational Exercises

### Sample Answer to Exercise 1: Fast-Forward vs. Non-Fast-Forward Comparison

* **Fast-Forward Merge:** Simply advances the target branch pointer directly to the commit of the feature branch. No separate merge commit is generated, resulting in a completely flat, linear revision graph.
* **Non-Fast-Forward (`--no-ff`) Merge:** Always generates a distinct merge commit with two parent commit hashes, preserving the visual branch arc in graph logs. Enterprise teams favor `--no-ff` on main integration branches because it allows entire feature commits to be identified, audited, or reverted as a single atomic unit.

### Sample Answer to Exercise 2: Resolving Stash Conflicts

1. Running `git stash pop` during an overlapping conflict outputs: `CONFLICT (content): Merge conflict in config.json`.
2. Git marks the conflict markers (`<<<<<<< Updated upstream`, `=======`, `>>>>>>> Stashed changes`) inside `config.json`.
3. The stash entry is intentionally retained on the stack until conflict resolution completes.
4. Open `config.json`, edit the file to resolve conflicting lines, save changes, and stage: `git add config.json`.
5. Remove the resolved conflict entry manually from the stash stack: `git stash drop`.
