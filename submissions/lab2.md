# Lab 2 — Version Control Deep Dive

## Task 1 — Git Object Model + Reflog Recovery

### 1.1 Explore Git object model

#### Current HEAD SHA

Command:

```bash
git rev-parse HEAD
```

Output:

```text
4c475060d9eacc2d506e7eef7036cdaf76fc3d90
```

#### HEAD object type

Command:

```bash
git cat-file -t HEAD
```

Output:

```text
commit
```

#### HEAD commit contents

Command:

```bash
git cat-file -p HEAD
```

Output:

```text
tree 01e9b2e7a6d5fccf3268951664c73dd6b4357db6
parent a8b97cf257dd012a68ec449b1e1dd753d7533823
author giselesikeh <giselesikeh17@gmail.com> 1780654581 +0300
committer giselesikeh <giselesikeh17@gmail.com> 1780654581 +0300

test: unsigned commit should fail

Signed-off-by: giselesikeh <giselesikeh17@gmail.com>
```

#### Tree object contents

Command:

```bash
git cat-file -p 01e9b2e7a6d5fccf3268951664c73dd6b4357db6
```

Output:

```text
040000 tree d0f15a494317a8a43f617b9d4784429b9c5167ab    .github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures
```

#### Blob object contents

Command:

```bash
git cat-file -p d10c04c6e7e0014f4fe883599c11747c15012d4e
```

Output excerpt:

```text
# DevOps Intro — Modern DevOps Practices Through One Project

A 10-week practical introduction to DevOps at Innopolis University. You will package, ship, observe, harden, and deploy one Go service — QuickNotes — across every lab.
```

#### Interpretation

This shows the Git object chain clearly. `HEAD` points to a commit object. The commit object points to a tree object. The tree object stores file and directory entries, including a blob for `README.md`. The blob stores the actual file contents.

---

### 1.2 Look inside `.git/`

#### High-level `.git/` contents

Command:

```bash
ls -la .git/
```

Output excerpt:

```text
COMMIT_EDITMSG
FETCH_HEAD
HEAD
ORIG_HEAD
config
description
hooks/
index
info/
logs/
objects/
packed-refs
refs/
```

#### Current HEAD ref

Command:

```bash
cat .git/HEAD
```

Output:

```text
ref: refs/heads/main
```

#### Local branches inside refs

Command:

```bash
ls .git/refs/heads/
```

Output:

```text
feature/  main
```

#### Object directory prefixes

Command:

```bash
ls .git/objects/ | head
```

Output:

```text
01/
03/
0a/
0c/
0e/
0f/
10/
13/
16/
18/
```

#### Number of loose objects

Command:

```bash
find .git/objects -type f | wc -l
```

Output:

```text
47
```

#### Interpretation

The `.git/` directory contains the real Git repository data. `HEAD` stores the current branch reference. The `refs/heads/` directory stores local branch references. The `objects/` directory stores Git objects, organized by the first two characters of their SHA. The repository had 47 loose object files at this point.

---

### 1.3 Simulate disaster and recover

#### Created Lab 2 branch and commits

Commands:

```bash
git switch -c feature/lab2
mkdir -p submissions
echo "important work" > submissions/lab2.md
git add submissions/lab2.md
git commit -S -s -m "wip(lab2): start"

echo "more important work" >> submissions/lab2.md
git commit -S -s -am "wip(lab2): more progress"
```

Output excerpt:

```text
Switched to a new branch 'feature/lab2'

[feature/lab2 b29a5ab] wip(lab2): start
 1 file changed, 1 insertion(+)
 create mode 100644 submissions/lab2.md

[feature/lab2 ce50924] wip(lab2): more progress
 1 file changed, 1 insertion(+)
```

#### Destructive reset

Command:

```bash
git reset --hard HEAD~2
```

Output:

```text
HEAD is now at 4c47506 test: unsigned commit should fail
```

#### Status after reset

Command:

```bash
git status
```

Output:

```text
On branch feature/lab2
nothing to commit, working tree clean
```

#### Log after reset

Command:

```bash
git log --oneline -3
```

Output:

```text
4c47506 test: unsigned commit should fail
a8b97cf docs: add PR template
66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
```

#### Reflog showing lost commits

Command:

```bash
git reflog
```

Output excerpt:

```text
4c47506 HEAD@{0}: reset: moving to HEAD~2
ce50924 HEAD@{1}: commit: wip(lab2): more progress
b29a5ab HEAD@{2}: commit: wip(lab2): start
4c47506 HEAD@{3}: checkout: moving from main to feature/lab2
```

#### Recovery command

Command:

```bash
git reset --hard ce50924
```

Output:

```text
HEAD is now at ce50924 wip(lab2): more progress
```

#### Status after recovery

Command:

```bash
git status
```

Output:

```text
On branch feature/lab2
nothing to commit, working tree clean
```

#### Log after recovery

Command:

```bash
git log --oneline -3
```

Output:

```text
ce50924 wip(lab2): more progress
b29a5ab wip(lab2): start
4c47506 test: unsigned commit should fail
```

#### Explanation of `git gc` risk

The reflog kept the lost commits reachable long enough for recovery. If an aggressive `git gc` had run after the reset and before recovery, the unreachable commits could eventually be pruned from `.git/objects/`. In normal Git settings, reflog retention usually gives a recovery window, but in CI or aggressive cleanup environments this window may be shorter, so it is important to capture the lost SHA immediately.

---

## Task 2 — Tag a Release and Rebase a Feature

### 2.1 Annotated signed release tag

#### Create and push tag

Commands:

```bash
git switch main
git pull --ff-only upstream main
git tag -a -s "v0.1.0-lab2-giselesikeh" -m "Lab 2 milestone — version control deep dive"
git push origin "v0.1.0-lab2-giselesikeh"
```

Output excerpt:

```text
Switched to branch 'main'
Already up to date.

[new tag] v0.1.0-lab2-giselesikeh -> v0.1.0-lab2-giselesikeh
```

#### Confirm tag is annotated

Command:

```bash
git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'
```

Output:

```text
v0.0.1 tag commit
v0.1.0-lab2-giselesikeh tag commit
```

#### Verify tag signature

Command:

```bash
git tag -v "v0.1.0-lab2-giselesikeh"
```

Output:

```text
object 4c475060d9eacc2d506e7eef7036cdaf76fc3d90
type commit
tag v0.1.0-lab2-giselesikeh
tagger giselesikeh <giselesikeh17@gmail.com> 1780668740 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for giselesikeh17@gmail.com with ED25519 key SHA256:pUth00w97iamHSgYiurlLAxO+foOF8m/sj25saSc0mU
```

---

### 2.2 Rebase and force-with-lease

#### Simulate upstream moving

Commands:

```bash
git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
git push origin main
```

Output excerpt:

```text
[main 1025a8b] docs: upstream moved while you worked
To github.com:giselesikeh/DevOps-Intro.git
   4c47506..1025a8b  main -> main
```

#### Log before rebase

Command:

```bash
git switch feature/lab2
git log --oneline --graph --decorate -5
```

Output:

```text
* ce50924 (HEAD -> feature/lab2) wip(lab2): more progress
* b29a5ab wip(lab2): start
* 4c47506 (tag: v0.1.0-lab2-giselesikeh) test: unsigned commit should fail
* a8b97cf docs: add PR template
* 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
```

#### Rebase command

Commands:

```bash
git fetch origin
git rebase origin/main
```

Output:

```text
Successfully rebased and updated refs/heads/feature/lab2.
```

#### Log after rebase

Command:

```bash
git log --oneline --graph --decorate -5
```

Output:

```text
* 6dbcc9e (HEAD -> feature/lab2) wip(lab2): more progress
* 870d745 wip(lab2): start
* 1025a8b (origin/main, origin/HEAD, main) docs: upstream moved while you worked
* 4c47506 (tag: v0.1.0-lab2-giselesikeh) test: unsigned commit should fail
* a8b97cf docs: add PR template
```

#### Push rebased branch safely

Command:

```bash
git push --force-with-lease origin feature/lab2
```

Output excerpt:

```text
To github.com:giselesikeh/DevOps-Intro.git
 * [new branch]      feature/lab2 -> feature/lab2
```

---

### 2.3 Merge vs Rebase Reflection

I would use rebase on my own feature branch when I want a clean, linear history before opening a pull request. This is useful because it makes the branch easier to review and keeps my commits on top of the latest `main`. I would use merge when combining completed work into a shared or public branch, because merge preserves the true branch history and does not rewrite commits that other people may already depend on.

---

## Bonus Task — Bisect a Real Bug

### B.1 Set up bisect

Commands:

```bash
git fetch upstream
git switch -c bisect-quickn upstream/bug/bisect-me
git bisect start
git bisect bad HEAD
git bisect good v0.0.1
```

Output excerpt:

```text
branch 'bisect-quickn' set up to track 'upstream/bug/bisect-me'.
Switched to a new branch 'bisect-quickn'

status: waiting for both good and bad commits
status: waiting for good commit(s), bad commit known

Bisecting: 1 revision left to test after this (roughly 1 step)
[f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
```

### B.2 Automated bisect run

Command:

```bash
git bisect run sh -c 'cd app && go test ./... && go build ./...'
```

Output:

```text
running  'sh' '-c' 'cd app && go test ./... && go build ./...'
--- FAIL: TestStorePersistsAcrossReload (0.01s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL    quicknotes      0.795s
FAIL
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89b9e2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
running  'sh' '-c' 'cd app && go test ./... && go build ./...'
ok      quicknotes      0.795s
f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
commit f285ede8611e55ac0a7d01100891c0cc775e0709
Author: Dmitrii Creed <creed22@gmail.com>
Date:   Fri Jun 5 13:36:56 2026 +0400

    refactor(store): simplify nextID restoration in load()

    Signed-off-by: Dmitrii Creed <creed22@gmail.com>

app/store.go | 2 +-
1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first bad commit
```

### B.3 Bisect log

Command:

```bash
git bisect log
```

Output:

```text
git bisect start
# status: waiting for both good and bad commits
# bad: [f0c9243b7c80ebb93a1ce7048a1d65b4c2ac493] docs(app): mention go test invocation
git bisect bad f0c9243b7c80ebb93a1ce7048a1d65b4c2ac493
# status: waiting for good commit(s), bad commit known
# good: [0ec878b80ae6a257a98ecea4a3c8d38a7f2c5ac7] chore(app): document versioning scheme (bisect fixture baseline)
git bisect good 0ec878b80ae6a257a98ecea4a3c8d38a7f2c5ac7
# bad: [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
git bisect bad f285ede8611e55ac0a7d01100891c0cc775e0709
# good: [cb89b9e2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
git bisect good cb89b9e2ee5010b166061447eaca3ae0da2378
# first bad commit: [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
```

### B.4 Offending commit

The offending commit is:

```text
f285ede8611e55ac0a7d01100891c0cc775e0709
```

Commit message:

```text
refactor(store): simplify nextID restoration in load()
```

### B.5 Explanation

`git bisect` found the bug by doing a binary search between a known good commit and a known bad commit. Instead of checking every commit manually, Git selected a commit halfway between the two points and used the test command to classify it as good or bad. Each result cut the remaining search space roughly in half, so the bug was found in about `log₂(N)` steps. In this case, the failing test showed that `nextID` was not restored correctly after reloading the store, and bisect identified the first commit that introduced that regression.


