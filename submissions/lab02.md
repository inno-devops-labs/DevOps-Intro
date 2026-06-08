# Lab 2 Submission — Ivan Alpatov

## Task 1 — Git Object Model + Reflog Recovery

### 1.1: Object chain exploration

Starting from HEAD commit:

```
$ git rev-parse HEAD
fee9e4429fece2c8736c299392bdda9e7d9b1cc5

$ git cat-file -t HEAD
commit

$ git cat-file -p HEAD
tree b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
parent 66bbd4db9228bc9a4cab7439746b993749c026ab
author Ivan Alpatov <ivanalpatov2003@gmail.com> 1780924832 +0300
committer Ivan Alpatov <ivanalpatov2003@gmail.com> 1780924832 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgaIPTe1opiLwbBwez6mD4EzxtDA
 ...
 -----END SSH SIGNATURE-----

docs: add PR template

Signed-off-by: Ivan Alpatov <ivanalpatov2003@gmail.com>
```

Tree SHA: `b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322`

```
$ git cat-file -p b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d    .github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures
```

Blob SHA for README.md: `d10c04c6e7e0014f4fe883599c11747c15012d4e`

```
$ git cat-file -p d10c04c6e7e0014f4fe883599c11747c15012d4e
# DevOps Intro — Modern DevOps Practices Through One Project
...
```

**Interpretation:** Git stores every commit as a complete snapshot, not a diff. The commit object points to a tree (the root directory), which points to blobs (file contents) and subtrees (subdirectories). Each object is addressed by the SHA-256 hash of its content — so identical files share the same blob, and nothing can be silently altered without changing its hash.

### 1.2: Inside .git/

```
$ ls -la .git/
COMMIT_EDITMSG  HEAD  branches  config  description  hooks  index  info  logs  objects  packed-refs  refs

$ cat .git/HEAD
ref: refs/heads/main

$ ls .git/refs/heads/
lab01  main

$ find .git/objects -type f | wc -l
39
```

**Interpretation:** `.git/HEAD` is just a text file pointing to the current branch. `refs/heads/` contains one file per local branch — each file holds the SHA of that branch's tip commit. The `objects/` directory holds 39 loose objects (blobs, trees, commits, tags) — each stored under a two-character subdirectory named after the first two hex digits of its SHA.

### 1.3: Disaster simulation + reflog recovery

Created two commits on `lab02`:

```
b312fc2 wip(lab2): more progress
3e223b7 wip(lab2): start
```

Simulated disaster:

```
$ git reset --hard HEAD~2
HEAD is now at fee9e44 docs: add PR template
```

Both commits disappeared from `git log`. File `submissions/lab02.md` was gone. Ran reflog:

```
$ git reflog
fee9e44 HEAD@{0}: reset: moving to HEAD~2
b312fc2 HEAD@{1}: commit: wip(lab2): more progress
3e223b7 HEAD@{2}: commit: wip(lab2): start
fee9e44 HEAD@{3}: checkout: moving from main to lab02
...
```

Recovery:

```
$ git reset --hard b312fc2
HEAD is now at b312fc2 wip(lab2): more progress
```

Both commits restored, working tree clean.

**What would happen if `git gc` had run?** Reflog entries expire after 30 days by default, and `git gc` prunes objects that are no longer reachable AND whose reflog entries have expired. If gc had run with aggressive settings (or after the 30-day window), the dangling commit objects `b312fc2` and `3e223b7` would have been permanently deleted from the object store — no recovery possible. This is why the lab's pitfall note says: capture the SHA first, then experiment.

---

## Task 2 — Signed Tag + Rebase

### 2.1: Annotated signed release tag

```
$ git tag -a -s "v0.1.0-lab2-alpatovia" -m "Lab 2 milestone — version control deep dive"

$ git tag -v "v0.1.0-lab2-alpatovia"
object fee9e4429fece2c8736c299392bdda9e7d9b1cc5
type commit
tag v0.1.0-lab2-alpatovia
tagger Ivan Alpatov <ivanalpatov2003@gmail.com> 1780940138 +0300
Lab 2 milestone — version control deep dive
Good "git" signature for ivanalpatov2003@gmail.com with ED25519 key SHA256:cU4NMBRxvi29DrWnRnZsfjLjUbAR9lc65rNYG/hbXGs
```

Tag pushed to origin: `git push origin v0.1.0-lab2-alpatovia`

### 2.2: Rebase onto updated main

Graph **before** rebase (commits on lab02 not yet in main):

```
* b312fc2 wip(lab2): more progress
* 3e223b7 wip(lab2): start
```

Simulated upstream moving: added an empty commit to main and pushed.

Rebased lab02 onto origin/main:

```
$ git rebase origin/main
Successfully rebased and updated refs/heads/lab02.
```

Graph **after** rebase:

```
* 2e6d462 wip(lab2): more progress
* db0965a wip(lab2): start
```

Note: commit SHAs changed (b312fc2 → 2e6d462, 3e223b7 → db0965a) because rebase rewrites commits onto the new base. Content is identical.

Force-pushed with lease: `git push --force-with-lease origin lab02`

**Merge vs rebase:** Rebase is the right choice when working alone on a feature branch and you want a clean, linear history — it replays your commits on top of the updated base as if you had started from there. Merge is better when collaborating on a shared branch, because it preserves the true history of when branches diverged and came together. The rule of thumb: never rebase commits that have already been pushed to a shared branch others are pulling from.
