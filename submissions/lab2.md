important work
more important work

# Task 1

## 1.1  Explore your repo's plumbing

Command:

```bash
git rev-parse HEAD
```

Output:

```bash
f3c449b71f05345adc17eb0f2edc9a43ff076d15

```

Command:

```bash
git cat-file -t HEAD
```

Output:

```bash
commit

```

Command:

```bash
git cat-file -p HEAD

```

Output:

```bash
tree b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
parent 027e77b74d10d71bd481aa3815bc4c8ab6574212
author Nikita Schankin <nikita.sshankin@gmail.com> 1780947044 +0300
committer Nikita Schankin <nikita.sshankin@gmail.com> 1780947044 +0300

test: unsigned commit (should fail)

Signed-off-by: Nikita Schankin <nikita.sshankin@gmail.com>


```

Command:

```bash
git cat-file -p b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
```

Output:

```bash
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d    .github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures

```

Command:

```bash
git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee
```

Output:

```bash
 ⚠️  KEEP THIS FILE MINIMAL.
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

## 1.2 Look inside .git/

Command:

```bash
ls -la .git/ 
```

Output:

```bash
total 33
drwxr-xr-x 1 user 197121    0 Jun  9 12:45 ./
drwxr-xr-x 1 user 197121    0 Jun  9 12:45 ../
-rw-r--r-- 1 user 197121   74 Jun  8 22:54 COMMIT_EDITMSG
-rw-r--r-- 1 user 197121  796 Jun  7 23:17 FETCH_HEAD
-rw-r--r-- 1 user 197121   21 Jun  9 12:45 HEAD
-rw-r--r-- 1 user 197121  566 Jun  8 13:29 config
-rw-r--r-- 1 user 197121   73 Jun  7 23:13 description
drwxr-xr-x 1 user 197121    0 Jun  7 23:13 hooks/
-rw-r--r-- 1 user 197121 3183 Jun  9 12:45 index
drwxr-xr-x 1 user 197121    0 Jun  7 23:13 info/
drwxr-xr-x 1 user 197121    0 Jun  7 23:14 logs/
drwxr-xr-x 1 user 197121    0 Jun  8 22:54 objects/
-rw-r--r-- 1 user 197121  112 Jun  7 23:14 packed-refs
drwxr-xr-x 1 user 197121    0 Jun  7 23:14 refs/

```

Command:

```bash
cat .git/HEAD
```

Output:

```bash
ref: refs/heads/main

```

Command:

```bash
ls .git/refs/heads/
```

Output:

```bash
feature/  main

```

Command:

```bash
ls .git/objects/ | head
```

Output:

```bash
02/
0a/
0c/
0d/
0e/
0f/
13/
16/
1a/
1d/

```

Command:

```bash
find .git/objects -type f | wc -l
```

Output:

```bash
62

```

## 1.3  Simulate disaster + recover

Command:

```bash
git reflog
```

Output:

```bash
f3c449b (HEAD -> feature/lab2, main) HEAD@{0}: reset: moving to HEAD~2
e4b9102 HEAD@{1}: commit: wip(lab2): more progress
0a54263 HEAD@{2}: commit: wip(lab2): start
f3c449b (HEAD -> feature/lab2, main) HEAD@{3}: checkout: moving from main to feature/lab2
f3c449b (HEAD -> feature/lab2, main) HEAD@{4}: checkout: moving from feature/lab1 to main

```

Command:

```bash
git reset --hard 0a54263
```

Output:

```bash
HEAD is now at 0a54263 wip(lab2): start

```

Command:

```bash
git reset --hard e4b9102
```

Output:

```bash
HEAD is now at e4b9102 wip(lab2): more progress

```

If `git gc` had run after the bad reset, Git might eventually remove unreachable commits that were no longer referenced by any branch or tag. In that case, the commits visible only through `git reflog` could disappear, making recovery much harder or impossible using normal Git commands. This is why reflog recovery should be done quickly after destructive commands like `git reset --hard`.

# Task 2

## 2.1: Annotated, signed release tag

```bash
git tag -v "v0.1.0-lab2-${USER}"
```

The signed tag verification output

```bash
object 0dcb25a68121f24c281348d724106ead11d1bf8d
type commit
tag v0.1.0-lab2-
tagger Nikita Schankin <nikita.sshankin@gmail.com> 1781014173 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for nikita.sshankin@gmail.com with ED25519 key SHA256:YmuqnukZ7Vv/dkS/udvYvJErhfCYImVdz+nMrsHdP/s

```

## 2.2 Rebase + force-with-lease

Before:

```bash
* 745403f docs(lab2): start submission
* e4b9102 wip(lab2): more progress
* 0a54263 wip(lab2): start
* f3c449b test: unsigned commit (should fail)
* 027e77b test: signed commit (should not fail)
* 0dcb25a (tag: v0.1.0-lab2-) docs: add PR template
:...skipping...
* 745403f docs(lab2): start submission
* e4b9102 wip(lab2): more progress
* 0a54263 wip(lab2): start

```

After:

```bash
* b91b8d4 (HEAD -> feature/lab2, origin/feature/lab2) docs(lab2): start submission
* 9207a96 wip(lab2): more progress
* 2da67d2 wip(lab2): start
* aa19fea test: unsigned commit (should fail)
* 92fa1a4 test: signed commit (should not fail)
* 88bdfab (origin/main, origin/HEAD, main) docs: upstream moved while you worked
* 0dcb25a (tag: v0.1.0-lab2-) docs: add PR template
* 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
|\  
| * d50436c (upstream/s26-refactor) fix(lab12,gitignore): Spin SDK

```

## 2.3: Document

I would choose **merge** when working on a shared branch or when I want to preserve the exact history of how branches were combined. I would choose **rebase** for my own feature branch before opening a PR, because it makes the history cleaner and easier to review. In team projects, I would avoid rebasing commits that other people already use, because rewriting shared history can create confusion.
