important work
more important work

# Task 1

## 1.1  Explore your repo's plumbing

```bash
git rev-parse HEAD
```

```bash
f3c449b71f05345adc17eb0f2edc9a43ff076d15

```

```bash
git cat-file -t HEAD
```

```bash
commit

```

```bash
git cat-file -p HEAD

```

```bash
tree b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
parent 027e77b74d10d71bd481aa3815bc4c8ab6574212
author Nikita Schankin <nikita.sshankin@gmail.com> 1780947044 +0300
committer Nikita Schankin <nikita.sshankin@gmail.com> 1780947044 +0300

test: unsigned commit (should fail)

Signed-off-by: Nikita Schankin <nikita.sshankin@gmail.com>


```

```bash
git cat-file -p b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
```

```bash
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d    .github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures

```

```bash
git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee
```

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

```bash
ls -la .git/ 
```

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

```bash
cat .git/HEAD
```

```bash
ref: refs/heads/main

```

```bash
ls .git/refs/heads/
```

```bash
feature/  main

```

```bash
ls .git/objects/ | head
```

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

```bash
find .git/objects -type f | wc -l
```

```bash
62

```

## 1.3  Simulate disaster + recover

```bash
git reflog
```

```bash
f3c449b (HEAD -> feature/lab2, main) HEAD@{0}: reset: moving to HEAD~2
e4b9102 HEAD@{1}: commit: wip(lab2): more progress
0a54263 HEAD@{2}: commit: wip(lab2): start
f3c449b (HEAD -> feature/lab2, main) HEAD@{3}: checkout: moving from main to feature/lab2
f3c449b (HEAD -> feature/lab2, main) HEAD@{4}: checkout: moving from feature/lab1 to main

```

```bash
git reset --hard 0a54263
```

```bash
HEAD is now at 0a54263 wip(lab2): start

```

```bash
git reset --hard e4b9102
```

```bash
HEAD is now at e4b9102 wip(lab2): more progress

```

If `git gc` had run after the bad reset, Git might eventually remove unreachable commits that were no longer referenced by any branch or tag. In that case, the commits visible only through `git reflog` could disappear, making recovery much harder or impossible using normal Git commands. This is why reflog recovery should be done quickly after destructive commands like `git reset --hard`.

# Task 2

```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

