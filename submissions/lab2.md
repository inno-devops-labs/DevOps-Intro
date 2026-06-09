important work
more important work

### 1.1

```
git rev-parse HEAD

abb7262c8d9cdccc4ab94b27070dc91d296cd605

git cat-file -t HEAD
commit

git cat-file -p HEAD

tree b1634347961735580bbc84379e52791819dd989a
parent 72471632c4c0fb56f1123df4a220fd0db5bbf8b9
author Dmitrii <15dnau@gmail.com> 1781016337 +0300
committer Dmitrii <15dnau@gmail.com> 1781016337 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgnldO7B3ilZBUR+ZW+f85wSvJXT
 zuTuwPDbyKqYuitWUAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQM/CAVAfGJDnXSqn8QwTlqvf/C5KCn9uv1cRjVo+9q+jiMsEfkWQyOzKlGgsWITJen
 eQtEAlqYCnUCE7tV8hiQ0=
 -----END SSH SIGNATURE-----

docs(lab1): bonus submission

Signed-off-by: Dmitrii <15dnau@gmail.com>

git cat-file -p b1634347961735580bbc84379e52791819dd989a

100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures
040000 tree c0386cb299c0c0ec3b9730d1c6b256cd405b5eec    submissions

git cat-file -p d10c04c6e7e0014f4fe883599c11747c15012d4e
# DevOps Intro — Modern DevOps Practices Through One Project

[![Course](https://img.shields.io/badge/Course-DevOps%20Intro-blue)](#course-roadmap)
[![Project](https://img.shields.io/badge/Project-QuickNotes%20(Go)-success)](#the-project-quicknotes)
[![Duration](https://img.shields.io/badge/Duration-10%20Weeks-lightgrey)](#course-roadmap)
[![Grading](https://img.shields.io/badge/Grading-70--14--5--30--30-orange)](#grading)

A 10-week practical introduction to DevOps at Innopolis University. You will package, ship, observe, harden, and deploy **one** Go service — QuickNotes — across every lab. The discipline you learn here is the spine of modern production engineering.
```

### 1.2

Key files of git
head points to current branch
commit_edditmsg stores the message of last commit
index the staging area
orig head saves before a destructive operation
ls -la .git/
total 64
drwxr-xr-x@ 15 dmitrijnaumov  staff   480 Jun  9 17:45 .
drwxr-xr-x@ 10 dmitrijnaumov  staff   320 Jun  9 17:45 ..
-rw-r--r--@  1 dmitrijnaumov  staff    72 Jun  9 17:45 COMMIT_EDITMSG
-rw-r--r--@  1 dmitrijnaumov  staff   515 Jun  9 15:18 config
-rw-r--r--@  1 dmitrijnaumov  staff    73 Jun  5 13:47 description
-rw-r--r--@  1 dmitrijnaumov  staff    97 Jun  9 17:38 FETCH_HEAD
-rw-r--r--@  1 dmitrijnaumov  staff    29 Jun  9 17:45 HEAD
drwxr-xr-x@ 16 dmitrijnaumov  staff   512 Jun  5 13:47 hooks
-rw-r--r--@  1 dmitrijnaumov  staff  3363 Jun  9 17:45 index
drwxr-xr-x@  3 dmitrijnaumov  staff    96 Jun  5 13:47 info
drwxr-xr-x@  4 dmitrijnaumov  staff   128 Jun  5 13:48 logs
drwxr-xr-x@ 60 dmitrijnaumov  staff  1920 Jun  9 17:45 objects
-rw-r--r--@  1 dmitrijnaumov  staff    41 Jun  9 17:40 ORIG_HEAD
-rw-r--r--@  1 dmitrijnaumov  staff   112 Jun  5 13:48 packed-refs
drwxr-xr-x@  5 dmitrijnaumov  staff   160 Jun  5 13:48 refs

cat .git/HEAD
ref: refs/heads/feature/lab1

ls .git/refs/heads/
feature main
2 branches feature/ and main. feature/lab1 stored in feature/

ls .git/objects/ | head
00
06
0a
0c
0d
0e
0f
13
17
1a

find .git/objects -type f | wc -l
      68
Each object is a commit, tree or blob     
### 1.3

```
git reflog
abb7262 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{0}: reset: moving to HEAD~2
c932f37 HEAD@{1}: commit: wip(lab2): more progress
d0fa8cd HEAD@{2}: commit: wip(lab2): start
abb7262 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{3}: checkout: moving from feature/lab1 to feature/lab2
abb7262 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{4}: commit: docs(lab1): bonus submission

git reset --hard c932f37
HEAD is now at c932f37 wip(lab2): more progress
```
After git reset --hard HEAD~2, the two commits become unreachable — no branch or tag points to them anymore. Normally git reflog still knows their SHAs, but if git gc had run in that window, it would have scanned for unreachable objects and deleted them from .git/objects/. The commits, their trees, and blobs would be permanently gone — reflog entry would still show the SHA, but git reset --hard <SHA> would fail with "fatal: ambiguous argument".


## 2.2
```
git tag -v "v0.1.0-lab2-${USER}"
object 272a4d82c5e3137594576a273834e5b994ed34f1
type commit
tag v0.1.0-lab2-dmitrijnaumov
tagger Dmitrii <15dnau@gmail.com> 1781020288 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for 15dnau@gmail.com with ED25519 key SHA256:k0n7/mx/uRX52s/zu9pxaN+h/IKnBJzcnuybJgthVkM
```

```
git log --oneline --graph
* e980939 (HEAD -> feature/lab2, origin/feature/lab2) task 1
* 449b55a wip(lab2): more progress
* 69e047f wip(lab2): start
* c8d68dc docs(lab1): bonus submission
* 5a5f5df (origin/main, origin/HEAD, main) docs: upstream moved while you worked
* 272a4d8 (tag: v0.1.0-lab2-dmitrijnaumov) test: unsigned commit (should fail)
*   846a7a7 Merge pull request #2 from Dnau15/feature/lab1
|\
| * 7247163 docs(lab1): task3
| * 067b59f docs(lab1): finish submission
| * 843a27f docs(lab1): start submission
* | c2789ae docs: add PR template
|/
```


## Bonus
```
git switch -c bisect-quickn upstream/bug/bisect-me

branch 'bisect-quickn' set up to track 'upstream/bug/bisect-me'.
Switched to a new branch 'bisect-quickn'
```

```
git bisect start

status: waiting for both good and bad commits
```

```
git bisect bad  HEAD
status: waiting for good commit(s), bad commit known
```

```
git bisect good v0.0.1
Bisecting: 1 revision left to test after this (roughly 1 step)
[f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
```

```
git bisect run sh -c 'cd app && go test ./... && go build ./...'
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
--- FAIL: TestStore_PersistsAcrossReload (0.00s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL    quicknotes      0.260s
FAIL
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
ok      quicknotes      0.362s
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
git bisect reset
Previous HEAD position was cb89bb9 docs(store): comment the load() decode step
Switched to branch 'bisect-quickn'
Your branch is up to date with 'upstream/bug/bisect-me'.
```

git bisect uses binary search. At each step it checks out the commit exactly halfway between the known good and known bad commit. This halves the search space with every step, so for N commits it takes at most log₂(N) steps to find the culprit. For example, with 128 commits between good and bad, bisect finds the offending commit in at most 7 steps instead of 127. This is exactly why bisect is powerful in large repositories. A regression buried 1000 commits deep is found in just 10 steps.