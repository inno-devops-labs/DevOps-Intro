# Lab 2 — Version Control Deep Dive: Internals, Recovery, Rebase

- Student: Arina Nikolaeva (Nik-ari-ai)
- Fork: https://github.com/Nik-ari-ai/DevOps-Intro
- Branch: feature/lab2

## Task 1 — Git Object Model + Reflog Recovery

### 1.1 Object chain: HEAD → tree → blob → file

```
=== HEAD SHA ===
ebfaeb1b51c9ff2ec533f965012dd3b392536cbf
=== type of HEAD ===
commit
=== HEAD commit object ===
tree 4e8941f4762188e39dde75dbbc42c9b8b0a2f920
parent 9f41b7deb32343a831b5e47c61533fbc7c0ce67d
author Arina Nikolaeva <a.nikolaeva@innopolis.university> 1789040344 +0300
committer Arina Nikolaeva <a.nikolaeva@innopolis.university> 1789040344 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgnrayl8qqXj/TAQ0DXbuYp5F7si
 AIbRCrf2Pzyejf1C0AAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQFxFXMVy7xe3zHhNE4+G4gCVb91XiGPtUXHYLSqQcSrDsvAo7Wm/RurORrN7A03l1k
 N+Lq0W30fmXp1Sv7wwXAE=
 -----END SSH SIGNATURE-----

docs: add PR template

Signed-off-by: Arina Nikolaeva <a.nikolaeva@innopolis.university>
=== tree object (from HEAD) ===
TREE=4e8941f4762188e39dde75dbbc42c9b8b0a2f920
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d .github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a app
040000 tree f4f047dd07b128eda5f899dfdaaf193f0291eaa2 labs
040000 tree c0ac2d55cf4335df659b347df3d19d0594a06b6c lectures
=== blob README.md ===
BLOB=d10c04c6e7e0014f4fe883599c11747c15012d4e
# DevOps Intro — Modern DevOps Practices Through One Project
```

HEAD is a commit; it points to a tree; the tree lists blobs (files) and subtrees (directories); the blob is the file content.

### 1.2 Inside .git/

```
=== ls -la .git/ ===
COMMIT_EDITMSG  FETCH_HEAD  HEAD  ORIG_HEAD  config  description
hooks  index  info  logs  objects  packed-refs  refs
=== .git/HEAD ===
ref: refs/heads/main
=== refs/heads ===
feature main
=== objects subdirs ===
06
1a
1b
1d
27
38
3d
4e
67
a4
=== loose object count ===
      16
```

`.git/HEAD` is a symbolic ref to the current branch. `refs/heads/` holds branch tips (`feature/` is a directory holding `lab1`, plus `main`). Objects live under `objects/` in subdirs named by the first two SHA characters; there are 16 loose objects.

### 1.3 Reflog recovery

Two wip commits, then a destructive `reset --hard HEAD~2`, then recovery from reflog:

```
[feature/lab2 fae13b8] wip(lab2): start
[feature/lab2 c8ee590] wip(lab2): more progress
GOOD=c8ee590d541bcc1bd19bbed312cdb64c5479c1f7
=== disaster: reset --hard HEAD~2 ===
Указатель HEAD сейчас на коммите ebfaeb1 docs: add PR template
=== reflog (top 8) ===
ebfaeb1 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{0}: reset: moving to HEAD~2
c8ee590 HEAD@{1}: commit: wip(lab2): more progress
fae13b8 HEAD@{2}: commit: wip(lab2): start
ebfaeb1 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{3}: reset: moving to ebfaeb1
8de962e HEAD@{4}: reset: moving to HEAD~2
ebfaeb1 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{5}: checkout: moving from main to feature/lab2
ebfaeb1 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{6}: checkout: moving from main to main
ebfaeb1 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{7}: checkout: moving from feature/lab1 to main
=== recover ===
Указатель HEAD сейчас на коммите c8ee590 wip(lab2): more progress
=== file ===
important work
more important work
```

After `reset --hard HEAD~2` the branch returned to `ebfaeb1`; `git log` then showed `main`'s history (not empty), but the two wip commits were off the branch. `git reset --hard c8ee590` (SHA taken from reflog) restored them and the file.

**gc-window risk:** after the bad reset the two wip commits are unreachable from any branch; the reflog is the only thing keeping them alive. A normal `git gc` will not prune them because reflog entries stay for the default expiry window (90 days reachable, 30 unreachable). But an aggressive gc that expires the reflog now would prune those objects, and then `git reset --hard <SHA>` fails with a "bad object" error — the SHA is useless once the object itself is gone.

## Task 2 — Tag a Release & Rebase a Feature

### 2.1 Annotated, signed release tag

```
=== tag list (objecttype) ===
v0.0.1 tag commit
v0.1.0-lab2-a79135 tag commit
=== tag verify ===
object ebfaeb1b51c9ff2ec533f965012dd3b392536cbf
type commit
tag v0.1.0-lab2-a79135
tagger Arina Nikolaeva <a.nikolaeva@innopolis.university> 1789042682 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for a.nikolaeva@innopolis.university with ED25519 key SHA256:8GSxlvdecN00j5Mus9SElUSDbK6BYcUOIagqME2SBsA
```

`tag commit` confirms it is an annotated tag object pointing to a commit; `tag -v` shows a Good signature.

### 2.2 Rebase + force-with-lease

Before rebase:

```
* c8ee590 (HEAD -> feature/lab2, origin/feature/lab2) wip(lab2): more progress
* fae13b8 wip(lab2): start
* ebfaeb1 (tag: v0.1.0-lab2-a79135, origin/main, origin/HEAD, main) docs: add PR template
* 9f41b7d (upstream/main, upstream/HEAD) docs(lab7): make seed.json shipping explicit; require bonus artifacts, not logs
* 8de962e docs(lab11): fix nixpkgs pin vs go.mod collision; add network fallback pitfalls
* bfa345b docs(lab3): matrix renames required checks — warn + ci-ok gate pattern; set honest cache expectations
```

After `git rebase origin/main` (main advanced by `docs: upstream moved while you worked`) and `git push --force-with-lease`:

```
* ed224cd (HEAD -> feature/lab2, origin/feature/lab2) wip(lab2): more progress
* a088c0e wip(lab2): start
* 8e1d360 (origin/main, origin/HEAD, main) docs: upstream moved while you worked
* ebfaeb1 (tag: v0.1.0-lab2-a79135) docs: add PR template
* 9f41b7d (upstream/main, upstream/HEAD) docs(lab7): make seed.json shipping explicit; require bonus artifacts, not logs
* 8de962e docs(lab11): fix nixpkgs pin vs go.mod collision; add network fallback pitfalls
```

The two wip commits got new SHAs (`fae13b8`→`a088c0e`, `c8ee590`→`ed224cd`) and now sit on top of the new main commit `8e1d360`.

**Merge vs rebase:** rebase keeps a linear history and is right for a private feature branch before it is merged, so the log reads as a straight line. Merge is right when the branch is shared or already relied on by others, because rebase rewrites SHAs and forces everyone to reset. Rebase to clean up local history, merge to integrate published history.

## Bonus — Bisect a Real Bug

```
=== bisect run ===
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
--- FAIL: TestStore_PersistsAcrossReload (0.00s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL quicknotes 0.217s
FAIL
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
ok  quicknotes 0.233s
f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
commit f285ede8611e55ac0a7d01100891c0cc775e0709
Author: Dmitrii Creed <creeed22@gmail.com>
Date:   Fri Jun 5 13:36:56 2026 +0400

    refactor(store): simplify nextID restoration in load()

    Signed-off-by: Dmitrii Creed <creeed22@gmail.com>

 app/store.go | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

=== bisect log ===
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

Offending commit: `f285ede8611e55ac0a7d01100891c0cc775e0709` — `refactor(store): simplify nextID restoration in load()`. It breaks `TestStore_PersistsAcrossReload` (nextID is 1 after reload, should be 2).

**log₂(N) efficiency:** bisect does a binary search over the commits between the known-good and known-bad ends. Each step tests the middle commit and throws away half the remaining range, so for N commits it needs about log₂(N) tests instead of N. Here it converged in 2 tests (1 revision left after the first, 0 after the second). `git bisect run` made the good/bad call automatically from the test exit code, so no manual marking was needed.
