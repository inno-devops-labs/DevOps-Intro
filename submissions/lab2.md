# Lab 2 Submission

## Task 1. Git Object Model and Reflog Recovery

### 1.1 Git object chain

```powershell
git rev-parse HEAD
```

```text
5d37ace628815ee1beccedb8fbd2b28f076eb122
```

```powershell
git cat-file -t HEAD
```

```text
commit
```

```powershell
git cat-file -p HEAD
```

```text
tree ef09126301250ea65f75d4da8a5a5300cfd381da
parent bfa345b2244ccfe8ae4d92caa24ed90f13fa6282
author Ilia Siaglov <ilya.syaglovv@gmail.com> 1781629372 +0800
committer Ilia Siaglov <ilya.syaglovv@gmail.com> 1781629372 +0800
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgZ9Z0eriILx4QT5q5NWAd5iVRfS
 Li2xq7KJGkgvif8+MAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQOLmOIaIOrSaBOblP32ro/2DwOutDidl59MurzK/gkxMYBKcwawIsgSBg/w7uAI1vu
 YRyhr07cEocjpa7tjuIAs=
 -----END SSH SIGNATURE-----

docs: add PR template

Signed-off-by: Ilia Siaglov <ilya.syaglovv@gmail.com>
```

```powershell
git cat-file -p ef09126301250ea65f75d4da8a5a5300cfd381da
```

```text
040000 tree 0485ce90c18b287a115068921ea29b64ccd4e6f8	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 89bc50bc368eff78a23dcf65c83a925674de2e66	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
```

```powershell
git cat-file -p d10c04c6e7e0014f4fe883599c11747c15012d4e
```

```text
# DevOps Intro - Modern DevOps Practices Through One Project

A 10-week practical introduction to DevOps at Innopolis University. You will package, ship, observe, harden, and deploy one Go service - QuickNotes - across every lab.
```

This chain shows that `HEAD` is a commit object. The commit points to a tree object, and that tree maps filenames to either nested trees or blob objects. The selected blob is the stored content of `README.md`.

### 1.2 Inside `.git/`

```powershell
Get-ChildItem -Force .git | Format-Table Mode,LastWriteTime,Length,Name -AutoSize
```

```text
Mode   LastWriteTime      Length Name
----   -------------      ------ ----
d----- 17.06.2026 0:47:12        hooks
d----- 17.06.2026 0:47:12        info
d----- 17.06.2026 0:47:15        logs
d----- 17.06.2026 1:19:02        objects
d----- 17.06.2026 0:47:15        refs
-a---- 17.06.2026 1:15:18 83     COMMIT_EDITMSG
-a---- 17.06.2026 1:03:36 568    config
-a---- 17.06.2026 0:47:12 73     description
-a---- 17.06.2026 1:18:33 845    FETCH_HEAD
-a---- 17.06.2026 1:19:19 29     HEAD
-a---- 17.06.2026 1:19:02 3183   index
-a---- 17.06.2026 0:47:15 112    packed-refs
```

```powershell
Get-Content .git\HEAD
```

```text
ref: refs/heads/feature/lab2
```

```powershell
Get-ChildItem .git\refs\heads -Recurse | ForEach-Object { $_.FullName.Replace((Resolve-Path .).Path + '\', '') }
```

```text
.git\refs\heads\feature
.git\refs\heads\main
.git\refs\heads\feature\lab1
.git\refs\heads\feature\lab2
```

```powershell
Get-ChildItem .git\objects | Select-Object -First 10 -ExpandProperty Name
```

```text
04
0a
0c
0e
0f
13
1a
1e
3a
40
```

```powershell
(Get-ChildItem .git\objects -Recurse -File).Count
```

```text
43
```

`.git/HEAD` stores the current branch reference, while `.git/refs/heads` stores branch tips. `.git/objects` stores Git objects by SHA prefix, so directories like `04` and `0a` are the first two hex characters of object IDs. The `logs` directory is important for recovery because reflog records previous HEAD positions.

### 1.3 Disaster simulation and recovery

```powershell
git switch -c feature/lab2
New-Item -ItemType Directory -Force -Path .\submissions | Out-Null
Set-Content -LiteralPath .\submissions\lab2.md -Value 'important work' -NoNewline
git add submissions/lab2.md
git commit -S -s -m "wip(lab2): start"
Add-Content -LiteralPath .\submissions\lab2.md -Value "`nmore important work"
git commit -S -s -am "wip(lab2): more progress"
```

```text
[feature/lab2 516da06] wip(lab2): start
 1 file changed, 1 insertion(+)
 create mode 100644 submissions/lab2.md
[feature/lab2 450f0a9] wip(lab2): more progress
 1 file changed, 2 insertions(+), 1 deletion(-)
```

```powershell
git rev-parse HEAD
git reset --hard HEAD~2
git status --short --branch
git log --oneline -5
git reflog --date=iso -8
```

```text
450f0a9707e08708b959bcdd77a4be2432446cb2
HEAD is now at 5d37ace docs: add PR template
## feature/lab2
5d37ace docs: add PR template
bfa345b docs(lab3): matrix renames required checks - warn + ci-ok gate pattern; set honest cache expectations
356419b docs(lab1,lab2): clarify GitHub auth vs signing SSH key roles; add publickey-denied pitfalls
66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
5d37ace HEAD@{2026-06-17 01:19:58 +0800}: reset: moving to HEAD~2
450f0a9 HEAD@{2026-06-17 01:19:52 +0800}: commit: wip(lab2): more progress
516da06 HEAD@{2026-06-17 01:19:52 +0800}: commit: wip(lab2): start
5d37ace HEAD@{2026-06-17 01:19:19 +0800}: checkout: moving from main to feature/lab2
5d37ace HEAD@{2026-06-17 01:19:02 +0800}: checkout: moving from feature/lab1 to main
aa8c0e8 HEAD@{2026-06-17 01:15:18 +0800}: commit: docs(lab1): add screenshots
cd1acab HEAD@{2026-06-17 01:14:35 +0800}: commit: docs(lab1): add PR evidence
505d6ad HEAD@{2026-06-17 01:03:11 +0800}: commit: docs(lab1): finish submission
```

```powershell
git reset --hard 450f0a9707e08708b959bcdd77a4be2432446cb2
git status --short --branch
Get-Content -Raw .\submissions\lab2.md
```

```text
HEAD is now at 450f0a9 wip(lab2): more progress
## feature/lab2
important work
more important work
```

If `git gc` had run between the bad reset and the recovery, the commits could still survive while they are reachable from reflog entries. The risk appears when reflog entries expire or aggressive pruning is configured: then the unreachable commit objects may be removed from `.git/objects`, and the SHA from reflog would no longer be recoverable. This is why the first recovery step is to capture the lost commit SHA immediately.

## Task 2. Signed Tag and Rebase

### 2.1 Annotated signed release tag

```powershell
git switch main
git pull --ff-only upstream main
git tag -a -s "v0.1.0-lab2-fleter" -m "Lab 2 milestone - version control deep dive"
git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)' | Select-String -Pattern 'v0.1.0-lab2-fleter'
git tag -v "v0.1.0-lab2-fleter"
git push origin "v0.1.0-lab2-fleter"
```

```text
Your branch is up to date with 'origin/main'.
Already up to date.

v0.1.0-lab2-fleter tag commit
object 5d37ace628815ee1beccedb8fbd2b28f076eb122
type commit
tag v0.1.0-lab2-fleter
tagger Ilia Siaglov <ilya.syaglovv@gmail.com> 1781630422 +0800

Lab 2 milestone - version control deep dive

Good "git" signature for ilya.syaglovv@gmail.com with ED25519 key SHA256:okgWuKx7Da6Eg2TtpXSeKorFBfWAsRTW9m/cPSEGsOA
To https://github.com/fleter/DevOps-Intro.git
 * [new tag]         v0.1.0-lab2-fleter -> v0.1.0-lab2-fleter
```

The `tag commit` output means the tag is an annotated tag object pointing to a commit object. The `Good "git" signature` line confirms that the tag signature verifies successfully.

### 2.2 Rebase and force-with-lease

Branch graph before rebase:

```powershell
git log --oneline --graph --decorate --all --max-count=16
```

```text
* 450f0a9 (HEAD -> feature/lab2) wip(lab2): more progress
* 516da06 wip(lab2): start
| * aa8c0e8 (origin/feature/lab1, feature/lab1) docs(lab1): add screenshots
| * cd1acab docs(lab1): add PR evidence
| * 505d6ad docs(lab1): finish submission
|/
* 5d37ace (origin/main, origin/HEAD, main) docs: add PR template
* bfa345b (upstream/main, upstream/HEAD) docs(lab3): matrix renames required checks - warn + ci-ok gate pattern; set honest cache expectations
* 356419b docs(lab1,lab2): clarify GitHub auth vs signing SSH key roles; add publickey-denied pitfalls
| * f0c9243 (upstream/bug/bisect-me) docs(app): mention go test invocation
| * 9fe75cc docs(store): document Count()
| * f285ede refactor(store): simplify nextID restoration in load()
| * cb89bb9 docs(store): comment the load() decode step
| * 0ec87b8 (tag: v0.0.1) chore(app): document versioning scheme (bisect fixture baseline)
|/
* 66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
```

```powershell
git switch main
git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
git push origin main
```

```text
[main 67069b7] docs: upstream moved while you worked
To https://github.com/fleter/DevOps-Intro.git
   5d37ace..67069b7  main -> main
```

```powershell
git switch feature/lab2
git fetch origin
git rebase origin/main
git log --oneline --graph --decorate --all --max-count=16
git push --force-with-lease origin feature/lab2
```

```text
Successfully rebased and updated refs/heads/feature/lab2.
* 1bd17ab (HEAD -> feature/lab2) wip(lab2): more progress
* 27fd2ff wip(lab2): start
* 67069b7 (origin/main, origin/HEAD, main) docs: upstream moved while you worked
| * aa8c0e8 (origin/feature/lab1, feature/lab1) docs(lab1): add screenshots
| * cd1acab docs(lab1): add PR evidence
| * 505d6ad docs(lab1): finish submission
|/
* 5d37ace (tag: v0.1.0-lab2-fleter) docs: add PR template
* bfa345b (upstream/main, upstream/HEAD) docs(lab3): matrix renames required checks - warn + ci-ok gate pattern; set honest cache expectations
* 356419b docs(lab1,lab2): clarify GitHub auth vs signing SSH key roles; add publickey-denied pitfalls
| * f0c9243 (upstream/bug/bisect-me) docs(app): mention go test invocation
| * 9fe75cc docs(store): document Count()
| * f285ede refactor(store): simplify nextID restoration in load()
| * cb89bb9 docs(store): comment the load() decode step
| * 0ec87b8 (tag: v0.0.1) chore(app): document versioning scheme (bisect fixture baseline)
|/
remote:
remote: Create a pull request for 'feature/lab2' on GitHub by visiting:
remote:      https://github.com/fleter/DevOps-Intro/pull/new/feature/lab2
remote:
To https://github.com/fleter/DevOps-Intro.git
 * [new branch]      feature/lab2 -> feature/lab2
```

I would choose merge for shared long-lived branches when preserving the exact collaboration history matters. I would choose rebase for local or personal feature branches before opening a PR, because it keeps the review history linear and removes unnecessary merge commits. I would avoid rebasing commits that other people may already have based work on, unless the team explicitly agreed to rewrite that branch.

## Bonus Task. Bisect a Real Bug

I used the installed Go binary directly because it was present at `C:\Program Files\Go\bin\go.exe` but was not on the current PowerShell `PATH`.

```powershell
& 'C:\Program Files\Go\bin\go.exe' version
```

```text
go version go1.26.4 windows/amd64
```

```powershell
git fetch upstream
git switch -c bisect-quickn upstream/bug/bisect-me
git bisect start
git bisect bad HEAD
git bisect good v0.0.1
git bisect run powershell -NoProfile -Command '& { Set-Location app; & C:\Progra~1\Go\bin\go.exe test ./...; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; & C:\Progra~1\Go\bin\go.exe build ./...; exit $LASTEXITCODE }'
git bisect log
git bisect reset
```

```text
Bisecting: 1 revision left to test after this (roughly 1 step)
[f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
running 'powershell' '-NoProfile' '-Command' '& { Set-Location app; & C:\Progra~1\Go\bin\go.exe test ./...; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; & C:\Progra~1\Go\bin\go.exe build ./...; exit $LASTEXITCODE }'
--- FAIL: TestStore_PersistsAcrossReload (0.01s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL	quicknotes	0.630s
FAIL
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
running 'powershell' '-NoProfile' '-Command' '& { Set-Location app; & C:\Progra~1\Go\bin\go.exe test ./...; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; & C:\Progra~1\Go\bin\go.exe build ./...; exit $LASTEXITCODE }'
ok  	quicknotes	0.577s
f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
commit f285ede8611e55ac0a7d01100891c0cc775e0709
Author: Dmitrii Creed <creeed22@gmail.com>
Date:   Fri Jun 5 13:36:56 2026 +0400

    refactor(store): simplify nextID restoration in load()

    Signed-off-by: Dmitrii Creed <creeed22@gmail.com>

 app/store.go | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first bad commit
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

Bisect works by repeatedly testing the midpoint between a known good commit and a known bad commit. Each test removes about half of the remaining candidate commits. In this branch there were only four commits after `v0.0.1`, so Git needed two test points to isolate the first bad commit, which matches the `log2(N)` behavior.
