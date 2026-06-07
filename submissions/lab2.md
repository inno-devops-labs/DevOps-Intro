# Lab 2 Submission

## Task 1 - Git Object Model and Reflog Recovery

### 1.1 Object Chain

I inspected one object chain from `HEAD` to the root tree, then the `app` tree, then the `app/go.mod` blob.

```text
$ git rev-parse HEAD
39bb854a713d3e1cc1d6091bbe57290ec872eba1

$ git cat-file -t HEAD
commit

$ git cat-file -p HEAD
tree 6e00068ef4b4cf2c0d0006ccd4a89b64e8fb164c
parent 2917077cebd5504bb75f658c11e47d6ab46b216e
author BearAx <medvedguk@gmail.com> 1780833436 +0300
committer BearAx <medvedguk@gmail.com> 1780833826 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgu2ywo50btBRASCWu78XCtSuEDP
 DikyJa4mW2JEhGpLYAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQNDMlNrEXqWP3eH2FlRdUYZlB8mzs/vfJNJnNeqOJxram8XScSlO+9c4Pli32wyY7p
 Cs9R40Ax06rMgTQbehSg4=
 -----END SSH SIGNATURE-----

wip(lab2): more progress

Signed-off-by: BearAx <medvedguk@gmail.com>

$ git cat-file -p 6e00068ef4b4cf2c0d0006ccd4a89b64e8fb164c
040000 tree 4718e71bbbfe37e3d846cecbb1c43cf72b4fa94d    .github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures
040000 tree 515cfb1afc6c0b8bd473997c34903798ff3976ba    submissions

$ git cat-file -p 7d0898a908e274ea809722844cdbd836f3b1c05a
100644 blob 8ba1a5234925005265281bf7809153487097373c    .golangci.yml
100644 blob 24ab0258318f4aac6ec7d3a924a1d6f05209b446    Makefile
100644 blob 1aed7f8904100182d3fb4e1b90dbf3bd5a126beb    README.md
100644 blob b76e91cf916dcebc1d6898e22012c737c117003a    go.mod
100644 blob c534979c5a3aa0e032fb61e1562d4bd343ecaf4c    handlers.go
100644 blob 9dff2e3e5b734f9afa4bc26c30d784bee8aa327c    handlers_test.go
100644 blob e258ffcfe44ebc6923eb78d51c63fc2317aa1dfd    main.go
100644 blob ecf4fd2edd38dcbc82459122660aa424342f9148    seed.json
100644 blob 4a9ca2b3a371cc43f8762095a6944cd96ea7d7d0    store.go
100644 blob 3b8ff9d45ae9e6781ffe333ccc7eff40da35a1bf    store_test.go

$ git cat-file -p b76e91cf916dcebc1d6898e22012c737c117003a
module quicknotes

go 1.24
```

This shows that a commit object points to a tree object, a tree object maps names to other trees and blobs, and a blob stores raw file contents.

### 1.2 Inside `.git`

PowerShell equivalents were used for `ls`, `cat`, and `find | wc -l`.

```text
$ Get-ChildItem -Force .git
Mode   Length Name
----   ------ ----
d-----        hooks
d-----        info
d-----        logs
d-----        objects
d-----        refs
-a---- 83     COMMIT_EDITMSG
-a---- 845    config
-a---- 73     description
-a---- 331    FETCH_HEAD
-a---- 29     HEAD
-a---- 3307   index
-a---- 41     ORIG_HEAD
-a---- 112    packed-refs

$ Get-Content .git/HEAD
ref: refs/heads/feature/lab2

$ Get-ChildItem .git/refs/heads
feature
bisect-quickn
main

$ Get-ChildItem .git/objects | Select-Object -First 20
05
09
0a
0b
0c
0e
0f
10
13
1a
1c
25
27
29
2a
2d
33
38
39
3a

$ Get-ChildItem .git/objects -Recurse -File | Measure-Object
91
```

`.git/HEAD` is a symbolic ref to the current branch, and `.git/refs/heads` stores local branch refs. `.git/objects` is split by the first two hex characters of object IDs; this repo had 91 loose object files at the time I counted it.

### 1.3 Reset Disaster and Recovery

Before the reset, the two WIP commits were present on `feature/lab2`.

```text
$ git log --oneline --graph -5
* 0b7edb7 wip(lab2): more progress
* 094c381 wip(lab2): start
* e3dd7a4 docs: add PR template
* 66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
|\

$ git reset --hard HEAD~2
HEAD is now at e3dd7a4 docs: add PR template

$ git status
On branch feature/lab2
nothing to commit, working tree clean

$ git log --oneline -5
e3dd7a4 docs: add PR template
66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
d50436c fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
4705a3d fix(.gitignore): stop ignoring submissions/

$ git reflog -8
e3dd7a4 HEAD@{0}: reset: moving to HEAD~2
0b7edb7 HEAD@{1}: commit: wip(lab2): more progress
094c381 HEAD@{2}: commit: wip(lab2): start
e3dd7a4 HEAD@{3}: checkout: moving from main to feature/lab2
e3dd7a4 HEAD@{4}: checkout: moving from feature/lab1 to main
c28e856 HEAD@{5}: rebase (finish): returning to refs/heads/feature/lab1
c28e856 HEAD@{6}: commit (amend): Add files via upload
791bedb HEAD@{7}: rebase (pick): Add files via upload
```

Recovery:

```text
$ git reset --hard 0b7edb7
HEAD is now at 0b7edb7 wip(lab2): more progress

$ git status
On branch feature/lab2
nothing to commit, working tree clean

$ git log --oneline --graph -5
* 0b7edb7 wip(lab2): more progress
* 094c381 wip(lab2): start
* e3dd7a4 docs: add PR template
* 66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
|\
```

If `git gc` had run aggressively between the bad reset and recovery, the reflog entry might still name the old commit SHA, but the underlying unreachable objects could have been pruned. With Git's normal grace periods, recently unreachable commits are usually retained long enough to recover, but CI or manual `git gc --prune=now` could remove them much sooner. The safe move is to copy the SHA from reflog and recover before experimenting further.

## Task 2 - Tag, Rebase, and Force-With-Lease

### 2.1 Signed Annotated Tag

The signed annotated tag was created as `v0.1.0-lab2-BearAx`.

```text
$ git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)' | Select-String 'v0.1.0-lab2-BearAx'
v0.1.0-lab2-BearAx tag commit

$ git tag -v v0.1.0-lab2-BearAx
object e3dd7a477cecf92eca42bf9dc40ea617cc782456
type commit
tag v0.1.0-lab2-BearAx
tagger BearAx <medvedguk@gmail.com> 1780833568 +0300

Lab 2 milestone - version control deep dive

Good "git" signature for medvedguk@gmail.com with ED25519 key SHA256:pvAaeUNT8jpJ+FusyKkvPM4x2Z1kjYJcBnR0JcCB2lg

$ git push origin v0.1.0-lab2-BearAx
To github.com:BearAx/DevOps-Intro.git
 * [new tag]         v0.1.0-lab2-BearAx -> v0.1.0-lab2-BearAx
```

### 2.2 Rebase

`main` was synced from the public upstream over HTTPS because SSH access to `upstream` was not authorized for this key.

```text
$ git pull --ff-only https://github.com/inno-devops-labs/DevOps-Intro.git main
Already up to date.
From https://github.com/inno-devops-labs/DevOps-Intro
 * branch            main       -> FETCH_HEAD
```

I created the signed empty commit requested by the lab:

```text
$ git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
[main 4b6195c] docs: upstream moved while you worked
```

Because my Lab 1 branch protection intentionally blocks direct pushes to `main`, I could not update `origin/main` directly. To keep the same learning objective, I rebased `feature/lab2` onto the locally advanced `main` commit and documented the branch protection rejection as the reason for this deviation.

```text
$ git push origin main
remote: error: GH013: Repository rule violations found for refs/heads/main.
remote: Review all repository rules at https://github.com/BearAx/DevOps-Intro/rules?ref=refs%2Fheads%2Fmain
remote:
remote: - Changes must be made through a pull request.
remote:
To github.com:BearAx/DevOps-Intro.git
 ! [remote rejected] main -> main (push declined due to repository rule violations)
error: failed to push some refs to 'github.com:BearAx/DevOps-Intro.git'
```

Before rebase:

```text
$ git log --oneline --graph --decorate --all -8
* 4b6195c (main) docs: upstream moved while you worked
| * 0b7edb7 (HEAD -> feature/lab2) wip(lab2): more progress
| * 094c381 wip(lab2): start
|/
* e3dd7a4 (tag: v0.1.0-lab2-BearAx, origin/main, origin/HEAD) docs: add PR template
| * c28e856 (origin/feature/lab1, feature/lab1) Add files via upload
| * c4206a3 Modify community checklist and add branch protection evidence
| * 333b7f4 Mark completed tasks in community checklist
| * f84bff7 Add screenshot for PR evidence in lab1.md
```

Rebase:

```text
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/lab2.
```

After rebase:

```text
$ git log --oneline --graph --decorate --all -8
* 39bb854 (HEAD -> feature/lab2) wip(lab2): more progress
* 2917077 wip(lab2): start
* 4b6195c (main) docs: upstream moved while you worked
* e3dd7a4 (tag: v0.1.0-lab2-BearAx, origin/main, origin/HEAD) docs: add PR template
| * c28e856 (origin/feature/lab1, feature/lab1) Add files via upload
| * c4206a3 Modify community checklist and add branch protection evidence
| * 333b7f4 Mark completed tasks in community checklist
| * f84bff7 Add screenshot for PR evidence in lab1.md
```

### Merge vs Rebase Reflection

I would use rebase for my own feature branch before review because it keeps the branch linear and makes the final PR easier to inspect. I would use merge when combining shared branches or preserving the exact integration history matters more than a clean linear story. I would not rebase commits that other people may already be building on unless the team agreed to rewrite that branch.

## Bonus Task - Bisect

I ran the automated bisect command against `upstream/bug/bisect-me`.

```text
$ git bisect run sh -c 'cd app && go test ./... && go build ./...'
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
--- FAIL: TestStore_PersistsAcrossReload (0.01s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL    quicknotes    0.569s
FAIL
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
ok      quicknotes    0.550s
f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
```

Full bisect log:

```text
$ git bisect log
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
f285ede8611e55ac0a7d01100891c0cc775e0709
refactor(store): simplify nextID restoration in load()
Dmitrii Creed <creeed22@gmail.com>
Fri Jun 5 13:36:56 2026 +0400
```

Bisect works in about `log2(N)` steps because each test splits the remaining commit range into two halves. In this run, Git tested `f285ede...` and found it bad, then tested `cb89bb9...` and found it good, which was enough to prove that `f285ede...` was the first bad commit. This is much faster than manually reading or testing each commit in order when a regression range is large.
