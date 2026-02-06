# Lab 2 Submission

## Task 1

### Finding Object Hashes

First, I retrieved the commit hash and inspected the commit object to find the tree and blob hashes (I've blurred SSH key in the screenshot):

![Finding object hashes](img/hashes.png)


### Inspecting Git Objects

![Inspecting blob, tree, and commit objects](img/inspect.png)


A blob (Binary Large Object) stores the raw content of a file without any metadata like filename or permissions. It represents a snapshot of file contents at a specific point in time.

A tree object represents a directory snapshot. It contains entries with file mode, object type (blob or tree), SHA-1 hash, and filename — essentially mapping names to blobs (files) or other trees (subdirectories).

A commit object contains a pointer to the root tree (project snapshot), parent commit(s), author/committer metadata with timestamps, an optional GPG/SSH signature, and the commit message.

### Analysis: How Git Stores Data

Git uses a content-addressable filesystem based on SHA-1 hashes. The storage model consists of three core object types:

1. Blobs — store file contents only (no filenames)
2. Trees — store directory structure, mapping names to blobs and subtrees
3. Commits — store metadata and point to a tree representing the project state

This design enables:
- Deduplication: Identical file contents share the same blob hash
- Integrity: Any change produces a completely different hash
- Efficient storage: Objects are compressed and stored in `.git/objects/`

## Task 2

### Creating Practice Branch

I created a new branch and made three commits to practice reset operations:


![Creating practice branch with 3 commits](img/new_branch.png)

**Commits created:**
- `8007b92` — First commit
- `3f43a54` — Second commit
- `18903b4` — Third commit

### Exploring Reset Modes

#### Soft Reset

![Soft reset result](img/soft_reset.png)

What changed:
- HEAD: Moved back one commit (from Third to Second commit)
- Index (staging area): Unchanged — "Third commit" changes remain staged
- Working tree: Unchanged — file.txt still contains all three lines

The soft reset is useful when you want to undo a commit but keep all changes staged for recommitting (e.g., to amend the commit message or combine with other changes).

#### Hard Reset


![Hard reset result](img/hard_reset.png)

What changed:
- HEAD: Moved back one commit (to First commit `8007b92`)
- Index (staging area): Reset to match the target commit
- Working tree: Reset to match the target commit — all changes discarded

The hard reset completely discards all changes after the target commit. This is destructive and should be used with caution.

### Recovery with Reflog

After the hard reset, the commits appeared "lost." I used `git reflog` to find the previous HEAD positions:

![Reflog showing HEAD movement history](img/reflog.png)

The reflog shows every HEAD movement including:
- `HEAD@{0}`: reset: moving to HEAD~1
- `HEAD@{1}`: reset: moving to HEAD~1  
- `HEAD@{2}`: commit: Third commit
- `HEAD@{3}`: commit: Second commit
- `HEAD@{4}`: commit: First commit

#### Recovering Lost Commits

Using the reflog hash, I recovered to the original state:

![Recovery using reflog hash](img/hard_reset_hash.png)

Result: HEAD is now at `892a0e2` (Add test file) — successfully recovered to feature/lab2 branch state.

### Git Log After Operations

![Git log showing commit history](img/log.png)

### Analysis

| Reset Mode | HEAD | Index | Working Tree | Use Case |
|------------|------|-------|--------------|----------|
| `--soft`   | Moves | Unchanged | Unchanged | Redo commit message, combine commits |
| `--mixed` (default) | Moves | Resets | Unchanged | Unstage changes, keep edits |
| `--hard`   | Moves | Resets | Resets | Completely discard changes |

Key takeaway: `git reflog` is a safety net that tracks all HEAD movements, allowing recovery even after destructive operations like `git reset --hard`.

