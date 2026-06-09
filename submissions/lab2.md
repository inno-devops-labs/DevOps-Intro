# Lab 2 submission

## Explore your repo's plumbing

Input:

```sh
git rev-parse HEAD
```

Output:

```sh
3fcf44f1df0624f972eca042c289435a025c1486
```

Input:
```sh
git cat-file -t HEAD
```

Output:
```sh
commit
```

Input:
```sh
git cat-file -p HEAD
```

Output:
```sh
tree c75b34af8f9e1b6ae8bba1321cddd2abf05e0643
parent b40e1a714757082ec39bd3eb0983049d6f4b21a6
author ilnarkhasanov <4sitescarp@gmail.com> 1780949484 +0300
committer ilnarkhasanov <4sitescarp@gmail.com> 1780950131 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAAZcAAAAHc3NoLXJzYQAAAAMBAAEAAAGBAMeIjD2FLzl5UlxMInYLwB
 B7/iLF7TmgVHEcuTg7NUnjjv3B1o0IJOg9W9wLZBlywz5balP1SS+JqVm2+bjXPWyxLUo2
 bd08CKwJb3jjxgfJY51dI+JHVz4kVnt/Xf6YB7xnsFRjC07Qv2Cnwj9nHuzbGXYz+Wm0ra
 4TALoq3rKSwroZKkuWoPIORelWQU2SlcY83IB2CuMAikeoiAzrJqsjVW7uTuNENViFRdKH
 f1Cgg5VJ0QBFz7LMS555FuxQLGHt822ZBtaidgQT0MaR93YJz3VPOvBxb9of9Bls3QiK+T
 Esone9Fg5UlTIvfIP9N/hQ208Vs9e4YbtEfXO366PJamrD/sjJX9zyi5eOcZ7Lnfpj7fC3
 6R1icDm0P9RV+fDgROJolFtU4Ibcqnajzz8iCdDHof6PRmjqsdbUxZnYkIr4H/wFnuO6AR
 ol2h39SedwpG2fRXcwWeHH8XjJQ80lQWZ3On4+cFLQp+Cp3P1PuhPoq0kMZupZbAVsCY/0
 QQAAAANnaXQAAAAAAAAABnNoYTUxMgAAAZQAAAAMcnNhLXNoYTItNTEyAAABgI1SRIUej7
 Tx5BMjbL5/ykS2iu0Y4Cs0m/JZ3gcCLuuFzx8HY335YiF50eBiz292cobkyrSKeIfhs1uV
 pvtgmnJt2fDZ0UsW2xrD7TuXx5dMT3kNV9onybD1nXzybnawztJMd/Y+pRBKBvoDy63edw
 K2GKNYqy90hfef3IFkNeEXORttMwGmHiNp/0Kfqt6qey1rLZyrAss41aCoXMfHfnpswLJn
 JErwtvhdgaREzM7nU8CNVBLHByvz1Z5j4lCTNUtJX5sSjLrWMVAVrtCat6GxxHwEQ1TGJE
 6mKUT+IS8pshph3RyT3WTnhBsWoQ/q47hl+c2b4ePBcm0wDy24AIU7FJeGVnZLUZJ0zuWf
 8ZUzUWMl+Y0KHz6CQrcUEoWWJD7GsOHnvS6/dYYnco7WSTUNba+dCwEwMkrLnWZtZ3Oyhx
 9fF7FLo8d0ueNeZBAOmrPIixuPj/FgjGo0UquGcC5tPcTLoKMElPCi+hoQu8yDBAfsbCSJ
 fzTAolOZCxSdOw==
 -----END SSH SIGNATURE-----

docs(lab1): finish submission

Signed-off-by: ilnarkhasanov <4sitescarp@gmail.com>
```

Input:

```sh
git cat-file -p c75b34af8f9e1b6ae8bba1321cddd2abf05e0643
```

Output:
```sh
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d    .github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures
040000 tree df98acc9e5305af9e23497a8bbdedcd1c993be44    submissions
```

Input:
```sh
git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee
```

Output:
```
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

## 1.2: Look inside `.git/`

Explanation:

Input:

```sh
ls -la .git
```

Output:

```sh
total 64
drwxr-xr-x  15 ilnarkhasanov  staff   480 Jun  9 19:38 .
drwxr-xr-x@ 10 ilnarkhasanov  staff   320 Jun  9 19:38 ..
-rw-r--r--   1 ilnarkhasanov  staff    75 Jun  8 23:13 COMMIT_EDITMSG
-rw-r--r--   1 ilnarkhasanov  staff    97 Jun  8 23:22 FETCH_HEAD
-rw-r--r--   1 ilnarkhasanov  staff    29 Jun  9 19:38 HEAD
-rw-r--r--   1 ilnarkhasanov  staff    41 Jun  8 23:22 ORIG_HEAD
-rw-r--r--   1 ilnarkhasanov  staff   451 Jun  8 23:11 config
-rw-r--r--   1 ilnarkhasanov  staff    73 Jun  6 10:35 description
drwxr-xr-x  16 ilnarkhasanov  staff   512 Jun  6 10:35 hooks
-rw-r--r--   1 ilnarkhasanov  staff  3411 Jun  9 19:38 index
drwxr-xr-x   3 ilnarkhasanov  staff    96 Jun  6 10:35 info
drwxr-xr-x   4 ilnarkhasanov  staff   128 Jun  6 10:35 logs
drwxr-xr-x  28 ilnarkhasanov  staff   896 Jun  8 23:22 objects
-rw-r--r--   1 ilnarkhasanov  staff   112 Jun  6 10:35 packed-refs
drwxr-xr-x   5 ilnarkhasanov  staff   160 Jun  6 10:35 refs
```

Input:

```sh
cat .git/HEAD
```

Output:

```sh
ref: refs/heads/feature/lab1
```

Input:

```sh
ls .git/refs/heads/
```

Output:

```sh
feature main
```

Input:
```sh
ls .git/objects/ | head
```

Output:

```sh
04
1a
1d
27
31
38
3d
3f
6f
79
```

Input:
```sh
find .git/objects -type f | wc -l
```

Output:
```sh
      28
```

Interpretation:

This shows the internals of my git repo. Specifially, I see where my HEAD is located, what branches I have, what objects I have and what loose objects I have.

## 1.3: Simulate disaster + recover

Input:

```sh
git reflog
```

Output:

```sh
60f56cf HEAD@{0}: reset: moving to 60f56cf
3fcf44f HEAD@{1}: reset: moving to HEAD~2
60f56cf HEAD@{2}: commit: wip(lab2): more progress
8c67dae HEAD@{3}: commit: wip(lab2): start
3fcf44f HEAD@{4}: checkout: moving from feature/lab1 to feature/lab2
3fcf44f HEAD@{5}: checkout: moving from main to feature/lab1
0478a0f HEAD@{6}: checkout: moving from feature/lab1 to main
3fcf44f HEAD@{7}: pull -r origin main (finish): returning to refs/heads/feature/lab1
3fcf44f HEAD@{8}: pull -r origin main (pick): docs(lab1): finish submission
b40e1a7 HEAD@{9}: pull -r origin main (pick): docs(lab1): replace submission directory
d0fa48b HEAD@{10}: pull -r origin main (pick): docs(lab1): start submission
0478a0f HEAD@{11}: pull -r origin main (start): checkout 0478a0fe61ea6e5f6ff80aca2709e909b2a23db2
b4b6473 HEAD@{12}: checkout: moving from main to feature/lab1
0478a0f HEAD@{13}: commit: docs: add PR template
66bbd4d HEAD@{14}: checkout: moving from feature/lab1 to main
b4b6473 HEAD@{15}: commit: docs(lab1): finish submission
8821e5b HEAD@{16}: commit: docs(lab1): replace submission directory
d7652de HEAD@{17}: commit: docs(lab1): start submission
66bbd4d HEAD@{18}: reset: moving to HEAD~1
31fd148 HEAD@{19}: commit: docs(lab1): start submission
66bbd4d HEAD@{20}: reset: moving to HEAD~1
6fb82e5 HEAD@{21}: commit: docs(lab1): start submission
66bbd4d HEAD@{22}: reset: moving to HEAD~1
f333a1c HEAD@{23}: commit: docs(lab1): start submission
66bbd4d HEAD@{24}: checkout: moving from main to feature/lab1
66bbd4d HEAD@{25}: clone: from github.com:ilnarkhasanov/DevOps-Intro.git
```

Input:
```sh
git reset --hard 60f56cf
```

Output:
```sh
HEAD is now at 60f56cf wip(lab2): more progress
```

Explanation:

If I run `git gc` before hard reseting I can lose the possibility to restore my commits since this command prunes orphan commits.

## Task 2 — Tag a Release & Rebase a Feature (4 pts)

### 2.1: Annotated, signed release tag

The signed tag verification output:

```sh
git tag -v "v0.1.0-lab2-${USER}"
```

Output:

```sh
object 60f56cf7757414521b9286a4959d2c2d45b31d99
type commit
tag v0.1.0-lab2-ilnarkhasanov
tagger ilnarkhasanov <4sitescarp@gmail.com> 1781025354 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for 4sitescarp@gmail.com with RSA key SHA256:L9YcU19uqANokeYEFcfoGcw1x+8iay2DQmOf7/L64lM
```

#### Your branch's `git log --oneline --graph` before and after rebase:

Before:
```
* fadce66 (HEAD -> feature/lab2) docs(lab2): add solution for task 1
* 60f56cf (tag: v0.1.0-lab2-ilnarkhasanov) wip(lab2): more progress
* 8c67dae wip(lab2): start
* 3fcf44f (origin/feature/lab1, feature/lab1) docs(lab1): finish submission
```

After:
```
* 0f25773 (HEAD -> feature/lab2) docs(lab2): add solution for task 1
* e4b6109 wip(lab2): more progress
* 5fbb5e0 wip(lab2): start
* f1054c2 docs(lab1): finish submission
* cb8d82b docs(lab1): replace submission directory
* 32961cd docs(lab1): start submission
* 9c9e541 (origin/main, origin/HEAD, main) docs: upstream moved while you worked
```

#### - A brief reflection on *when* you'd choose merge vs rebase

I would use rebase on a project where linear project is required. On a project there several people use one branch merge can be better.
