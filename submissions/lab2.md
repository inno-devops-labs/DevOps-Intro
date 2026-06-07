# Lab 2 submission
### Git internals
Chain: HEAD -> tree (.) -> tree (./.github) -> blob (pull_request_template.md) -> file (pull_request_template.md)
- HEAD SHA
```sh
$ git rev-parse HEAD
9952fea4631fd30f9dd790ccf65d39d7dd94fa87
```
- HEAD type
```sh
$ git cat-file -t HEAD
commit
```
- HEAD contents
```sh
$ git cat-file -p HEAD
tree b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
parent 66bbd4db9228bc9a4cab7439746b993749c026ab
author arsenez <arsenez@cybercommunity.space> 1780816430 +0300
committer arsenez <arsenez@cybercommunity.space> 1780816430 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgfUxVs3ggHSRiEaI28J13lUtVYA
 lowGiI0HN1Vrlm5b0AAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQPAMB0SKy9wA24YIO+8d4jiqcuZxz2U4QG2+3VM8cGtLXDMFynLFVhQ9Hn+RJkNVOE
 6JStzhAuNO9PpAQpFYNgc=
 -----END SSH SIGNATURE-----

docs: add PR template

Signed-off-by: arsenez <arsenez@cybercommunity.space>
```
- tree (.)
```sh
$ git cat-file -p b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d    .github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures
```
- tree (./.github)
```sh
$ git cat-file -p 1d07791eee3c3dd0955a02402b05b3a357816d8d
100644 blob 1a68db5e5229c49aa74891fa11c9cfb2d6b1e6e4    pull_request_template.md
```
- blob (pull_request_template.md)
```sh
$ git cat-file -p 1a68db5e5229c49aa74891fa11c9cfb2d6b1e6e4
## Goal
<!-- What does this PR accomplish? 1 sentence. -->

## Changes
- 

## Testing
<!-- How did you verify it? -->

## Checklist
- [ ] Title is a clear sentence (≤ 70 chars)
- [ ] Commits are signed (`git log --show-signature`)
- [ ] `submissions/labN.md` updated
```
- file (pull_request_template.md)
```sh
$ cat .github/pull_request_template.md 
## Goal
<!-- What does this PR accomplish? 1 sentence. -->

## Changes
- 

## Testing
<!-- How did you verify it? -->

## Checklist
- [ ] Title is a clear sentence (≤ 70 chars)
- [ ] Commits are signed (`git log --show-signature`)
- [ ] `submissions/labN.md` updated
```

### `.git` internals
- `.git` directory structure:
```sh
$ ls -la .git
total 32
drwxr-xr-x 1 arsenez users  188 Jun  7 14:57 .
drwxr-xr-x 1 arsenez users  112 Jun  7 14:58 ..
-rw-r--r-- 1 arsenez users   78 Jun  7 14:39 COMMIT_EDITMSG
-rw-r--r-- 1 arsenez users  671 Jun  7 14:57 config
-rw-r--r-- 1 arsenez users   73 Jun  7 09:35 description
-rw-r--r-- 1 arsenez users  240 Jun  7 15:17 FETCH_HEAD
-rw-r--r-- 1 arsenez users   29 Jun  7 14:57 HEAD
drwxr-xr-x 1 arsenez users  556 Jun  7 09:35 hooks
-rw-r--r-- 1 arsenez users 3183 Jun  7 14:56 index
drwxr-xr-x 1 arsenez users   14 Jun  7 09:35 info
drwxr-xr-x 1 arsenez users   16 Jun  7 09:35 logs
drwxr-xr-x 1 arsenez users  200 Jun  7 15:17 objects
-rw-r--r-- 1 arsenez users   41 Jun  7 13:51 ORIG_HEAD
-rw-r--r-- 1 arsenez users  112 Jun  7 09:35 packed-refs
drwxr-xr-x 1 arsenez users   32 Jun  7 09:35 refs
```
- HEAD reference
```sh
$ cat .git/HEAD 
ref: refs/heads/feature/lab2
```
- Branch and worktree heads
```sh
$ ls -l .git/refs/heads
total 8
drwxr-xr-x 1 arsenez users 16 Jun  7 14:57 feature
-rw-r--r-- 1 arsenez users 41 Jun  7 14:36 main
-rw-r--r-- 1 arsenez users 41 Jun  7 14:33 rejection
```
- Subdirectories for git objects
```sh
$ ls .git/objects/ | head 
07
0a
0c
0e
0f
12
13
1a
1d
23
```
- Count of git objects
```sh
$ find .git/objects -type f | wc -l
56
```

### Recovery from `git reset`
- Reflog output
```sh
$ git reflog
ebd0570 (HEAD -> feature/lab2) HEAD@{0}: reset: moving to HEAD~2
097e2b7 HEAD@{1}: commit: wip(lab2): more progress
1083649 HEAD@{2}: commit: wip(lab2): start
ebd0570 (HEAD -> feature/lab2) HEAD@{3}: commit: docs(lab2): git internals
```
- Restore
```sh
$ git reset --hard 097e2b7
HEAD is now at 097e2b7 wip(lab2): more progress
```

If `git gc` (garbage collection) had run after a bad reset but before you could recover, it would have permanently deleted the orphaned commits from Git's internal database. Because a hard reset removes the branch pointer, those commits become unreachable, and `git gc` is designed to prune these unreferenced objects to optimize repository size. Once garbage collection purges them, the lost code can no longer be recovered using `git reflog`.

### Annotated, signed release tag
Signature confirmation
```sh
$ git tag -v "v0.1.0-lab2-${USER}"
object 9952fea4631fd30f9dd790ccf65d39d7dd94fa87
type commit
tag v0.1.0-lab2-arsenez
tagger arsenez <arsenez@cybercommunity.space> 1780836310 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for arsenez@cybercommunity.space with ED25519 key SHA256:2J3M7ENdm13QZIlzpxyzXRyoz6dEuk9j8zLyMQigQ40
```

### Rebasing
Feature branch before rebase
```sh
$ git log --oneline --graph
* f485c3d (HEAD -> feature/lab2, origin/feature/lab2) docs(lab2): tag signature confirmation
* 6e3f784 docs(lab2): recovery from reset
* ebd0570 docs(lab2): git internals
* 9952fea (tag: v0.1.0-lab2-arsenez) docs: add PR template
* 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
```
Feature branch after rebase
```sh
$ git log --oneline --graph
* 56ed5aa (HEAD -> feature/lab2, origin/feature/lab2) docs(lab2): tag signature confirmation
* d25a31d docs(lab2): recovery from reset
* 2c610f2 docs(lab2): git internals
* 1a9aa4e (origin/main, origin/HEAD, main) docs: upstream moved while you worked
* 9952fea (tag: v0.1.0-lab2-arsenez) docs: add PR template
* 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
```

The choice between merge and rebase comes down to whether you prioritize a perfectly accurate historical record or a clean, readable story. For public shared branches, use `git merge` instead of `git rebase` to prevent other contributors from manual reconciling of their local branches.
