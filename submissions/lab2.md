# Lab 2 Submission — Version Control Deep Dive

## Task 1

### 1.1: Repo's plumbing

#### 1.1.1: Get current HEAD commit SHA

```bash
$ git rev-parse HEAD
e9bc7088d25ea989726a77230742c39c8d260f32
```

#### 1.1.2: Verify HEAD is a commit object

```bash
$ git cat-file -t HEAD
commit
```

#### 1.1.3: Examine the commit object

```bash
$ git cat-file -p HEAD
tree 372acf29ff043f6dce3127bc7ce818813d390180
parent 7b7fe1d0e628331350f5209e79da47b89ef05f57
author G-Akleh <ghadeer_akleh@hotmail.com> 1781034493 +0300
committer G-Akleh <ghadeer_akleh@hotmail.com> 1781034493 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1NTE5AAAAg93Kab0J+rIsoM7iW4Zz96y6NmI
 1+pOooheU4wkebZ3MAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQPLy1Fr8bp4htF/ZerGmE1SfeSvMkEGriFUAgtiKZodpUeaybGWsx3Dn1NRN0X8O6o
 w1ZsZocRsX2NzZH5F3wg0=
 -----END SSH SIGNATURE-----

docs(lab1): add community engagement

Signed-off-by: G-Akleh <ghadeer_akleh@hotmail.com>
```

**Observation:** This commit contains a tree SHA `372acf29ff043f6dce3127bc7ce818813d390180`, a parent commit SHA, author information, and a cryptographic signature.

#### 1.1.4: Examine the tree object

```bash
$ git cat-file -p 372acf29ff043f6dce3127bc7ce818813d390180
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures
040000 tree 772d6f22bc4f6e93c96e371b9c881633e861d07b    submissions
```

**Observation:** The tree object contains file mode, type (blob/tree), SHA, and name. Blobs represent file content; trees represent directories.

#### 1.1.5: Examine a blob (README.md (first lines))

```bash
$ git cat-file -p d10c04c6e7e0014f4fe883599c11747c15012d4e
# DevOps Intro — Modern DevOps Practices Through One Project

[![Course](https://img.shields.io/badge/Course-DevOps%20Intro-blue)](#course-roadmap)
[![Project](https://img.shields.io/badge/Project-QuickNotes%20(Go)-success)](#the-project-quicknotes)
[![Duration](https://img.shields.io/badge/Duration-10%20Weeks-lightgrey)](#course-roadmap)
[![Grading](https://img.shields.io/badge/Grading-70--14--5--30--30-orange)](#grading)
...
```

**Observation:** The blob contains the raw, compressed file content. This is what Git stores and retrieves when you check out files. (provided output includes only first couple of lines)

#### Chain Summary

The full object chain for this commit is:

- **Commit** `e9bc708` → **Tree** `372acf2` → **Blobs** like `1c0a1e9` (`.gitignore`), `d10c04c` (README.md), etc.
- Each commit is immutable; the SHA changes if any content (tree, parent, author, message) changes
- This forms the foundation of Git's content-addressable storage

---

### 1.2: Inside `.git/`

#### High-level directory structure

**Note**: I used Windows PowerShell for this lab so some commands are different.

```bash
$ Get-ChildItem .git -Force

    Directory: D:\VSCodeProjects\DevOps-Intro\.git

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----          6/9/2026   4:48 AM                hooks
d-----          6/9/2026   4:48 AM                info
d-----          6/9/2026   4:48 AM                logs
d-----          6/9/2026  10:48 PM                objects
d-----          6/9/2026  10:14 PM                refs
-a----          6/9/2026  10:48 PM             89 COMMIT_EDITMSG
-a----          6/9/2026  11:03 PM            626 config
-a----          6/9/2026   4:48 AM             73 description
-a----          6/9/2026   5:35 AM            679 FETCH_HEAD
-a----          6/9/2026  11:03 PM             29 HEAD
-a----          6/9/2026  10:48 PM           3356 index
-a----          6/9/2026  10:13 PM             41 ORIG_HEAD
-a----          6/9/2026   4:48 AM            112 packed-refs
```

#### HEAD file

```bash
$ Get-Content .git/HEAD
ref: refs/heads/feature/lab2
```

The HEAD file is a symbolic reference pointing to the current branch.

#### Branch references

```bash
$ Get-ChildItem .git/refs/heads/ -Recurse
    Directory: D:\VSCodeProjects\DevOps-Intro\.git\refs\heads\feature

Mode                 LastWriteTime         Length Name
-a----          6/9/2026  10:48 PM             41 lab1
-a----          6/9/2026  11:03 PM             41 lab2

    Directory: D:\VSCodeProjects\DevOps-Intro\.git\refs\heads

-a----          6/9/2026  10:16 PM             41 main
```

Each file contains the SHA-1 of the commit it points to.

#### Git objects storage

```bash
$ Get-ChildItem .git/objects/ | Measure-Object
Count    : 55  # Number of subdirectories (0-9, a-f pairs)

$ Get-ChildItem .git/objects -Recurse -File | Measure-Object
Count    : 60  # Total loose object files
```

**Interpretation:**

- **objects/** contains all git objects (commits, trees, blobs, tags)
- Objects are stored in subdirectories named after the first 2 characters of their SHA
- **60 loose objects** are currently stored; this includes commits, trees, and blobs
- The **index** file (3356 bytes) is the staging area; it lists files tracked and ready to commit
- **logs/** contains reflog entries, enabling recovery from hard resets
- **config** holds repository-specific settings (e.g., user info, signing settings)

---

### 1.3: Disaster + recover simulation

#### Two commits created for the scenario

```bash
$ echo "important work" | Out-File -Encoding UTF8 submissions/lab2.md
$ git add submissions/lab2.md
$ git commit -S -s -m "wip(lab2): start"
[feature/lab2 6e915db] wip(lab2): start
 1 file changed, 1 insertion(+)
 create mode 100644 submissions/lab2.md

$ Add-Content -Path submissions/lab2.md -Value "more important work"
$ git commit -S -s -am "wip(lab2): more progress"
[feature/lab2 3cd6061] wip(lab2): more progress
 1 file changed, 1 insertion(+)
```

#### Commits verified are in the log

```bash
$ git log --oneline -5
3cd6061 (HEAD -> feature/lab2) wip(lab2): more progress
6e915db wip(lab2): start
e9bc708 (origin/feature/lab1, feature/lab1) docs(lab1): add community engagement
7b7fe1d docs(lab1): fix screenshot path
2bcc1d7 docs(lab1): finish submission
```

#### Simulate catastrophe: hard reset

```bash
$ git reset --hard HEAD~2
HEAD is now at e9bc708 docs(lab1): add community engagement
```

#### The commits appear "lost"

```bash
$ git status
On branch feature/lab2
nothing to commit, working tree clean

$ git log --oneline -5
e9bc708 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) docs(lab1): add community engagement
7b7fe1d docs(lab1): fix screenshot path
2bcc1d7 docs(lab1): finish submission
d79f289 docs(lab1): add badge screenshot
0d4720a docs(lab1): add submission content
```

**Observations:** The two commits (`3cd6061` and `6e915db`) are no longer in the commit history. The file `submissions/lab2.md` was also reset.

#### Reflog to find the lost commits

```bash
$ git reflog
e9bc708 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{0}: reset: moving to HEAD~2
3cd6061 HEAD@{1}: commit: wip(lab2): more progress
6e915db HEAD@{2}: commit: wip(lab2): start
e9bc708 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{3}: checkout: moving from feature/lab1 to feature/lab2
e9bc708 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{4}: commit: docs(lab1): add community engagement
[... additional reflog history ...]
```

The reflog shows the **chain of HEAD movements**:

- `HEAD@{1}` points to commit `3cd6061` (the most recent lost commit)
- `HEAD@{2}` points to commit `6e915db` (the earlier lost commit)
- These entries prove the commits still exist in the object database, even though they're unreachable from the current branch

#### Recovery: reset to the lost commit

```bash
$ git reset --hard 3cd6061
HEAD is now at 3cd6061 wip(lab2): more progress
```

#### Recovery success verified

```bash
$ git status
On branch feature/lab2
nothing to commit, working tree clean

$ git log --oneline -5
3cd6061 (HEAD -> feature/lab2) wip(lab2): more progress
6e915db wip(lab2): start
e9bc708 (origin/feature/lab1, feature/lab1) docs(lab1): add community engagement
7b7fe1d docs(lab1): fix screenshot path
2bcc1d7 docs(lab1): finish submission
```

**Revovery was successful** Both commits are restored and the working tree matches.

---

### Analysis: What if `git gc` had run?

If `git gc` had run between the bad reset and recovery:

Git's garbage collection (`git gc`) repacks loose objects and cleans up unreachable objects older than a default grace period (typically 2 weeks for loose objects). The critical factor is the **reflog expiration window**, which defaults to 90 days for unreachable objects.

In this scenario:

- Before `git gc`: The reflog entry `HEAD@{1}` still references commit `3cd6061`, keeping it and its tree/blob objects alive.
- After `git gc`: If the reflog entry is still within its grace period, `git gc` would preserve these objects because they are reachable from the reflog. The objects would be repacked but remain in the repository.
- However: If a system administrator has configured aggressive garbage collection (`--aggressive` or `--prune=now`), or if the reflog entries had expired (beyond 90 days), the objects would be permanently deleted and unrecoverable.

The reflog is Git's safety net for recovery, but it is not permanent. Always create branches or tags for important work rather than relying on reflog for long-term recovery.

---

## Task 2 — Tag a Release & Rebase a Feature

### 2.1: Annotated, signed release tag

Created an annotated, signed tag for the release:

```bash
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.

$ git pull --ff-only upstream main
From github.com:inno-devops-labs/DevOps-Intro
 * branch            main       -> FETCH_HEAD
Already up to date.

$ git tag -a -s "v0.1.0-lab2-Ghadeer" -m "Lab 2 milestone — version control deep dive"
# (tag created successfully)

$ git push origin "v0.1.0-lab2-Ghadeer"
To github.com:G-Akleh/DevOps-Intro.git
 * [new tag]         v0.1.0-lab2-Ghadeer -> v0.1.0-lab2-Ghadeer
```

#### Verify tag is annotated and signed

```bash
$ git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)' | Select-String lab2
v0.1.0-lab2-Ghadeer tag commit
```

**Interpretation:** The format shows:

- Tag name: `v0.1.0-lab2-Ghadeer`
- `objecttype: tag` → It's an annotated tag (not lightweight)
- `*objecttype: commit` → The tag points to a commit

#### Verify the signature

```bash
$ git tag -v "v0.1.0-lab2-Ghadeer"
object 2667a3e516e7ecc574676a1a5f65d0c58077da2f
type commit
tag v0.1.0-lab2-Ghadeer
tagger G-Akleh <ghadeer_akleh@hotmail.com> 1781037881 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for ghadeer_akleh@hotmail.com with ED25519 key SHA256:F+2/0O65nDRR6Zz2lIJc7eEn+w7kEfeZWrTc5J1HGy8
```

**Success:** The tag is verified with a **"Good" signature** using the ED25519 SSH key.

---

### 2.2: Rebase + force-with-lease

#### Before rebase: branch graph

```bash
$ git log --oneline --graph --all -10
* 5622c8c (feature/lab2) docs(lab2): add task 1
* 3cd6061 wip(lab2): more progress
* 6e915db wip(lab2): start
* e9bc708 (origin/feature/lab1, feature/lab1) docs(lab1): add community engagement
* 7b7fe1d docs(lab1): fix screenshot path
* 2bcc1d7 docs(lab1): finish submission
* d79f289 docs(lab1): add badge screenshot
* 0d4720a docs(lab1): add submission content
* 001a94a docs(lab1): start submission
| * 2667a3e (HEAD -> main, tag: v0.1.0-lab2-Ghadeer, origin/main, origin/HEAD) docs: add PR template
|/
```

**Analysis:** feature/lab2 is 3 commits ahead of main and has diverged. The branches have a common ancestor but have separate histories.

#### Simulate upstream moving while you worked

```bash
$ git switch main
Switched to branch 'main'

$ git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
[main 781ab23] docs: upstream moved while you worked

$ git push origin main
To github.com:G-Akleh/DevOps-Intro.git
   2667a3e..781ab23  main -> main
```

Now upstream/main is ahead of the feature branch's base.

#### Perform the rebase

```bash
$ git switch feature/lab2
Switched to branch 'feature/lab2'

$ git fetch origin
# (fetched remote updates)

$ git rebase origin/main
Successfully rebased and updated refs/heads/feature/lab2.
```

**No conflicts** — rebase completed cleanly.

#### After rebase: branch graph

```bash
$ git log --oneline --graph --all -10
* 391b7d6 (HEAD -> feature/lab2) docs(lab2): add task 1
* 08b2f41 wip(lab2): more progress
* 4fc459f wip(lab2): start
* 151c85b docs(lab1): add community engagement
* 2429c8d docs(lab1): fix screenshot path
* 9574fad docs(lab1): finish submission
* 202bab1 docs(lab1): add badge screenshot
* 1687725 docs(lab1): add submission content
* ac2c2d2 docs(lab1): start submission
* 781ab23 (origin/main, origin/HEAD, main) docs: upstream moved while you worked
```

**Analysis:** feature/lab2 is now **linearly on top** of origin/main:

- The three lab2 commits have **new SHAs** (expected: rebase replays commits)
- Old SHAs: `5622c8c`, `3cd6061`, `6e915db`
- New SHAs: `391b7d6`, `08b2f41`, `4fc459f`
- The common ancestor is now the "upstream moved" commit `781ab23`
- No branching — clean linear history

#### Push with force-with-lease

```bash
$ git push --force-with-lease origin feature/lab2
To github.com:G-Akleh/DevOps-Intro.git
 * [new branch]      feature/lab2 -> feature/lab2

remote: Create a pull request for 'feature/lab2' on GitHub by visiting:
remote:      https://github.com/G-Akleh/DevOps-Intro/pull/new/feature/lab2
```

**Successfully pushed** with `--force-with-lease` (lease protection prevented accidental overwrites of concurrent work).

---

### 2.3: Merge vs Rebase

#### rebase is better for:

- **Feature branch development:** Keeping a clean, linear history on a feature branch before merging makes code review clearer
- **Avoiding merge commits:** If we want a "flat" history without "Merge branch" commits, we rebase first then merge with `--ff-only`
- **Local branches:** On branches only we're working on, rebase is safe and clean
- **CI/CD pipelines:** Linear history makes bisect and blame operations easier to interpret
- **Before merging to main:** We rebase a feature branch onto main, then fast-forward merge to keep main's history linear

#### merge is better for:

- **Shared branches:** we should never rebase a branch that multiple people are working on; we merge instead (rewriting history breaks others' work)
- **Preserving history:** Merge commits document _when_ and _how_ branches were integrated (useful for release management)
- **Distributed teams:** Merge is safer for collaborative branches; it explicitly documents integration points
- **Merging into main:** Some teams use `git merge --no-ff` to main to preserve evidence of each feature

#### In this lab:

**Rebase was the right choice** because:

1. `feature/lab2` was a solo, local branch with no other collaborators
2. The rebase was before a PR (integration), not after collaboration
3. The result is a clean, linear history that will be easy to review in the PR
4. Once pushed as a PR, rebasing again would be problematic; at that point, further changes would use merge if main moved again
