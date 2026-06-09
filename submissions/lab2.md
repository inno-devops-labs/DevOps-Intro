# Lab 2 submission

## Task 1 - Git Object Model + Reflog Recovery

### 1.1 Plumbing chain (HEAD → tree → blob → file)

**`git rev-parse HEAD`**

```
8e61358fa53f7feeddd22dbd976355f4eb08e427
```

**`git cat-file -t HEAD`**

```
commit
```

**`git cat-file -p HEAD`**

```
tree 651ea749429462ed43f200ce6cbb43507cc03aa9
parent 66bbd4db9228bc9a4cab7439746b993749c026ab
author Arseny Pinigin <hidancloud@yandex.ru> 1781004509 +0300
committer Arseny Pinigin <hidancloud@yandex.ru> 1781004509 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 ...
 -----END SSH SIGNATURE-----

docs: add PR template

Signed-off-by: Arseny Pinigin <hidancloud@yandex.ru>
```

**`git cat-file -p 651ea749429462ed43f200ce6cbb43507cc03aa9`** (tree)

```
040000 tree 4718e71bbbfe37e3d846cecbb1c43cf72b4fa94d	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 6db686e340ecdd318fa43375e26254293371942a	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
```

**`git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee`** (blob — `.gitignore`, excerpt)

```
# ⚠️  KEEP THIS FILE MINIMAL.
#
# This .gitignore is inherited by every student fork. Anything listed here
# is something a student CANNOT `git add` without `-f`. So this file must
# ONLY contain:
...
refs/
```

**Chain:** commit `8e61358` → tree `651ea749` → blob `1c0a1e94` → contents of `.gitignore`.

### 1.2 Inside `.git/`

**`ls -la .git/`** — contains `HEAD`, `config`, `objects/`, `refs/`, `logs/`, `index`, `hooks/`, etc.

**`cat .git/HEAD`**

```
ref: refs/heads/main
```

**`ls .git/refs/heads/`**

```
feature
main
```

**`ls .git/objects/ | head`**

```
0a
0c
0e
0f
1a
1e
3a
3c
3d
6a
```

**`find .git/objects -type f | wc -l`**

```
47
```

**Interpretation:** `.git/HEAD` is a pointer to the current branch ref (`refs/heads/main`). Branch tips live under `.git/refs/heads/`. Objects are stored as loose files under `.git/objects/XX/...` (first two hex digits of the SHA as subdirectory). Each commit, tree, and blob is a content-addressed object identified by its SHA-1 hash.

### 1.3 Disaster + recovery

Created two commits on `feature/lab2`, then ran `git reset --hard HEAD~2`.

**After disaster — `git status`**

```
On branch feature/lab2
nothing to commit, working tree clean
```

**After disaster — `git log --oneline`**

```
8e61358 docs: add PR template
66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
...
```

**`git reflog` (excerpt)**

```
8e61358 HEAD@{0}: reset: moving to HEAD~2
7fa0f92 HEAD@{1}: reset: moving to 7fa0f9245235d6efbf43023150574e982ff0dff5
2779f60 HEAD@{2}: reset: moving to 2779f607c8dd739ca30391e674bbf47432116a76
8e61358 HEAD@{3}: checkout: moving from main to feature/lab2
```

**Recovery**

```bash
git reset --hard 7fa0f92
```

```
HEAD is now at 7fa0f92 wip(lab2): more progress
```

Both wip commits and `submissions/lab2.md` were restored.

**What if `git gc` had run?** Reflog entries expire (default ~90 days) and `git gc --prune=now` can remove unreachable commits that are no longer referenced by any ref or reflog. If aggressive garbage collection ran between the bad reset and recovery attempt, the "lost" commits could be pruned permanently and `git reflog` would not help. That is why capturing the SHA from reflog immediately is important before experimenting further.

---

## Task 2 - Tag a Release & Rebase a Feature

### 2.1 Signed annotated tag

```bash
git tag -a -s "v0.1.0-lab2-Hidancloud" -m "Lab 2 milestone — version control deep dive"
git push origin "v0.1.0-lab2-Hidancloud"
```

**`git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'`**

```
v0.1.0-lab2-Hidancloud tag commit
```

**`git tag -v "v0.1.0-lab2-Hidancloud"`**

```
Good "git" signature for hidancloud@yandex.ru with ED25519 key SHA256:0suWfmEHZ/Xt+yrRNKc2HZQbjzw33ZGHOnxmXKllv54
object 8e61358fa53f7feeddd22dbd976355f4eb08e427
type commit
tag v0.1.0-lab2-Hidancloud
tagger Arseny Pinigin <hidancloud@yandex.ru> ...

Lab 2 milestone — version control deep dive
```

### 2.2 Rebase + force-with-lease

While working on `feature/lab2`, simulated upstream moving on `main`:

```bash
git switch main
git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
git push origin main
```

```
To github.com:Hidancloud/DevOps-Intro.git
   8e61358..56c8ab1  main -> main
```

Then rebased the feature branch onto `origin/main`:

```bash
git switch feature/lab2
git fetch origin
git rebase origin/main
git push --force-with-lease origin feature/lab2
```

**`git log --oneline --graph` before rebase**

```
* 7fa0f92 wip(lab2): more progress
* 2779f60 wip(lab2): start
* 8e61358 docs: add PR template
```

**`git log --oneline --graph` after rebase**

```
* 55ceaa2 wip(lab2): more progress
* f413146 wip(lab2): start
* 56c8ab1 docs: upstream moved while you worked
* 8e61358 docs: add PR template
```

The two feature commits were replayed on top of the updated `origin/main`; commit SHAs changed (`7fa0f92` → `55ceaa2`, `2779f60` → `f413146`) but the diff is preserved.

### Merge vs rebase reflection

Use **merge** when integrating shared/long-lived branches where preserving exact history and merge context matters (e.g. team `main` with many contributors). Use **rebase** when you want a linear, readable history on a feature branch before opening a PR — it replays your commits on top of the latest base. Rebase rewrites SHAs, so it is appropriate only for branches you own; never rebase commits others have already pulled without coordination. `--force-with-lease` is safer than `--force` because it refuses to push if the remote branch moved unexpectedly.

---

## Bonus Task - Bisect a Real Bug

**Setup:** `upstream/bug/bisect-me`, good=`v0.0.1`, bad=`HEAD`

**`git bisect run sh -c 'cd app && go test ./... && go build ./...'`**

```
f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
commit f285ede8611e55ac0a7d01100891c0cc775e0709
Author: Dmitrii Creed <creeed22@gmail.com>
Date:   Fri Jun 5 13:36:56 2026 +0400

    refactor(store): simplify nextID restoration in load()

 app/store.go | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

**`git bisect log`**

```
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

**Offending commit:** `f285ede` — `refactor(store): simplify nextID restoration in load()` broke `TestStore_PersistsAcrossReload` (`nextID not restored: got 1, want 2`).

**How bisect works:** With N commits between good and bad, each step halves the search space by testing the midpoint — at most ⌈log₂(N)⌉ tests. Here Git needed only 2 test runs to isolate the first bad commit out of a small range on `bug/bisect-me`.
