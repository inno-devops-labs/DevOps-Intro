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

