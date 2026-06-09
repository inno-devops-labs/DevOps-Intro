# Lab 2 Submission

## Task 1 - Git Object Model + Reflog Recovery

### 1.1 Plumbing chain (HEAD -> tree -> blob -> file)

`git rev-parse HEAD`

```text
80b3abcabb1944d3b77f8ae6a5fb6d3271a04c1a
```

`git cat-file -t HEAD`

```text
commit
```

`git cat-file -p HEAD`

```text
tree 4949d6dee916add2be7aa71712858455d1239fd9
parent 66bbd4db9228bc9a4cab7439746b993749c026ab
author IlyaPechersky <foodgamesimple@mail.ru> 1780936457 +0300
committer IlyaPechersky <foodgamesimple@mail.ru> 1780938441 +0300

docs: add PR template

Signed-off-by: IlyaPechersky <foodgamesimple@mail.ru>
```

`git cat-file -p 4949d6dee916add2be7aa71712858455d1239fd9`

```text
040000 tree af080e474767b4931935c2b4565f66bc9f0b8d22	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 6db686e340ecdd318fa43375e26254293371942a	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
```

`git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee` (first lines of `.gitignore`)

```text
# KEEP THIS FILE MINIMAL.
#
# This .gitignore is inherited by every student fork...
refs/
```

### 1.2 Inside `.git/`

```text
$ cat .git/HEAD
ref: refs/heads/main

$ ls .git/refs/heads/
feature  main

$ ls .git/objects/ | head
0c 0e 30 31 33 35 36 3d 3f 43

$ find .git/objects -type f | wc -l
51
```

`HEAD` points to the current branch ref. `refs/heads/` stores branch tips. Objects live under `.git/objects/` in loose form (51 files here). Each commit points to a tree; trees point to blobs or other trees.

### 1.3 Disaster + recovery

After two wip commits I ran `git reset --hard HEAD~2`. Work looked gone:

```text
$ git log --oneline
80b3abc docs: add PR template
66bbd4d docs(lab1): align Task 3 GitHub Community engagement with other courses
```

`git reflog` still had the lost commits:

```text
80b3abc HEAD@{0}: reset: moving to HEAD~2
5be35eb HEAD@{1}: reset: moving to 5be35eba90d76815ce4f02fe0a21ca1bbf487cb1
bea1657 HEAD@{2}: reset: moving to bea165796d5b3d2bbeec13d68027f49206b23962
80b3abc HEAD@{3}: checkout: moving from main to feature/lab2
```

Recovery:

```bash
git reset --hard 5be35eba90d76815ce4f02fe0a21ca1bbf487cb1
```

```text
HEAD is now at 5be35eb wip(lab2): more progress
5be35eb wip(lab2): more progress
bea1657 wip(lab2): start
80b3abc docs: add PR template
```

If `git gc` had run between the bad reset and recovery, unreachable commits could be pruned once reflog entries expire (default ~90 days, sooner with aggressive gc). The SHA would stop resolving and recovery would fail.

## Task 2 - Signed Tag + Rebase

### 2.1 Signed annotated tag

```bash
git tag -a -s "v0.1.0-lab2-IlyaPechersky" -m "Lab 2 milestone - version control deep dive"
git push origin "v0.1.0-lab2-IlyaPechersky"
```

```text
$ git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'
v0.1.0-lab2-IlyaPechersky tag commit

$ git tag -v v0.1.0-lab2-IlyaPechersky
Good "git" signature for foodgamesimple@mail.ru with ED25519 key SHA256:e1sAHFFYl4uOnpFOwThMC3M+fNgpvd5/MBZp5ekpbJc
object 80b3abcabb1944d3b77f8ae6a5fb6d3271a04c1a
type commit
tag v0.1.0-lab2-IlyaPechersky
tagger IlyaPechersky <foodgamesimple@mail.ru>

Lab 2 milestone - version control deep dive
```

### 2.2 Rebase onto updated main

Simulated upstream move with an empty commit on `main`, then rebased `feature/lab2`.

Before rebase:

```text
* 5be35eb wip(lab2): more progress
* bea1657 wip(lab2): start
* 80b3abc docs: add PR template
```

After rebase:

```text
* fbc9898 wip(lab2): more progress
* 6a320a5 wip(lab2): start
* b6f211b docs: upstream moved while you worked
* 80b3abc docs: add PR template
```

```bash
git push --force-with-lease origin feature/lab2
```

Pushed successfully. `--force-with-lease` refuses to overwrite remote commits I have not seen, which avoids clobbering someone else's work.

### 2.3 Merge vs rebase

I use rebase on feature branches to keep history linear and easier to review. Merge is better when the branch is shared or already public — rebasing rewritten SHAs would break collaborators' local copies.

## Bonus - Git Bisect

```text
git bisect start
git bisect bad f0c9243b7c80ebb930a1ce7048a1d65b4c2ac493
git bisect good 0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7
git bisect bad f285ede8611e55ac0a7d01100891c0cc775e0709
git bisect good cb89bb9ee2ee5010b166061447eaca3ae0da2378
# first bad commit: [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
```

Offending commit:

```text
f285ede refactor(store): simplify nextID restoration in load()
```

`TestStore_PersistsAcrossReload` fails because `nextID` is not restored after reload.

With 5 commits between good (`v0.0.1`) and bad (`HEAD`), bisect needed about log2(5) ~= 2-3 test runs. Each step cuts the search space in half, so cost grows slowly even on long histories.
