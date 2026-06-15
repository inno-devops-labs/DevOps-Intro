## Task 1.1 — Git Object Model Chain

### 1. HEAD → Commit

Command:

bash git rev-parse HEAD 

Output:

text 5854b9ca2cea5f30dfb5ceb1b7d137f2a3cb34a8 

---

### 2. Object Type

Command:

bash git cat-file -t HEAD 

Output:

text commit 

---

### 3. Commit Object

Command:

bash git cat-file -p HEAD 

Output:

text tree 18785a6ecf62ac501ae44c44ce86aa800dd97f35 parent 73fa34a86bfe066e2bbb8d669663c5ea3a2ae8a3 parent 7979db4894a597a05f6baf5131492f769ed28dad author Ayomide <daliquido@gmail.com> 1781443904 +0100 committer Ayomide <daliquido@gmail.com> 1781443904 +0100  resolve merge conflict in lab1.md 


### 4. Tree Object

Command:

bash git cat-file -p 18785a6ecf62ac501ae44c44ce86aa800dd97f35 

Output:

text 040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d .github 100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee .gitignore 100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e README.md 040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a app 040000 tree 89bc50bc368eff78a23dcf65c83a925674de2e66 labs 040000 tree 3f11973a71be5915539cb53313149aa319d69cb5 lectures 040000 tree a4cf651fa5ebc05a02df100814fe1f55a8904b76 submissions 



### 5. Blob Object

Command:

bash git cat-file -p d10c04c6e7e0014f4fe883599c11747c15012d4e 

Output (beginning of file):

text # DevOps Intro — Modern DevOps Practices Through One Project 

Interpretation:

A commit object points to a tree object. The tree object contains references to blobs and subtrees. A blob stores the actual contents of a file. The chain observed was:

HEAD → Commit → Tree → Blob → README.md
 ## Task 1.2 — Inspecting .git Internals  ### High-Level .git Structure  Command: bash
ls -la .git/
 Output: text
total 64
drwxr-xr-x  15 i  staff   480 Jun 14 14:31 .
drwxr-xr-x  11 i  staff   352 Jun 14 14:25 ..
-rw-r--r--   1 i  staff    34 Jun 14 14:31 COMMIT_EDITMSG
-rw-r--r--   1 i  staff   504 Jun 14 12:55 config
-rw-r--r--   1 i  staff    73 Jun 14 12:24 description
-rw-r--r--   1 i  staff   793 Jun 14 12:26 FETCH_HEAD
-rw-r--r--   1 i  staff    29 Jun 14 14:25 HEAD
drwxr-xr-x  15 i  staff   480 Jun 14 12:24 hooks
-rw-r--r--   1 i  staff  3391 Jun 14 14:31 index
drwxr-xr-x   3 i  staff    96 Jun 14 12:24 info
drwxr-xr-x   4 i  staff   128 Jun 14 12:24 logs
drwxr-xr-x  53 i  staff  1696 Jun 14 14:31 objects
-rw-r--r--   1 i  staff    41 Jun 14 14:25 ORIG_HEAD
-rw-r--r--   1 i  staff   112 Jun 14 12:24 packed-refs
drwxr-xr-x   5 i  staff   160 Jun 14 12:24 refs

 Interpretation:  The `.git` directory contains Git's internal metadata, including objects, references, logs, hooks, and repository configuration.  ---  ### HEAD Reference  Command: bash

cat .git/HEAD
 Output: text
ref: refs/heads/feature/lab1
 Interpretation:  HEAD is a symbolic reference to the currently checked-out branch. It points to `feature/lab1`.  ---  ### Branch References  Command: bash
ls .git/refs/heads/
 Output: text
feature
main

 Interpretation:  This directory stores branch references. Each branch points to a specific commit.  ---  ### Object Directory Structure  Command: bash
ls .git/objects/ | head
 Output: text
0a
0c
0e
0f
11
13
14
15
18
1a
 Interpretation:  Git stores objects using hash-based directories. The first two characters of the object hash form the directory name.  ---  ### Loose Objects Count  Command: bash
find .git/objects -type f | wc -l
 Output: text
59
```

Interpretation:

The repository currently contains 59 loose Git objects (commits, trees, blobs, and other object types stored individually).

## Task 1.3 — Simulate Disaster and Recover

### Reflog Output

Command:

bash git reflog 

Output:

text 5854b9c (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{0}: reset: moving to HEAD~2 81cc3d3 HEAD@{1}: commit: wip(lab2): more progress fd8a526 HEAD@{2}: commit: wip(lab2): start 5854b9c (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{3}: checkout: moving from feature/lab1 to feature/lab2 5854b9c (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{4}: commit (merge): resolve merge conflict in lab1.md 73fa34a HEAD@{5}: checkout: moving from feature/lab1 to feature/lab1 73fa34a HEAD@{6}: checkout: moving from main to feature/lab1 7979db4 (main) HEAD@{7}: commit: final: lab1 complete 58059c2 HEAD@{8}: commit: final: lab1 complete 7cf5fef (origin/main, origin/HEAD) HEAD@{9}: checkout: moving from feature/lab1 to main 73fa34a HEAD@{10}: checkout: moving from main to feature/lab1 7cf5fef (origin/main, origin/HEAD) HEAD@{11}: commit: test: should fail 8089ff4 HEAD@{12}: commit: test: should fail f5bd7cd HEAD@{13}: commit: test: unsigned commit (should fail) 92f37c9 HEAD@{14}: checkout: moving from feature/lab1 to main 73fa34a HEAD@{15}: commit: docs(lab1): add GitHub community section 150a623 HEAD@{16}: commit: docs(lab1): finish submission 4273e5b HEAD@{17}: checkout: moving from main to feature/lab1 92f37c9 HEAD@{18}: commit: docs: add PR template bfa345b (upstream/main) HEAD@{19}: checkout: moving from feature/lab1 to main 4273e5b HEAD@{20}: commit (amend): docs(lab1): start submission 5946294 HEAD@{21}: commit: docs(lab1): start submission bfa345b (upstream/main) HEAD@{22}: checkout: moving from main to feature/lab1 bfa345b (upstream/main) HEAD@{23}: clone: from github.com:Daliquido/DevOps-Intro.git 

### Recovery Command

Command:

bash git reset --hard 81cc3d3 

Output:

text HEAD is now at 81cc3d3 wip(lab2): more progress 

### Explanation

The git reflog command records movements of HEAD, including commits, resets, and checkouts. Even after the destructive git reset --hard HEAD~2, the lost commits remained accessible through the reflog and were recovered by resetting back to commit 81cc3d3.

If git gc had run between the bad reset and the recovery, the unreachable commits could eventually have been garbage-collected and permanently removed. In that case, recovery through the reflog might no longer be possible because the underlying objects would have been deleted.


## Task 2.1 — Annotated Signed Release Tag

### Tag creation command
```bash
git tag -a -s "v0.1.0-lab2-${USER}" -m "Lab 2 milestone — version control deep dive"
Tag type
git cat-file -t v0.1.0-lab2-i
OUTPUT
tag
Tag verification output
git show v0.1.0-lab2-i