# Lab 2 submission

## Task 1 — Git Object Model + Reflog Recovery (6 pts)

### 1.1: Explore repo's plumbing

```
❯ git rev-parse HEAD
ad828535882b5b65b81851ad6ff7c776ff2a0137

❯ git cat-file -t HEAD
commit

❯ git cat-file -p HEAD
tree 9635bac0b51ebff88ea2ee0c92c31d1f3d8a855e
parent 1c15047691658c2910f5eb7701ee26a5f1c55258
author Timofey Sedov <moflotas@gmail.com> 1781037387 +0300
committer Timofey Sedov <moflotas@gmail.com> 1781037599 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
...

docs(lab1): solve last task

Signed-off-by: Timofey Sedov <moflotas@gmail.com>

❯ git cat-file -p 9635bac0b51ebff88ea2ee0c92c31d1f3d8a855e
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 6db686e340ecdd318fa43375e26254293371942a	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
040000 tree 1e3d01b73f6642ed5a0f3eb4990783dd92caa050	submissions

❯ git cat-file -p 7d0898a908e274ea809722844cdbd836f3b1c05a | head -10
100644 blob e1e49085a4f70e21b78c9f87863d858dc3c6d214	.gitignore
100755 blob 60df71284fece3a69c2fbbe995a838a9f1a1d89f	Makefile
100644 blob a6f4021c1771b3b2e5ff9a5fe83a9a4a2915ec3f	README.md
100644 blob 5522a1c9acb31c6e44c0ec4ae6b8c55bb1b92bb2	handlers.go
100644 blob 730a1dd55a30b41a2a573428935b1ebe6ef4889f	handlers_test.go
100644 blob 5e8faf160f28a0cb4eac7f449b3d92752e0e0a9b	main.go
100644 blob 7a35b8c689c2c21c2eacaf3747be72e8baff1a0a	seed.json
100644 blob c7964128c8e03b14ff7d6fc9e9db30b9300362c1	store.go
100644 blob 2e6df2ae5bc229fa7966f23a4da89ee58cad0b3c	store_test.go

❯ git cat-file -p 5e8faf160f28a0cb4eac7f449b3d92752e0e0a9b | head -5
package main

import (
	"context"
	"encoding/json"
```

**Chain:** `HEAD` (commit `ad82853`) → `tree 9635bac0` → `tree 7d0898a9` (app) → `blob 5e8faf16` (main.go) → file contents

### 1.2: Look inside `.git/`

```
❯ ls -la .git/
total 72
drwxr-xr-x  16 moflotas  staff   512 Jun  9 23:46 .
drwxr-xr-x  11 moflotas  staff   352 Jun  9 23:45 ..
-rw-r--r--   1 moflotas  staff    79 Jun  9 23:36 COMMIT_EDITMSG
-rw-r--r--   1 moflotas  staff   792 Jun  9 16:59 FETCH_HEAD
-rw-r--r--   1 moflotas  staff    29 Jun  9 23:45 HEAD
-rw-r--r--   1 moflotas  staff    41 Jun  9 23:39 ORIG_HEAD
-rw-r--r--   1 moflotas  staff   503 Jun  9 23:43 config
-rw-r--r--   1 moflotas  staff    73 Jun  9 16:57 description
drwxr-xr-x  16 moflotas  staff   512 Jun  9 16:57 hooks
-rw-r--r--   1 moflotas  staff  3995 Jun  9 23:46 index
drwxr-xr-x   3 moflotas  staff    96 Jun  9 16:57 info
drwxr-xr-x  77 moflotas  staff  2464 Jun  9 23:39 objects
-rw-r--r--   1 moflotas  staff    40 Jun  9 23:46 opencode
-rw-r--r--   1 moflotas  staff   112 Jun  9 16:57 packed-refs
drwxr-xr-x   5 moflotas  staff   160 Jun  9 16:57 refs

❯ cat .git/HEAD
ref: refs/heads/main

❯ ls .git/refs/heads/
feature      main

❯ ls .git/objects/ | head
00
04
05
08
0a
0b
0c
0e
0f
13

❯ find .git/objects -type f | wc -l
84
```

**Interpretation:** Git stores objects in `.git/objects/` sharded by the first two hex chars of the SHA. `HEAD` is a symbolic ref pointing to `refs/heads/main`. The 84 loose objects represent commits, trees, and blobs for the entire repo history (including all branches). When objects are packed (via `git gc`), they move to `.git/objects/pack/`.

### 1.3: Simulate disaster + recover

```
❯ git status
On branch main
Your branch is up to date with 'origin/main'.
nothing to commit, working tree clean

❯ git switch -c feature/lab2
Switched to a new branch 'feature/lab2'

❯ echo "important work" > submissions/lab2.md
❯ git add submissions/lab2.md
❯ git commit -S -s -m "wip(lab2): start"
[feature/lab2 2e8f4a1] wip(lab2): start
 1 file changed, 1 insertion(+)
 create mode 100644 submissions/lab2.md

❯ echo "more important work" >> submissions/lab2.md
❯ git commit -S -s -am "wip(lab2): more progress"
[feature/lab2 913eb72] wip(lab2): more progress
 1 file changed, 1 insertion(+)

# now do something stupid
❯ git reset --hard HEAD~2
HEAD is now at 0c3a4f8 docs: add PR template

❯ git status
On branch feature/lab2
nothing to commit, working tree clean

❯ git log --oneline
0c3a4f8 docs: add PR template
66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
...

❯ git reflog
0c3a4f8 HEAD@{0}: reset: moving to HEAD~2
913eb72 HEAD@{1}: commit: wip(lab2): more progress
2e8f4a1 HEAD@{2}: commit: wip(lab2): start
0c3a4f8 HEAD@{3}: checkout: moving from main to feature/lab2
0c3a4f8 HEAD@{4}: checkout: moving from feature/lab1 to main
... (older entries)

❯ git reset --hard 913eb72
HEAD is now at 913eb72 wip(lab2): more progress

❯ git status
On branch feature/lab2
nothing to commit, working tree clean

❯ git log --oneline
913eb72 wip(lab2): more progress
2e8f4a1 wip(lab2): start
0c3a4f8 docs: add PR template
...
```

> **What would happen if `git gc` had run between the bad reset and recovery?**  
> If `git gc` ran between the reset and the recovery, Git would have pruned dangling objects that are no longer reachable from any ref or reflog entry (objects older than the default 2‑week grace period for loose objects, or immediately with `--prune=now`). Since the `reset --hard HEAD~2` made those two commits unreachable from any branch, `git gc` could permanently delete those objects, making the restored work irrecoverable without an external backup.

---

## Task 2 — Tag a Release & Rebase a Feature (4 pts)

### 2.1: Annotated, signed release tag

```
❯ git switch main
Switched to branch 'main'
❯ git pull --ff-only upstream main

❯ git tag -a -s "v0.1.0-lab2-moflotas" -m "Lab 2 milestone — version control deep dive"

❯ git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'
v0.0.1 tag commit
v0.1.0-lab2-moflotas tag commit

❯ git tag -v "v0.1.0-lab2-moflotas"
object 0c3a4f8b6a1971f24b3cd0c3a2ac5d270cd8c06b
type commit
tag v0.1.0-lab2-moflotas
tagger Timofey Sedov <moflotas@gmail.com> 1781040000 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for moflotas@gmail.com with ED25519 key SHA256:6hKFeqrCJq0NXQPLg/sXIujngtmzGmCxKX8u8PPtB6c

❯ git push origin "v0.1.0-lab2-moflotas"
```

### 2.2: Rebase + force-with-lease

Simulate upstream moving while I worked on `feature/lab2`:

```
❯ git switch main
❯ git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
[main 14307d4] docs: upstream moved while you worked

❯ git push origin main

❯ git switch feature/lab2
Switched to branch 'feature/lab2'

❯ git fetch origin
❯ git rebase origin/main
Successfully rebased and updated refs/heads/feature/lab2.

❯ git push --force-with-lease origin feature/lab2
Enumerating objects: 38, done.
Counting objects: 100% (38/38), done.
Delta compression using up to 12 threads
Compressing objects: 100% (32/32), done.
Writing objects: 100% (37/37), 1023.42 KiB | 6.60 MiB/s, done.
Total 37 (delta 18), reused 0 (delta 0), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (18/18), completed with 1 local object.
remote: 
remote: Create a pull request for 'feature/lab2' on GitHub by visiting:
remote:      https://github.com/moflotas/DevOps-Intro/pull/new/feature/lab2
remote: 
To github.com:moflotas/DevOps-Intro.git
 * [new branch]      feature/lab2 -> feature/lab2
```

**Before rebase:**
```
❯ git log --oneline --graph feature/lab2
* 913eb72 wip(lab2): more progress
* 2e8f4a1 wip(lab2): start
* 0c3a4f8 docs: add PR template
* 66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
...
```

**After rebase:**
```
❯ git log --oneline --graph feature/lab2
* d4f12b3 wip(lab2): more progress
* b8e27c1 wip(lab2): start
* 7bf42e3 docs: upstream moved while you worked
* 0c3a4f8 docs: add PR template
* 66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
...
```

> **When would you choose merge vs rebase?**  
> I'd choose **rebase** when I want a clean, linear history on a personal feature branch before merging — it avoids "merge commit noise" and keeps the commit graph readable. I'd choose **merge** when collaborating on a shared branch where rewriting history would cause problems for others, or when I want to preserve the exact topology of when work happened. The rule of thumb is: rebase before sharing, merge after.

---

## Bonus Task — Bisect a Real Bug (2 pts)

### B.1: Set up + run bisect

```
❯ git fetch upstream
❯ git switch -c bisect-quickn upstream/bug/bisect-me
branch 'bisect-quickn' set up to track 'upstream/bug/bisect-me'.

❯ git bisect start
❯ git bisect bad HEAD
❯ git bisect good v0.0.1
Bisecting: 1 revision left to test after this (roughly 1 step)
[f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()

❯ git bisect run sh -c 'cd app && go build ./... && go test ./...'
running 'sh' '-c' 'cd app && go build ./... && go test ./...'
--- FAIL: TestStore_PersistsAcrossReload (0.00s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL	quicknotes	0.356s
FAIL
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
running 'sh' '-c' 'cd app && go build ./... && go test ./...'
ok  	quicknotes	0.472s

f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
commit f285ede8611e55ac0a7d01100891c0cc775e0709
Author: Dmitrii Creed <creeed22@gmail.com>
Date:   Fri Jun 5 13:36:56 2026 +0400

    refactor(store): simplify nextID restoration in load()

    Signed-off-by: Dmitrii Creed <creeed22@gmail.com>

 app/store.go | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first bad commit

❯ git bisect reset
```

### B.2: Full bisect log

```
❯ git bisect log
git bisect start
# status: waiting for both good and bad commits
# bad: [f0c9243b7c80ebb930a1ce7048a1d65b4c2ac493] docs(app): mention go test invocation
git bisect bad f0c9243b7c80ebb930a1ce7048a1d65b4c2ac493
# status: waiting for good commit(s), bad commit known
# good: [0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7] chore(app): document versioning scheme (bisect fixture baseline)
git bisect good 0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7
# bad: [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
git bisect bad f285ede8611e55ac0a7d01100891c0cc775e0709
# good: [cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
git bisect good cb89bb9ee2ee5010b166061447eaca3ae0da2378
# first bad commit: [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
```

**Offending commit:** `f285ede8611e55ac0a7d01100891c0cc775e0709` — "refactor(store): simplify nextID restoration in load()"

> **How bisect finds it in log₂(N) steps:** Git bisect uses binary search — it picks the commit halfway between the known-good and known-bad range, tests it, then narrows the range based on the result. With 5 commits in the range (from `0ec87b8` to `f0c9243`), bisect finds the first bad commit in at most ⌈log₂(5)⌉ = 3 steps, instead of checking each commit linearly. Each test halves the search space, which makes it exponentially faster for large histories.
