# Lab 2 — Submission

## Task 1 — Git Object Model Exploration

### Commit Object

```text
git cat-file -p HEAD

5aa7beb (HEAD -> feature/lab2) Add test file
tree e01190a54fada311e728a373704607500bb584da
parent de7445dfd8c71b2de3f7ada4687dbc6fb32f09c2
author krasand <krasnovandrej4802@gmail.com>
committer krasand <krasnovandrej4802@gmail.com>
gpgsig -----BEGIN SSH SIGNATURE-----
...
-----END SSH SIGNATURE-----

Add test file
```

### Tree Object

```text
git cat-file -p e01190a54fada311e728a373704607500bb584da

040000 tree 20a69a4c10cd24afe3af16e1ec9d5c8648a66935    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree eeb14f2b4120f6de2400033aad74b1a1de159c0e    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 862cea48ff9bff97be940756b0ea9aa0cfb7e256    test.txt
```

### Blob Object

```text
git cat-file -p 862cea48ff9bff97be940756b0ea9aa0cfb7e256

Test content
```

---

### Explanation of Git Objects

- **Blob** — stores the raw content of a file. It does not store the filename, only the file data.
- **Tree** — represents a directory. It contains filenames and references (hashes) to blobs or other trees.
- **Commit** — represents a snapshot of the project. It references a tree object and contains metadata such as author, parent commit, and commit message.

---

### Analysis

Git stores repository data as immutable objects identified by SHA hashes.  
A commit points to a tree object, which represents the project structure at that moment.  
The tree object points to blob objects that contain the actual file contents.  

This object-based storage model allows Git to efficiently track changes, reconstruct any previous state of the repository, and ensure data integrity through cryptographic hashing.

## Task 2 — Reset and Reflog Recovery

### Commands I ran (practice branch)

```text
git switch -c git-reset-practice
echo "First commit" > file.txt && git add file.txt && git commit -m "First commit"
echo "Second commit" >> file.txt && git add file.txt && git commit -m "Second commit"
echo "Second commit" >> file.txt && git add file.txt && git commit -m "Second commit"   # (accidental extra commit)
git reset --soft HEAD~1
git reset --hard HEAD~1
git reflog
git reset --hard 949c510
```

### `git log --oneline` snippet (practice branch)

```text
949c510 (HEAD -> git-reset-practice, tag: v1.0.0, cmd-compare) Second commit
1c3bfd3 Second commit
f05eb28 First commit
```

### `git reflog` snippet (shows HEAD movement and recovery)

```text
949c510 HEAD@{7}: reset: moving to 949c510
f05eb28 HEAD@{8}: reset: moving to HEAD~1
1c3bfd3 HEAD@{9}: reset: moving to HEAD~1
949c510 HEAD@{10}: commit: Second commit
1c3bfd3 HEAD@{11}: commit: Second commit
f05eb28 HEAD@{12}: commit: First commit
```

### What changed in working tree, index, and history

- `git reset --soft HEAD~1` moved `HEAD` back by one commit, but **kept the changes staged** (index unchanged, working tree unchanged). This is useful when you want to edit/rewrite the last commit message or combine commits.
- `git reset --hard HEAD~1` moved `HEAD` back and **discarded staged and working tree changes**. This is destructive and should be used carefully.
- `git reflog` recorded every movement of `HEAD`, including resets. Even after a hard reset, the “lost” commit hashes still appeared in reflog, so I could recover the repository state using:
  - `git reset --hard 949c510`

### Short recovery analysis

`git reflog` is a safety net: it tracks previous `HEAD` positions and allows recovery of commits that are no longer visible in `git log` after reset operations. In this task, reflog allowed me to restore the repository back to commit `949c510`.

## Task 3 — Visualize Commit History

### Graph output (`git log --oneline --graph --all`)

```text
* 7ce8594 (side-branch) Side branch commit
* 949c510 (tag: v1.0.0, git-reset-practice, cmd-compare) Second commit
* 1c3bfd3 Second commit
* f05eb28 First commit
* 5aa7beb (HEAD -> feature/lab2) Add test file
* de7445d (origin/main, origin/HEAD, main) chore: add pull request template
* a6287c2 Create test
| * 3ad4db2 (origin/feature/lab1) docs: complete lab1 submission
| * b0ad4bc (feature/lab1) docs: explain importance of signed commits
| * 78fbf16 docs: add lab1 submission skeleton
|/
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10
* 1826c36 feat: update lab7
* 3049f08 feat: publish lec8
* da8f635 feat: introduce all labs and revised structure
* 04b174e feat: publish lab and lec #5
* 67f12f1 feat: publish labs 4&5, revise others
* 82d1989 feat: publish lab3 and lec3
* 3f80c83 feat: publish lec2
* 499f2ba feat: publish lab2
* af0da89 feat: update lab1
* 74a8c27 Publish lab1
* f0485c0 Publish lec1
* 31dd11b Publish README.md
```

### Commit messages shown in the graph
- Side branch commit
- First commit / Second commit(s) (practice history)
- Add test file
- chore: add pull request template
- docs: explain importance of signed commits (lab1 history)

### Reflection
The graph view makes it easier to understand how branches diverge and where `HEAD` currently points.  
It helps visually track parallel work (feature branches) and makes it clear which commits belong to which branch.

## Task 4 — Tagging Commits

### Commands + outputs

```text
git tag v1.0.0
git show v1.0.0 --no-patch
git tag
```

```text
commit 949c51056fa1715903783cddd0e44cca8c4e3ce1 (tag: v1.0.0)
Author: krasand <krasnovandrej4802@gmail.com>
Date:   Fri Feb 13 14:36:34 2026 +0300

    Second commit

v1.0.0
```

### Why tags matter
Tags provide a stable name for a specific commit (for example, a release version).  
They are useful for versioning, release notes, and CI/CD pipelines that build or deploy based on version tags.

## Task 5 — git switch vs git checkout vs git restore

### Commands used

```text
git switch -c cmd-compare
git switch -
git branch
git status

echo "scratch" >> demo.txt
git add demo.txt
git restore --staged demo.txt
git restore demo.txt
```

### Observed behavior

- `git switch -c cmd-compare` created and switched to a new branch.
- `git switch -` returned to the previous branch.
- After modifying `demo.txt`, `git add` staged the file.
- `git restore --staged demo.txt` removed the file from the staging area.
- `git restore demo.txt` discarded changes from the working directory.

### When to use each command

- **git switch** — used only for switching or creating branches. It is clear and focused on branch operations.
- **git restore** — used for restoring files in the working directory or staging area.
- **git checkout** — a legacy command that can both switch branches and restore files, which can be confusing because it has multiple responsibilities.

Modern Git separates responsibilities between `switch` (branches) and `restore` (files), making commands safer and easier to understand.

## Task 6 — GitHub Community

I starred the course repository and the `simple-container-com/api` project, 
followed the professor and teaching assistants, and followed at least three classmates.

Starring repositories helps signal interest, bookmark useful projects, 
and support open-source maintainers. Following developers helps with networking, 
learning from others’ work, and staying updated on project activity.