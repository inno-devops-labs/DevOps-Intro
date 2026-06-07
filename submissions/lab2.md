# Lab 2 Submission — Yury Rybenko

## Task 1 — Git Object Model + Reflog Recovery

### 1.1: Exploring the repo's plumbing

**Step 1: Get HEAD SHA**
```
$ git rev-parse HEAD
3c777e89f7faf2a1552d0cf9b67d387039f3aeb3
```

**Step 2: Type and content of the commit object**
```
$ git cat-file -t HEAD
commit

$ git cat-file -p HEAD
tree b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
parent b26df80dda8d8bec302d179e2da16e634ad69af9
author Ten-Do <107281193+Ten-Do@users.noreply.github.com> 1780757801 +0300
committer GitHub <noreply@github.com> 1780757801 +0300
gpgsig -----BEGIN PGP SIGNATURE-----
 ...
 -----END PGP SIGNATURE-----

Update pull_request_template.md
```

**Step 3: Inspect the tree object**
```
$ git cat-file -p b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 6db686e340ecdd318fa43375e26254293371942a	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
```

**Step 4: Inspect the blob for README.md**
```
$ git cat-file -t d10c04c6e7e0014f4fe883599c11747c15012d4e
blob

$ git cat-file -p d10c04c6e7e0014f4fe883599c11747c15012d4e
# DevOps Intro — Modern DevOps Practices Through One Project
...
(full contents of README.md)
```

**Chain summary:** `HEAD` (commit `3c777e8`) → tree `b2fe0c7` → blob `d10c04c` → `README.md` file contents.

Each Git commit points to a tree snapshot; the tree lists blobs (files) and sub-trees (directories) by their SHA-1; blobs contain the raw file data. Nothing is stored by filename — only by content hash.

---

### 1.2: Looking inside `.git/`

```
$ ls -la .git/
total 32
drwxr-xr-x. 1 tend tend  192 Jun  7 15:07 .
drwxr-xr-x. 1 tend tend  104 Jun  7 15:03 ..
-rw-r--r--. 1 tend tend   76 Jun  6 18:35 COMMIT_EDITMSG
-rw-r--r--. 1 tend tend  717 Jun  7 15:06 config
-rw-r--r--. 1 tend tend   73 Jun  6 15:37 description
-rw-r--r--. 1 tend tend  201 Jun  7 15:05 FETCH_HEAD
drwxr-xr-x. 1 tend tend   12 Jun  7 15:05 gk
-rw-r--r--. 1 tend tend   29 Jun  7 15:06 HEAD
drwxr-xr-x. 1 tend tend  556 Jun  6 15:37 hooks
-rw-r--r--. 1 tend tend 3183 Jun  7 15:06 index
drwxr-xr-x. 1 tend tend   14 Jun  6 15:37 info
drwxr-xr-x. 1 tend tend   16 Jun  6 15:37 logs
drwxr-xr-x. 1 tend tend  228 Jun  7 15:05 objects
-rw-r--r--. 1 tend tend   41 Jun  7 15:03 ORIG_HEAD
-rw-r--r--. 1 tend tend  112 Jun  6 15:37 packed-refs
drwxr-xr-x. 1 tend tend   42 Jun  6 15:45 refs

$ cat .git/HEAD
ref: refs/heads/feature/lab2

$ ls .git/refs/heads/
feature  main

$ ls .git/refs/heads/feature/
lab1  lab2

$ ls .git/objects/ | head
0a
0b
0c
0e
0f
13
16
18
1a
1d

$ find .git/objects -type f | wc -l
68
```

**Interpretation:**

- `.git/HEAD` contains `ref: refs/heads/feature/lab2` — a symbolic ref telling Git which branch is currently checked out.
- `.git/refs/heads/` stores one file per local branch; each file contains the SHA of the tip commit.
- `.git/objects/` stores all objects (commits, trees, blobs, tags) as zlib-compressed files, sharded into 256 subdirectories by the first two hex characters of their SHA. Here we have 68 loose objects.
- `packed-refs` lists refs that have been packed (remote-tracking branches and tags consolidated into a single file by `git pack-refs`).
- `index` is the staging area — a binary file mapping the working tree state for the next commit.
- `logs/` contains the reflog — a chronological record of every HEAD movement.

---

### 1.3: Simulate disaster + recover

**Setup — two commits on `feature/lab2`:**
```
$ echo "important work" > submissions/lab2.md
$ git add submissions/lab2.md
$ git commit -S -s -m "wip(lab2): start"
[feature/lab2 6fa362b] wip(lab2): start
 1 file changed, 1 insertion(+)
 create mode 100644 submissions/lab2.md

$ echo "more important work" >> submissions/lab2.md
$ git commit -S -s -am "wip(lab2): more progress"
[feature/lab2 376e694] wip(lab2): more progress
 1 file changed, 1 insertion(+)
```

**The disaster:**
```
$ git reset --hard HEAD~2
HEAD is now at 3c777e8 Update pull_request_template.md

$ git status
On branch feature/lab2
nothing to commit, working tree clean

$ git log --oneline -3
3c777e8 Update pull_request_template.md
b26df80 docs: add PR template
66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
```

Both commits appear to be gone.

**Recovery via reflog:**
```
$ git reflog
3c777e8 HEAD@{0}: reset: moving to HEAD~2
376e694 HEAD@{1}: commit: wip(lab2): more progress
6fa362b HEAD@{2}: commit: wip(lab2): start
3c777e8 HEAD@{3}: checkout: moving from main to feature/lab2
3c777e8 HEAD@{4}: pull: Fast-forward
b26df80 HEAD@{5}: checkout: moving from feature/lab1 to main
...
```

The commits are still reachable — `376e694` (the latest) is visible at `HEAD@{1}`.

**Restore:**
```
$ git reset --hard 376e694
HEAD is now at 376e694 wip(lab2): more progress

$ git status
On branch feature/lab2
nothing to commit, working tree clean

$ git log --oneline -3
376e694 wip(lab2): more progress
6fa362b wip(lab2): start
3c777e8 Update pull_request_template.md
```

Everything is back.

**What if `git gc` had run between the bad reset and the recovery?**

`git gc` prunes objects that are not reachable from any ref and are older than the grace period (default: 14 days for `gc.pruneExpire`, 30 days for reflog entries via `gc.reflogExpire`). In a standard local setup the reflog entries themselves protect the dangling commits for 30 days, so `gc` would not delete them — recovery would still work. However, in CI/CD environments or repos configured with aggressive GC settings (`gc.reflogExpire=now` or `gc.pruneExpire=now`), `git gc --prune=now` would permanently delete any commits unreachable from a ref, making recovery impossible without an external backup. The safe practice is: **capture the SHA from `git reflog` before experimenting with reset**, so you can restore even if gc has run.

---

## Task 2 — Tag a Release & Rebase a Feature

### 2.1: Annotated, signed release tag

```
$ git switch main
$ git pull --ff-only upstream main
Already up to date.

$ git tag -a -s "v0.1.0-lab2-tend" -m "Lab 2 milestone — version control deep dive"

$ git push origin "v0.1.0-lab2-tend"
To github.com:Ten-Do/DevOps-Intro.git
 * [new tag]         v0.1.0-lab2-tend -> v0.1.0-lab2-tend
```

**Tag type verification:**
```
$ git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'
v0.1.0-lab2-tend tag commit
```

`objecttype` is `tag` (an annotated tag object) and `*objecttype` is `commit` (the tagged commit) — confirming it is an annotated tag, not a lightweight one.

**Signature verification:**
```
$ git tag -v "v0.1.0-lab2-tend"
Good "git" signature for rybenko.urii@gmail.com with RSA key SHA256:5+QHMVYRnfNneCLqbLVqF/WRPbn4KvwSiMxoL/s2UkE
object 3c777e89f7faf2a1552d0cf9b67d387039f3aeb3
type commit
tag v0.1.0-lab2-tend
tagger yury <rybenko.urii@gmail.com> 1780834585 +0300

Lab 2 milestone — version control deep dive
```

Signature is **Good** — SSH-signed with the configured key.

---

### 2.2: Rebase + force-with-lease

**`git log --oneline --graph` BEFORE rebase** (feature/lab2 branched off `3c777e8`):
```
* e0fdd0b wip(lab2): more progress
* 6fa362b wip(lab2): start
* 3c777e8 Update pull_request_template.md
* b26df80 docs: add PR template
* 66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
```

**Simulating upstream move:**
```
$ git switch main
$ git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
[main c4d4a97] docs: upstream moved while you worked

$ git push origin main
   3c777e8..c4d4a97  main -> main
```

**Rebase:**
```
$ git switch feature/lab2
$ git fetch origin
$ git rebase origin/main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/lab2.
```

**`git log --oneline --graph` AFTER rebase** (feature/lab2 replayed on top of `c4d4a97`):
```
* 3a06aa5 wip(lab2): more progress
* 854830c wip(lab2): start
* c4d4a97 docs: upstream moved while you worked
* 3c777e8 Update pull_request_template.md
* b26df80 docs: add PR template
* 66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
```

**Force-push:**
```
$ git push --force-with-lease origin feature/lab2
 * [new branch]      feature/lab2 -> feature/lab2
```

---

### 2.3: Merge vs Rebase reflection

**Choose rebase when:** you own a feature branch that hasn't been shared with teammates (or everyone on the team knows to expect rewrites). Rebase produces a clean, linear history that is easy to `git bisect` and `git log` through. It's the right call before merging a short-lived feature branch into `main` in a project that enforces linear history.

**Choose merge when:** the branch is shared / public — rewriting commits that others have based work on will cause diverging histories and force-push pain. Merge also preserves the exact context of *when* and *from where* integration happened, which can matter for audit trails or for long-running release branches that must accept hotfixes.

---

## Bonus Task — Bisect a Real Bug

### B.1 + B.2: Bisect setup and automated run

The `bug/bisect-me` branch on upstream contains 4 commits after the `v0.0.1` baseline. Confirming HEAD is broken:

```
$ cd app && go test ./...
--- FAIL: TestStore_PersistsAcrossReload (0.00s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL	quicknotes	0.008s
```

**Bisect session:**
```
$ git bisect start
$ git bisect bad HEAD
$ git bisect good v0.0.1
Bisecting: 1 revision left to test after this (roughly 1 step)
[f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()

$ git bisect run sh -c 'cd app && go test ./... && go build ./...'
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
--- FAIL: TestStore_PersistsAcrossReload (0.00s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL	quicknotes	0.008s
FAIL
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
ok  	quicknotes	0.007s
f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
commit f285ede8611e55ac0a7d01100891c0cc775e0709
Author: Dmitrii Creed <creeed22@gmail.com>
Date:   Fri Jun 5 13:36:56 2026 +0400

    refactor(store): simplify nextID restoration in load()

 app/store.go | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first bad commit

$ git bisect reset
```

**Full `git bisect log`:**
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

---

### B.3: The offending commit

**SHA:** `f285ede8611e55ac0a7d01100891c0cc775e0709`  
**Message:** `refactor(store): simplify nextID restoration in load()`

**Diff:**
```diff
-		if n.ID >= s.nextID {
+		if n.ID > s.nextID {
 			s.nextID = n.ID + 1
 		}
```

**The bug:** changing `>=` to `>` means that when the store reloads from disk and the last saved ID equals `nextID` (the initial value of 0), the `nextID` is no longer updated. After reload, `nextID` stays at 1 instead of advancing past the highest existing ID, causing new notes to get ID 1 — colliding with an already-stored note. The test `TestStore_PersistsAcrossReload` catches this: it creates a note (ID=1), reloads, and expects `nextID=2`, but gets `1`.

**How bisect found it in log₂(N) steps:**

With 4 commits in the suspect range, bisect needs at most ⌈log₂(4)⌉ = 2 test rounds. In round 1 it checked the midpoint commit `f285ede` — tests failed → marked bad. In round 2 it checked the commit below that midpoint `cb89bb9` — tests passed → marked good. With bad and good adjacent, bisect concludes `f285ede` is the first bad commit. This binary search strategy guarantees at most ⌈log₂(N)⌉ test executions regardless of N, compared to O(N) for linear grep-based debugging.
