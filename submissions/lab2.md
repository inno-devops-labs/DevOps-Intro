# Lab 2

## Task 1

### 1.1

```console
$ git rev-parse HEAD
ff7d6992fd74c478a9629ec052959d3f82ae70bb

$ git cat-file -t HEAD
commit

$ git cat-file -p HEAD
tree b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
parent c7795ae3423e4571a984354c99c72300e3d2bddf
author Aleksandr <55945487+Dekart-hub@users.noreply.github.com> 1781023371 +0300
committer Aleksandr <55945487+Dekart-hub@users.noreply.github.com> 1781023371 +0300

test: unsigned commit (should fail)

Signed-off-by: Aleksandr <55945487+Dekart-hub@users.noreply.github.com>

$ git cat-file -p b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d    .github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures

$ git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee
# ⚠️  KEEP THIS FILE MINIMAL.
#
# This .gitignore is inherited by every student fork. Anything listed here
# is something a student CANNOT `git add` without `-f`.
...
```

The chain goes commit → tree → blob → file. `HEAD` is a commit object that points at one tree and records the parent SHA, the author and the message. The tree is the directory listing: one line per entry with a mode, a type, a SHA and a name. The `.gitignore` entry points to a blob, and the blob is just the raw bytes of the file with no name attached (the name lives in the tree). Walking those four objects is how Git puts any file back together at a given commit.

### 1.2

```console
$ cat .git/HEAD
ref: refs/heads/main

$ ls .git/
COMMIT_EDITMSG  FETCH_HEAD  HEAD  config  description  hooks
index  info  logs  objects  packed-refs  refs

$ ls .git/refs/heads/
feature  main

$ ls .git/objects/ | head
0a
0c
0e
0f
13
1a
1d
27
38
3a

$ find .git/objects -type f | wc -l
52
```

`.git/HEAD` just points at the current branch (`refs/heads/main` here), and every branch under `refs/heads/` is a tiny one-line file with its tip commit SHA. The objects themselves sit under `objects/`, split into folders named after the first two characters of each SHA (`0a`, `0c`, and so on). Right now there are 52 loose objects.

### 1.3

```console
$ git switch -c feature/lab2
Switched to a new branch 'feature/lab2'

$ echo "important work" > submissions/lab2.md
$ git add submissions/lab2.md
$ git commit -S -s -m "wip(lab2): start"
[feature/lab2 0b2b15f] wip(lab2): start
 1 file changed, 1 insertion(+)
 create mode 100644 submissions/lab2.md

$ echo "more important work" >> submissions/lab2.md
$ git commit -S -s -am "wip(lab2): more progress"
[feature/lab2 e385f87] wip(lab2): more progress
 1 file changed, 1 insertion(+)

$ git reset --hard HEAD~2
HEAD is now at ff7d699 test: unsigned commit (should fail)

$ git status
On branch feature/lab2
nothing to commit, working tree clean

$ git reflog
ff7d699 HEAD@{0}: reset: moving to HEAD~2
e385f87 HEAD@{1}: commit: wip(lab2): more progress
0b2b15f HEAD@{2}: commit: wip(lab2): start
ff7d699 HEAD@{3}: checkout: moving from main to feature/lab2

$ git reset --hard e385f87
HEAD is now at e385f87 wip(lab2): more progress

$ git status
On branch feature/lab2
nothing to commit, working tree clean
```

The `reset --hard HEAD~2` didn't really delete anything, it just moved the branch pointer back two commits. Those commits were unreachable afterwards but still sitting in `.git/objects`, and the reflog still remembered where HEAD had been, so `git reflog` handed me `e385f87` to reset back onto. The thing that would have made this unrecoverable is `git gc`: if it had run in between (especially `gc --prune=now`) it could have pruned those now-unreachable objects for good. So the takeaway is to read the SHA out of the reflog and recover first, before touching anything else in the repo.

---

## Task 2

### 2.1

```console
$ git pull --ff-only upstream main
From github.com:inno-devops-labs/DevOps-Intro
 * branch            main       -> FETCH_HEAD
Already up to date.

$ git tag -a -s "v0.1.0-lab2-${USER}" -m "Lab 2 milestone — version control deep dive"

$ git push origin "v0.1.0-lab2-${USER}"
To github.com:Dekart-hub/DevOps-Intro.git
 * [new tag]         v0.1.0-lab2-dekart -> v0.1.0-lab2-dekart

$ git tag -v "v0.1.0-lab2-${USER}"
object ff7d6992fd74c478a9629ec052959d3f82ae70bb
type commit
tag v0.1.0-lab2-dekart
tagger Aleksandr <55945487+Dekart-hub@users.noreply.github.com> 1781027370 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for 55945487+Dekart-hub@users.noreply.github.com with ED25519 key SHA256:4mgBS56IPmiiv9CfXkM7q5i3rb7LPWi6N5wlQfYCeVs
```

The tag is annotated rather than lightweight: `git tag -v` shows a real tag object with its own tagger and message that points at a commit, not just a bare ref. It's also signed (the `Good "git" signature` line), and the push put it on `origin` (the `[new tag]` line).

### 2.2

```console
$ git switch main
$ git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
[main c1bfaac] docs: upstream moved while you worked

$ git switch feature/lab2
$ git rebase main
Successfully rebased and updated refs/heads/feature/lab2.

$ git push --force-with-lease origin feature/lab2
To github.com:Dekart-hub/DevOps-Intro.git
 * [new branch]      feature/lab2 -> feature/lab2
```

Branch before the rebase (from the reflog):

```text
e385f87 wip(lab2): more progress
0b2b15f wip(lab2): start
ff7d699 test: unsigned commit (should fail)
c7795ae docs: add PR template
```

Branch after the rebase (`git log --oneline --graph`):

```text
* 775b871 (HEAD -> feature/lab2, origin/feature/lab2) wip(lab2): more progress
* b8c7505 wip(lab2): start
* b302f71 test: unsigned commit (should fail)
* 8e90dc8 (main) docs: upstream moved while you worked
* c7795ae (origin/main, origin/HEAD) docs: add PR template
* 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
```

After the rebase the commits are in the same order with the same content, they just sit on the new base and picked up fresh SHAs, so the history stays linear. I couldn't push the new commit straight to `main` because branch protection blocks direct pushes ("changes must be made through a pull request"), so I rebased `feature/lab2` onto my local `main` instead. I went with `--force-with-lease` instead of plain `--force` so the push would back out if the remote branch had moved without me noticing.

**Merge vs rebase:** for a short-lived `feature/labN` branch I rebase onto `main` before opening the PR, since it keeps history linear and skips the extra merge commits. I wouldn't do that to a shared branch like `main` though, because rewriting its SHAs breaks anyone who already pulled it, so there I'd merge. Short version: rebase your own feature branch, merge the PR.

---

## Bonus

The broken commit lives on `upstream/bug/bisect-me`. I ran the bisect between the last known-good tag `v0.0.1` and the broken tip, which are only 4 commits apart, and did it inside a throwaway worktree so my `feature/lab2` checkout wasn't disturbed.

```console
$ git worktree add --detach /tmp/qn-bisect upstream/bug/bisect-me
$ cd /tmp/qn-bisect
$ git bisect start
$ git bisect bad HEAD
$ git bisect good v0.0.1
$ git bisect run sh -c 'cd app && go test ./... && go build ./...'
--- FAIL: TestStore_PersistsAcrossReload (0.00s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL	quicknotes	0.478s
ok  	quicknotes	0.500s
f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
 app/store.go | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first bad commit
```

`git bisect log`:

```text
git bisect start
git bisect bad f0c9243b7c80ebb930a1ce7048a1d65b4c2ac493
git bisect good 0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7
git bisect bad f285ede8611e55ac0a7d01100891c0cc775e0709
git bisect good cb89bb9ee2ee5010b166061447eaca3ae0da2378
# first bad commit: [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
```

**The bad commit** turned out to be `f285ede`, *refactor(store): simplify nextID restoration in load()*. The entire bug is one line in `app/store.go`:

```diff
-		if n.ID >= s.nextID {
+		if n.ID > s.nextID {
 			s.nextID = n.ID + 1
 		}
```

It's a classic off-by-one in `load()`. With `>=`, a stored note whose ID equals the current `nextID` still pushes `nextID` one past it; switching to `>` means that case no longer bumps it, so after a reload the store can hand out an ID that's already in use. `TestStore_PersistsAcrossReload` is the test that trips on it: it saves one note, reloads the store, and expects the next `Create()` to return ID 2, but gets 1 instead (`nextID not restored: got 1, want 2`).

**On the log₂(N) part:** rather than walk the 4 candidate commits one at a time, bisect keeps cutting the range in half. It checked out the middle commit `f285ede` (bad), then `cb89bb9` (good), and that was already enough to pin `f285ede` as the first bad one, so 2 builds instead of 4. That scales as about log₂(N), which is why a bug buried in 1,000 commits still only takes around 10 builds to track down. `git bisect run` did the whole search for me by watching the script's exit code each step: non-zero counted as bad, zero as good.
