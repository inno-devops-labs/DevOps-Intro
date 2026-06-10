# Lab 2 — Submission

**Student:** Mahmoud Hassan  
**GitHub:** @selysecr332  
**Date:** <!-- YYYY-MM-DD -->

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

**`git reflog` (after `reset --hard HEAD~2`)**

```text
<!-- paste -->
```

**Recovery command + output**

```text
<!-- git reset --hard <SHA> -->
```

**What if `git gc` ran before recovery?**

<!-- 2-3 sentences -->

---

## Task 2 — Signed tag + rebase

### 2.1 Tag verification

**`git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'`**

```text
<!-- paste — expect: v0.1.0-lab2-selysecr332 tag commit -->
```

**`git tag -v v0.1.0-lab2-selysecr332`**

```text
<!-- paste — expect Good signature -->
```

### 2.2 Rebase — log before

```text
<!-- git log --oneline --graph before rebase -->
```

### 2.2 Rebase — log after

```text
<!-- git log --oneline --graph after rebase -->
```

### Merge vs rebase reflection

<!-- brief reflection -->

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

- [ ] HEAD → tree → blob chain documented
- [ ] `.git/` exploration + interpretation
- [ ] Reflog recovery demonstrated
- [ ] `git gc` risk explained

### Task 2 (4 pts)

- [ ] Signed annotated tag `v0.1.0-lab2-selysecr332` pushed
- [ ] `git tag -v` shows Good signature
- [ ] Rebase before/after graphs captured
- [ ] Merge vs rebase reflection

### Submission

- [ ] Course PR opened (`feature/lab2` → `inno-devops-labs/main`)
- [ ] Fork PR opened (`feature/lab2` → `selysecr332/main`)
- [ ] Both URLs on Moodle

### Bonus (2 pts)

- [ ] Bisect log + offending commit + log₂(N) explanation