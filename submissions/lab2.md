# Lab 2 — Submission

**Student:** Mahmoud Hassan  
**GitHub:** @selysecr332  

---

## Task 1 — Git object model + reflog recovery

### 1.1 Plumbing chain (HEAD → tree → blob → file)

**`git rev-parse HEAD`**

```text
a8b4bd1a3bfbc1da6301abb9807c12b3d4130f88
```

**`git cat-file -t HEAD`**

```text
commit
```

**`git cat-file -p HEAD`**

```text
tree b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
parent 72fc9389da47dae0ef0c76760bb13b2ca8ad7c66
author selysecr332 <mh2325132@gmail.com> 1781040565 +0300
committer selysecr332 <mh2325132@gmail.com> 1781040565 +0300

test: unsigned commit (should fail)

Signed-off-by: selysecr332 <mh2325132@gmail.com>
```

**`git cat-file -p b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322`** (tree from commit)

```text
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 6db686e340ecdd318fa43375e26254293371942a	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
```

**`git cat-file -p d10c04c6e7e0014f4fe883599c11747c15012d4e`** (blob → `README.md`)

```text
# DevOps Intro — Modern DevOps Practices Through One Project
(full README.md contents printed — blob d10c04c stores the raw file bytes)
```

**Chain summary:** `commit a8b4bd1` → `tree b2fe0c7` → `blob d10c04` → `README.md`

### 1.2 Inside `.git/`

**`Get-ChildItem .git -Force`**

```text
hooks, info, logs, objects, refs
COMMIT_EDITMSG, config, description, FETCH_HEAD, HEAD, index, ORIG_HEAD, packed-refs
```

**`Get-Content .git\HEAD`**

```text
ref: refs/heads/feature/lab2
```

**`Get-ChildItem .git\refs\heads`**

```text
feature/   (contains feature/lab1, feature/lab2)
main
```

**Loose object count:** `88`

**Interpretation:** `.git/` is Git's local database. `HEAD` points at the current branch (`feature/lab2`). Branch tips live under `refs/heads/` (e.g. `main`, `feature/lab2`). The `objects/` directory stores commits, trees, and blobs as content-addressed files (88 loose objects here). `index` is the staging area; `config` holds remotes and signing settings.

### 1.3 Disaster + recovery

**After `git reset --hard HEAD~2`**

```text
$ git log --oneline -3
a8b4bd1 (HEAD -> feature/lab2, main) test: unsigned commit (should fail)
72fc938 (origin/main) test: unsigned commit (should fail)
d149677 test: unsigned commit (should fail)

$ git status
On branch feature/lab2
Untracked files: submissions/
(two wip commits no longer appear on the branch — looks "gone")
```

**`git reflog` (after `reset --hard HEAD~2`)**

```text
a8b4bd1 HEAD@{0}: reset: moving to HEAD~2
1316d8a HEAD@{1}: commit: wip(lab2): more progress
36bcfbb HEAD@{2}: commit: wip(lab2): start submission
a8b4bd1 HEAD@{3}: checkout: moving from feature/lab2 to feature/lab2
```

**Recovery command + output**

```text
$ git reset --hard 1316d8a
HEAD is now at 1316d8a wip(lab2): more progress

$ git log --oneline -3
1316d8a (HEAD -> feature/lab2) wip(lab2): more progress
36bcfbb wip(lab2): start submission
a8b4bd1 (main) test: unsigned commit (should fail)
```

**What if `git gc` ran before recovery?**

Reflog keeps a history of where `HEAD` pointed, so after a bad `reset --hard` you can still find lost commit SHAs (like `1316d8a`). But `git gc` prunes unreachable objects once reflog entries expire (default ~90 days, sooner with aggressive gc). If gc ran before recovery and no remote/backup still had those commits, the wip work would be permanently lost. Reflog is a safety net, not a backup — always copy the SHA from reflog first.

---

## Task 2 — Signed tag + rebase

### 2.1 Tag verification

**`git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'`**

```text
v0.0.1 tag commit
v0.1.0-lab2-selysecr332 tag commit
```

**`git tag -v v0.1.0-lab2-selysecr332`**

```text
object a8b4bd1a3bfbc1da6301abb9807c12b3d4130f88
type commit
tag v0.1.0-lab2-selysecr332
tagger selysecr332 <mh2325132@gmail.com> 1781077340 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for mh2325132@gmail.com with ED25519 key SHA256:9OvCsi/f5zN9TWAVj8HsTQLZkJEnKjrkkQZZJi+BYe0
```

### 2.2 Rebase — log before

```text
* a8b4bd1 (HEAD -> main, tag: v0.1.0-lab2-selysecr332) test: unsigned commit (should fail)
* 72fc938 (origin/main) test: unsigned commit (should fail)
* d149677 test: unsigned commit (should fail)
(feature/lab2 commits were on top of a8b4bd1, not yet rebased)
```

### 2.2 Rebase — log after

```text
* d9c9191 (HEAD -> feature/lab2, origin/feature/lab2) docs(lab2): complete submission documentation
* 6517a28 docs(lab2): complete Task 1 object model and reflog
* 2ffea95 wip(lab2): more progress
* 1cdad4b wip(lab2): start submission
* 578b0b4 (main) docs: upstream moved while you worked
* a8b4bd1 (tag: v0.1.0-lab2-selysecr332) test: unsigned commit (should fail)
* 72fc938 (origin/main) test: unsigned commit (should fail)
```

Lab 2 commits now sit linearly on top of `578b0b4` (simulated upstream move) after `git rebase main`.

**`git push origin main` (upstream simulation) — rejected by Lab 1 branch protection:**

```text
remote: error: GH013: Repository rule violations found for refs/heads/main.
remote: - Changes must be made through a pull request.
! [remote rejected] main -> main
(Rebased onto local main commit 578b0b4 instead)
```

### Merge vs rebase reflection

Use **merge** on shared branches (`main`, `develop`) when others may already have your commits — it preserves history and avoids rewriting. Use **rebase** on private feature branches to replay your commits on top of latest `main` for a clean linear history before opening a PR. Never rebase commits that teammates have already pulled; use `--force-with-lease` only on your own feature branch.

---

## Task 2 — PRs

- Course PR: <!-- paste -->
- Fork PR: <!-- paste -->

---

## Bonus — Git bisect (optional)

### `git bisect log`

```text
<!-- paste -->
```

### Offending commit

```text
<!-- SHA + message -->
```

### log₂(N) explanation

<!-- 3-4 sentences -->

---

## Lab 2 completion checklist

### Task 1 (6 pts)

- [x] HEAD → tree → blob chain documented
- [x] `.git/` exploration + interpretation
- [x] Reflog recovery demonstrated
- [x] `git gc` risk explained

### Task 2 (4 pts)

- [x] Signed annotated tag `v0.1.0-lab2-selysecr332` pushed
- [x] `git tag -v` shows Good signature
- [x] Rebase before/after graphs captured
- [x] Merge vs rebase reflection

### Submission

- [ ] Course PR opened (`feature/lab2` → `inno-devops-labs/main`)
- [ ] Fork PR opened (`feature/lab2` → `selysecr332/main`)
- [ ] Both URLs on Moodle

### Bonus (2 pts)

- [ ] Bisect log + offending commit + log₂(N) explanation