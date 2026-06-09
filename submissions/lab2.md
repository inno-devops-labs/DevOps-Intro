# Lab 2 — Version Control Deep Dive: Internals, Recovery, Rebase

> Submission by **RoukayaZaki** (`roka.zaki2002@gmail.com`).
> Commits and the release tag are signed with SSH key `SHA256:ty3gjRlrqQAvG/Ian7j0TKoEVGbHZ7IUOFR13Abyvuw`.

---

## Task 1 — Git Object Model + Reflog Recovery

### 1.1 Explore the plumbing — one full `HEAD → tree → blob → file` chain

**`git rev-parse HEAD`**
```
e11cae9b792348d49a73315a3c4079c4bda74622
```

**`git cat-file -t HEAD`** — the object pointed to by HEAD is a *commit*:
```
commit
```

**`git cat-file -p HEAD`** — the commit object names its root *tree*, its *parent*, and author/committer:
```
tree 54501682022264ae3ea92335094dbce0a518791e
parent 4afe3679e0ab6482b37191966893d3afa7da5ee6
author RoukayaZaki <roka.zaki2002@gmail.com> 1781033942 +0300
committer RoukayaZaki <roka.zaki2002@gmail.com> 1781033942 +0300

test: unsigned commit (should fail)

Signed-off-by: RoukayaZaki <roka.zaki2002@gmail.com>
```

**`git cat-file -p 54501682…`** — the tree lists one entry per top-level path; each is itself a sub-tree (directory) or a blob (file):
```
040000 tree 2c6ca2d310a2decda5bd5063999dee0fc5eb472f	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 6db686e340ecdd318fa43375e26254293371942a	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
```

**`git cat-file -t 1c0a1e94…`** → `blob`, and **`git cat-file -p 1c0a1e94…`** prints the actual file contents of `.gitignore` (truncated):
```
# ⚠️  KEEP THIS FILE MINIMAL.
#
# This .gitignore is inherited by every student fork. Anything listed here
# is something a student CANNOT `git add` without `-f`. ...
refs/
app/quicknotes
app/data/
...
```

**Interpretation.** Git is a content-addressed object store. A **commit** is a tiny object that points to a single root **tree** (plus parent + metadata). A **tree** is a directory listing mapping names → SHAs of sub-trees and **blobs**. A **blob** is just raw file bytes with no name (the name lives in the tree). Walking `commit → tree → blob` reconstructs the working tree; identical content anywhere in history shares one blob (deduplication by SHA).

### 1.2 Inside `.git/`

**`ls -la .git/`**
```
COMMIT_EDITMSG   FETCH_HEAD   HEAD   ORIG_HEAD   config   description
gk/   hooks/   index   info/   logs/   objects/   packed-refs   refs/
```

**`cat .git/HEAD`** — a symbolic ref, not a SHA: HEAD points at a branch:
```
ref: refs/heads/main
```

**`ls .git/refs/heads/`** — local branches:
```
feature   main
```

**`ls .git/objects/ | head`** — objects are sharded into subdirectories by the first 2 hex chars of their SHA:
```
0a  0c  0e  0f  13  1a  1f  25  26  27 ...
```

**`find .git/objects -type f | wc -l`** — loose (un-packed) objects:
```
56
```

**Interpretation.** `HEAD` is an indirection to the current branch ref; the branch ref is a 40-char SHA file under `refs/heads/`. `objects/` is the object database (loose objects sharded by SHA prefix; older history lives in packfiles + `packed-refs`). `logs/` holds the reflog, `index` is the staging area, `config` the per-repo settings. (`gk/` is a local GitKraken cache, not part of Git itself.)

### 1.3 Simulate disaster + recover

Created the feature branch and two **signed + signed-off** commits:
```
$ git switch -c feature/lab2
$ echo "important work" > submissions/lab2.md
$ git add submissions/lab2.md
$ git commit -S -s -m "wip(lab2): start"          # 5f46b0e
$ echo "more important work" >> submissions/lab2.md
$ git commit -S -s -am "wip(lab2): more progress" # e2c35ba
$ git log --show-signature -1
Good "git" signature for roka.zaki2002@gmail.com with ED25519 key SHA256:ty3gjRlrqQAvG/Ian7j0TKoEVGbHZ7IUOFR13Abyvuw
```

**Disaster — `git reset --hard HEAD~2`:**
```
$ git reset --hard HEAD~2
HEAD is now at e11cae9 test: unsigned commit (should fail)

$ git status
On branch feature/lab2
nothing to commit, working tree clean

$ git log --oneline
e11cae9 test: unsigned commit (should fail)
4afe367 test: unsigned commit (should fail)
46e058e docs: add PR template
```
Both `wip` commits have vanished from `log` and the working tree.

**Recovery — the reflog still has them:**
```
$ git reflog
e11cae9 HEAD@{0}: reset: moving to HEAD~2
e2c35ba HEAD@{1}: commit: wip(lab2): more progress
5f46b0e HEAD@{2}: commit: wip(lab2): start
e11cae9 HEAD@{3}: checkout: moving from main to feature/lab2
e11cae9 HEAD@{4}: checkout: moving from feature/lab1 to main
d176032 HEAD@{5}: commit: docs: add Bonus
...
```

```
$ git reset --hard e2c35ba
HEAD is now at e2c35ba wip(lab2): more progress

$ git status
On branch feature/lab2
nothing to commit, working tree clean

$ git log --oneline
e2c35ba wip(lab2): more progress
5f46b0e wip(lab2): start
e11cae9 test: unsigned commit (should fail)

$ cat submissions/lab2.md
important work
more important work
```
The "lost" commit `e2c35ba` and its file contents are fully restored.

**What would happen if `git gc` had run between the bad reset and recovery?**
`reset --hard` only moves the branch ref; the orphaned commits stay in the object database and remain reachable through the reflog, which is exactly why recovery works. A normal `git gc` prunes only *unreachable* objects and still honors the reflog plus the `gc.reflogExpireUnreachable` grace window (90 days by default), so it would **not** have deleted them. The real danger is an aggressive prune (`git gc --prune=now`, `git reflog expire --expire=now --all`, or CI configured with a near-zero expiry): that drops the reflog entries first, leaving the commits genuinely unreachable and eligible for immediate deletion. Lesson: **capture the SHA before experimenting** — once it's written down you can always `git reset`/`cherry-pick` it back, gc or not.

---

## Task 2 — Tag a Release & Rebase a Feature

### 2.1 Annotated, signed release tag

```
$ git switch main
$ git pull --ff-only upstream main
Already up to date.
$ git tag -a -s "v0.1.0-lab2-roukayazaki" -m "Lab 2 milestone — version control deep dive"
$ git push origin "v0.1.0-lab2-roukayazaki"
 * [new tag]         v0.1.0-lab2-roukayazaki -> v0.1.0-lab2-roukayazaki
```

**Annotated *and* signed check** — `objecttype` is `tag` (annotated) and it dereferences to a `commit`:
```
$ git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)' v0.1.0-lab2-roukayazaki
v0.1.0-lab2-roukayazaki tag commit
```

**Signature verification — "Good":**
```
$ git tag -v v0.1.0-lab2-roukayazaki
object e11cae9b792348d49a73315a3c4079c4bda74622
type commit
tag v0.1.0-lab2-roukayazaki
tagger RoukayaZaki <roka.zaki2002@gmail.com> 1781035344 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for roka.zaki2002@gmail.com with ED25519 key SHA256:ty3gjRlrqQAvG/Ian7j0TKoEVGbHZ7IUOFR13Abyvuw
```

### 2.2 Rebase + force-with-lease

Simulate upstream moving while the feature branch was in progress:
```
$ git switch main
$ git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
[main fd1f787] docs: upstream moved while you worked
$ git push origin main
   e11cae9..fd1f787  main -> main
```

Replay the two feature commits on top of the new `origin/main`:
```
$ git switch feature/lab2
$ git fetch origin
$ git rebase origin/main
Rebasing (1/2) ... Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/lab2.
$ git log --show-signature -1
Good "git" signature for roka.zaki2002@gmail.com ...   # commits re-signed on replay
$ git push --force-with-lease origin feature/lab2
 * [new branch]      feature/lab2 -> feature/lab2
```

**`git log --oneline --graph` — before rebase** (feature commits sit directly on `e11cae9`):
```
* e2c35ba wip(lab2): more progress
* 5f46b0e wip(lab2): start
* e11cae9 test: unsigned commit (should fail)
* 4afe367 test: unsigned commit (should fail)
* 46e058e docs: add PR template
```

**after rebase** (replayed with new SHAs on top of the moved `fd1f787`):
```
* f515e84 wip(lab2): more progress
* 862b231 wip(lab2): start
* fd1f787 docs: upstream moved while you worked   <-- new upstream commit
* e11cae9 test: unsigned commit (should fail)
* 4afe367 test: unsigned commit (should fail)
```
Note the rewritten hashes (`5f46b0e/e2c35ba` → `862b231/f515e84`): rebase creates *new* commit objects whose parent is now `fd1f787`. History stays linear — no merge commit.

> 💡 `--force-with-lease` (never plain `--force`) refuses the push if `origin/feature/lab2` advanced beyond what I last fetched, so I can't silently clobber a teammate's work. After a rewrite the branch is no longer a fast-forward of the remote, so a force is required — the *lease* makes it safe.

### Reflection — merge vs rebase

- **Rebase** when tidying *my own* not-yet-shared feature branch onto an updated mainline: it produces a clean, linear, bisect-friendly history with no noise merge commits, and lets me squash WIP commits before review. The cost is rewritten hashes, so I only rebase commits nobody else has pulled.
- **Merge** when integrating a finished branch into a shared/protected branch, or when the branch is already public: the merge commit preserves exactly what happened and when, never rewrites shared history, and records the integration point. For long-lived shared branches, merge is the safe default; for local cleanup before a PR, rebase wins. Rule of thumb: *rebase local, merge public.*

---

## Bonus — Bisect a Real Bug

Set up bisect over the deliberately-broken fixture branch, bracketing with the known-good `v0.0.1` tag and the broken tip:
```
$ git switch -c bisect-quickn upstream/bug/bisect-me
$ git bisect start
$ git bisect bad  HEAD       # tip fails: TestStore_PersistsAcrossReload
$ git bisect good v0.0.1     # 4 commits in range
```

**Automated bisect:**
```
$ git bisect run sh -c 'cd app && go test ./... && go build ./...'
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
--- FAIL: TestStore_PersistsAcrossReload (0.02s)
    store_test.go:78: nextID not restored: got 1, want 2
... (Git checks out the midpoint, tests, narrows the range) ...
ok  	quicknotes	0.960s
f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
```

**Full `git bisect log`:**
```
git bisect start
# status: waiting for both good and bad commits
# bad: [f0c9243…] docs(app): mention go test invocation
git bisect bad f0c9243b7c80ebb930a1ce7048a1d65b4c2ac493
# status: waiting for good commit(s), bad commit known
# good: [0ec87b8…] chore(app): document versioning scheme (bisect fixture baseline)
git bisect good 0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7
# bad: [f285ede…] refactor(store): simplify nextID restoration in load()
git bisect bad f285ede8611e55ac0a7d01100891c0cc775e0709
# good: [cb89bb9…] docs(store): comment the load() decode step
git bisect good cb89bb9ee2ee5010b166061447eaca3ae0da2378
# first bad commit: [f285ede…] refactor(store): simplify nextID restoration in load()
```

**Offending commit**
- **SHA:** `f285ede8611e55ac0a7d01100891c0cc775e0709`
- **Message:** `refactor(store): simplify nextID restoration in load()`
- **Author:** Dmitrii Creed — Fri Jun 5 13:36:56 2026

**The bug** — a one-character off-by-one in `app/store.go`'s `load()`:
```diff
 	for _, n := range notes {
 		s.notes[n.ID] = n
-		if n.ID >= s.nextID {
+		if n.ID > s.nextID {
 			s.nextID = n.ID + 1
 		}
 	}
```
With `>` instead of `>=`, when the highest persisted note ID equals the current `nextID`, the counter is not advanced, so after a reload the next note reuses an ID — exactly what `TestStore_PersistsAcrossReload` catches (`nextID not restored: got 1, want 2`).

**Why bisect is `log₂(N)`.** Bisect runs a binary search over the commit range: each tested commit is the midpoint, and its `good`/`bad` verdict discards *half* the remaining suspects. So `N` commits are isolated in about `⌈log₂(N)⌉` tests instead of a linear `N` scan. Here `N = 4` commits → only **2** build/test steps were needed to pin the culprit. The same math means a 1000-commit regression is found in ~10 tests — and `git bisect run` automates the whole search by deriving each verdict from the test script's exit code.

---

## Summary of artifacts

| Artifact | Value |
|----------|-------|
| Signed annotated tag | `v0.1.0-lab2-roukayazaki` (pushed to origin, `git tag -v` → Good) |
| Recovered commit | `e2c35ba` via `git reflog` + `git reset --hard` |
| Rebased branch | `feature/lab2` replayed onto `fd1f787`, pushed `--force-with-lease` |
| First bad commit (bisect) | `f285ede` — off-by-one `>=`→`>` in `store.go` `load()` |
