important work
more important work

## Task 1 — Git Object Model + Reflog Recovery

#### Task 1.1

Head
```
PS C:\Users\Admin\DevOps-Intro> git rev-parse HEAD
834b47ef160013807c4d3873a51d6ce06aa33977
```

Commit
```
PS C:\Users\Admin\DevOps-Intro> git cat-file -t 834b47ef160013807c4d3873a51d6ce06aa33977
commit
```

(P.s. latest commit is the for test is firrst lab one, while it shows in history it couldn't do any changes and doesn't have verified mark)

```
PS C:\Users\Admin\DevOps-Intro> git cat-file -p 834b47ef160013807c4d3873a51d6ce06aa33977
tree a06281d8ceb2fe57d4453d85b17e496606fc0f12
parent b0ec79b830291db5eab94a71cbe9791a6076dc60
author Ceylary <elfsgithub@gmail.com> 1781031453 +0300
committer Ceylary <elfsgithub@gmail.com> 1781031453 +0300

test: unsigned commit (should fail)

Signed-off-by: Ceylary <elfsgithub@gmail.com>
```

Tree
```
PS C:\Users\Admin\DevOps-Intro> git cat-file -p a06281d8ceb2fe57d4453d85b17e496606fc0f12
040000 tree af83e0b6652f6a4b35a626db6e147a5dd9fd6106    .github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures
```

Blob
```
PS C:\Users\Admin\DevOps-Intro> git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee
# ⚠️  KEEP THIS FILE MINIMAL.
#
# This .gitignore is inherited by every student fork. Anything listed here
# is something a student CANNOT `git add` without `-f`. So this file must
# ONLY contain:
#   (a) instructor-only paths (refs/), and
#   (b) machine-generated junk that NOBODY should ever commit.
#
# Do NOT add lab DELIVERABLES here (scan reports, SBOMs, go.sum, k8s
# manifests, CI workflows, Dockerfiles, playbooks, dashboards, …). Students
# are told to commit those in their submission PRs — ignoring them upstream
# silently breaks the lab. When in doubt, leave it OUT of this file.

# ── Instructor-only ─────────────────────────────────────────────
# Reference submissions (dry-run worked examples). Never pushed upstream;
# students never see these. This is the one path that is intentionally hidden.
refs/

# ── Machine-generated junk (no one commits these) ───────────────
# Compiled binaries / local runtime state
app/quicknotes
app/data/
/quicknotes
*.exe

# Vagrant runtime state (Lab 5) — the Vagrantfile IS committed; .vagrant/ is not
.vagrant/

# Nix build symlinks (Lab 11) — flake.nix + flake.lock ARE committed; result is not
result
result-*

# Terraform state — MUST never be committed (can contain secrets)
*.tfstate
*.tfstate.backup
.terraform/

# Python virtualenvs / caches
.venv/
__pycache__/
*.pyc

# Editor / IDE
.vscode/
.idea/
*.swp

# OS noise
.DS_Store
Thumbs.db

# Local agent config (not part of the course)
.claude/

# NOTE: deliberately NOT ignored, because students commit them as lab evidence:
#   submissions/labN.md        (lab reports)
#   .github/workflows/*.yml    (Lab 3 CI)
#   Dockerfile, compose.yaml   (Lab 6)
#   ansible/                   (Lab 7)
#   monitoring/                (Lab 8)
#   *.sbom.cdx.json, zap-*.html/json, trivy-*.txt   (Lab 9 scan evidence)
#   flake.nix, flake.lock      (Lab 11)
#   wasm/main.go, spin.toml, go.sum   (Lab 12)
```

#### Task 1.2

I'm working in powershell so I had to change commands for them to work, I think later I will move to linux to do labs without extra troubles

```
PS C:\Users\Admin\DevOps-Intro> Get-ChildItem -Force .git

    Directory: C:\Users\Admin\DevOps-Intro\.git

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----          09.06.2026    20:10                hooks
d----          09.06.2026    20:10                info
d----          09.06.2026    20:10                logs
d----          10.06.2026    19:29                objects
d----          09.06.2026    20:59                refs
-a---          09.06.2026    23:13             64 COMMIT_EDITMSG
-a---          09.06.2026    19:30            495 config
-a---          09.06.2026    17:18             73 description
-a---          10.06.2026    19:29            100 FETCH_HEAD
-a---          10.06.2026    19:15             21 HEAD
-a---          10.06.2026    19:29           3183 index
-a---          10.06.2026    19:21             41 ORIG_HEAD
-a---          09.06.2026    17:19            112 packed-refs
```

```
PS C:\Users\Admin\DevOps-Intro> cat .git/HEAD
ref: refs/heads/main
```

```
PS C:\Users\Admin\DevOps-Intro> ls .git/refs/heads/

    Directory: C:\Users\Admin\DevOps-Intro\.git\refs\heads

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----          09.06.2026    23:13                feature
-a---          10.06.2026    19:14             41 main
```

```
PS C:\Users\Admin\DevOps-Intro> Get-ChildItem .git\objects | Select-Object -First 10

    Directory: C:\Users\Admin\DevOps-Intro\.git\objects

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----          09.06.2026    22:51                00
d----          09.06.2026    20:10                03
d----          09.06.2026    20:10                04
d----          09.06.2026    21:09                06
d----          09.06.2026    22:49                08
d----          09.06.2026    20:10                0a
d----          09.06.2026    20:10                0c
d----          09.06.2026    20:10                0e
d----          09.06.2026    20:41                0f
d----          09.06.2026    20:10                10
```

```
PS C:\Users\Admin\DevOps-Intro> dir .git\objects -Recurse -File | measure | % Count
96
```

Interpretation -
So thats how I analysed my `.git` directory, which is an actual git repository where HEAD is a pointer to the current branch. Branch references are stored as files inside `.git/refs/heads/` — each file contains a single commit SHA. The `objects/` directory stores all Git objects (commits, trees, blobs) as loose files, organised into subdirectories named after the first two characters of their SHA-1 hash. There are currently 96 loose objects in this repository.
#### Task 1.3

Createtd a new branch and made some "important work". Commited that "important work".

```
PS C:\Users\Admin\DevOps-Intro> git switch -c feature/lab2
Switched to a new branch 'feature/lab2'
PS C:\Users\Admin\DevOps-Intro> mkdir submissions

    Directory: C:\Users\Admin\DevOps-Intro

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----          10.06.2026    21:04                submissions

PS C:\Users\Admin\DevOps-Intro> echo "important work" > submissions\lab2.md
PS C:\Users\Admin\DevOps-Intro> cat submissions\lab2.md
important work
PS C:\Users\Admin\DevOps-Intro> git add submissions/lab2.md
PS C:\Users\Admin\DevOps-Intro> git commit -S -s -m "wip(lab2): start"
Enter passphrase for "C:\Users\Admin/.ssh/id_ed25519":
[feature/lab2 ff207b0] wip(lab2): start
 1 file changed, 1 insertion(+)
 create mode 100644 submissions/lab2.md
PS C:\Users\Admin\DevOps-Intro> echo "more important work" >> submissions/lab2.md
PS C:\Users\Admin\DevOps-Intro> git commit -S -s -am "wip(lab2): more progress"
Enter passphrase for "C:\Users\Admin/.ssh/id_ed25519":
[feature/lab2 0c94e9c] wip(lab2): more progress
 1 file changed, 1 insertion(+)
```

Made disaster

```
PS C:\Users\Admin\DevOps-Intro> git reset --hard HEAD~2
HEAD is now at 834b47e test: unsigned commit (should fail)
PS C:\Users\Admin\DevOps-Intro> git status
On branch feature/lab2
nothing to commit, working tree clean
PS C:\Users\Admin\DevOps-Intro> git log --oneline
834b47e (HEAD -> feature/lab2, origin/main, origin/HEAD, main) test: unsigned commit (should fail)
b0ec79b docs: add PR template
66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
d50436c (upstream/s26-refactor) fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
4705a3d fix(.gitignore): stop ignoring submissions/ 
```
(....etc.. too long to past the full one)

Looked at git reflog

```
PS C:\Users\Admin\DevOps-Intro> git reflog
834b47e (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{0}: reset: moving to HEAD~2
0c94e9c HEAD@{1}: commit: wip(lab2): more progress
ff207b0 HEAD@{2}: commit: wip(lab2): start
834b47e (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{3}: checkout: moving from main to feature/lab2
834b47e (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{4}: checkout: moving from main to main
834b47e (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{5}: pull: Fast-forward
b0ec79b HEAD@{6}: checkout: moving from feature/lab1 to main
e09589e (origin/feature/lab1, feature/lab1) HEAD@{7}: commit: docs(lab1): done
fb26de0 HEAD@{8}: commit: docs(lab1): final
6de3ddc HEAD@{9}: commit: docs(lab1): finalizing3
e9d4208 HEAD@{10}: commit: docs(lab1): finalizing2
00727f7 HEAD@{11}: commit: docs(lab1): finalizing
5318c76 HEAD@{12}: commit: docs(lab1): add task 3 and bonus
fa586e2 HEAD@{13}: checkout: moving from main to feature/lab1
b0ec79b HEAD@{14}: reset: moving to HEAD~1
834b47e (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{15}: commit: test: unsigned commit (should fail)
b0ec79b HEAD@{16}: checkout: moving from feature/lab1 to main
fa586e2 HEAD@{17}: commit: docs(lab1): add task 3
e68b3a8 HEAD@{18}: commit: docs(lab1): finish submission
bcc9825 HEAD@{19}: checkout: moving from main to feature/lab1
b0ec79b HEAD@{20}: checkout: moving from feature/lab1 to main
bcc9825 HEAD@{21}: checkout: moving from main to feature/lab1
b0ec79b HEAD@{22}: commit: docs: add PR template
66bbd4d (upstream/main, upstream/HEAD) HEAD@{23}: checkout: moving from feature/lab1 to main
bcc9825 HEAD@{24}: reset: moving to HEAD
bcc9825 HEAD@{25}: checkout: moving from main to feature/lab1
66bbd4d (upstream/main, upstream/HEAD) HEAD@{26}: checkout: moving from feature/lab1 to main
bcc9825 HEAD@{27}: commit: docs(lab1): start submission
66bbd4d (upstream/main, upstream/HEAD) HEAD@{28}: checkout: moving from main to feature/lab1
```

And saved the day!

```
PS C:\Users\Admin\DevOps-Intro> git reset --hard 0c94e9c
HEAD is now at 0c94e9c wip(lab2): more progress
PS C:\Users\Admin\DevOps-Intro> git status
On branch feature/lab2
nothing to commit, working tree clean
PS C:\Users\Admin\DevOps-Intro>
```

Explanation: _what would happen if `git gc` had run between the bad reset and your recovery?_

If `git gc` had run between the bad reset and recovery, the dangling commits would have been permanently deleted. That means that it would be impossible to recover lost work and it would be unnavoidable to do everything again by hand. This is why it's critical to act quickly after an accidental reset and to regularly push work to a remote.

## Task 2 — Tag a Release & Rebase a Feature (4 pts)

#### Task 2.1

```
PS C:\Users\Admin\DevOps-Intro> git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
PS C:\Users\Admin\DevOps-Intro> git pull --ff-only upstream main
Enter passphrase for key '/c/Users/Admin/.ssh/id_ed25519':
Enter passphrase for key '/c/Users/Admin/.ssh/id_ed25519':
Enter passphrase for key '/c/Users/Admin/.ssh/id_ed25519':
From github.com:inno-devops-labs/DevOps-Intro
 * branch            main       -> FETCH_HEAD
Already up to date.
PS C:\Users\Admin\DevOps-Intro> git tag -a -s "v0.1.0-lab2-Сeylary" -m "Lab 2 milestone — version control deep dive"
Enter passphrase for "C:\Users\Admin/.ssh/id_ed25519":
PS C:\Users\Admin\DevOps-Intro> git push origin "v0.1.0-lab2-Сeylary"
Enter passphrase for key '/c/Users/Admin/.ssh/id_ed25519':
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 421 bytes | 421.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To github.com:Ceylary/DevOps-Intro.git
 * [new tag]         v0.1.0-lab2-Сeylary -> v0.1.0-lab2-Сeylary
```

The signed tag verification output:
``` 
PS C:\Users\Admin\DevOps-Intro> git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'
v0.0.1 tag commit
v0.1.0-lab2-Сeylary tag commit
PS C:\Users\Admin\DevOps-Intro> git tag -v "v0.1.0-lab2-Сeylary"
object 834b47ef160013807c4d3873a51d6ce06aa33977
type commit
tag v0.1.0-lab2-Сeylary
tagger Ceylary <elfsgithub@gmail.com> 1781116336 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for elfsgithub@gmail.com with ED25519 key SHA256:7fzVMV2xmsK1ThtLKMTIVY8/yHjvl6FI9bEJLqbCP4w
```
#### Task 2.2

Used command `git log --oneline -5` for more compact output

Before rebase
```
PS C:\Users\Admin\DevOps-Intro> git log --oneline -5
0c94e9c (HEAD -> feature/lab2, origin/feature/lab2) wip(lab2): more progress
ff207b0 wip(lab2): start
834b47e (tag: v0.1.0-lab2-Сeylary) test: unsigned commit (should fail)
b0ec79b docs: add PR template
66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
```

Rebase
```
PS C:\Users\Admin\DevOps-Intro> git rebase origin/main
Enter passphrase for "C:\Users\Admin/.ssh/id_ed25519":
Enter passphrase for "C:\Users\Admin/.ssh/id_ed25519":
Successfully rebased and updated refs/heads/feature/lab2.
PS C:\Users\Admin\DevOps-Intro> git push --force-with-lease origin feature/lab2
Enter passphrase for key '/c/Users/Admin/.ssh/id_ed25519':
Enumerating objects: 9, done.
Counting objects: 100% (9/9), done.
Delta compression using up to 16 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (8/8), 948 bytes | 948.00 KiB/s, done.
Total 8 (delta 3), reused 0 (delta 0), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (3/3), completed with 1 local object.
To github.com:Ceylary/DevOps-Intro.git
 + 0c94e9c...0c42ee3 feature/lab2 -> feature/lab2 (forced update)
```

After rebase
```
PS C:\Users\Admin\DevOps-Intro> git log --oneline -5
0c42ee3 (HEAD -> feature/lab2, origin/feature/lab2) wip(lab2): more progress
cb93af1 wip(lab2): start
a49ea17 (origin/main, origin/HEAD, main) docs: upstream moved while you worked
834b47e (tag: v0.1.0-lab2-Сeylary) test: unsigned commit (should fail)
b0ec79b docs: add PR template
```

A brief reflection on _when_ you'd choose merge vs rebase -

Merge preserves the complete history including branch topology, it is useful for public branches and tracking exactly when and how integration happened. Rebase creates a linear, cleaner history that preferred for feature branches before merging into main, as it eliminates unnecessary merge commits and makes `git log` easier to read. I would use rebase for updating a personal feature branch with upstream changes, and merge for integrating a completed feature into a shared branch like `main`.

#### Task 2.3

Dokument done (you are reading it right now)
Also I avoided screenshots because it taken too much time for putting everything together with screenshots when I did the first lab.

## Bonus Task — Bisect a Real Bug

#### B.1 Set up bisect

Got into the bisect-quickn branch and started it
```
PS C:\Users\Admin\DevOps-Intro> git fetch upstream
Enter passphrase for key '/c/Users/Admin/.ssh/id_ed25519':
Enter passphrase for key '/c/Users/Admin/.ssh/id_ed25519':
PS C:\Users\Admin\DevOps-Intro> git switch -c bisect-quickn upstream/bug/bisect-me
branch 'bisect-quickn' set up to track 'upstream/bug/bisect-me'.
Switched to a new branch 'bisect-quickn'
PS C:\Users\Admin\DevOps-Intro> git bisect start
status: waiting for both good and bad commits
PS C:\Users\Admin\DevOps-Intro> git bisect bad HEAD
status: waiting for good commit(s), bad commit known
PS C:\Users\Admin\DevOps-Intro> git bisect good v0.0.1
Bisecting: 1 revision left to test after this (roughly 1 step)
[f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
```

Found bad one
```
PS C:\Users\Admin\DevOps-Intro> cd app
PS C:\Users\Admin\DevOps-Intro\app> go build ./...
PS C:\Users\Admin\DevOps-Intro\app> go test ./...
--- FAIL: TestStore_PersistsAcrossReload (0.01s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL    quicknotes      0.401s
FAIL
PS C:\Users\Admin\DevOps-Intro\app> git bisect bad
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
```

Found good one 
```
PS C:\Users\Admin\DevOps-Intro\app> go build ./...
PS C:\Users\Admin\DevOps-Intro\app> go test ./...
ok      quicknotes      0.399s
PS C:\Users\Admin\DevOps-Intro\app> git bisect good
f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
commit f285ede8611e55ac0a7d01100891c0cc775e0709
Author: Dmitrii Creed <creeed22@gmail.com>
Date:   Fri Jun 5 13:36:56 2026 +0400

    refactor(store): simplify nextID restoration in load()

    Signed-off-by: Dmitrii Creed <creeed22@gmail.com>

 app/store.go | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

#### B.2 Automate it

Returned to do automated test 
```
PS C:\Users\Admin\DevOps-Intro\app> git bisect reset
Previous HEAD position was cb89bb9 docs(store): comment the load() decode step
Switched to branch 'bisect-quickn'
Your branch is up to date with 'upstream/bug/bisect-me'.
PS C:\Users\Admin\DevOps-Intro\app> git branch
* bisect-quickn
  feature/lab1
  feature/lab2
  main
```

Did automated test 
```
PS C:\Users\Admin\DevOps-Intro\app> git bisect start
status: waiting for both good and bad commits
PS C:\Users\Admin\DevOps-Intro\app> git bisect bad HEAD
status: waiting for good commit(s), bad commit known
PS C:\Users\Admin\DevOps-Intro\app> git bisect good v0.0.1
Bisecting: 1 revision left to test after this (roughly 1 step)
[f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
PS C:\Users\Admin\DevOps-Intro\app> git bisect run sh -c 'cd app && go test ./... && go build ./...'
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
--- FAIL: TestStore_PersistsAcrossReload (0.01s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL    quicknotes      0.399s
FAIL
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
ok      quicknotes      (cached)
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

Automated test worked.

I reseted and returned to my `feature\lab2` branch.
```
PS C:\Users\Admin\DevOps-Intro\app> git bisect reset
Previous HEAD position was cb89bb9 docs(store): comment the load() decode step
Switched to branch 'bisect-quickn'
Your branch is up to date with 'upstream/bug/bisect-me'.
PS C:\Users\Admin\DevOps-Intro\app> git switch feature/lab2
Switched to branch 'feature/lab2'
```

#### B.3: Document
Showed everything that was requred to show in this document. 

Write 3-4 sentences explaining how bisect found it in `log₂(N)` steps -

Git bisect uses binary search to locate the first bad commit. Instead of testing every commit linearly (which would require up to `N` tests), bisect halves the search space at each step. With N commits in the range, bisect needs at most `log₂(N)` steps. In this case, there were roughly 2-4 commits in the suspicious range, so bisect found the culprit in just 2 steps. For a repository with 1000 commits, bisect would need at most 10 steps exponentially faster than manual searching. This approach scales to hundreds of commits, so for a range of `N` commits, bisect needs at most `log₂(N)` automated iterations which is really useful, espetially in large codebases.
