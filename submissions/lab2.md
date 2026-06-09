# Lab 2

## 1.1: Explore your repo's plumbing

```bash
[feature/lab1][~/Study/Innopolis/DevOps-Intro]$ git rev-parse HEAD
9e29205886d22a495a313e4c492a725bec502fa4
[feature/lab1][~/Study/Innopolis/DevOps-Intro]$ git rev-parse HEAD
9e29205886d22a495a313e4c492a725bec502fa4
[feature/lab1][~/Study/Innopolis/DevOps-Intro]$ git cat-file -t HEAD
commit
[feature/lab1][~/Study/Innopolis/DevOps-Intro]$ git cat-file -p HEAD
tree 489a92710136b9225902c9edbf9ffeb4adaae0d6
parent 376a4f6b081223eb7d26ac8850c7f608e42d5984
author smairon <man@smairon.ru> 1780740470 +0300
committer smairon <man@smairon.ru> 1780740470 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgHb5ugwpW+0CtnM+JdM/o49apDP
 BbYKnvUBqn3oe/RIkAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQJvc4ogC33+sWHyIzfcZPXHm28Nrh/teBvy2aVtVbg4g24IIZIDylOUPrhDFAx0oth
 KaEzF2IitFTPAKNiMeqQk=
 -----END SSH SIGNATURE-----

docs(lab1): added gitlab community section

Signed-off-by: smairon <man@smairon.ru>
[feature/lab1][~/Study/Innopolis/DevOps-Intro]$ git cat-file -p 489a92710136b9225902c9edbf9ffeb4adaae0d6
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 6db686e340ecdd318fa43375e26254293371942a	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
040000 tree cc91251f52063072d56b53698c6cfe1172e089ad	submissions
[feature/lab1][~/Study/Innopolis/DevOps-Intro]$ git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee
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

## Look inside .git/

Look inside .git directory
```bash
[feature/lab1][~/Study/Innopolis/DevOps-Intro]$ ls -la .git
total 56
drwxr-xr-x  14 axxil  staff   448 Jun  6 13:07 .
drwxr-xr-x  10 axxil  staff   320 Jun  6 12:06 ..
-rw-r--r--   1 axxil  staff    84 Jun  6 13:07 COMMIT_EDITMSG
-rw-r--r--   1 axxil  staff   791 Jun  6 10:54 FETCH_HEAD
-rw-r--r--   1 axxil  staff    29 Jun  6 12:06 HEAD
-rw-r--r--   1 axxil  staff   502 Jun  6 11:01 config
-rw-r--r--   1 axxil  staff    73 Jun  6 10:53 description
drwxr-xr-x  15 axxil  staff   480 Jun  6 10:53 hooks
-rw-r--r--   1 axxil  staff  3498 Jun  6 13:07 index
drwxr-xr-x   3 axxil  staff    96 Jun  6 10:53 info
drwxr-xr-x   4 axxil  staff   128 Jun  6 10:53 logs
drwxr-xr-x  44 axxil  staff  1408 Jun  6 13:07 objects
-rw-r--r--   1 axxil  staff   112 Jun  6 10:53 packed-refs
drwxr-xr-x   5 axxil  staff   160 Jun  6 10:53 refs
```

determine where the HEAD looks (current branch)
```bash
[feature/lab1][~/Study/Innopolis/DevOps-Intro]$ cat .git/HEAD
ref: refs/heads/feature/lab1
```

display a list of all local branches
```bash
[feature/lab1][~/Study/Innopolis/DevOps-Intro]$ ls .git/refs/heads
feature main
```

see first 10 internal objects
```bash
[feature/lab1][~/Study/Innopolis/DevOps-Intro]$ ls .git/objects | head
0a
0c
0e
0f
13
1a
1c
1d
27
2c
```

calculate count of internal objects
```bash
[feature/lab1][~/Study/Innopolis/DevOps-Intro]$ find .git/objects -type f | wc -l
      47
```

## 1.3: Simulate disaster + recover

Bring back "lost commits"
```bash
[feature/lab2][~/Study/Innopolis/DevOps-Intro]$ git reset --hard 9e29205
HEAD is now at 9e29205 docs(lab1): added gitlab community section
```

Make sure the operation is successful
```bash
[feature/lab2][~/Study/Innopolis/DevOps-Intro]$ git reflog

9e29205 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{0}: reset: moving to 9e29205
9e29205 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{1}: reset: moving to HEAD~2
fb90dca HEAD@{2}: commit: wip(lab2): more progress
19fecd9 HEAD@{3}: commit: wip(lab2): start
9e29205 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{4}: checkout: moving from feature/lab1 to feature/lab2
9e29205 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{5}: commit: docs(lab1): added gitlab community section
376a4f6 HEAD@{6}: commit: docs(lab1): finish submission
fc52d4e HEAD@{7}: checkout: moving from main to feature/lab1
e0b9bcc (origin/main, origin/HEAD, main) HEAD@{8}: commit: docs: add PR template
66bbd4d (upstream/main) HEAD@{9}: checkout: moving from feature/lab1 to main
fc52d4e HEAD@{10}: commit: docs(lab1): added documentation for task1
98a1ccd HEAD@{11}: commit: docs(lab1): start submission
66bbd4d (upstream/main) HEAD@{12}: checkout: moving from main to feature/lab1
66bbd4d (upstream/main) HEAD@{13}: clone: from github.com:smairon/DevOps-Intro.git
```

If garbage collection had run between the bad `reset --hard` and my recovery, git would have permanently deleted the orphaned commits because they were no longer reachable from any branch, tag, or reference. The reflog entries would also be removed once the commits themselves were garbage‑collected, making it impossible to recover the lost work with git `reset --hard <SHA>`.

## 2.1: Annotated, signed release tag

The signed tag verification output
```bash
[main][~/Study/Innopolis/DevOps-Intro]$ git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'

v0.0.1 tag commit
v0.1.0-lab2-axxil tag commit

[main][~/Study/Innopolis/DevOps-Intro]$ git tag -v "v0.1.0-lab2-${USER}"
object e0b9bcc4ca06d1c877b18e90afebb5d767317ff2
type commit
tag v0.1.0-lab2-axxil
tagger smairon <man@smairon.ru> 1780979576 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for man@smairon.ru with ED25519 key SHA256:AVEGU6ocCAbpEDpvgdH9g8pKpDB6BsGiY4NzPGxRbfg
```

## 2.2: Rebase + force-with-lease

Commits graph before rebase

```bash
* 9e29205 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) docs(lab1): added gitlab community section
* 376a4f6 docs(lab1): finish submission
* fc52d4e docs(lab1): added documentation for task1
* 98a1ccd docs(lab1): start submission
* 66bbd4d (upstream/main) docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
|\
| * d50436c (upstream/s26-refactor) fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
| * 4705a3d fix(.gitignore): stop ignoring submissions/
| * 4082340 docs(grading,lab11,lab12): bonus labs to 4+4+2; grading rebalanced to 70-14-5-20-30 = 139%
| * 7b16dc5 docs(lab10): switch deploy targets to card-free platforms — HF Spaces + Cloudflare Tunnel
| * 4a05efa docs(labs): scaffold the skill — labs 5-12 stop handing students copy-paste answers
| * 8387fb9 docs(lab3): scaffold the skill — students write their own CI yaml; GitLab as parallel path
| * 983fba0 docs(course): rewrite README + add .gitignore for project-threaded structure
| * 7914e37 docs(labs): refactor 12 labs to 6+4+2 (lab1) / 6+4+bonus (lab2-10) / 10pts (lab11-12)
| * aa5aa1c docs(lectures): rewrite lec1-10 + add reading11/12 for project-threaded course
| * b8fc480 feat(app): introduce QuickNotes Go service for project-threaded course
|/
* 6f044dd (upstream/s26) Replace IPFS with Nix
* 0a87e1c refactor: reduce prescriptiveness in GitLab CI instructions
* eaea715 feat: add GitLab CI alternative instructions to lab3
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10
* 1826c36 feat: update lab7
* 3049f08 feat: publish lec8
* da8f635 feat: introduce all labs and revised structure
* 04b174e feat: publish lab and lec #5
* 67f12f1 feat: publish labs 4&5, revise others
* 82d1989 feat: publish lab3 and lec3
* 3f80c83 feat: publish lec2
* 499f2ba feat: publish lab2
* af0da89 feat: update lab1
* 74a8c27 Publish lab1
* f0485c0 Publish lec1
* 31dd11b Publish README.md
```

Commits graph after rebase
```bash
* 7ec8cb7 (HEAD -> feature/lab2) docs(lab1): added gitlab community section
* 78cbd79 docs(lab1): finish submission
* e8e5a56 docs(lab1): added documentation for task1
* d9d740c docs(lab1): start submission
* c5c5f10 (origin/main, origin/HEAD, main) docs: upstream moved while you worked
* e0b9bcc (tag: v0.1.0-lab2-axxil) docs: add PR template
* 66bbd4d (upstream/main) docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
|\
| * d50436c (upstream/s26-refactor) fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
| * 4705a3d fix(.gitignore): stop ignoring submissions/
| * 4082340 docs(grading,lab11,lab12): bonus labs to 4+4+2; grading rebalanced to 70-14-5-20-30 = 139%
| * 7b16dc5 docs(lab10): switch deploy targets to card-free platforms — HF Spaces + Cloudflare Tunnel
| * 4a05efa docs(labs): scaffold the skill — labs 5-12 stop handing students copy-paste answers
| * 8387fb9 docs(lab3): scaffold the skill — students write their own CI yaml; GitLab as parallel path
| * 983fba0 docs(course): rewrite README + add .gitignore for project-threaded structure
| * 7914e37 docs(labs): refactor 12 labs to 6+4+2 (lab1) / 6+4+bonus (lab2-10) / 10pts (lab11-12)
| * aa5aa1c docs(lectures): rewrite lec1-10 + add reading11/12 for project-threaded course
| * b8fc480 feat(app): introduce QuickNotes Go service for project-threaded course
|/
* 6f044dd (upstream/s26) Replace IPFS with Nix
* 0a87e1c refactor: reduce prescriptiveness in GitLab CI instructions
* eaea715 feat: add GitLab CI alternative instructions to lab3
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10
* 1826c36 feat: update lab7
* 3049f08 feat: publish lec8
* da8f635 feat: introduce all labs and revised structure
* 04b174e feat: publish lab and lec #5
* 67f12f1 feat: publish labs 4&5, revise others
* 82d1989 feat: publish lab3 and lec3
* 3f80c83 feat: publish lec2
* 499f2ba feat: publish lab2
* af0da89 feat: update lab1
* 74a8c27 Publish lab1
* f0485c0 Publish lec1
* 31dd11b Publish README.md

```

Choose merge when working on a **shared public branch** where others might have based their work on it, as it preserves the exact history of how changes were integrated and is non-destructive. 
Choose rebase when working on a **local feature branch** before sharing it with others, as it creates a clean, linear history by reapplying commits on top of the target branch, but it crucial to avoid rebasing public branches that other people have already fetched.

## Bonus Task — Bisect a Real Bug
```bash
[cb89bb9][~/Study/Innopolis/DevOps-Intro]$ git bisect log
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

first bad commit:
 ```bash
 [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
 ```

Git bisect works like a binary search. It starts from a bad commit (with a bug) and a good commit (without the bug). Then it jumps to the middle commit between them and asks you if this commit is good or bad. Each time, it cuts the remaining commits in half, so we only need about log₂(N) steps to find the exact bug, even if you have thousands of commits. 

For example, with 1 million commits, we need only about 20 steps because log₂(1,000,000) ≈ 20 — that means we can find the bug in just 20 tests, not 1 million.
