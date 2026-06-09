# Lab 2 submission



## Task 1.



### HEAD



```

$ git cat-file -p HEAD

tree cc6bbbe8afd190b513ffd92f400906558a872fec

parent d10cb568aea15bce95482512b61db716921b89d8

author darknesod <darknesod1@gmail.com> 1781008666 +0300

committer darknesod <darknesod1@gmail.com> 1781008666 +0300

gpgsig -----BEGIN SSH SIGNATURE-----

&#x20;U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgGwo9P6Qa2noWzMMeAY0YqvaWMZ

&#x20;eQ8TynK6jc/3lTKH8AAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5

&#x20;AAAAQKEyEiNkkcTp/MOeLwr96EhOA6igy1notCi0j1FktcuSVeMUWGYWeK1xNl522a+XaF

&#x20;Kct05lkRGdce3L6gOHgwI=

&#x20;-----END SSH SIGNATURE-----



docs: update PR template



Signed-off-by: darknesod <darknesod1@gmail.com>

```



### tree



```

$ git cat-file -p cc6bbbe8afd190b513ffd92f400906558a872fec

040000 tree 895aaaccf626c1f668406e2f9f6b15a9d17ddb62    .github

100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore

100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md

040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app

040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs

040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures

```



### blob

```

$ git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee

\# ⚠️  KEEP THIS FILE MINIMAL.

\#

\# This .gitignore is inherited by every student fork. Anything listed here

\# is something a student CANNOT `git add` without `-f`. So this file must

\# ONLY contain:

\#   (a) instructor-only paths (refs/), and

\#   (b) machine-generated junk that NOBODY should ever commit.

\#

\# Do NOT add lab DELIVERABLES here (scan reports, SBOMs, go.sum, k8s

\# manifests, CI workflows, Dockerfiles, playbooks, dashboards, …). Students

\# are told to commit those in their submission PRs — ignoring them upstream

\# silently breaks the lab. When in doubt, leave it OUT of this file.



\# ── Instructor-only ─────────────────────────────────────────────

\# Reference submissions (dry-run worked examples). Never pushed upstream;

\# students never see these. This is the one path that is intentionally hidden.

refs/



\# ── Machine-generated junk (no one commits these) ───────────────

\# Compiled binaries / local runtime state

app/quicknotes

app/data/

/quicknotes

\*.exe



\# Vagrant runtime state (Lab 5) — the Vagrantfile IS committed; .vagrant/ is not

.vagrant/



\# Nix build symlinks (Lab 11) — flake.nix + flake.lock ARE committed; result is not

result

result-\*



\# Terraform state — MUST never be committed (can contain secrets)

\*.tfstate

\*.tfstate.backup

.terraform/



\# Python virtualenvs / caches

.venv/

\_\_pycache\_\_/

\*.pyc



\# Editor / IDE

.vscode/

.idea/

\*.swp



\# OS noise

.DS\_Store

Thumbs.db



\# Local agent config (not part of the course)

.claude/



\# NOTE: deliberately NOT ignored, because students commit them as lab evidence:

\#   submissions/labN.md        (lab reports)

\#   .github/workflows/\*.yml    (Lab 3 CI)

\#   Dockerfile, compose.yaml   (Lab 6)

\#   ansible/                   (Lab 7)

\#   monitoring/                (Lab 8)

\#   \*.sbom.cdx.json, zap-\*.html/json, trivy-\*.txt   (Lab 9 scan evidence)

\#   flake.nix, flake.lock      (Lab 11)

\#   wasm/main.go, spin.toml, go.sum   (Lab 12)



```



### inside .git/



```

$ ls -la .git/  # The .git/ directory contains all internal Git metadata that makes version control work.

total 34

drwxr-xr-x 1 ddost 197609    0 Jun  9 17:35 ./

drwxr-xr-x 1 ddost 197609    0 Jun  9 17:35 ../

\-rw-r--r-- 1 ddost 197609   74 Jun  9 17:18 COMMIT\_EDITMSG

\-rw-r--r-- 1 ddost 197609  110 Jun  9 17:30 FETCH\_HEAD

\-rw-r--r-- 1 ddost 197609   29 Jun  9 17:35 HEAD

\-rw-r--r-- 1 ddost 197609   41 Jun  9 17:25 ORIG\_HEAD

\-rw-r--r-- 1 ddost 197609  432 Jun  7 18:11 config

\-rw-r--r-- 1 ddost 197609   73 Jun  7 18:05 description

drwxr-xr-x 1 ddost 197609    0 Jun  7 18:05 hooks/

\-rw-r--r-- 1 ddost 197609 3307 Jun  9 17:35 index

drwxr-xr-x 1 ddost 197609    0 Jun  7 18:05 info/

drwxr-xr-x 1 ddost 197609    0 Jun  7 18:05 logs/

drwxr-xr-x 1 ddost 197609    0 Jun  9 17:30 objects/

\-rw-r--r-- 1 ddost 197609  112 Jun  7 18:05 packed-refs

drwxr-xr-x 1 ddost 197609    0 Jun  7 18:05 refs/





$ cat .git/HEAD # points to the current active branch

ref: refs/heads/feature/lab2





$ ls .git/refs/heads/ # Stores latest commit hashes (pointers) for each local branch.

feature/  main





$ ls .git/objects/ | head # Git’s object database. It stores all commits, trees, and blobs in compressed form

00/

07/

0a/

0c/

0e/

0f/

13/

14/

17/

1a/





$ find .git/objects -type f | wc -l # Total number of stored Git objects in the repository (commits, blobs, trees)

58

```



### disaster + recover



```

$ git reflog

1772d01 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{0}: reset: moving to HEAD\~2

2aedaf4 HEAD@{1}: commit: wip(lab2): more progress

dbfa639 HEAD@{2}: commit: wip(lab2): start

1772d01 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{3}: checkout: moving from main to feature/lab2

1772d01 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{4}: checkout: moving from main to main

1772d01 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{5}: commit: docs: update PR template

d10cb56 HEAD@{6}: checkout: moving from feature/lab1 to main

9ba65b7 (origin/feature/lab1, feature/lab1) HEAD@{7}: checkout: moving from main to feature/lab1

d10cb56 HEAD@{8}: commit: docs: add PR template

66bbd4d (upstream/main, upstream/HEAD) HEAD@{9}: checkout: moving from feature/lab1 to main

9ba65b7 (origin/feature/lab1, feature/lab1) HEAD@{10}: commit (amend): docs(lab1

): complete submission

14b3f3c HEAD@{11}: commit: docs(lab1): complete submission

07770d4 HEAD@{12}: checkout: moving from feature/lab1 to feature/lab1

07770d4 HEAD@{13}: commit: docs: add PR template

e90b6df HEAD@{14}: commit (amend): docs(lab1): start submission

409618a HEAD@{15}: commit: docs(lab1): start submission

```



```

$ git reset --hard 2aedaf4

HEAD is now at 2aedaf4 wip(lab2): more progress

```



If git gc had run between the bad --hard reset and the recovery, Git might have permanently deleted the “lost” commits if they were no longer referenced anywhere. Normally, reflog keeps commits recoverable for a period of time, but garbage collection can clean up unreachable objects earlier in some cases. This means your ability to restore the commits using reflog could have been lost.



## Task 2.


### Tag verification

```
$ git tag -v v0.1.0-lab2-darknesod
object c7bb13418e6ad7bd7655d913d70b6e2a3cb438e5
type commit
tag v0.1.0-lab2-darknesod
tagger darknesod <darknesod1@gmail.com> 1781020928 +0300

Lab 2 milestone — version control deep dive
Good "git" signature with ED25519 key SHA256:KTIlBmBdoxVYD31wa9exPhLOUXTzl+xYbxxIi8xDwkU
C:/Users/ddost/.config/git/allowed_signers:1: bad options: unknown key option
No principal matched.
```

```
Note: SSH signing verification shows "Good signature" but no principal match due to local allowed_signers configuration issue. Signature is still valid.
```

### Before tag:

```
$ git log --oneline --graph --decorate -5
* 1772d01 (HEAD) docs: update PR template
* d10cb56 docs: add PR template
* 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
|\
| * d50436c (upstream/s26-refactor) fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
```

### After tag:

```
git log --oneline --graph --decorate -5
* c7bb134 (HEAD -> main, tag: v0.1.0-lab2-darknesod, origin/main, origin/HEAD) docs: upstream moved while you worked
* 1772d01 docs: update PR template
* d10cb56 docs: add PR template
* 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
|\
```

### Tag Description

```
$ git show v0.1.0-lab2-darknesod
tag v0.1.0-lab2-darknesod
Tagger: darknesod <darknesod1@gmail.com>
Date:   Tue Jun 9 19:02:08 2026 +0300

Lab 2 milestone — version control deep dive
-----BEGIN SSH SIGNATURE-----
U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgGwo9P6Qa2noWzMMeAY0YqvaWMZ
eQ8TynK6jc/3lTKH8AAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
AAAAQF/4UCfP0wgwrTqZuF9uppYk4axQT7x3j7uHWsJS7Gbn9B3dhk3GLCoWpm83tQGkVl
DFYiC3+IB/As1sDsL43go=
-----END SSH SIGNATURE-----

commit c7bb13418e6ad7bd7655d913d70b6e2a3cb438e5 (HEAD -> main, tag: v0.1.0-lab2-darknesod, origin/main, origin/HEAD)
Author: darknesod <darknesod1@gmail.com>
Date:   Tue Jun 9 17:40:19 2026 +0300

    docs: upstream moved while you worked

    Signed-off-by: darknesod <darknesod1@gmail.com>
```



## Bonus task.



### B.3



```
$ git bisect start
git bisect bad
git bisect good v0.0.1
status: waiting for both good and bad commits
status: waiting for good commit(s), bad commit known
Bisecting: 1 revision left to test after this (roughly 1 step)
[f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
```



```
$ git bisect run sh -c "cd app && go test ./... && go build ./..."
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
--- FAIL: TestStore_PersistsAcrossReload (0.01s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL    quicknotes      0.797s
FAIL
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
ok      quicknotes      0.716s
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

```
$ git bisect reset
Previous HEAD position was cb89bb9 docs(store): comment the load() decode step
Switched to branch 'bisect'
Your branch is up to date with 'upstream/bug/bisect-me'.
```

Git bisect works like a binary search over commit history. It starts with one known good commit and one known bad commit, then repeatedly selects the midpoint commit between them for testing. After each step, Git marks the commit as good or bad and reduces the search range by half. Because the search space is halved at every iteration, the algorithm finds the faulty commit in logarithmic time, approximately O(log₂(N)), where N is the number of commits in the range.