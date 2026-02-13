# Lab 2 — Version Control & Advanced Git

**Course:** DevOps Intro
**Branch:** `feature/lab2`
**Repository:** DevOps-Intro

---

# Task 1 — Git Object Model Exploration

## 1.1 Sample Commit Creation

```bash
echo "Test content" > test.txt
git add test.txt
git commit -m "Add test file"
```

This created a new commit containing a single tracked file `test.txt`.

---

## 1.2 Inspecting Git Objects

### Blob Object

```bash
git cat-file -p 2eec599a1130d2ff231309bb776d1989b97c6ab2
```

**Output:**

```
Test content
```

### Tree Object

```bash
git cat-file -p 0a6933a1c2296f6f21c2cdd829dff8be5340b34d
```

**Output:**

```
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb	README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c	app
040000 tree eb79e5a468ab89b024bd4f3ed867c6a3954fe1f0	labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63	lectures
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2	test.txt
```

### Commit Object

```bash
git cat-file -p a867c63
```

**Output (excerpt):**

```
tree 0a6933a1c2296f6f21c2cdd829dff8be5340b34d
parent d6b6a0364131afc0c79e1f5ca089c5c6131ef4b4
author r3taker <rokra2005@yandex.ru> 1771001039 +0300
committer r3taker <rokra2005@yandex.ru> 1771001039 +0300
gpgsig -----BEGIN PGP SIGNATURE-----
...
-----END PGP SIGNATURE-----

Add test file
```

---

## Object Type Explanation

* **Blob** — Stores raw file content (no filename, no metadata).
* **Tree** — Represents directory structure, mapping filenames to blobs and subtrees.
* **Commit** — Points to a tree and contains metadata (author, timestamp, parent commit, signature, message).

### Analysis

Git stores repository data as a content-addressable object database.
Each object (blob, tree, commit) is identified by its SHA-1 hash.

* A commit references a tree.
* A tree references blobs and other trees.
* Blobs store file content.

This design ensures immutability and integrity: if file content changes, its hash changes, producing a new blob and consequently a new tree and commit.

---

# Task 2 — Reset and Reflog Recovery

## 2.1 Practice Branch Setup

```bash
git switch -c git-reset-practice
echo "First commit" > file.txt && git add file.txt && git commit -m "First commit"
echo "Second commit" >> file.txt && git add file.txt && git commit -m "Second commit"
echo "Third commit"  >> file.txt && git add file.txt && git commit -m "Third commit"
```

---

## 2.2 Reset Modes Exploration

### Commands Executed

```bash
git reset --soft HEAD~1
git reset --hard HEAD~1
git reflog
git reset --hard 4cdfed2
```

### Reset Output

```
HEAD is now at 1e1c32b feat: update structure
HEAD is now at 4cdfed2 Third commit
```

---

## Behavior Analysis

### `git reset --soft HEAD~1`

* Moves HEAD to previous commit.
* Keeps index and working tree unchanged.
* Changes remain staged.

### `git reset --hard HEAD~1`

* Moves HEAD to previous commit.
* Resets index and working tree.
* Discards uncommitted changes.

### Recovery Using Reflog

`git reflog` records every HEAD movement.
Even after a hard reset, previous commit references remain in reflog.

Using:

```bash
git reset --hard 4cdfed2
```

I restored the branch to the commit labeled "Third commit".

### Recovery Insight

Reflog acts as a safety net for destructive operations.
Even when commits appear lost from history, they remain recoverable until garbage collection removes them.

---

# Task 3 — Visualizing Commit History

## Commands

```bash
git switch -c side-branch
echo "Branch commit" >> history.txt
git add history.txt && git commit -m "Side branch commit"
git switch -
git log --oneline --graph --all
```

## Graph Output

```
* 9449fc4 (side-branch) Side branch commit
* 4cdfed2 (HEAD -> git-reset-practice) Third commit
* 8b322ef Second commit
* 7afc81f First commit
* a867c63 (Feature/lab2) Add test file
| * b7c6b5c (origin/Feature/lab1, Feature/lab1) Feature: Lab 1
| * 7313965 Lab 1 submission
|/
* d6b6a03 (origin/main, origin/HEAD, main) Update lab2
...
```

## Reflection

The `--graph` option visually represents branch divergence and commit ancestry.
It clarifies how branches relate to each other and helps detect merge bases, parallel development, and branch structure.

---

# Task 4 — Tagging Commits

## Commands

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Push Output

```
[new tag]         v1.0.0 -> v1.0.0
```

## Purpose of Tags

Tags provide stable references to specific commits.
They are essential for:

* Versioning releases
* Triggering CI/CD pipelines
* Creating reproducible builds
* Generating release notes

Unlike branches, tags do not move after creation.

---

# Task 5 — git switch vs git checkout vs git restore

## Branch Switching

### Modern Approach

```bash
git switch -c cmd-compare
git switch -
```

Output:

```
Switched to a new branch 'cmd-compare'
Switched to branch 'Feature/lab2'
```

### Legacy Approach

```bash
git checkout -b cmd-compare-2
```

Output:

```
Switched to a new branch 'cmd-compare-2'
```

---

## File Restoration

```bash
echo "scratch" >> demo.txt
git restore demo.txt
git restore --staged demo.txt
git restore --source=HEAD~1 demo.txt
```

Output:

```
error: pathspec 'demo.txt' did not match any file(s) known to git
```

This error occurred because `demo.txt` was never staged or committed, therefore Git had no tracked version to restore from.

---

## Command Comparison

### `git switch`

* Branch management only.
* Clear and purpose-focused.

### `git checkout`

* Overloaded (branches + file restore).
* Historically confusing.

### `git restore`

* File restoration only.
* Explicit separation of responsibilities.

### When to Use Each

* Use **`git switch`** for branch operations.
* Use **`git restore`** for file-level state recovery.
* Avoid `git checkout` in new workflows for clarity and maintainability.

Modern Git separates concerns, reducing ambiguity and improving command ergonomics.

---

# Task 6 — GitHub Community Engagement

I starred the course repository and the `simple-container-com/api` project.
I followed the professor, TAs, and classmates.

## Why Starring Matters

Stars serve as bookmarks and signals of trust.
They increase project visibility and demonstrate engagement with quality open-source tools.

## Why Following Matters

Following developers improves:

* Professional networking
* Awareness of ongoing work
* Collaboration opportunities
* Exposure to best practices

Active participation in GitHub’s ecosystem strengthens both technical growth and professional presence.

---

# Conclusion

This lab deepened my understanding of:

* Git’s internal object storage model
* Safe history rewriting and recovery mechanisms
* Branch visualization techniques
* Semantic versioning with tags
* Modern Git command design

The exercises reinforced Git as a content-addressable, immutable data system with powerful recovery guarantees and improved modern ergonomics.
