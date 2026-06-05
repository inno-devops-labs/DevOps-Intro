# Lab 2 submission

## Task 1 — Git Object Model + Reflog Recovery

### 1.1: Explore the repo's plumbing (`HEAD` → tree → blob → file)

**`git rev-parse HEAD`**

```text
95704553fbc6da22bf3cbe4da12f94d6e410f7df
```

**`git cat-file -t HEAD`**

```text
commit
```

**`git cat-file -p HEAD`** (signature block truncated for readability)

```text
tree b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
parent 66bbd4db9228bc9a4cab7439746b993749c026ab
author Andrei Markov <me@markovav.ru> 1780614768 +0300
committer Andrei Markov <me@markovav.ru> 1780614768 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 …
 -----END SSH SIGNATURE-----

docs: add PR template

Signed-off-by: Andrei Markov <me@markovav.ru>
```

**`git cat-file -p b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322`** (tree)

```text
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 6db686e340ecdd318fa43375e26254293371942a	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
```

**`git cat-file -p d10c04c6e7e0014f4fe883599c11747c15012d4e`** (blob → `README.md`, first lines)

```text
# DevOps Intro — Modern DevOps Practices Through One Project

[![Course](https://img.shields.io/badge/Course-DevOps%20Intro-blue)](#course-roadmap)
[![Project](https://img.shields.io/badge/Project-QuickNotes%20(Go)-success)](#the-project-quicknotes)
…
| 2 | Lab 2 | Version Control Deep Dive | Object model, reflog recovery, reset modes, signed tags, rebase, bisect |
```

**Chain:** commit `9570455` → tree `b2fe0c7…` → blob `d10c04c…` (`README.md`).

---

### 1.2: Look inside `.git/`

**`cat .git/HEAD`**

```text
ref: refs/heads/main
```

**`ls .git/refs/heads/`**

```text
feature  main
```

**`ls .git/objects/ | head`**

```text
06  0a  0c  0d  1a  1d  26  27  …
```

**`find .git/objects -type f | wc -l`**

```text
64
```

**Interpretation:** `.git/HEAD` points at the current branch ref. Branch tips live in `refs/heads/`; objects are stored content-addressed under `objects/XX/…`. Git will eventually pack loose objects with `git gc`.

---

### 1.3: Simulate disaster + recover via reflog

**WIP commits, then `git reset --hard HEAD~2`:**

```text
[feature/lab2 05b8900] wip(lab2): start
[feature/lab2 bc405c9] wip(lab2): more progress
HEAD is now at 9570455 docs: add PR template
```

**After reset — commits appear gone:**

```text
$ git log --oneline -3
9570455 docs: add PR template
66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
```

**`git reflog`**

```text
bc405c9 HEAD@{0}: reset: moving to bc405c9
9570455 HEAD@{1}: reset: moving to HEAD~2
bc405c9 HEAD@{2}: checkout: moving from feature/lab2 to feature/lab2
bc405c9 HEAD@{3}: commit: wip(lab2): more progress
05b8900 HEAD@{4}: commit: wip(lab2): start
9570455 HEAD@{5}: checkout: moving from main to feature/lab2
```

**Recovery:**

```text
$ git reset --hard bc405c9
HEAD is now at bc405c9 wip(lab2): more progress

$ git log --oneline -3
bc405c9 wip(lab2): more progress
05b8900 wip(lab2): start
9570455 docs: add PR template
```

### What if `git gc` had run between reset and recovery?

Reflog records every `HEAD` movement, including the destructive `reset --hard`. If `git gc --prune=now` ran before I copied `bc405c9` from reflog, commits `05b8900` and `bc405c9` could be pruned as unreachable and recovery would be impossible. **Lesson:** grab the SHA from reflog first, then experiment.

---

## Task 2 — Tag a Release & Rebase a Feature

### 2.1: Annotated, signed release tag

```text
$ git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)' v0.1.0-lab2-markovav
v0.1.0-lab2-markovav tag commit

$ git tag -v v0.1.0-lab2-markovav
object 95704553fbc6da22bf3cbe4da12f94d6e410f7df
type commit
tag v0.1.0-lab2-markovav
tagger Andrei Markov <me@markovav.ru> 1780619911 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for me@markovav.ru with RSA key SHA256:1v0b9seRUOWIYpA8U+rk+m+rYSp3XafJ2Ge82CsZrdY

$ git push origin v0.1.0-lab2-markovav
 * [new tag] v0.1.0-lab2-markovav -> v0.1.0-lab2-markovav
```

---

### 2.2: Rebase + `--force-with-lease`

**Simulate upstream on `main`:**

```text
[main 10833e9] docs: upstream moved while you worked

$ git push origin main
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote: - Changes must be made through a pull request.
 ! [remote rejected] main -> main (protected branch hook declined)
```

Branch protection from Lab 1 blocked direct push (expected). Rebase used **local** `main` with `10833e9`.

**Before rebase** (`feature/lab2`):

```text
* bc405c9 wip(lab2): more progress
* 05b8900 wip(lab2): start
* 9570455 docs: add PR template
* 66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
```

**After `git rebase main`:**

```text
* 6cc0d38 wip(lab2): more progress
* 235f3c5 wip(lab2): start
* 10833e9 docs: upstream moved while you worked
* 9570455 docs: add PR template
* 66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
```

WIP SHAs changed after rebase (`bc405c9` → `6cc0d38`, `05b8900` → `235f3c5`) — expected.

---

### 2.3: Merge vs rebase — when to choose which

**Rebase** keeps history linear — good for short-lived personal branches (GitHub Flow, this course). **Merge** preserves parallel history and is safer when others already pulled your branch. I rebased `feature/lab2` because it is a solo lab branch; I would merge (not rebase) shared branches, and always prefer `--force-with-lease` over `--force`.

---

## Bonus Task — Bisect a Real Bug

**Not attempted:** `upstream/bug/bisect-me` and tag `v0.0.1` are not published on the course repo yet (`git ls-remote upstream 'refs/heads/bug/*'` returned empty).
