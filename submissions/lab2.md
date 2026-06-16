# Lab 2 — Version Control Deep Dive

**Author:** Karim Abdulkin (@GrandAdmiralBee)
**Branch:** `feature/lab2`
**Tag:** `v0.1.0-lab2-karim`

---

## Task 1 — Git Object Model + Reflog Recovery (6 pts)

### 1.1 — One full plumbing chain: `HEAD` → tree → blob → file

```text
$ git rev-parse HEAD
0a23580b0d23fcb07f12381d8c7948e33096b384

$ git cat-file -t HEAD
commit

$ git cat-file -p HEAD
tree 95c394c04333503e7bc1e2816cda5340616b955b
parent 38144352c18068ed65c429218b14eac70f3eb892
author GrandAdmiralBee <karim.abdulkin@gmail.com> 1781605342 +0300
committer GrandAdmiralBee <karim.abdulkin@gmail.com> 1781605342 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 …redacted…
 -----END SSH SIGNATURE-----

env: add nix devenv files
```

The commit object names a tree, a parent commit, an author/committer pair, and an inline SSH signature. The tree SHA is what makes the commit "point at" a directory snapshot.

```text
$ git cat-file -p 95c394c04333503e7bc1e2816cda5340616b955b
040000 tree b9f60bd2351ed3e910692544434747780dbb5aea	.devenv
100644 blob c18a76248bcd1821764d76779fbc8870ca809e2c	.envrc
040000 tree d0f15a494317a8a43f617b9d4784429b9c5167ab	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
100644 blob 38484f3403ceae15a0793827dd9ec6fd7cde7ac1	devenv.lock
100644 blob a6dc2047cc09fe30d95078134b8c2500530878cd	devenv.nix
100644 blob 6bf1e6c17d5bed410cf83accd4c5bf2159d59a2c	devenv.yaml
040000 tree 89bc50bc368eff78a23dcf65c83a925674de2e66	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
```

The tree is just a sorted list of `(mode, type, sha, name)` rows. `040000 tree` = subdirectory; `100644 blob` = regular file. Names are not stored inside the blob — they live in the *parent* tree, which is how git can share identical blobs across paths without duplication.

```text
$ git cat-file -p c18a76248bcd1821764d76779fbc8870ca809e2c
export DIRENV_WARN_TIMEOUT=20s

eval "$(devenv direnvrc)"

use devenv

if [[ "$SHELL" =~ "zsh" || "$SHELL"  =~ "bash" ]]; then
  source ./site/env/bin/activate || true
fi

if [[ "$SHELL" =~ "fish" ]]; then
  source ./site/env/bin/activate.fish || true
fi
```

That's the raw, uncompressed contents of `.envrc` at this commit — no metadata, no filename, just bytes. Identical bytes anywhere in history would land at the same blob SHA.

### 1.2 — Inside `.git/`

```text
$ ls -la .git/
-rw-r--r-- COMMIT_EDITMSG
-rw-r--r-- config            ← per-repo overrides
-rw-r--r-- description
-rw-r--r-- FETCH_HEAD
-rw-r--r-- HEAD              ← what HEAD points at
drwxr-xr-x hooks/
-rw-r--r-- index             ← staging area
drwxr-xr-x logs/             ← reflog lives here
drwxr-xr-x objects/          ← all blobs / trees / commits / tags
-rw-r--r-- packed-refs       ← static branches/tags from clone
drwxr-xr-x refs/             ← live branch/tag refs

$ cat .git/HEAD
ref: refs/heads/feature/lab2

$ ls .git/refs/heads/
feature   main

$ ls .git/objects/ | head -10
04  0a  14  16  1f  24  27  38  44  4d
```

The `refs/heads/feature/` entry is itself a directory because both `feature/lab1` and `feature/lab2` exist — git folds the slash in a branch name into a real path on disk.

```text
$ find .git/objects -type f | wc -l
53

$ ls .git/objects/pack/
pack-998570c2e14ddd4adb67f7efd2967228849f87fa.idx
pack-998570c2e14ddd4adb67f7efd2967228849f87fa.pack
pack-998570c2e14ddd4adb67f7efd2967228849f87fa.rev
```

53 loose objects (everything I committed locally) sit alongside one packfile from the original clone — `git` writes new objects loose and `git gc` periodically rolls them into packs for compression and faster reads.

### 1.3 — Disaster + reflog recovery

Two work-in-progress commits on `feature/lab2`:

```text
$ git log --oneline -5
61b3234 (HEAD -> feature/lab2) wip(lab2): more progress
2a3e7e7 wip(lab2): start
0a23580 (origin/main, origin/HEAD, main) env: add nix devenv files
3814435 docs: add PR template
bfa345b (upstream/main, upstream/HEAD) docs(lab3): …
```

The disaster — undo both commits, hard:

```text
$ git reset --hard HEAD~2
HEAD is now at 0a23580 env: add nix devenv files
```

`git log --oneline` no longer shows the wip commits — but the reflog remembers every HEAD movement for 30 days:

```text
$ git reflog | head -10
0a23580 HEAD@{0}: reset: moving to HEAD~2
61b3234 HEAD@{1}: commit: wip(lab2): more progress
2a3e7e7 HEAD@{2}: commit: wip(lab2): start
0a23580 HEAD@{3}: checkout: moving from main to feature/lab2
0a23580 HEAD@{4}: checkout: moving from feature/lab1 to main
bafab32 HEAD@{5}: commit: docs(lab1): add PR autofill screenshot
8db76c7 HEAD@{6}: checkout: moving from main to feature/lab1
0a23580 HEAD@{7}: commit: env: add nix devenv files
3814435 HEAD@{8}: commit: docs: add PR template
bfa345b HEAD@{9}: checkout: moving from feature/lab1 to main
```

`HEAD@{1}` is the "more progress" SHA — that's the recovery target.

```text
$ git reset --hard 61b3234
HEAD is now at 61b3234 wip(lab2): more progress

$ cat submissions/lab2.md
important work
more important work
```

**What would happen if `git gc` had run between the bad reset and the recovery?** Reflog entries protect their referenced commits from garbage collection by default for 30 days (`gc.reflogExpire` for reachable, 90 days for unreachable). So an opportunistic `git gc --auto` between the reset and the recovery would *not* have lost the commits — the reflog itself is a root that keeps them reachable. The danger is `git gc --prune=now` (or any aggressive prune that ignores reflog), or running gc after explicitly clearing the reflog with `git reflog expire --expire=now --all`. In CI environments where someone has set `gc.reflogExpire = 0`, the wip commits *would* be unreachable from anywhere and would be deleted on the next gc pass — at which point the SHAs in the reflog text point at objects that no longer exist, and the recovery silently fails. The honest takeaway: the reflog is a safety net with a fuse, not a guarantee — write down the SHA *before* you experiment.

---

## Task 2 — Tag a Release & Rebase (4 pts)

### 2.1 — Signed annotated tag

```bash
git tag -a -s "v0.1.0-lab2-${USER}" -m "Lab 2 milestone — version control deep dive"
git push origin "v0.1.0-lab2-${USER}"
```

Tag is *annotated* (own object, has tagger + message) **and** *signed* (Good ED25519 signature):

```text
$ git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)' "v0.1.0-lab2-${USER}"
v0.1.0-lab2-karim tag commit

$ git tag -v "v0.1.0-lab2-${USER}"
object 0a23580b0d23fcb07f12381d8c7948e33096b384
type commit
tag v0.1.0-lab2-karim
tagger GrandAdmiralBee <karim.abdulkin@gmail.com> 1781606592 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for karim.abdulkin@gmail.com with ED25519 key SHA256:XvCfUeZDdYoI8od4q4/PZZU4OiyMs8bx0P8m2Z+Yxus
```

The second column of `%(objecttype) %(*objecttype)` is `tag commit` — meaning the ref points at a *tag* object, which in turn points at a *commit* (a lightweight tag would show `commit` alone with no second column).

### 2.2 — Rebase + force-with-lease

Simulated upstream moving with an empty commit on `main`, then rebased `feature/lab2` on top.

**Before rebase** (two histories diverging at `0a23580`):

```text
* 9d6f8fc (HEAD -> feature/lab2) env: removed devenv cache on lab2 branch
* 61b3234 wip(lab2): more progress
* 2a3e7e7 wip(lab2): start
| * a20957e (origin/main, origin/HEAD, main) env: updated gitignore and removed devenv local cache
| * e349913 docs: upstream moved while you worked
|/
* 0a23580 (tag: v0.1.0-lab2-karim) env: add nix devenv files
```

The rebase command:

```bash
git rebase --empty=drop origin/main
```

`--empty=drop` was needed because in parallel I'd made a `9d6f8fc env: removed devenv cache on lab2 branch` commit on the feature branch that mirrored what `a20957e` already did on `main` — once replayed onto the new base its diff would be empty. With `--empty=drop`, git silently drops it instead of leaving a vestigial empty commit on the branch.

**After rebase** (linear history, two wip commits replayed with new SHAs):

```text
* d9087ed (HEAD -> feature/lab2) wip(lab2): more progress
* ef09b33 wip(lab2): start
* a20957e (origin/main, origin/HEAD, main) env: updated gitignore and removed devenv local cache
* e349913 docs: upstream moved while you worked
* 0a23580 (tag: v0.1.0-lab2-karim) env: add nix devenv files
* 3814435 docs: add PR template
```

Pushed with the safer flag — `--force-with-lease` aborts the push if someone else has updated `origin/feature/lab2` since my last fetch, instead of blindly stomping their work the way plain `--force` would.

```bash
git push --force-with-lease -u origin feature/lab2
```

**When to rebase vs. merge.** Rebase when you're keeping a personal/feature branch tidy for review — a clean linear sequence of intent-bearing commits is much easier to bisect and to review hunk-by-hunk than a "merge from main" snake. Merge when you're integrating a *shared* branch where rewriting history would invalidate other people's checkouts (the cardinal rule: don't rebase commits anyone else has based work on), or when the merge itself is the historically meaningful event ("this is where release/2025-q1 landed in main"). In practice I rebase my own working branches up to the moment I open a PR, and the maintainer merges (often squash-merge) at the end; the only `--force-with-lease` ever needed is on my private branch, and the upstream history stays linear-without-rewrites.

---

## Repro: how to run this on NixOS

The repo includes `devenv.nix` + `devenv.yaml` from Lab 1. `devenv shell` brings in Go, git, openssh, python3, curl, jq, gh — same env that produced every output above.
