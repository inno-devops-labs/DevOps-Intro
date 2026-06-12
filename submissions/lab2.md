# Lab 2

## Task 1

### Task 1.1

`git rev-parse HEAD`

```
450023952d78dcbb2faa5a1010887681daf96fde
```

---

`git cat-file -t HEAD`

```
commit
```

---

`git cat-file -p HEAD`

```
tree b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322
parent 66bbd4db9228bc9a4cab7439746b993749c026ab
author Danil Khasanshin <danil.2006@list.ru> 1780767681 +0300
committer Danil Khasanshin <danil.2006@list.ru> 1780767681 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgr/Ar9WGZQj0ceRFSxfX+gfUejA
 FZe0Wh1FUIAjPd5AIAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQC6AWsdNtKbzjk1VBwh8BR/IK8L2rCJCbsdZ6FdvPhOQG2V3HdLANwZS2WwXyYUShG
 bRpsZTbyw8EvDgOGNcMgc=
 -----END SSH SIGNATURE-----

 docs: add PR template

Signed-off-by: Danil Khasanshin <danil.2006@list.ru>
 ```

 ---

`git cat-file -p b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322`

```
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 6db686e340ecdd318fa43375e26254293371942a	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
```

---

`git cat-file -p d10c04c6e7e0014f4fe883599c11747c15012d4e`

```
# DevOps Intro — Modern DevOps Practices Through One Project

[![Course](https://img.shields.io/badge/Course-DevOps%20Intro-blue)](#course-roadmap)
[![Project](https://img.shields.io/badge/Project-QuickNotes%20(Go)-success)](#the-project-quicknotes)
[![Duration](https://img.shields.io/badge/Duration-10%20Weeks-lightgrey)](#course-roadmap)
[![Grading](https://img.shields.io/badge/Grading-70--14--5--30--30-orange)](#grading)

A 10-week practical introduction to DevOps at Innopolis University. You will package, ship, observe, harden, and deploy **one** Go service — QuickNotes — across every lab. The discipline you learn here is the spine of modern production engineering.

> 💬 *"If it hurts, do it more often."* — Jez Humble

---

## Course Roadmap

10 weekly labs + 2 optional bonus labs:

| Week | Lab | Module | Key Topics & Technologies |
|------|-----|--------|---------------------------|
| 1 | Lab 1 | DevOps Foundations & Git | DevOps history, fork → branch → PR, signed commits (SSH 2.34+), PR templates |
| 2 | Lab 2 | Version Control Deep Dive | Object model, reflog recovery, reset modes, signed tags, rebase, bisect |
| 3 | Lab 3 | CI/CD | GitHub Actions (matrix, cache, OIDC); Bonus: GitLab CI mirror |
| 4 | Lab 4 | OS & Networking | OSI, DNS, HTTP, TLS, `ss`/`dig`/`tcpdump`/`journalctl` debugging |
| 5 | Lab 5 | Virtualization | Vagrant + VirtualBox, snapshots, cloud-init |
| 6 | Lab 6 | Containers | Multi-stage Dockerfile, distroless, Compose, hardening |
| 7 | Lab 7 | Configuration Management | Ansible playbook to deploy QuickNotes to Lab 5 VM; ansible-pull GitOps preview |
| 8 | Lab 8 | SRE & Monitoring | Golden signals, Prometheus, Grafana, one good alert, Checkly |
| 9 | Lab 9 | DevSecOps | Trivy, OWASP ZAP, SBOM, govulncheck reachability |
| 10 | Lab 10 | Cloud Computing | `ghcr.io` push from CI, Hugging Face Spaces deploy (card-free), Cloudflare Tunnel comparison |
| — | Lab 11 | Reproducible Builds *(bonus)* | Nix flake for QuickNotes; deterministic OCI image |
| — | Lab 12 | WebAssembly Containers *(bonus)* | TinyGo + Spin/WAGI; perf comparison vs Docker |

---
...
```

### Task 1.2

`ls -la .git/`

```
total 64
drwxr-xr-x  15 dankhasanshin  staff   480 Jun  7 10:35 .
drwxr-xr-x  11 dankhasanshin  staff   352 Jun  7 10:20 ..
-rw-r--r--   1 dankhasanshin  staff    87 Jun  6 23:43 COMMIT_EDITMSG
-rw-r--r--   1 dankhasanshin  staff   795 Jun  7 10:21 FETCH_HEAD
-rw-r--r--   1 dankhasanshin  staff    29 Jun  7 10:23 HEAD
-rw-r--r--   1 dankhasanshin  staff    41 Jun  6 23:29 ORIG_HEAD
-rw-r--r--   1 dankhasanshin  staff   504 Jun  6 19:56 config
-rw-r--r--   1 dankhasanshin  staff    73 Jun  6 18:07 description
drwxr-xr-x  16 dankhasanshin  staff   512 Jun  6 18:07 hooks
-rw-r--r--   1 dankhasanshin  staff  3183 Jun  7 10:20 index
drwxr-xr-x   3 dankhasanshin  staff    96 Jun  6 18:07 info
drwxr-xr-x   4 dankhasanshin  staff   128 Jun  6 18:07 logs
drwxr-xr-x  65 dankhasanshin  staff  2080 Jun  7 10:21 objects
-rw-r--r--   1 dankhasanshin  staff   112 Jun  6 18:07 packed-refs
drwxr-xr-x   5 dankhasanshin  staff   160 Jun  6 23:38 refs
```

---

`cat .git/HEAD`

```
ref: refs/heads/feature/lab2
```

---

`ls .git/refs/heads/`

```
feature	main
```

---

`find .git/refs/heads -type f -print`

```
.git/refs/heads/feature/lab1
.git/refs/heads/feature/lab2
.git/refs/heads/main
```

---

`ls .git/objects/ | head`

```
00
03
04
0a
0b
0c
0e
0f
11
13
```

---

`find .git/objects -type f | wc -l`

```
77
```

---

The .git/ directory contains the local repository metadata and history. HEAD points to the currently checked-out branch through a reference such as refs/heads/feature/lab2. Local branch references ultimately point to commit SHAs, while .git/objects/ stores Git objects such as commits, trees, and blobs. Loose objects are grouped into directories by the first two characters of their hashes; packed objects may also be stored under .git/objects/pack/.

### Task 1.3

`echo "important work" > submissions/lab2.md`

`git add submissions/lab2.md`

`git commit -S -s -m "wip(lab2): start"`

`git log --oneline -3`

```
3e9b619 (HEAD -> feature/lab2) wip(lab2): start
4500239 (origin/main, origin/HEAD, main) docs: add PR template
66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
```

---

`echo "more important work" >> submissions/lab2.md`

`git commit -S -s -am "wip(lab2): more progress"`

`git log --oneline -5`

```
9d87572 (HEAD -> feature/lab2) wip(lab2): more progress
3e9b619 wip(lab2): start
4500239 (origin/main, origin/HEAD, main) docs: add PR template
66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
```

`git reset --hard HEAD~2`

```
HEAD is now at 4500239 docs: add PR template
```

`git log --oneline -5`

```
4500239 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) docs: add PR template
66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
d50436c (upstream/s26-refactor) fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
4705a3d fix(.gitignore): stop ignoring submissions/
```

`git reflog --oneline -10`

```
4500239 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{0}: reset: moving to HEAD~2
9d87572 HEAD@{1}: commit: wip(lab2): more progress
3e9b619 HEAD@{2}: commit: wip(lab2): start
4500239 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{3}: checkout: moving from main to feature/lab2
4500239 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{4}: checkout: moving from feature/lab1 to main
f9f9300 (origin/feature/lab1, feature/lab1) HEAD@{5}: commit: docs(lab1): added .png to images
518f8de HEAD@{6}: commit: docs(lab1): document branch protection bonus
dd58d30 HEAD@{7}: checkout: moving from main to feature/lab1
4500239 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{8}: reset: moving to HEAD~1
70bccd8 HEAD@{9}: pull --ff-only origin main: Fast-forward
```

`git reset --hard 9d87572`

```
HEAD is now at 9d87572 wip(lab2): more progress
```

`git log --oneline -5`


```
9d87572 (HEAD -> feature/lab2) wip(lab2): more progress
3e9b619 wip(lab2): start
4500239 (origin/main, origin/HEAD, main) docs: add PR template
66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
```

After the destructive reset, the discarded commits became unreachable from the current branch, but they were still recoverable because their objects remained in .git/objects/ and their SHAs were recorded in the reflog. A normal git gc usually preserves recently unreachable objects for a grace period, so immediate data loss would be unlikely. However, after reflog expiration or an aggressive pruning command such as git gc --prune=now, the unreachable objects could be deleted permanently, and the reflog SHA would no longer be sufficient to restore the lost work.

## Task 2

### Task 2.1

`git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'`


```
v0.0.1 tag commit
v0.1.0-lab2-dankhasanshin tag commit
```

`git tag -v "v0.1.0-lab2-${USER}"`

```
object 450023952d78dcbb2faa5a1010887681daf96fde
type commit
tag v0.1.0-lab2-dankhasanshin
tagger Danil Khasanshin <danil.2006@list.ru> 1780827806 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for danil.2006@list.ru with ED25519 key SHA256:xBYpXoDFi9CwxWco0tgFXy+0HSD4NxXrb3qsNsdqQY0
```

### Task 2.2

**Before:**

`git log --oneline --graph --decorate -8`

```
* 9d87572 (HEAD -> feature/lab2) wip(lab2): more progress
* 3e9b619 wip(lab2): start
* 4500239 (tag: v0.1.0-lab2-dankhasanshin, origin/main, origin/HEAD, main) docs: add PR template
* 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
|\
| * d50436c (upstream/s26-refactor) fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
| * 4705a3d fix(.gitignore): stop ignoring submissions/
| * 4082340 docs(grading,lab11,lab12): bonus labs to 4+4+2; grading rebalanced to 70-14-5-20-30 = 139%
```

---

**After:**

`git log --oneline --graph --decorate -8`

```
* c6b63d2 (HEAD -> feature/lab2) wip(lab2): more progress
* 41fede9 wip(lab2): start
* 30cf07c (origin/main, origin/HEAD, main) docs: upstream moved while you worked
* 4500239 (tag: v0.1.0-lab2-dankhasanshin) docs: add PR template
* 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
|\
| * d50436c (upstream/s26-refactor) fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
| * 4705a3d fix(.gitignore): stop ignoring submissions/`
```

I would use rebase for my local feature branch before opening a pull request because it produces a clean linear history and places my changes on top of the latest main. I would use merge when integrating an approved pull request into a shared branch because it preserves the relationship between branches and avoids rewriting public history. Rebasing a shared branch such as main would be unsafe because other developers may already depend on its existing commit SHAs.


## Bonus Task

`git bisect run sh -c 'cd app && go test ./... && go build ./...'`

```
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
--- FAIL: TestStore_PersistsAcrossReload (0.00s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL	quicknotes	0.305s
FAIL
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
ok  	quicknotes	0.303s
f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
commit f285ede8611e55ac0a7d01100891c0cc775e0709
Author: Dmitrii Creed <creeed22@gmail.com>
Date:   Fri Jun 5 13:36:56 2026 +0400

    refactor(store): simplify nextID restoration in load()

    Signed-off-by: Dmitrii Creed <creeed22@gmail.com>

 app/store.go | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first bad commit
```

`git bisect log`

```
git bisect start
# status: waiting for both good and bad commits
# bad: [f0c9243b7c80ebb930a1ce7048a1d65b4c2ac493] docs(app): mention go test invocation
git bisect bad f0c9243b7c80ebb930a1ce7048a1d65b4c2ac493
# status: waiting for good commit(s), bad commit known
# good: [0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7] chore(app): document versioning scheme (bisect fixture baseline)
git bisect good 0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7
# good: [0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7] chore(app): document versioning scheme (bisect fixture baseline)
git bisect good 0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7
# bad: [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
git bisect bad f285ede8611e55ac0a7d01100891c0cc775e0709
# good: [cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
git bisect good cb89bb9ee2ee5010b166061447eaca3ae0da2378
# first bad commit: [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
```

`git show --no-patch --oneline f285ede8611e55ac0a7d01100891c0cc775e0709`

```
f285ede refactor(store): simplify nextID restoration in load()
```

### Why bisect is efficient

Git bisect uses binary search. At every step, it tests a commit approximately halfway between the known-good and known-bad revisions, then discards half of the remaining search range. As a result, finding the first bad commit among N candidate commits requires approximately log₂(N) checks rather than testing every commit one by one. This makes bisect especially useful for large repositories with long histories.