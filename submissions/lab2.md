# Lab 2 submission

## Task 1 - Git Object Model + Reflog Recovery

### 1.1: Repo plumbing

```text
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git rev-parse HEAD
bb53ad923871a866557e8c2463423560d12c999a
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git cat-file -t HEAD
commit
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git cat-file -p HEAD
tree b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
parent 66bbd4db9228bc9a4cab7439746b993749c026ab
author Tatyana Shmykova <limefox413@gmail.com> 1780946419 +0300
committer Tatyana Shmykova <limefox413@gmail.com> 1780946419 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgkk4uXu4WQuJZjg9jV470YgPcOh
 +/a7QWRjF2vCWL53EAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQLtaJJy6Fzurye7cpT5hcicLCw6Q1NlEnxYjBC097skarvn+/p0GudY1sHNd1cDLh3
 ZUheMJF9JjXRVh3cS+sA8=
 -----END SSH SIGNATURE-----

docs: add PR template

Signed-off-by: Tatyana Shmykova <limefox413@gmail.com>
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git cat-file -p b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d    .github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee
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

### 1.2: `.git` inspection

```text
ls -la .git/
cat .git/HEAD
ls .git/refs/heads/
ls .git/objects/ | head
find .git/objects -type f | wc -l
total 64
drwxr-xr-x@ 15 tatyana  staff   480 Jun  9 13:07 .
drwxr-xr-x@ 12 tatyana  staff   384 Jun  9 13:10 ..
-rw-r--r--@  1 tatyana  staff   101 Jun  9 12:22 COMMIT_EDITMSG
-rw-r--r--@  1 tatyana  staff   210 Jun  9 12:56 FETCH_HEAD
-rw-r--r--@  1 tatyana  staff    29 Jun  9 12:58 HEAD
-rw-r--r--@  1 tatyana  staff    41 Jun  9 12:57 ORIG_HEAD
-rw-r--r--@  1 tatyana  staff   699 Jun  9 12:58 config
-rw-r--r--@  1 tatyana  staff    73 Jun  8 21:28 description
drwxr-xr-x@ 16 tatyana  staff   512 Jun  8 21:30 hooks
-rw-r--r--@  1 tatyana  staff  3183 Jun  9 12:58 index
drwxr-xr-x@  3 tatyana  staff    96 Jun  8 21:30 info
drwxr-xr-x@  4 tatyana  staff   128 Jun  8 22:20 logs
drwxr-xr-x@ 82 tatyana  staff  2624 Jun  9 13:07 objects
-rw-r--r--@  1 tatyana  staff   499 Jun  8 21:28 packed-refs
drwxr-xr-x@  6 tatyana  staff   192 Jun  9 12:15 refs
ref: refs/heads/feature/lab2
feature main
01
02
0b
0c
0f
12
16
1a
1c
1d
      95
```

The `.git` directory stores the repository's internal state and history. `HEAD` points to the current branch, `refs/heads/` stores branch pointers, and `objects/` contains the commit, tree, and blob data Git uses to reconstruct files. This shows that Git tracks content as linked objects instead of storing only one plain copy of each file.

### 1.3: Disaster and recovery

```text
tatyana@Tatyanas-MacBook-Air DevOps-Intro % echo "important work" > submissions/lab2.md
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git add submissions/lab2.md
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git commit -S -s -m "wip(lab2): start"
[feature/lab2 ccdf36c] wip(lab2): start
 1 file changed, 1 insertion(+)
 create mode 100644 submissions/lab2.md
tatyana@Tatyanas-MacBook-Air DevOps-Intro % echo "more important work" >> submissions/lab2.md 
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git commit -S -s -am "wip(lab2): more progress"
[feature/lab2 63b0c99] wip(lab2): more progress
 1 file changed, 1 insertion(+)
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git reset --hard HEAD~2
HEAD is now at bb53ad9 docs: add PR template
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git status
On branch feature/lab2
nothing to commit, working tree clean
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git log --oneline
bb53ad9 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) docs: add PR template
66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
d50436c (upstream/s26-refactor, origin/s26-refactor) fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
4705a3d fix(.gitignore): stop ignoring submissions/
4082340 docs(grading,lab11,lab12): bonus labs to 4+4+2; grading rebalanced to 70-14-5-20-30 = 139%
7b16dc5 docs(lab10): switch deploy targets to card-free platforms — HF Spaces + Cloudflare Tunnel
4a05efa docs(labs): scaffold the skill — labs 5-12 stop handing students copy-paste answers
8387fb9 docs(lab3): scaffold the skill — students write their own CI yaml; GitLab as parallel path
:
bb53ad9 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) docs: add PR template
66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
d50436c (upstream/s26-refactor, origin/s26-refactor) fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
4705a3d fix(.gitignore): stop ignoring submissions/
4082340 docs(grading,lab11,lab12): bonus labs to 4+4+2; grading rebalanced to 70-14-5-20-30 = 139%
7b16dc5 docs(lab10): switch deploy targets to card-free platforms — HF Spaces + Cloudflare Tunnel
4a05efa docs(labs): scaffold the skill — labs 5-12 stop handing students copy-paste answers
8387fb9 docs(lab3): scaffold the skill — students write their own CI yaml; GitLab as parallel path

tatyana@Tatyanas-MacBook-Air DevOps-Intro % git reflog
bb53ad9 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{0}: reset: moving to HEAD~2
63b0c99 HEAD@{1}: commit: wip(lab2): more progress
ccdf36c HEAD@{2}: commit: wip(lab2): start
bb53ad9 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{3}: reset: moving to HEAD~
f983b28 HEAD@{4}: reset: moving to HEAD
f983b28 HEAD@{5}: commit: wip(lab2): start
bb53ad9 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{6}: checkout: moving from main to feature/lab2
bb53ad9 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{7}: checkout: moving from main to main
bb53ad9 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{8}: reset: moving to bb53ad9
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git reset --hard 63b0c99
HEAD is now at 63b0c99 wip(lab2): more progress
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git status
On branch feature/lab2
nothing to commit, working tree clean
```

Reflog records where `HEAD` and branch references pointed over time, so it can help recover commits after a bad reset. If `git gc` ran before recovery, unreachable commits could be pruned after the reflog entry expires, and the lost work might become impossible to restore. That is why recovery should happen quickly after the mistake.

## Task 2 - Tag a Release and Rebase a Feature

### 2.1: Signed release tag

```text
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git pull --ff-only upstream main
From github.com:inno-devops-labs/DevOps-Intro
 * branch            main       -> FETCH_HEAD
Already up to date.
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git tag -a -s "v0.1.0-lab2-${USER}" -m "Lab 2 milestone — version control deep dive"
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git push origin "v0.1.0-lab2-${USER}"
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 425 bytes | 425.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To https://github.com/lime413/DevOps-Intro.git
 * [new tag]         v0.1.0-lab2-tatyana -> v0.1.0-lab2-tatyana
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'
v0.0.1 tag commit
v0.1.0-lab2-tatyana tag commit
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git tag -v "v0.1.0-lab2-${USER}"
object bb53ad923871a866557e8c2463423560d12c999a
type commit
tag v0.1.0-lab2-tatyana
tagger Tatyana Shmykova <limefox413@gmail.com> 1781000744 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for limefox413@gmail.com with ED25519 key SHA256:uILBmFloXYwLzB7ZEV76znUjoz28KKEF7OZWNJr7Jio
```

### 2.2: Rebase and force-with-lease

Note: I turned off the branch protection rule on `main` before this step, so I could simulate the upstream move and push to `main` for the lab exercise.

```text
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
[main e478559] docs: upstream moved while you worked
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git push origin main
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 457 bytes | 457.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To https://github.com/lime413/DevOps-Intro.git
   bb53ad9..e478559  main -> main
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git switch feature/lab2
Switched to branch 'feature/lab2'
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git fetch origin
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git log --oneline --graph --decorate --all -10
* 4b3ef17 (origin/feature/lab2) wip(lab2): more progress
* 1b8121f wip(lab2): start
* e478559 (origin/main, origin/HEAD, main) docs: upstream moved while you worked
| *-.   f932387 (refs/stash) WIP on feature/lab2: 63b0c99 wip(lab2): more progress
| |\ \  
| | | * 9b823a1 untracked files on feature/lab2: 63b0c99 wip(lab2): more progress
| | * 09b9fa9 index on feature/lab2: 63b0c99 wip(lab2): more progress
| |/  
| * 63b0c99 (HEAD -> feature/lab2) wip(lab2): more progress
| * ccdf36c wip(lab2): start
|/  
* bb53ad9 (tag: v0.1.0-lab2-tatyana) docs: add PR template
| * d0dd2e5 (origin/feature/lab1, feature/lab1) docs(lab1): small fix - add triple backticks
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git rebase origin/main
Successfully rebased and updated refs/heads/feature/lab2.
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git push --force-with-lease origin feature/lab2
Enumerating objects: 9, done.
Counting objects: 100% (9/9), done.
Delta compression using up to 10 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (8/8), 931 bytes | 931.00 KiB/s, done.
Total 8 (delta 3), reused 0 (delta 0), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (3/3), completed with 1 local object.
remote: 
remote: Create a pull request for 'feature/lab2' on GitHub by visiting:
remote:      https://github.com/lime413/DevOps-Intro/pull/new/feature/lab2
remote: 
To https://github.com/lime413/DevOps-Intro.git
 * [new branch]      feature/lab2 -> feature/lab2
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git log --oneline --graph --decorate --all -10
* 3963f64 (HEAD -> feature/lab2) wip(lab2): more progress
* e20724f wip(lab2): start
| * 4b3ef17 (origin/feature/lab2) wip(lab2): more progress
| * 1b8121f wip(lab2): start
|/  
* e478559 (origin/main, origin/HEAD, main) docs: upstream moved while you worked
| *-.   f932387 (refs/stash) WIP on feature/lab2: 63b0c99 wip(lab2): more progress
| |\ \  
| | | * 9b823a1 untracked files on feature/lab2: 63b0c99 wip(lab2): more progress
| | * 09b9fa9 index on feature/lab2: 63b0c99 wip(lab2): more progress
| |/  
| * 63b0c99 wip(lab2): more progress
| * ccdf36c wip(lab2): start
|/
```

### 2.3: Merge vs rebase

I use merge when I want to keep the full branch history and avoid rewriting commits, especially for shared branches. I use rebase when I want a clean linear history and I am working on my own feature branch before it is shared. For this lab, rebase fits because it shows how to replay my work on top of the latest `main`.

## Bonus Task - Bisect a Real Bug

### B.1: Set up bisect

```text
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git fetch upstream
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git switch -c bisect-quickn upstream/bug/bisect-me
branch 'bisect-quickn' set up to track 'upstream/bug/bisect-me'.
Switched to a new branch 'bisect-quickn'
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git bisect start
status: waiting for both good and bad commits
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git bisect bad  HEAD  
status: waiting for good commit(s), bad commit known
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git bisect good v0.0.1
Bisecting: 1 revision left to test after this (roughly 1 step)
[f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
tatyana@Tatyanas-MacBook-Air DevOps-Intro % cd app/
tatyana@Tatyanas-MacBook-Air app % go build ./...
tatyana@Tatyanas-MacBook-Air app % go test ./...
--- FAIL: TestStore_PersistsAcrossReload (0.00s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL    quicknotes      0.478s
FAIL
tatyana@Tatyanas-MacBook-Air app % git bisect bad
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
tatyana@Tatyanas-MacBook-Air app % go build ./...
tatyana@Tatyanas-MacBook-Air app % go test ./... 
ok      quicknotes      0.621s
tatyana@Tatyanas-MacBook-Air app % git bisect good
f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
commit f285ede8611e55ac0a7d01100891c0cc775e0709
Author: Dmitrii Creed <creeed22@gmail.com>
Date:   Fri Jun 5 13:36:56 2026 +0400

    refactor(store): simplify nextID restoration in load()
    
    Signed-off-by: Dmitrii Creed <creeed22@gmail.com>

 app/store.go | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

### B.2: Automate bisect

```text
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git bisect run sh -c 'cd app && go test ./... && go build ./...'
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
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git bisect reset
Previous HEAD position was cb89bb9 docs(store): comment the load() decode step
Switched to branch 'bisect-quickn'
Your branch is up to date with 'upstream/bug/bisect-me'.
```

### B.3: Document

```text
tatyana@Tatyanas-MacBook-Air app % git bisect log
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
tatyana@Tatyanas-MacBook-Air app % git show --no-patch --oneline f285ede8611e55ac0a7d01100891c0cc775e0709
f285ede refactor(store): simplify nextID restoration in load()
```

Bisect narrowed the search by splitting the commit range in half and checking the code at each step. I started with a known good tag and a known bad branch head, then Git checked one middle commit and asked me to mark it good or bad based on the test result. After only a few steps, bisect identified the first commit that broke the test, so I did not need to inspect every commit one by one. This is much faster than manual checking when the history is large.
