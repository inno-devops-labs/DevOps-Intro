# Lab 2 — Version Control Deep Dive: Internals, Recovery, Rebase

![difficulty](https://img.shields.io/badge/difficulty-beginner-success)
![topic](https://img.shields.io/badge/topic-Git%20Internals-blue)
![points](https://img.shields.io/badge/points-10%2B2-orange)
![tech](https://img.shields.io/badge/tech-Git%202.49%2B-informational)

> **Goal:** Open the hood on Git's object model on the QuickNotes repo. Practice recovery from a `--hard` reset. Tag a release. Rebase a feature branch onto `main`.
> **Deliverable:** A PR from `feature/lab2` to the course repo with `submissions/lab2.md`. Submit the PR link via Moodle.

---

## Overview

This lab makes Git's plumbing visible. You'll:
- Inspect blobs, trees, and commits in your QuickNotes fork
- Force a destructive `--hard` reset and recover via reflog
- Create an annotated, signed release tag
- Rebase a feature branch and squash its history

---

## Project State

**Starting point:** QuickNotes runs locally; Lab 1 PR merged or in review.

**After this lab:** A signed annotated tag `v0.1.0-lab2-USER` exists; your feature branch has been rebased and pushed; you've recovered a "lost" commit.

---

## Prerequisites

- Git **2.49+** (`git switch`, `git restore`, `git maintenance` available)
- Lab 1 completed — your fork is set up with SSH signing
- A clean working tree on `main`

---

## Task 1 — Git Object Model + Reflog Recovery (6 pts)

### 1.1: Explore your repo's plumbing

```bash
cd DevOps-Intro
git rev-parse HEAD
git cat-file -t HEAD         # commit
git cat-file -p HEAD          # see tree SHA, parent SHA, author
# pick a tree SHA from the output:
git cat-file -p <TREE_SHA>    # see blob SHAs for each file
# pick a blob SHA:
git cat-file -p <BLOB_SHA>    # actual file contents
```

In your submission: paste each step's output for one chain (`HEAD` → tree → blob → file).

### 1.2: Look inside `.git/`

```bash
ls -la .git/                       # high-level
cat .git/HEAD                      # ref: refs/heads/...
ls .git/refs/heads/                # branches
ls .git/objects/ | head            # subdirs by first 2 SHA chars
find .git/objects -type f | wc -l  # how many loose objects?
```

Document what you see in `submissions/lab2.md` with a short interpretation.

### 1.3: Simulate disaster + recover

```bash
git switch -c feature/lab2
echo "important work" > submissions/lab2.md
git add submissions/lab2.md
git commit -S -s -m "wip(lab2): start"
echo "more important work" >> submissions/lab2.md
git commit -S -s -am "wip(lab2): more progress"

# now do something stupid
git reset --hard HEAD~2

git status            # everything is "gone"
git log --oneline     # nothing
git reflog            # 🎉 your commits are still here
```

Restore the most recent commit:

```bash
# pick the SHA from `git reflog`
git reset --hard <SHA>
git status            # everything's back
```

Capture:
- The `git reflog` output (showing the chain of HEAD movements)
- The recovery `git reset --hard <SHA>` command and its output
- A 2-3 sentence explanation: *what would happen if `git gc` had run between the bad reset and your recovery?*

---

## Task 2 — Tag a Release & Rebase a Feature (4 pts)

### 2.1: Annotated, signed release tag

```bash
git switch main
git pull --ff-only upstream main
git tag -a -s "v0.1.0-lab2-${USER}" -m "Lab 2 milestone — version control deep dive"
git push origin "v0.1.0-lab2-${USER}"
```

Confirm the tag is annotated **and** signed:

```bash
git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'
# expected: v0.1.0-lab2-USER tag commit
git tag -v "v0.1.0-lab2-${USER}"   # verifies signature; "Good" expected
```

### 2.2: Rebase + force-with-lease

While you were working on `feature/lab2`, simulate upstream moving:

```bash
git switch main
git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
git push origin main

git switch feature/lab2
git fetch origin
git rebase origin/main            # replay your two commits on top
# resolve conflicts if any
git push --force-with-lease origin feature/lab2
```

> 💡 **Always `--force-with-lease`, never plain `--force`** — Lecture 2 explained why.

### 2.3: Document

In `submissions/lab2.md`:
- The signed tag verification output
- Your branch's `git log --oneline --graph` before and after rebase
- A brief reflection on *when* you'd choose merge vs rebase

---

## Bonus Task — Bisect a Real Bug (2 pts)

QuickNotes ships with a deliberately broken commit on a branch called `bug/bisect-me` (created for this lab). Find the offending commit with `git bisect`.

### B.1: Set up bisect

```bash
git fetch upstream
git switch -c bisect-quickn upstream/bug/bisect-me
git bisect start
git bisect bad  HEAD               # current state is broken
git bisect good v0.0.1             # known-good earlier tag
```

At each step Git checks out a commit halfway. Build and test:

```bash
cd app/
go build ./...        # if build fails: `git bisect bad`
go test ./...         # if any test fails: `git bisect bad`; else `git bisect good`
```

### B.2: Automate it

```bash
git bisect run sh -c 'cd app && go test ./... && go build ./...'
# Git iterates automatically; reports the first bad commit
git bisect reset
```

### B.3: Document

- Paste the full `git bisect log`
- Show the offending commit's SHA + message
- Write 3-4 sentences explaining how bisect found it in `log₂(N)` steps

---

## How to Submit

1. `submissions/lab2.md` contains output + analysis for Tasks 1, 2, and (if attempted) Bonus
2. Push `feature/lab2` to your fork
3. Open a PR from `feature/lab2` → course repo's `main`
4. Submit the PR URL via Moodle

---

## Acceptance Criteria

### Task 1 (6 pts)
- ✅ One full chain explored (`HEAD` → tree → blob → file)
- ✅ Reflog output captured, recovery successful
- ✅ Short explanation of the gc-window risk

### Task 2 (4 pts)
- ✅ Signed annotated tag exists on origin
- ✅ `git tag -v` shows "Good" signature
- ✅ Branch rebased; `git log --oneline --graph` before/after captured

### Bonus Task (2 pts)
- ✅ `git bisect log` captured
- ✅ Offending commit identified with SHA + message
- ✅ Reasoning about log₂(N) efficiency

---

## Rubric

| Task | Points | Criteria |
|------|-------:|----------|
| **Task 1** — Object model + reflog recovery | **6** | All plumbing chain steps, reflog evidence, recovery + gc reflection |
| **Task 2** — Signed tag + rebase | **4** | Signed annotated tag, before/after rebase logs, merge-vs-rebase reflection |
| **Bonus** — `git bisect` | **2** | Bisect log, bug commit identified, log₂(N) explanation |
| **Total** | **10 + 2 bonus** | |

---

## Common Pitfalls

- 🪤 **`git@github.com: Permission denied (publickey)` on `git fetch upstream`** — *not* a remote-config bug (the error is at the SSH layer, before Git reads the repo). Your key isn't registered for **authentication** on GitHub — and a **Signing Key** (Lab 1) does *not* count for auth, they're separate roles. Add the same `~/.ssh/id_ed25519.pub` as an **Authentication Key** (Lab 1 §1.3), verify with `ssh -T git@github.com`, then re-run. To unblock right now, the public upstream fetches over HTTPS with no key: `git remote set-url upstream https://github.com/inno-devops-labs/DevOps-Intro.git`
- 🪤 **`reset --hard` without committing first** — your *uncommitted* edits really *are* gone (reflog only saves committed work). Always check `git status` first
- 🪤 **`tag -v` says "no signature"** — you used `git tag NAME` instead of `git tag -a -s NAME -m "..."`
- 🪤 **Rebase conflicts** — resolve, then `git rebase --continue`. Never `git rebase --skip` unless you know what you're skipping
- 🪤 **Force-push wipes someone's commits** — that's why we use `--force-with-lease`. If you see the rejection message, `git fetch` and rebase again
- 🪤 **`git gc` ran during recovery** — the 30-day reflog default kept you safe, but in CI environments aggressive gc can be configured. **Capture the SHA *first*, then experiment**

---

## Guidelines

- Show *commands you ran* + *output you got* in the submission, not paraphrased descriptions
- For rebase, the diff between branches should be clean — no accidental upstream commits in `feature/lab2`
- Bisect is the kind of skill that *prevents* hours of grep-driven debugging when something regresses

---

## Resources

- 📕 *Pro Git* — Chacon & Straub — Chapters 7 (Customizing Git) and 10 (Git Internals)
- 📗 [Git Magic — Ben Lynn](https://www-cs-students.stanford.edu/~blynn/gitmagic/) — short, free
- 📘 [Git from the Bottom Up — John Wiegley](https://jwiegley.github.io/git-from-the-bottom-up/)
- 🎥 [Linus Torvalds — *Linux Foundation talk on Git*](https://www.youtube.com/watch?v=4XpnKHJAok8)
- 📝 [Git reflog documentation](https://git-scm.com/docs/git-reflog)
