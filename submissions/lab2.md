# Lab 2 Submission — Version Control Deep Dive

## Task 1 — Git Object Model + Reflog Recovery

### 1.1: HEAD → Tree → Blob → File chain

```
$ git rev-parse HEAD
1b1adf87c44a7a5c34fcb041e6ba669a5a8161d8

$ git cat-file -t HEAD
commit

$ git cat-file -p HEAD
tree 54501682022264ae3ea92335094dbce0a518791e
parent 66bbd4db9228bc9a4cab7439746b993749c026ab
author rikire <rizireY@yandex.ru> 1781026785 +0300
committer rikire <rizireY@yandex.ru> 1781026785 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgEbNXjC/2HryeFKz+FlQwiL4bft
 NeVmhFJAJ83nJDVGoAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQMMzPT8+tWntM4nC6qomHeXfvgr98KzUBipwWQMcCCcMh48etwiOf9g2OF+kVnqVRq
 jqg2hA4oxwpnyDuHkAZgs=
 -----END SSH SIGNATURE-----

docs: add PR template

Signed-off-by: rikire <rizireY@yandex.ru>

$ git cat-file -p 54501682022264ae3ea92335094dbce0a518791e
040000 tree 2c6ca2d310a2decda5bd5063999dee0fc5eb472f	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 6db686e340ecdd318fa43375e26254293371942a	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures

$ git cat-file -p d10c04c6e7e0014f4fe883599c11747c15012d4e
# DevOps Intro — Modern DevOps Practices Through One Project
...
(README.md raw file contents)
```

**Chain:** `HEAD` (commit `1b1adf8`) → tree `5450168` → blob `d10c04c` (README.md) → file contents.
Each object is addressed by the SHA-1 of its content: a commit points to a tree, a tree lists blobs and sub-trees, a blob holds raw file bytes.

---

### 1.2: `.git/` directory internals

```
$ ls -la .git/
drwxr-xr-x  COMMIT_EDITMSG   — last commit message
-rw-r--r--  FETCH_HEAD       — SHAs fetched from remote
-rw-r--r--  HEAD             — points to current branch ref
-rw-r--r--  ORIG_HEAD        — previous HEAD before destructive op
-rw-r--r--  config           — repo-level git config
drwxr-xr-x  hooks/           — client-side hook scripts
-rw-r--r--  index            — staging area (binary)
drwxr-xr-x  logs/            — reflog data
drwxr-xr-x  objects/         — all git objects (blobs, trees, commits, tags)
-rw-r--r--  packed-refs      — compacted refs for efficiency
drwxr-xr-x  refs/            — human-readable branch/tag pointers

$ cat .git/HEAD
ref: refs/heads/main

$ ls .git/refs/heads/
feature/  main

$ ls .git/objects/ | head
06  0a  0c  0e  0f  13  16  1a  1b  22  2c  ...
(subdirs named by first 2 hex chars of SHA)

$ find .git/objects -type f | wc -l
56
```

**Interpretation:** `.git/HEAD` is a symbolic ref pointing at the current branch. `refs/heads/` maps branch names to commit SHAs. The `objects/` store uses a two-level directory scheme (first 2 chars of SHA as dir, remaining 38 as filename) to avoid huge flat directories. `packed-refs` compacts many refs into one file for efficiency. `logs/` holds the reflog — a journal of every HEAD movement, enabling recovery even after destructive operations.

---

### 1.3: Disaster simulation + recovery

```
$ git switch -c feature/lab2
$ echo "important work" > submissions/lab2.md
$ git add submissions/lab2.md
$ git commit -S -s -m "wip(lab2): start"
[feature/lab2 9c16f68] wip(lab2): start

$ echo "more important work" >> submissions/lab2.md
$ git commit -S -s -am "wip(lab2): more progress"
[feature/lab2 50b31cb] wip(lab2): more progress

# Disaster:
$ git reset --hard HEAD~2
HEAD is now at 1b1adf8 docs: add PR template

$ git status
nothing to commit, working tree clean

$ git log --oneline -3
1b1adf8 docs: add PR template
...

$ git reflog | head -8
1b1adf8 HEAD@{0}: reset: moving to HEAD~2
50b31cb HEAD@{1}: commit: wip(lab2): more progress
9c16f68 HEAD@{2}: commit: wip(lab2): start
1b1adf8 HEAD@{3}: checkout: moving from main to feature/lab2
...

# Recovery:
$ git reset --hard 50b31cb
HEAD is now at 50b31cb wip(lab2): more progress

$ git status
nothing to commit, working tree clean
```

**gc-window risk:** If `git gc` had run between the bad reset and the recovery, Git would have pruned objects unreachable from any ref or reflog entry. By default, reflog entries expire after 30 days and unreachable objects after 14 days (`gc.pruneExpire`). In a normal local repo we'd be safe within that window. In CI environments where `gc --prune=now` or `gc --aggressive` is configured, the objects could be deleted immediately — making recovery impossible without a backup. **The safeguard is to capture the SHA from `git reflog` before doing any experimental resets.**

---

## Task 2 — Tag a Release & Rebase a Feature

### 2.1: Signed annotated tag

```
$ git tag -a -s "v0.1.0-lab2-rikire" -m "Lab 2 milestone — version control deep dive"

$ git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'
v0.0.1 tag commit
v0.1.0-lab2-rikire tag commit

$ git tag -v "v0.1.0-lab2-rikire"
object 1b1adf87c44a7a5c34fcb041e6ba669a5a8161d8
type commit
tag v0.1.0-lab2-rikire
tagger rikire <rizireY@yandex.ru> 1781030251 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for rizireY@yandex.ru with ED25519 key SHA256:Us9/3OQQhW1AtBi9vmiPx2Lj41t52Vu0WwsqEajJoEU
```

Tag is annotated (objecttype `tag`, not `commit`) and carries a valid SSH signature verified as **Good**.

---

### 2.2: Rebase onto upstream-moved main

**Before rebase** (`git log --oneline --graph`):

```
* 77748ba docs: upstream moved while you worked   <- main
| * 50b31cb wip(lab2): more progress              <- feature/lab2
| * 9c16f68 wip(lab2): start
|/
* 1b1adf8 docs: add PR template
```

```
$ git switch feature/lab2
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/lab2.

$ git push --force-with-lease origin feature/lab2
```

**After rebase:**

```
* eaa7bc7 wip(lab2): more progress   <- feature/lab2
* 61fcd82 wip(lab2): start
* 77748ba docs: upstream moved while you worked
* 1b1adf8 docs: add PR template
```

The two feature commits were replayed on top of the new `main` commit. No merge commit was created; history is linear.

**Merge vs Rebase:** Rebase is preferable when preparing a feature branch for review — it produces clean, linear history that is easy to read and bisect. Merge is preferable when preserving the true topology of parallel work matters (e.g., long-lived integration branches, or when audit trails require the exact branch-and-merge structure). On shared branches that others have already pulled, rebase rewrites SHAs and requires a force-push, so merge is safer there.

---

## Bonus — git bisect

### Setup and automated run

```
$ git fetch upstream
$ git switch -c bisect-quickn upstream/bug/bisect-me
$ git bisect start
$ git bisect bad HEAD
$ git bisect good v0.0.1
Bisecting: 1 revision left to test after this (roughly 1 step)
[f285ede] refactor(store): simplify nextID restoration in load()
```

Manual testing at each step (`cd app && go test ./...`):
- `f285ede` — FAIL (`TestStore_PersistsAcrossReload: nextID not restored: got 1, want 2`) — `git bisect bad`
- `cb89bb9` — PASS — `git bisect good`

### Full bisect log

```
git bisect start
# bad: [f0c9243b7c80ebb930a1ce7048a1d65b4c2ac493] docs(app): mention go test invocation
git bisect bad f0c9243b7c80ebb930a1ce7048a1d65b4c2ac493
# good: [0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7] chore(app): document versioning scheme (bisect fixture baseline)
git bisect good 0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7
# bad: [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
git bisect bad f285ede8611e55ac0a7d01100891c0cc775e0709
# good: [cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
git bisect good cb89bb9ee2ee5010b166061447eaca3ae0da2378
# first bad commit: [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
```

### Offending commit

```
SHA:     f285ede8611e55ac0a7d01100891c0cc775e0709
Message: refactor(store): simplify nextID restoration in load()
Author:  Dmitrii Creed <creeed22@gmail.com>
File:    app/store.go (1 line changed)
```

### How bisect finds the bug in log₂(N) steps

Git bisect performs binary search over the commit history. With N commits between the known-good and known-bad endpoints, it always checks out the midpoint commit, halving the search space on each answer. This yields at most ⌈log₂(N)⌉ test steps regardless of N. In this case, 4 commits between good and bad required only 2 manual steps (log₂(4) = 2). This makes bisect dramatically faster than grepping through a linear blame or checking out commits one-by-one — a 1 000-commit history takes at most 10 tests, a 1 000 000-commit history at most 20.
