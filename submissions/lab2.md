# Lab 2 — Version Control Deep Dive: Internals, Recovery, Rebase

> All command output below is pasted verbatim from the terminal. Repo: `tdzdslippen/DevOps-Intro` (fork of `inno-devops-labs/DevOps-Intro`).
> Git version: `git version 2.50.1 (Apple Git-155)`.

---

## Task 1 — Git Object Model + Reflog Recovery

### 1.1 Explore the plumbing — one full chain `HEAD → tree → blob → file`

**Step 1 — `HEAD` is a commit object:**

```bash
$ git rev-parse HEAD
f0191e4d2737bc306781a11f2c8f9daccc4e7c47

$ git cat-file -t HEAD
commit

$ git cat-file -p HEAD
tree b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
parent 66bbd4db9228bc9a4cab7439746b993749c026ab
author tdzdslippen <avlaptev@avito.ru> 1780900801 +0300
committer tdzdslippen <avlaptev@avito.ru> 1780900801 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 ... (SSH signature) ...
 -----END SSH SIGNATURE-----

docs: add PR template

Signed-off-by: tdzdslippen <avlaptev@avito.ru>
```

The commit points at a **tree** (`b2fe0c7c…`), its **parent** commit, the author/committer, and an inline SSH signature.

**Step 2 — the tree lists the repo's top level (name → blob/subtree SHA):**

```bash
$ git cat-file -p b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 6db686e340ecdd318fa43375e26254293371942a	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
```

**Step 3 — pick the `.gitignore` blob and read its bytes:**

```bash
$ git cat-file -t 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee
blob

$ git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee | head -8
# ⚠️  KEEP THIS FILE MINIMAL.
#
# This .gitignore is inherited by every student fork. Anything listed here
# is something a student CANNOT `git add` without `-f`. So this file must
# ONLY contain:
#   (a) instructor-only paths (refs/), and
#   (b) machine-generated junk that NOBODY should ever commit.
# ...
```

**Chain:** commit `f0191e4` → tree `b2fe0c7c` → blob `1c0a1e94` (`.gitignore`) → file contents.

**Interpretation.** Git is a content-addressed object store. A **commit** is metadata + a pointer to one **tree** (a snapshot of the whole working directory at that moment). A **tree** maps file names to **blobs** (file contents) or sub-trees (directories). A **blob** is just the bytes of a file — it carries no name; the name lives in the tree that references it. Every object's name *is* the SHA of its content, so identical content is stored once and any tampering changes the hash.

### 1.2 Look inside `.git/`

```bash
$ ls -la .git/
-rw-r--r--   COMMIT_EDITMSG
-rw-r--r--   FETCH_HEAD
-rw-r--r--   HEAD
-rw-r--r--   ORIG_HEAD
-rw-r--r--   config
-rw-r--r--   description
drwxr-xr-x   hooks
-rw-r--r--   index
drwxr-xr-x   info
drwxr-xr-x   logs
drwxr-xr-x   objects
-rw-r--r--   packed-refs
drwxr-xr-x   refs

$ cat .git/HEAD
ref: refs/heads/main

$ ls .git/refs/heads/
feature
main

$ ls .git/objects/ | head
06
0a
0c
0e
0f
13
17
1a
1d
1f

$ find .git/objects -type f | wc -l
      54

$ git count-objects -vH
count: 51
size: 412.00 KiB
in-pack: 201
packs: 1
size-pack: 538.64 KiB
prune-packable: 0
garbage: 0
size-garbage: 0 bytes
```

**Interpretation.**
- `.git/HEAD` is a symbolic ref — it doesn't store a SHA, it stores *which branch is current* (`refs/heads/main`).
- `.git/refs/heads/` holds one file per local branch, each containing that branch's tip SHA.
- `.git/objects/` shards loose objects into sub-directories named by the **first two hex characters** of the SHA (the remaining 38 chars are the filename). 54 loose object files exist right now.
- `git count-objects -vH` shows the rest already live in a **packfile** (201 objects, ~539 KiB) — Git periodically compresses loose objects into delta-compressed packs.
- `index` is the staging area; `logs/` holds the reflog that makes Task 1.3 possible.

### 1.3 Simulate disaster + recover

Create the branch and two work-in-progress commits:

```bash
$ git switch -c feature/lab2
Switched to a new branch 'feature/lab2'

$ printf 'important work\n' > submissions/lab2.md
$ git add submissions/lab2.md
$ git commit -S -s -m "wip(lab2): start"
[feature/lab2 338fae6] wip(lab2): start
 1 file changed, 1 insertion(+)

$ printf 'more important work\n' >> submissions/lab2.md
$ git commit -S -s -am "wip(lab2): more progress"
[feature/lab2 8d09f76] wip(lab2): more progress
 1 file changed, 1 insertion(+)
```

**Best practice — capture the tip SHA *before* experimenting:** `8d09f767a1f5f4bf6f4d482180d1153591d2c25d`.

Now the destructive reset:

```bash
$ git reset --hard HEAD~2
HEAD is now at f0191e4 docs: add PR template

$ git status
On branch feature/lab2
nothing to commit, working tree clean

$ git log --oneline -4
f0191e4 docs: add PR template
66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
d50436c fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
```

Both commits look gone from `log` — but the reflog still records every move of `HEAD`:

```bash
$ git reflog
f0191e4 HEAD@{0}: reset: moving to HEAD~2
8d09f76 HEAD@{1}: commit: wip(lab2): more progress
338fae6 HEAD@{2}: commit: wip(lab2): start
f0191e4 HEAD@{3}: checkout: moving from main to feature/lab2
f0191e4 HEAD@{4}: checkout: moving from main to main
f0191e4 HEAD@{5}: checkout: moving from feature/lab1 to main
b9c958d HEAD@{6}: commit: docs(lab1): polish submission document
a07c650 HEAD@{7}: commit: 3 task and bonus
```

Recovery — reset back to the SHA we captured (also visible as `HEAD@{1}`):

```bash
$ git reset --hard 8d09f767a1f5f4bf6f4d482180d1153591d2c25d
HEAD is now at 8d09f76 wip(lab2): more progress

$ git status
On branch feature/lab2
nothing to commit, working tree clean

$ git log --oneline -4
8d09f76 wip(lab2): more progress
338fae6 wip(lab2): start
f0191e4 docs: add PR template
66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses

$ cat submissions/lab2.md
important work
more important work
```

**What if `git gc` had run between the bad reset and recovery?** `reset --hard HEAD~2` only moved the branch ref backwards; the two commit objects were still in `.git/objects`, *unreachable* from any branch but *reachable* from the reflog, which is why recovery worked. `git gc` prunes unreachable objects — **but only those older than `gc.reflogExpireUnreachable` (default 30 days)**, and it does not drop reflog entries that are still within their expiry window. So an ordinary `gc` right after the reset would have been harmless. The real danger is `git gc --prune=now` or `git reflog expire --expire=now --all` (sometimes triggered in aggressive CI): that drops the reflog entries, the objects become truly unreachable, and the next prune deletes them permanently. Lesson: **capture the SHA first, then experiment.**

---

## Task 2 — Tag a Release & Rebase a Feature

### 2.1 Annotated, signed release tag

> Note: `git pull --ff-only upstream main` is a no-op here — my fork's `main` is already **1 commit ahead** of `upstream/main` (it carries the `docs: add PR template` commit from Lab 1), so there is nothing to fast-forward. The tag is created on that current `main` tip (`f0191e4`).

```bash
$ git tag -a -s "v0.1.0-lab2-${USER}" -m "Lab 2 milestone — version control deep dive"
$ git push origin "v0.1.0-lab2-${USER}"
To github.com:tdzdslippen/DevOps-Intro.git
 * [new tag]         v0.1.0-lab2-avlaptev -> v0.1.0-lab2-avlaptev
```

Confirm it is **annotated** (`objecttype = tag`, pointing at a `commit`) **and signed** (`Good` signature):

```bash
$ git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)' v0.1.0-lab2-avlaptev
v0.1.0-lab2-avlaptev tag commit

$ git tag -v v0.1.0-lab2-avlaptev
Good "git" signature for avlaptev@avito.ru with ED25519 key SHA256:exUDMmioM811FWmw8zr69z++b06Ukg8jWy2eA4V+Rtk
object f0191e4d2737bc306781a11f2c8f9daccc4e7c47
type commit
tag v0.1.0-lab2-avlaptev
tagger tdzdslippen <avlaptev@avito.ru> 1780997729 +0300

Lab 2 milestone — version control deep dive
```

A lightweight tag would have printed `objecttype = commit` (no wrapping tag object) and `tag -v` would report *no signature*. Here we get a real tag object **and** a verified SSH signature.

### 2.2 Rebase + force-with-lease

**Before rebase** — `feature/lab2` sits directly on `f0191e4`:

```bash
$ git log --oneline --graph feature/lab2 -6
* 8d09f76 wip(lab2): more progress
* 338fae6 wip(lab2): start
* f0191e4 docs: add PR template
* 66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
|\
```

Simulate the base branch moving while I worked:

```bash
$ git switch main
$ git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
[main 790869f] docs: upstream moved while you worked
$ git push origin main
remote: Bypassed rule violations for refs/heads/main:
remote: - Changes must be made through a pull request.
To github.com:tdzdslippen/DevOps-Intro.git
   f0191e4..790869f  main -> main
```

Replay my two commits on top of the new `main`:

```bash
$ git switch feature/lab2
$ git fetch origin
$ git rebase origin/main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/lab2.
```

**After rebase** — the two commits are re-parented onto `790869f` and get **new SHAs** (`cd9202f`, `1c97e4d`):

```bash
$ git log --oneline --graph feature/lab2 -6
* cd9202f wip(lab2): more progress
* 1c97e4d wip(lab2): start
* 790869f docs: upstream moved while you worked
* f0191e4 docs: add PR template
* 66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
|\

$ git log --oneline origin/main..feature/lab2
cd9202f wip(lab2): more progress
1c97e4d wip(lab2): start
```

The diff is clean — exactly my **two** commits sit on top of `origin/main`, no stray upstream commits leaked in.

**Why `--force-with-lease`.** I had already published the pre-rebase branch (`8d09f76`). After rebasing, my local branch (`cd9202f`) diverges from `origin/feature/lab2`, so a plain push is rejected. `--force-with-lease` overwrites the remote **only if** it still points where I last saw it (`8d09f76`) — protecting any teammate commits I haven't fetched. Plain `--force` would clobber them blindly.

```bash
# local (rebased) vs remote (pre-rebase): 2 behind / 3 ahead → diverged
$ git rev-list --left-right --count origin/feature/lab2...feature/lab2
2	3

$ git push --force-with-lease origin feature/lab2
To github.com:tdzdslippen/DevOps-Intro.git
 + 8d09f76...cd9202f feature/lab2 -> feature/lab2 (forced update)
```

**Merge vs rebase — when I'd choose each.** I **rebase** a private feature branch onto the latest base before opening a PR: it produces a linear, easy-to-review history and avoids noisy "Merge branch main" commits. I **never** rebase a branch other people have already pulled — rewriting shared history forces everyone to recover. For integrating a finished, reviewed branch into a long-lived shared branch (`main`), I **merge** (often a merge commit or squash-merge), because the merge records the integration point and never rewrites published commits. Rule of thumb: *rebase to clean up history that is still mine; merge to combine history that is already shared.*

---

## Bonus Task — Bisect a Real Bug

Set up bisect over the instructor's `bug/bisect-me` branch (4 commits between the last good tag and the broken tip):

```bash
$ git fetch upstream
$ git switch -c bisect-quickn upstream/bug/bisect-me
$ git rev-list --count v0.0.1..HEAD
4
```

Confirm the current tip is genuinely broken:

```bash
$ cd app && go test ./...
--- FAIL: TestStore_PersistsAcrossReload (0.00s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL	quicknotes	0.599s
```

Automate the search — Git checks out the midpoint each step and uses the script's exit code (`0` = good, non-zero = bad):

```bash
$ git bisect start
$ git bisect bad  HEAD
$ git bisect good v0.0.1
Bisecting: 1 revision left to test after this (roughly 1 step)

$ git bisect run sh -c 'cd app && go test ./... && go build ./...'
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
--- FAIL: TestStore_PersistsAcrossReload (0.00s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL	quicknotes	0.525s
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
ok  	quicknotes	0.377s
f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
```

**Full `git bisect log`:**

```text
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

**Offending commit:**

- **SHA:** `f285ede8611e55ac0a7d01100891c0cc775e0709`
- **Message:** `refactor(store): simplify nextID restoration in load()`
- **The bug — an off-by-one in `app/store.go`:**

```diff
 for _, n := range notes {
 	s.notes[n.ID] = n
-	if n.ID >= s.nextID {
+	if n.ID > s.nextID {
 		s.nextID = n.ID + 1
 	}
 }
```

Changing `>=` to `>` means that when a note's ID equals the current `nextID`, the counter is **not** advanced, so after a reload `nextID` is one too small and `TestStore_PersistsAcrossReload` fails (`got 1, want 2`).

```bash
$ git bisect reset
Previous HEAD position was cb89bb9 docs(store): comment the load() decode step
Switched to branch 'bisect-quickn'
```

**Why bisect is `log₂(N)`.** Bisect performs a **binary search** over the commit range. Each tested commit is the midpoint of the remaining suspects; the test result throws away *half* of them — if the midpoint is bad, the bug is in the older half, otherwise in the newer half. So `N` candidate commits collapse to the single culprit in about `⌈log₂(N)⌉` tests instead of a linear `N` sweep. Here `N = 4`, so `log₂(4) = 2` tests pinpointed `f285ede`. The win is dramatic at scale: a regression hidden among 1,000 commits is found in ~10 builds, and `git bisect run` makes even that fully unattended.
