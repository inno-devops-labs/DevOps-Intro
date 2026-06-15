# Lab 2 submission

## Task 1

### 1.1: Exploring the repo

```console
$ git rev-parse HEAD
6f636654d85046b446f487b0632c3dfcbc9fd499
```

```console
$ git cat-file -t HEAD
commit
```

```console
$ git cat-file -p HEAD
tree 08a2d32d81ec697cc3f043680300e3be173028da
parent bfa345b2244ccfe8ae4d92caa24ed90f13fa6282
author danielpancake <45727078+danielpancake@users.noreply.github.com> 1781518457 +0500
committer danielpancake <45727078+danielpancake@users.noreply.github.com> 1781518457 +0500
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgNWBFYt8AE/NlEc5E0+8cXvq0AY
 LMkrAp8TxeqwGXPHcAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQB6IT5OFRk1kW9KCelcyeqpKGXpR3F0O1ZbKBcLtV2EWP2EYGSEK31lW3MLv7S+ZuG
 uaXU6JByiwJfhz131H2gg=
 -----END SSH SIGNATURE-----

docs: add PR template

Signed-off-by: danielpancake <45727078+danielpancake@users.noreply.github.com>
```

```console
$ git cat-file -p 08a2d32d81ec697cc3f043680300e3be173028da
040000 tree 78d51eb792c558b6b1da9ee23b3b3bc40992e60a    .github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree 89bc50bc368eff78a23dcf65c83a925674de2e66    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures
```

Reading the `.gitignore` blob.

```gitignore
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

### 1.2: Looking inside `.git/`

```console
$ ls .git/
COMMIT_EDITMSG  FETCH_HEAD  HEAD  config  description  index  packed-refs
hooks/  info/  logs/  objects/  refs/
```

```console
$ cat .git/HEAD
ref: refs/heads/feature/lab2
```

```console
$ ls .git/refs/heads/
feature  main
```

```console
$ ls .git/objects/ | head
08  0a  0c  0e  0f  13  14  1a  27  29
```

```console
$ find .git/objects -type f | wc -l
45
```

**Interpretation:** `HEAD` is a symbolic ref pointing at the current branch (`refs/heads/feature/lab2`); `refs/heads/` holds the branch tips (here a `feature/` namespace dir plus `main`). Under `objects/`, each two-char subdirectory is the first byte of an object's SHA-1. `config`, `index`, `hooks/`, `logs/`, and `packed-refs` hold repo settings, the staging area, hook scripts, the reflog, and packed ref tips respectively.

### 1.3: Simulating disaster + recovery

Two WIP commits, then `git reset --hard HEAD~2`:

```console
$ git commit -S -s -m "wip(lab2): start"
[feature/lab2 4b156ac] wip(lab2): start
$ git commit -S -s -am "wip(lab2): more progress"
[feature/lab2 24be0e1] wip(lab2): more progress
$ git reset --hard HEAD~2
HEAD is now at 6f63665 docs: add PR template
```

After the reset, the two commits appear gone:

```console
$ git log --oneline -3
6f63665 docs: add PR template
bfa345b docs(lab3): matrix renames required checks — warn + ci-ok gate pattern; set honest cache expectations
356420b docs(lab1,lab2): clarify GitHub auth vs signing SSH key roles; add publickey-denied pitfalls
```

The reflog still has the "lost" commits:

```console
$ git reflog
6f63665 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{0}: reset: moving to HEAD~2
24be0e1 HEAD@{1}: commit: wip(lab2): more progress
4b156ac HEAD@{2}: commit: wip(lab2): start
6f63665 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{3}: checkout: moving from main to feature/lab2
```

Recover to the most recent commit (`24be0e1`):

```console
$ git reset --hard 24be0e1
HEAD is now at 24be0e1 wip(lab2): more progress
$ git log --oneline -3
24be0e1 wip(lab2): more progress
4b156ac wip(lab2): start
6f63665 docs: add PR template
```

**`git gc` risk:** The commits survived only because the reflog still referenced them, and `git gc` will not prune reflog-reachable objects, so a routine `gc` between the reset and recovery would have been harmless (reflog entries default to 90 days reachable / 30 days unreachable). The danger is `git gc --prune=now` or an expired reflog: once those entries are gone, `4b156ac` and `24be0e1` become unreferenced and get collected, and `git reset --hard 24be0e1` then fails with `unknown revision`.

## Task 2

### 2.1: Annotated, signed release tag

List the tags (`tag` objecttype confirms they are annotated):

```console
$ git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'
v0.0.1 tag commit
v0.1.0-lab2-danielpancake tag commit
```

Verify the signature:

```console
$ git tag -v "v0.1.0-lab2-danielpancake"
object 6f636654d85046b446f487b0632c3dfcbc9fd499
type commit
tag v0.1.0-lab2-danielpancake
tagger danielpancake <45727078+danielpancake@users.noreply.github.com> 1781522885 +0500

Lab 2 milestone — version control deep dive
Good "git" signature for 45727078+danielpancake@users.noreply.github.com with ED25519 key SHA256:9X3YQHiqrWoDjoaRwFmJ5YC04AAtZX8GDBNeS3atwEk
```

### 2.2: Rebase + force-with-lease

Move `main` forward, then rebase `feature/lab2` and force-push with lease:

```console
$ git switch main
Already on 'main'
Your branch is up to date with 'origin/main'.
$ git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
[main 221274b] docs: upstream moved while you worked
$ git push origin main
To https://github.com/danielpancake/DevOps-Intro
   6f63665..221274b  main -> main
$ git switch feature/lab2
Switched to branch 'feature/lab2'
$ git fetch origin
$ git rebase origin/main
Successfully rebased and updated refs/heads/feature/lab2.
$ git push --force-with-lease origin feature/lab2
To https://github.com/danielpancake/DevOps-Intro
 * [new branch]      feature/lab2 -> feature/lab2
```

### 2.3: Before/after graphs + reflection

**Before rebase** (WIP commits sit directly on `6f63665`):

```console
$ git log --oneline --graph
* 24be0e1 (HEAD -> feature/lab2) wip(lab2): more progress
* 4b156ac wip(lab2): start
* 6f63665 (tag: v0.1.0-lab2-danielpancake) docs: add PR template
* bfa345b (upstream/main, upstream/HEAD) docs(lab3): matrix renames required checks — warn + ci-ok gate pattern; set honest cache expectations
* 356419b docs(lab1,lab2): clarify GitHub auth vs signing SSH key roles; add publickey-denied pitfalls
…
```

**After rebase** (`221274b` inserted below the WIP commits; SHAs change to `598c46f`/`8e5c5e8`):

```console
$ git log --oneline --graph
* 8e5c5e8 (HEAD -> feature/lab2, origin/feature/lab2) wip(lab2): more progress
* 598c46f wip(lab2): start
* 221274b (origin/main, origin/HEAD, main) docs: upstream moved while you worked
* 6f63665 (tag: v0.1.0-lab2-danielpancake) docs: add PR template
* bfa345b (upstream/main, upstream/HEAD) docs(lab3): matrix renames required checks — warn + ci-ok gate pattern; set honest cache expectations
…
```

**Merge vs rebase.** I use **rebase** on a private, in-progress feature branch to keep its history linear and replay my work on top of the latest `main`, with no merge-bubble noise. The trade-off is that it rewrites commit SHAs, so it is only safe on branches nobody else has based work on (hence `--force-with-lease`, never plain `--force`). I'd choose **merge** for integrating a shared or completed branch: it preserves the true history, doesn't rewrite commits others may have pulled, and records when integration happened. Rule of thumb: rebase to tidy local history before sharing, merge to combine published history.
