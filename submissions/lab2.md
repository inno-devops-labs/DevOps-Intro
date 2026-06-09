# Lab 2 submission

Student: Irina Bychkova

## Task 1 - Git object model and reflog recovery

### 1.1 HEAD to tree to blob

```bash
git rev-parse HEAD
```

```text
6eb9e2a16cf1102c44cad37209c253f828734984
```

```bash
git cat-file -t HEAD
```

```text
commit
```

```bash
git cat-file -p HEAD
```

```text
tree 4949d6dee916add2be7aa71712858455d1239fd9
parent 66bbd4db9228bc9a4cab7439746b993749c026ab
author Irina <irina.bychkova06@mail.ru> 1780986324 +0300
committer Irina <irina.bychkova06@mail.ru> 1780986324 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 ...
 -----END SSH SIGNATURE-----

docs: add PR template

Signed-off-by: Irina <irina.bychkova06@mail.ru>
```

```bash
git cat-file -p 4949d6dee916add2be7aa71712858455d1239fd9
```

```text
040000 tree af080e474767b4931935c2b4565f66bc9f0b8d22	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 6db686e340ecdd318fa43375e26254293371942a	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
```

```bash
git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee
```

```text
# KEEP THIS FILE MINIMAL.
...
app/quicknotes
app/data/
/quicknotes
*.exe
...
```

The commit object points to a tree. The tree maps names such as `.gitignore` to blob objects. The blob stores only the file contents; the filename lives in the tree entry.

### 1.2 Inside `.git`

```bash
ls -la .git
```

```text
COMMIT_EDITMSG
FETCH_HEAD
HEAD
allowed_signers
config
description
hooks
index
info
logs
objects
packed-refs
refs
```

```bash
cat .git/HEAD
```

```text
ref: refs/heads/main
```

```bash
ls .git/refs/heads
```

```text
feature
main
```

```bash
ls .git/objects | head
```

```text
03
0b
0f
19
1a
40
49
67
69
6a
```

```bash
find .git/objects -type f | wc -l
```

```text
30
```

`.git/HEAD` says which branch is checked out. `refs/heads` stores local branch refs. `objects` stores loose Git objects split into directories by the first two SHA characters; this repository had 30 loose object files at the time of inspection.

### 1.3 Disaster and recovery

I created two signed commits on `feature/lab2`:

```text
b93372d wip(lab2): start
1ba9171 wip(lab2): more progress
```

Then I simulated the destructive reset:

```bash
git reset --hard HEAD~2
```

```text
HEAD is now at 6eb9e2a docs: add PR template
```

```bash
git status --short --branch
```

```text
## feature/lab2
?? submissions/
```

```bash
git log --oneline -5
```

```text
6eb9e2a docs: add PR template
66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
d50436c fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
4705a3d fix(.gitignore): stop ignoring submissions/
```

The lost commits were still visible in reflog:

```bash
git reflog -8
```

```text
6eb9e2a HEAD@{0}: reset: moving to HEAD~2
1ba9171 HEAD@{1}: commit: wip(lab2): more progress
b93372d HEAD@{2}: commit: wip(lab2): start
6eb9e2a HEAD@{3}: checkout: moving from main to feature/lab2
6eb9e2a HEAD@{4}: checkout: moving from main to main
6eb9e2a HEAD@{5}: checkout: moving from feature/lab1 to main
f56a495 HEAD@{6}: checkout: moving from feature/lab1 to feature/lab1
f56a495 HEAD@{7}: commit: docs(lab1): complete community checklist
```

I restored the latest lost commit:

```bash
git reset --hard 1ba9171
```

```text
HEAD is now at 1ba9171 wip(lab2): more progress
```

```bash
cat submissions/lab2.md
```

```text
important work
more important work
```

If `git gc` had run aggressively between the bad reset and recovery, unreachable commits could eventually be pruned after their grace period. Normally reflog keeps recent commits recoverable, but CI or custom maintenance settings can shorten that safety window. The safest recovery habit is to copy the reflog SHA immediately before experimenting further.

## Task 2 - Signed tag and rebase

### 2.1 Signed annotated tag

Tag name:

```text
v0.1.0-lab2-1r444444
```

```bash
git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)' | grep 'v0.1.0-lab2-1r444444'
```

```text
v0.1.0-lab2-1r444444 tag commit
```

```bash
git tag -v "v0.1.0-lab2-1r444444"
```

```text
Good "git" signature for irina.bychkova06@mail.ru with ED25519 key SHA256:0QziAHQZeFYu2R3UOly0My2Bl/aGmRK46bdyePgznWM
object 6eb9e2a16cf1102c44cad37209c253f828734984
type commit
tag v0.1.0-lab2-1r444444
tagger Irina <irina.bychkova06@mail.ru> 1780988784 +0300

Lab 2 milestone - version control deep dive
```

### 2.2 Rebase evidence

Before rebase:

```bash
git log --oneline --graph --decorate --max-count=8 feature/lab2 main
```

```text
* 1ba9171 (feature/lab2) wip(lab2): more progress
* b93372d wip(lab2): start
* 6eb9e2a (HEAD -> main, tag: v0.1.0-lab2-1r444444, origin/main) docs: add PR template
* 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
```

Then I simulated `main` moving:

```bash
git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
git push origin main
```

```text
[main bad4a5b] docs: upstream moved while you worked
To github.com:1r444444/DevOps-Intro.git
   6eb9e2a..bad4a5b  main -> main
```

After rebase:

```bash
git rebase origin/main
```

```text
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/lab2.
```

```bash
git log --oneline --graph --decorate --max-count=8 feature/lab2 main origin/main
```

```text
* 30a6075 (HEAD -> feature/lab2) wip(lab2): more progress
* 70d42bb wip(lab2): start
* bad4a5b (origin/main, main) docs: upstream moved while you worked
* 6eb9e2a (tag: v0.1.0-lab2-1r444444) docs: add PR template
* 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
```

I would choose merge for shared long-lived branches when preserving the exact collaboration history matters. I would choose rebase for my own feature branch before opening a PR, because it keeps the review history linear and easier to read. I would avoid rebasing commits that other people have already based work on.

## Bonus - Git bisect

```bash
git bisect run sh -c 'cd app && GOCACHE=/private/tmp/gocache go test ./... && GOCACHE=/private/tmp/gocache go build ./...'
```

```text
running  'sh' '-c' 'cd app && GOCACHE=/private/tmp/gocache go test ./... && GOCACHE=/private/tmp/gocache go build ./...'
--- FAIL: TestStore_PersistsAcrossReload (0.00s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL	quicknotes	1.094s
FAIL
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
running  'sh' '-c' 'cd app && GOCACHE=/private/tmp/gocache go test ./... && GOCACHE=/private/tmp/gocache go build ./...'
ok  	quicknotes	0.536s
f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
commit f285ede8611e55ac0a7d01100891c0cc775e0709
Author: Dmitrii Creed <creeed22@gmail.com>
Date:   Fri Jun 5 13:36:56 2026 +0400

    refactor(store): simplify nextID restoration in load()

    Signed-off-by: Dmitrii Creed <creeed22@gmail.com>

 app/store.go | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first bad commit
```

Full bisect log:

```text
git bisect start
# status: waiting for both good and bad commits
# good: [0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7] chore(app): document versioning scheme (bisect fixture baseline)
git bisect good 0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7
# status: waiting for bad commit, 1 good commit known
# bad: [f0c9243b7c80ebb930a1ce7048a1d65b4c2ac493] docs(app): mention go test invocation
git bisect bad f0c9243b7c80ebb930a1ce7048a1d65b4c2ac493
# bad: [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
git bisect bad f285ede8611e55ac0a7d01100891c0cc775e0709
# good: [cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
git bisect good cb89bb9ee2ee5010b166061447eaca3ae0da2378
# first bad commit: [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
```

Offending commit:

```text
f285ede8611e55ac0a7d01100891c0cc775e0709 refactor(store): simplify nextID restoration in load()
```

Bisect works by repeatedly testing the midpoint between a known good commit and a known bad commit. Each test cuts the remaining search space roughly in half, so it needs about `log2(N)` test runs instead of checking every commit. In this branch only a few commits were between `v0.0.1` and the broken HEAD, so bisect found the first bad commit in two test decisions.
