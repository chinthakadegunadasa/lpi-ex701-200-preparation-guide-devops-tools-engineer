# Chapter 7: Advanced Git Operations

## Table of Contents

* Introduction
* Advanced Branching and Merging Strategies
* Git Rebase vs. Git Merge
* Interactive Releasing and History Cleaning (git rebase -i)
* Recovering Lost Commits with git reflog
* Finding Bugs with Binary Search (git bisect)
* Git Hooks: Automating Quality Control
* Guided Exercises
* Explorational Exercises
* Summary
* Answers to Guided Exercises
* Answers to Explorational Exercises

---

## Introduction

In mission-critical enterprise environments, basic version control practices are insufficient to maintain production-grade system resilience. Complex software architectures require sophisticated repository management techniques to preserve clean historical linear graphs, isolate regression defects rapidly, enforce mandatory pre-commit code compliance, and recover from destructive administrative errors.

This chapter explores advanced Git operations, including rebase workflows, interactive history squashing, historical recovery via `reflog`, automated binary search debugging using `bisect`, and client-side quality enforcement using Git Hooks.

---

## Advanced Branching and Merging Strategies

Enterprise teams adopt structured branching models to regulate code flow between unstable feature development and production deployment environments.

```
                    +---------------------------------------+
                    |       Gitflow Branching Model         |
                    +---------------------------------------+

   Production  =======================================================> (main)
                                      ^                      ^
                                      |                      | (hotfix)
                                  (release)                  |
                                      |                      |
   Integration  ----------------------+----------------------+---------> (develop)
                                 ^         ^             ^
                                 |         |             |
   Topic Lanes  ................ +-- [feat1]             +-- [feat2]

```

### Enterprise Branching Models

| Strategy | Structure & Characteristics | Primary Use Case |
| --- | --- | --- |
| **Gitflow** | Strict separation with `main`, `develop`, `feature/*`, `release/*`, and `hotfix/*` branches. | Scheduled enterprise release cycles with strict QA gates. |
| **Trunk-Based** | Developers push short-lived topic branches directly into `main` using feature flags. | High-frequency Continuous Integration / Continuous Deployment (CI/CD). |
| **GitHub Flow** | Lightweight workflow based on feature branches merged into `main` via Pull Request reviews. | Web services, microservices, and rapid iteration pipelines. |

---

## Git Rebase vs. Git Merge

Integrating changes between parallel branches can be executed using either `git merge` or `git rebase`. Understanding their architectural distinctions is essential for repository governance.

```
                             MERGE WORKFLOW
  feature  -----[ C1 ]-----[ C2 ]-----------+
                                            v
  main     -----[ B1 ]-----[ B2 ]------[ Merge Commit ]


                             REBASE WORKFLOW
  feature  ----------------------------[ C1' ]----[ C2' ]
                                      /
  main     -----[ B1 ]-----[ B2 ]----+

```

### Comparison Matrix

| Dimensional Metric | Git Merge | Git Rebase |
| --- | --- | --- |
| **Commit History Structure** | Non-destructive; creates an explicit, non-linear diamond-shaped merge graph. | Linear; rewrites branch commit history by replaying commits onto the upstream HEAD. |
| **Traceability** | Preserves historical timing, author timestamps, and branch context. | Re-applies changes with new SHA commit hashes; linearizes history. |
| **Conflict Resolution** | Resolves all file conflicts in a single merge commit. | Requires resolving conflicts sequentially for each replayed commit. |
| **Governance Rule** | Safe for public, shared, and production integration branches. | **Golden Rule:** Never rebase branches that have been pushed to public/shared repositories. |

---

## Interactive Releasing and History Cleaning (git rebase -i)

Before merging a topic branch into `main` or submitting a pull request, developers should clean up intermediate "work-in-progress" commits into logical, self-contained atomic units.

```bash
# Interactively rebase the last 4 commits on the active branch
git rebase -i HEAD~4

```

### Common Interactive Command Directives

* `pick` (`p`): Retain the commit as-is in the history.
* `reword` (`r`): Keep the commit content, but edit the commit message.
* `edit` (`e`): Pause the rebase execution to modify commit contents or split commits.
* `squash` (`s`): Combine the commit into the previous commit, merging message payloads.
* `fixup` (`f`): Combine the commit into the previous commit, discarding its message payload.
* `drop` (`d`): Remove the commit completely from the historical stream.

```
# Example Interactive Rebase Script Layout
pick 8a1b2c3 feat(auth): implement initial login endpoint
fixup 3f4a5b6 wip: add console debug logs
squash e7d8c9a docs(auth): update swagger API specs

```

---

## Recovering Lost Commits with git reflog

Git maintains a reference log (`reflog`) that records every movement of local reference pointers (e.g., `HEAD`, branches). Unlike `git log`, which displays the commit graph, `git reflog` tracks every state change—including destructive resets, discarded commits, and aborted rebase operations.

```
+-------------------------------------------------------------------------------+
|                             GIT REFLOG RECOVERY                               |
+-------------------------------------------------------------------------------+
|  Index       Action                               Target Hash                 |
|  HEAD@{0}:   reset: moving to HEAD~1              -----> Lost Commit!         |
|  HEAD@{1}:   commit: feat(security): add JWT      -----> [ 9a8b7c6 ]          |
|  HEAD@{2}:   checkout: moving from main to feat   -----> [ 1a2b3c4 ]          |
+-------------------------------------------------------------------------------+

```

### Recovery Command Pattern

```bash
# View local reference log history
git reflog

# Restore branch state to a pre-destructive commit hash
git reset --hard HEAD@{1}

```

---

## Finding Bugs with Binary Search (git bisect)

`git bisect` is a diagnostic tool that performs a binary search through the repository's commit history to identify the exact commit that introduced a defect or regression.

```
[Good Commit] -- [ ? ] -- [ ? ] -- [ Bad Commit (HEAD) ]
                       |
                 bisect test

```

### Automated Bisect Execution Loop

```bash
# 1. Start the binary search operation
git bisect start

# 2. Mark current HEAD as defective
git bisect bad

# 3. Mark a known-good historical commit/tag
git bisect good v1.0.0

# 4. Git automatically checks out intermediate commits.
# Test the codebase and mark each iteration:
git bisect good  # or: git bisect bad

# 5. Alternatively, run an automated unit test script:
git bisect run pytest tests/test_regression.py

# 6. Reset working directory back to original HEAD after finding culprit
git bisect reset

```

---

## Git Hooks: Automating Quality Control

Git Hooks are event-driven scripts located in `.git/hooks/` that execute automatically before or after key Git lifecycle events (e.g., `pre-commit`, `commit-msg`, `pre-push`).

```
+------------------+      Triggers      +--------------------+      Fails      +------------------+
| git commit Event | -----------------> | .git/hooks/        | --------------> | Block Commit &   |
| Execution        |                    | pre-commit Script  |                 | Reject Request   |
+------------------+                    +--------------------+                 +------------------+
                                                  |
                                                  | Passes
                                                  v
                                        +--------------------+
                                        | Create Commit      |
                                        | Object in Storage  |
                                        +--------------------+

```

### Enterprise Hook Categories

* **Client-Side Hooks:** Executed on local developer workstations (`pre-commit` for linting/formatting, `commit-msg` for enforcing conventional commit formats).
* **Server-Side Hooks:** Executed on central server endpoints (`pre-receive` to enforce branch protection policies, secret detection, and policy compliance before accepting pushes).

---

## Guided Exercises

### Exercise 7.1: Interactive History Cleanup using `git rebase -i`

**Scenario:** Clean up a messy topic branch containing work-in-progress commits into a single structured commit before merging into `main`.

**Step-by-Step Execution:**

1. Initialize lab workspace:

```bash
mkdir enterprise-rebase-lab && cd enterprise-rebase-lab
git init
git branch -M main

```

2. Establish baseline commit:

```bash
echo "# Payment Gateway Microservice" > README.md
git add README.md
git commit -m "chore: initial project initialization"

```

3. Create topic branch and generate iterative WIP commits:

```bash
git checkout -b feature/jwt-auth
echo "func Authenticate() {}" > auth.go
git add auth.go
git commit -m "feat: add auth skeleton"

echo "// WIP debug log" >> auth.go
git commit -am "wip: add temporary print statements"

echo "// Token expiration logic" >> auth.go
git commit -am "feat: implement token expiry validation"

```

4. Launch interactive rebase to clean up the last 3 commits:

```bash
git rebase -i HEAD~3

```

5. In the interactive editor, keep the first commit and squash/fixup subsequent WIP commits:

```text
pick 1a2b3c4 feat: add auth skeleton
fixup 2b3c4d5 wip: add temporary print statements
squash 3c4d5e6 feat: implement token expiry validation

```

6. Save and exit the editor. Provide a clean, consolidated commit message when prompted:

```text
feat(auth): implement JWT authentication and token validation

```

7. Verify the sanitized history graph:

```bash
git log --oneline --graph

```

---

### Exercise 7.2: Recovering a Destructively Deleted Commit with `git reflog`

**Scenario:** Simulate an accidental `git reset --hard` that removes unpushed commits, and restore the lost state using `git reflog`.

**Step-by-Step Execution:**

1. Create a new commit containing critical business logic:

```bash
echo "func ValidateSignature() bool { return true }" >> auth.go
git commit -am "feat(security): add cryptographic signature verification"

```

2. Capture the current SHA reference:

```bash
SAVED_SHA=$(git rev-parse HEAD)
echo "Critical Commit Hash: $SAVED_SHA"

```

3. Simulate a destructive hard reset back to `main` baseline:

```bash
git reset --hard HEAD~1

```

*Observation:* The commit appears to be lost from `git log`.

4. Retrieve lost commit pointer from reference logs:

```bash
git reflog

```

5. Recover the deleted commit state:

```bash
git reset --hard $SAVED_SHA

```

6. Verify that the critical commit and file contents are fully restored:

```bash
git log -1
cat auth.go

```

---

## Explorational Exercises

### Exercise 1: Enforcing Conventional Commits with a `commit-msg` Hook

1. Inside `.git/hooks/`, create an executable file named `commit-msg`.
2. Write a Bash script using regex pattern matching (`^feat|^fix|^chore|^docs|^style`) to validate that incoming commit messages follow Conventional Commit guidelines.
3. Attempt to execute `git commit -m "invalid message format"` and verify that the commit is rejected.
4. Test with a valid message (`git commit -m "fix(core): resolve null pointer exception"`) and confirm successful execution.

### Exercise 2: Automated Defect Isolation via `git bisect run`

1. Write a script `test_runner.sh` that checks for a specific string or syntax failure in your project and exits with code `0` (pass) or `1` (fail).
2. Seed a multi-commit sequence where a bug is introduced on commit #5 out of 10.
3. Configure and execute `git bisect run ./test_runner.sh`.
4. Document how `git bisect` automatically isolates the exact culprit commit without manual intervention.

---

## Summary

* **Git Rebase** linearizes commit history by replaying local feature commits onto an updated upstream base pointer.
* **Interactive Rebase (`git rebase -i`)** allows developers to squash, reword, edit, or drop intermediate commits before merging code into shared branches.
* **`git reflog`** maintains a log of local reference movements, enabling recovery of lost commits resulting from hard resets, deleted branches, or rebase mistakes.
* **`git bisect`** uses binary search to quickly isolate defect-introducing commits across large revision histories.
* **Git Hooks** provide event-driven automation for enforcing pre-commit code quality, message standards, and enterprise compliance rules.

---

## Answers to Guided Exercises

### Answer to Exercise 7.1

Using `git rebase -i` with `squash` and `fixup` directives condenses intermediate "work-in-progress" commits into a single atomic commit. This eliminates noisy debug history while preserving a clean, readable commit log.

### Answer to Exercise 7.2

Although `git reset --hard` updates branch pointers and clears working tree changes, Git retains unreferenced commit objects in internal storage (`.git/objects/`) until garbage collection runs. `git reflog` tracks historical `HEAD` states, allowing immediate recovery using `git reset --hard <SHA>`.

---

## Answers to Explorational Exercises

### Sample Answer to Exercise 1: Pre-Commit Quality Enforcement Hook

```bash
#!/usr/bin/env bash
# .git/hooks/commit-msg

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")
PATTERN="^(feat|fix|chore|docs|style|refactor|test)(\([a-z0-9_-]+\))?: .+"

if ! [[ "$COMMIT_MSG" =~ $PATTERN ]]; then
    echo "ERROR: Invalid commit message format."
    echo "Message must match: <type>(<scope>): <description>"
    echo "Example: feat(auth): add JWT token validation"
    exit 1
fi

```

### Sample Answer to Exercise 2: Automated Bisect Debugging Script

```bash
#!/usr/bin/env bash
# test_runner.sh
# Exit 0 indicates good commit, exit 1 indicates bad commit

if grep -q "DEPRECATED_FUNC_CALL" app.py; then
    exit 1 # Defect present
else
    exit 0 # Defect absent
fi

```

Executing `git bisect run ./test_runner.sh` evaluates commits logarithmically ($O(\log N)$). For example, across 1,000 commits, `git bisect` identifies the culprit commit in roughly 10 automated test steps.
