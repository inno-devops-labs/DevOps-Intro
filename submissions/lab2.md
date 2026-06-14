# Lab 2 Submission

## Task 1: Git Object Model and Reflog Recovery

### 1.1 Object Chain: HEAD -> Tree -> Blob -> File

```bash
git rev-parse HEAD
```

```text
187f4a96ec544458295358c5be2c2b0240d2130c
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
tree 651ea749429462ed43f200ce6cbb43507cc03aa9
parent 66bbd4db9228bc9a4cab7439746b993749c026ab
author whynotgm <a.shiian@innopolis.university> 1780834860 +0300
committer whynotgm <a.shiian@innopolis.university> 1780834860 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgF5d5oB6QPMrXv84M9itOrDJkW9
 GtmlMwuUdp+D3T2S0AAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQKH8F+jPgW/EiVkqwzYO+e13F5dh1Y1MeX1HITxkDn84j5O4vy6T2tlKeEwp3WQJ6X
 qA6PC3obCiMJUS5paAiAA=
 -----END SSH SIGNATURE-----

docs: add PR template

Signed-off-by: whynotgm <a.shiian@innopolis.university>
```

```bash
git cat-file -p 651ea749429462ed43f200ce6cbb43507cc03aa9
```

```text
040000 tree 4718e71bbbfe37e3d846cecbb1c43cf72b4fa94d	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 6db686e340ecdd318fa43375e26254293371942a	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
```

```bash
git cat-file -p 4718e71bbbfe37e3d846cecbb1c43cf72b4fa94d
```

```text
100644 blob 3da493f8e243105189866af7574ab9ae8c51357f	pull_request_template.md
```

```bash
git cat-file -p 3da493f8e243105189866af7574ab9ae8c51357f
```

```text
## Goal
<!-- What does this PR accomplish? 1 sentence. -->

## Changes
-

## Testing
<!-- How did you verify it? -->

## Checklist
- [ ] Title is a clear sentence (<= 70 chars)
- [ ] Commits are signed (`git log --show-signature`)
- [ ] `submissions/labN.md` updated
```

The commit object points to a tree object, and that tree lists file and directory entries by object SHA. The `.github` entry is another tree, and its `pull_request_template.md` entry is a blob, so `git cat-file -p` prints the file contents directly.

### 1.2 Inside `.git/`

```bash
ls -la .git/
```

```text
total 64
drwxr-xr-x@ 17 shiyan.aleksandr3  staff   544 Jun  9 15:32 .
drwxr-xr-x@  9 shiyan.aleksandr3  staff   288 Jun  9 15:32 ..
-rw-r--r--@  1 shiyan.aleksandr3  staff    31 Jun  8 12:16 COMMIT_EDITMSG
-rw-r--r--@  1 shiyan.aleksandr3  staff   969 Jun  9 15:31 FETCH_HEAD
-rw-r--r--@  1 shiyan.aleksandr3  staff    21 Jun  9 15:32 HEAD
-rw-r--r--@  1 shiyan.aleksandr3  staff    41 Jun  8 12:16 ORIG_HEAD
-rw-r--r--@  1 shiyan.aleksandr3  staff   573 Jun  7 15:29 config
-rw-r--r--@  1 shiyan.aleksandr3  staff    73 Jun  3 17:39 description
drwxr-xr-x@  3 shiyan.aleksandr3  staff    96 Jun  3 17:40 fsmonitor--daemon
srwxr-xr-x@  1 shiyan.aleksandr3  staff     0 Jun  7 15:18 fsmonitor--daemon.ipc
drwxr-xr-x@ 16 shiyan.aleksandr3  staff   512 Jun  3 17:39 hooks
-rw-r--r--@  1 shiyan.aleksandr3  staff  3183 Jun  9 15:32 index
drwxr-xr-x@  3 shiyan.aleksandr3  staff    96 Jun  3 17:39 info
drwxr-xr-x@  4 shiyan.aleksandr3  staff   128 Jun  3 17:39 logs
drwxr-xr-x@ 61 shiyan.aleksandr3  staff  1952 Jun  9 15:31 objects
-rw-r--r--@  1 shiyan.aleksandr3  staff   112 Jun  3 17:39 packed-refs
drwxr-xr-x@  6 shiyan.aleksandr3  staff   192 Jun  3 17:40 refs
```

```bash
cat .git/HEAD
```

```text
ref: refs/heads/main
```

```bash
ls .git/refs/heads/
```

```text
feature
main
```

```bash
ls .git/objects/ | head
```

```text
04
09
0a
0c
0e
0f
12
13
18
1a
```

```bash
find .git/objects -type f | wc -l
```

```text
      65
```

`HEAD` is a symbolic reference to the current branch. `refs/heads/` stores local branch refs, and `objects/` is split into directories named by the first two hexadecimal characters of object IDs. This repo had 65 loose object files at the time of inspection; other objects may also be stored in packfiles.

### 1.3 Reset Disaster and Recovery

I created `feature/lab2`, committed the temporary file once, added a second line, and committed again:

```text
[feature/lab2 dae26b3] wip(lab2): start
 1 file changed, 1 insertion(+)
 create mode 100644 submissions/lab2.md

[feature/lab2 537228d] wip(lab2): more progress
 1 file changed, 1 insertion(+)
```

Before the reset:

```bash
git log --oneline --decorate --max-count=5
```

```text
537228d (HEAD -> feature/lab2) wip(lab2): more progress
dae26b3 wip(lab2): start
187f4a9 (origin/main, origin/HEAD, main) docs: add PR template
66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
```

The destructive reset:

```bash
git reset --hard HEAD~2
```

```text
HEAD is now at 187f4a9 docs: add PR template
```

After the reset:

```bash
git status
```

```text
On branch feature/lab2
nothing to commit, working tree clean
```

```bash
git log --oneline --decorate --max-count=5
```

```text
187f4a9 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) docs: add PR template
66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
d50436c (upstream/s26-refactor) fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
4705a3d fix(.gitignore): stop ignoring submissions/
```

Reflog still had the lost commits:

```bash
git reflog --date=iso --max-count=12
```

```text
187f4a9 HEAD@{2026-06-09 15:33:31 +0300}: reset: moving to HEAD~2
537228d HEAD@{2026-06-09 15:33:21 +0300}: commit: wip(lab2): more progress
dae26b3 HEAD@{2026-06-09 15:33:14 +0300}: commit: wip(lab2): start
187f4a9 HEAD@{2026-06-09 15:32:53 +0300}: checkout: moving from main to feature/lab2
187f4a9 HEAD@{2026-06-09 15:32:22 +0300}: checkout: moving from feature/lab1 to main
0979bf4 HEAD@{2026-06-08 12:16:24 +0300}: commit: docs(lab1, task2): PR evidence
d5ab80d HEAD@{2026-06-08 12:11:38 +0300}: commit: docs(lab1): bonus task
f8a96ca HEAD@{2026-06-08 12:09:55 +0300}: checkout: moving from main to feature/lab1
187f4a9 HEAD@{2026-06-08 12:09:44 +0300}: reset: moving to origin/main
45c1414 HEAD@{2026-06-08 12:05:23 +0300}: commit: Your commit message
187f4a9 HEAD@{2026-06-08 12:04:55 +0300}: reset: moving to HEAD^
1f0bb37 HEAD@{2026-06-08 12:03:18 +0300}: commit: Your commit message
```

Recovery:

```bash
git reset --hard 537228d
```

```text
HEAD is now at 537228d wip(lab2): more progress
```

```bash
git status
```

```text
On branch feature/lab2
nothing to commit, working tree clean
```

If `git gc` had run aggressively before recovery, the unreachable commits might eventually have been pruned after their reflog/object grace periods expired. Normal Git settings usually keep reflog entries and unreachable objects long enough to recover, but CI systems or manual `git gc --prune=now` can remove the safety net. The safest move after a bad reset is to copy the reflog SHA immediately.

## Task 2: Signed Tag and Rebase

### 2.1 Annotated Signed Tag

```bash
git pull --ff-only upstream main
```

```text
From https://github.com/inno-devops-labs/DevOps-Intro
 * branch            main       -> FETCH_HEAD
Already up to date.
```

```bash
git tag -a -s "v0.1.0-lab2-shiyan.aleksandr3" -m "Lab 2 milestone - version control deep dive"
git push origin "v0.1.0-lab2-shiyan.aleksandr3"
```

```text
To https://github.com/whynotgm/DevOps-Intro
 * [new tag]         v0.1.0-lab2-shiyan.aleksandr3 -> v0.1.0-lab2-shiyan.aleksandr3
```

```bash
git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'
```

```text
v0.0.1 tag commit
v0.1.0-lab2-shiyan.aleksandr3 tag commit
```

```bash
git tag -v "v0.1.0-lab2-shiyan.aleksandr3"
```

```text
Good "git" signature with ED25519 key SHA256:1+FN7gbX/oPuOkViQ3tkxMNih4MR/jJIPbeyF52zax8
No principal matched.
object 187f4a96ec544458295358c5be2c2b0240d2130c
type commit
tag v0.1.0-lab2-shiyan.aleksandr3
tagger whynotgm <a.shiian@innopolis.university> 1781008445 +0300

Lab 2 milestone - version control deep dive
```

The tag is annotated because its object type is `tag`, and it points to a commit via `*objecttype`. Verification shows a good SSH signature; the "No principal matched" line means the local `allowed_signers` file did not map the signer principal, not that the tag is unsigned.

### 2.2 Rebase and Force-With-Lease

I simulated `main` moving:

```bash
git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
```

```text
[main b40820b] docs: upstream moved while you worked
```

Direct push to `origin/main` was blocked by the branch protection configured during Lab 1:

```bash
git push origin main
```

```text
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote:
remote: - Changes must be made through a pull request.
To https://github.com/whynotgm/DevOps-Intro
 ! [remote rejected] main -> main (protected branch hook declined)
error: failed to push some refs to 'https://github.com/whynotgm/DevOps-Intro'
```

Because the protected branch correctly rejected direct pushes, I rebased `feature/lab2` onto the local signed `main` commit that represented the simulated upstream movement.

Before rebase:

```bash
git log --oneline --graph --decorate --all --max-count=15
```

```text
* b40820b (main) docs: upstream moved while you worked
| * 537228d (HEAD -> feature/lab2) wip(lab2): more progress
| * dae26b3 wip(lab2): start
|/
| * 0979bf4 (origin/feature/lab1, feature/lab1) docs(lab1, task2): PR evidence
| * d5ab80d docs(lab1): bonus task
| * f8a96ca feat(lab1): signing screenshot
| * 3ca3dc8 docs(lab1): add signature evidence
| * ad68bde docs(lab1): complete submission
|/
* 187f4a9 (tag: v0.1.0-lab2-shiyan.aleksandr3, origin/main, origin/HEAD) docs: add PR template
| * f0c9243 (upstream/bug/bisect-me) docs(app): mention go test invocation
| * 9fe75cc docs(store): document Count()
| * f285ede refactor(store): simplify nextID restoration in load()
| * cb89bb9 docs(store): comment the load() decode step
| * 0ec87b8 (tag: v0.0.1) chore(app): document versioning scheme (bisect fixture baseline)
|/
* 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
```

```bash
git rebase main
```

```text
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/lab2.
```

After rebase, before this final documentation commit:

```bash
git log --oneline --graph --decorate --all --max-count=15
```

```text
* 0bfe9f7 (HEAD -> feature/lab2) wip(lab2): more progress
* 53b3691 wip(lab2): start
* b40820b (main) docs: upstream moved while you worked
| * 0979bf4 (origin/feature/lab1, feature/lab1) docs(lab1, task2): PR evidence
| * d5ab80d docs(lab1): bonus task
| * f8a96ca feat(lab1): signing screenshot
| * 3ca3dc8 docs(lab1): add signature evidence
| * ad68bde docs(lab1): complete submission
|/
* 187f4a9 (tag: v0.1.0-lab2-shiyan.aleksandr3, origin/main, origin/HEAD) docs: add PR template
| * f0c9243 (upstream/bug/bisect-me) docs(app): mention go test invocation
| * 9fe75cc docs(store): document Count()
| * f285ede refactor(store): simplify nextID restoration in load()
| * cb89bb9 docs(store): comment the load() decode step
| * 0ec87b8 (tag: v0.0.1) chore(app): document versioning scheme (bisect fixture baseline)
|/
* 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
```

I would choose merge when preserving the exact shared history is more important than a tidy commit sequence, especially on long-lived integration branches. I would choose rebase for local or feature-branch cleanup before review, where replaying my commits on the newest base makes the PR easier to read. I would avoid rebasing public shared branches unless the team explicitly agreed to rewrite that history.

## Bonus Task: Bisect a Real Bug

```bash
git switch -c bisect-quickn upstream/bug/bisect-me
git bisect start
git bisect bad HEAD
git bisect good v0.0.1
git bisect run sh -c 'cd app && go test ./... && go build ./...'
```

Automated bisect output:

```text
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
--- FAIL: TestStore_PersistsAcrossReload (0.00s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL	quicknotes	0.322s
FAIL
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
ok  	quicknotes	0.318s
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

```bash
git bisect log
```

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

Offending commit:

```text
f285ede8611e55ac0a7d01100891c0cc775e0709 refactor(store): simplify nextID restoration in load()
```

`git bisect` performs a binary search between a known-good and known-bad commit. Instead of checking every commit one by one, it tests a midpoint, discards half of the remaining search space, and repeats. That means the number of test runs grows around `log2(N)` rather than `N`, which is why this bug was found with only two automated test points in a five-commit range.
