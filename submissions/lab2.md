# Lab 2 Submission

## Task 1: Git Object Model + Reflog Recovery

### 1.1: Plumbing Chain
```bash 
$ git rev-parse HEAD
01b52259fcdd0a52948e1481e409f29838758f7c
```

```bash
$ git cat-file -t HEAD
commit
```


```bash
$ git cat-file -p HEAD
tree a06281d8ceb2fe57d4453d85b17e496606fc0f12
parent 66bbd4db9228bc9a4cab7439746b993749c026ab
author Levak <levakov2003@gmail.com> 1780771053 +0300
committer Levak <levakov2003@gmail.com> 1780771053 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgLCYBCG1u7nhw53g5MFZ8x7I3lc
 RwNZdeB2RQ7KL7RQwAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQE61iBg/zTHFQW3/CXam16FOgXUSnitr3QlNGAOyUmt8/2+x9ytaFkIRRrdOm1XRkB
 KVKaDfxbQNkATcEXR0Nws=
 -----END SSH SIGNATURE-----

docs: add PR template

Signed-off-by: Levak <levakov2003@gmail.com>
```

```bash
$ git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee
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

### 1.2: Inside .git/
I was using cmd in windows, so commands are a bit different
```bash
$ dir .git

06.06.2026  22:01                76 COMMIT_EDITMSG
06.06.2026  21:04               547 config
06.06.2026  18:57                73 description
06.06.2026  18:58               805 FETCH_HEAD
09.06.2026  09:34                21 HEAD
06.06.2026  18:57    <DIR>          hooks
09.06.2026  09:34             3 183 index
06.06.2026  18:57    <DIR>          info
06.06.2026  18:57    <DIR>          logs
06.06.2026  22:01    <DIR>          objects
06.06.2026  18:57               112 packed-refs
06.06.2026  18:57    <DIR>          refs
```
```bash
$ type .git\HEAD
ref: refs/heads/main
```
```bash
$ dir .git\refs\heads
06.06.2026  21:37    <DIR>          .
06.06.2026  21:37    <DIR>          ..
06.06.2026  22:01    <DIR>          feature
06.06.2026  21:37                41 main
```

```bash
$ dir .git\objects
06.06.2026  22:01    <DIR>          .
06.06.2026  22:01    <DIR>          ..
06.06.2026  21:37    <DIR>          01
06.06.2026  18:58    <DIR>          0a
06.06.2026  18:58    <DIR>          0c
...
```

```bash
$ dir /s /b .git\objects | find /c /v ""
81
```

#### Interpretation
The .git/HEAD file contains a ref pointer: refs/heads/main, which means Git is currently looking at the main branch.
This is simply a text file with the path to the current branch.

The .git/refs/heads/ folder stores pointers to the latest commits on each local branch.
The .git/objects/ folder contains all repository data (commits, trees, files) as objects whose names are their SHA-1 hashes. 

Git uses the first two characters of the hash as the subfolder name and the remaining 38 characters as the file name within.
This allows Git to quickly find objects without having to scan thousands of files in a single directory.

My repository has 81 loose objects.

### 1.3: Disaster - Recovery

**Git reflog output:**
```bash
$ git reflog
01b5225 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{0}: reset: moving to HEAD~2
7b2886d HEAD@{1}: commit: wip(lab2): more progress
8f9da93 HEAD@{2}: commit: wip(lab2): start
01b5225 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{3}: checkout: moving from main to feature/lab2
01b5225 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{4}: checkout: moving from feature/lab1 to main
40e70f5 (origin/feature/lab1, feature/lab1) HEAD@{5}: commit: docs(lab1): finish submission
c2a66c4 HEAD@{6}: checkout: moving from main to feature/lab1
01b5225 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{7}: commit: docs: add PR template
66bbd4d (upstream/main, upstream/HEAD) HEAD@{8}: checkout: moving from feature/lab1 to main
c2a66c4 HEAD@{9}: commit: docs(lab1): First task done, all essential outputs are included
d394eba HEAD@{10}: commit: docs(lab1): start submission
66bbd4d (upstream/main, upstream/HEAD) HEAD@{11}: checkout: moving from main to feature/lab1
66bbd4d (upstream/main, upstream/HEAD) HEAD@{12}: clone: from https://github.com/infernaltiger/DevOps-Intro.git
```

**Recovery command:**
```bash
$ git reset --hard 7b2886d
HEAD is now at 7b2886d wip(lab2): more progress
```

**Git status after recovery:**
```bash
$ git status
On branch feature/lab2
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        .vs/

nothing added to commit but untracked files present (use "git add" to track)
```

#### What if git gc had run?

If git garbage collector had run between the destructive reset (git reset --hard HEAD~2) and the reflog restore (especially in aggressive mode),
it could have irreversibly deleted dangling (unreachable) objects that are no longer referenced.
In this case, it would be impossible to restore the commits via the reflog, as their physical data would have been erased from .git/objects.

However, by default, the reflog in a local repository stores history for 30 days, giving us a safe window for recovery.
This is why it's important to quickly grab the SHA from the reflog before garbage collection removes the objects.

## Task 2: Tag a Release & Rebase a Feature
### 2.1: Signed Annotated Tag

```bash
$ git tag -v "v0.1.0-lab2-infernaltiger"
object 01b52259fcdd0a52948e1481e409f29838758f7c
type commit
tag v0.1.0-lab2-infernaltiger
tagger Levak <levakov2003@gmail.com> 1780989361 +0300

Lab 2 milestone - version control deep dive
Good "git" signature for levakov2003@gmail.com with ED25519 key SHA256:Uy5EthB3DwEUnS1a18RY23swxV+0kSuppzGEkQURsgQ
```

### 2.2: Rebase
**Git log BEFORE rebase:**
```bash
$ git log --oneline --graph --all
* cbd003c (origin/main, origin/HEAD, main) docs: upstream moved while you worked
| * 7b2886d (HEAD -> feature/lab2) wip(lab2): more progress
| * 8f9da93 wip(lab2): start
|/
* 01b5225 (tag: v0.1.0-lab2-infernaltiger) docs: add PR template
| * 40e70f5 (origin/feature/lab1, feature/lab1) docs(lab1): finish submission
| * c2a66c4 docs(lab1): First task done, all essential outputs are included
| * d394eba docs(lab1): start submission
|/
```

**Git log AFTER rebase:**
```bash
$git rebase origin/main
Successfully rebased and updated refs/heads/feature/lab2.
$git log --oneline --graph --all
* b7500ce (HEAD -> feature/lab2) wip(lab2): more progress
* 667f3bf wip(lab2): start
* cbd003c (origin/main, origin/HEAD, main) docs: upstream moved while you worked
* 01b5225 (tag: v0.1.0-lab2-infernaltiger) docs: add PR template
| * 40e70f5 (origin/feature/lab1, feature/lab1) docs(lab1): finish submission
| * c2a66c4 docs(lab1): First task done, all essential outputs are included
| * d394eba docs(lab1): start submission
|/
```

### 2.3: Merge vs Rebase

Merge preserves an accurate chronology of events and indicates the fact that branches have been merged, creating "bubbles" in the history.
It's safe for shared branches, as it doesn't rewrite history and makes it easy to track when and what changes were integrated.

Rebase rewrites history, creating a clean, linear sequence of commits on top of the current main branch.
This makes history more readable and simplifies code review. Rebase is ideal for local feature branches before creating a PR, but it shouldn't be applied to branches already used by other developers, to avoid breaking their history (which is why we use --force-with-lease instead of --force).

In general: merge for integrating into shared branches, rebase for preparing local work for merging.

## Bonus Task: Bisect a Real Bug

### B.1-B.2: Bisect Process
**git bisect log:**
```bash
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
### B.3: Documentation

- SHA: f285ede8611e55ac0a7d01100891c0cc775e0709
- Message: refactor(store): simplify nextID restoration in load()
- Author: Dmitrii Creed creeed22@gmail.com
- Date: Fri Jun 5 13:36:56 2026 +0400
- Problem: The commit broke the TestStore_PersistsAcrossReload test — the nextID field was no longer being restored correctly during reload (expected 2, got 1).


#### Why $log_2(N)$ is efficient:

Git bisect uses a binary search algorithm. Instead of checking each commit linearly (O(N)), it splits the search space in half at each step.

In my case, there were only 4 commits between v0.0.1 and HEAD, 
and Git found the problematic commit in 2 steps ($log_2(4) = 2$).

If there were 1,000 commits, binary search would have found the culprit in at most 10 steps ($log_2(1000) \approx 9.96$), which saves a huge amount of time compared to a linear search.
This turns hours of manual debugging into seconds of automated testing.