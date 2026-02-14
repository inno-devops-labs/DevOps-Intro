# Lab 2 — Version Control & Advanced Git

## Task 1 — Git Object Model Exploration

## 1.1 Sample commits

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git status
On branch feature/lab2
nothing to commit, working tree clean
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ echo "Test content" > test.txt
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git add test.txt
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git commit -m "Add test file"
[feature/lab2 24dc484] Add test file
 1 file changed, 1 insertion(+)
 create mode 100644 test.txt
```

## 1.2 Inspect Git Objects

### Command outputs and examples

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git cat-file -p 2eec599 # blob for test.txt
Test content

thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git cat-file -p 560d532 # tree
040000 tree 427b12c6e48e802d5f39053d3dbab402f8ae374b    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree eb79e5a468ab89b024bd4f3ed867c6a3954fe1f0    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt

thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git cat-file -p 24dc484 # commit
tree 560d532e2f9a7e92ed1c5760c05e6ac2228eebd1
parent 5e57782fbef6c6d2e5bd2ee3080e4aaef103bf80
author thallars <arszemlyanikin@gmail.com> 1771057219 +0300
committer thallars <arszemlyanikin@gmail.com> 1771057219 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgMnV12Q66paCVHknJuSdNMKV9go
 GTg92ZAjIBauGtXIcAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQLpCJGfhrCXPlaWXJ3DXqRdHolTvaScqCByP4CCCJMYfaIyP5usulxeQCQFh+TQDex
 7JToppB/HR9jlCXqJYUwM=
 -----END SSH SIGNATURE-----

Add test file
```

### Object types

- Blob (Binary Large Object) stores the content of a file without any metadata.
- Tree represents a directory snapshot, containing references to blobs.
- Commit is a snapshot of the entire repository.

### How Git Stores Repository Data

Git stores data in a key-value database inside the .git/objects directory, where the key is a hash of the content and the value is the compressed object itself.

## Task 2 — Reset and Reflog Recovery

### Initial state after setup

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git log --oneline
e3122c6 (HEAD -> git-reset-practice) Third commit
0aaea91 Second commit
09cbfb5 First commit

thallars@ASUS-TUF:~/Documents/DevOps-Intro$ cat file.txt
First commit
Second commit
Third commit
```

### Soft reset

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git log --oneline
0aaea91 (HEAD -> git-reset-practice) Second commit
09cbfb5 First commit

thallars@ASUS-TUF:~/Documents/DevOps-Intro$ cat file.txt
First commit
Second commit
Third commit
```

- History: HEAD moved from "Third commit" to "Second commit"
- Index (staging area): Still contains changes from the third commit
- Working tree: File unchanged, still has all three lines

### Hard reset

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git log --oneline
01b4be2 (HEAD -> git-reset-practice) Second commit
09cbfb5 First commit

thallars@ASUS-TUF:~/Documents/DevOps-Intro$ cat file.txt
First commit
Second commit
```

- History: HEAD moved from "Third commit" to "Second commit"
- Index: Completely reset to match the second commit
- Working tree: File overwritten to match the second commit

### Recovery

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git reflog
01b4be2 (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
f9c305e HEAD@{1}: commit: Third commit
01b4be2 (HEAD -> git-reset-practice) HEAD@{2}: commit: Second commit
09cbfb5 HEAD@{3}: reset: moving to HEAD~1
0aaea91 HEAD@{4}: reset: moving to HEAD~1
e3122c6 HEAD@{5}: reset: moving to HEAD@{1}
0aaea91 HEAD@{6}: reset: moving to HEAD~1
e3122c6 HEAD@{7}: commit: Third commit
0aaea91 HEAD@{8}: commit: Second commit
09cbfb5 HEAD@{9}: commit: First commit
```

The refog shows:
- e3122c6 HEAD@{7} -- Original "Third commit"

To recover the third commit:

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git reset --hard e3122c6
HEAD is now at e3122c6 Third commit

thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git log --oneline
e3122c6 (HEAD -> git-reset-practice) Third commit
0aaea91 Second commit
09cbfb5 First commit

thallars@ASUS-TUF:~/Documents/DevOps-Intro$ cat file.txt
First commit
Second commit
Third commit
```

### Recovery Analysis 

1. Git doesn't immediately delete orphaned commits. 
2. Reflog records every HEAD movement locally.
3. Even after --hard, the commit object still exists in .git/objects

## Task 3 — Visualize Commit History

```bash
* 8363613 (side-branch) Side branch commit
* 1435eca (HEAD -> feature/lab2) docs: add lab2 submission
| * e3122c6 (git-reset-practice) Third commit
| * 0aaea91 Second commit
| * 09cbfb5 First commit
| * cecc6d1 docs: add lab2 submission
|/  
* 24dc484 Add test file
* ...
```

- The graph visualization transforms Git's complex DAG (Directed Acyclic Graph) structure into an intuitive visual map.

## Task 4 — Tagging Commits

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git tag v1.0.0
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git push origin v1.0.0
Enumerating objects: 9, done.
Counting objects: 100% (9/9), done.
Delta compression using up to 16 threads
Compressing objects: 100% (6/6), done.
Writing objects: 100% (7/7), 2.08 KiB | 2.08 MiB/s, done.
Total 7 (delta 4), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (4/4), completed with 2 local objects.
To github.com:thallars/DevOps-Intro.git
 * [new tag]         v1.0.0 -> v1.0.0
```

- Versioning: Tags create immutable, human-readable references to specific points in history, making it trivial to checkout exact release versions for debugging or deployment.
- CI/CD Triggers: Many CI/CD pipelines automatically build and deploy when new tags are pushed, enabling automated release workflows based on semantic versioning.
- Release Notes: Tags serve as anchors for generating changelogs and release notes by comparing commit history between tagged versions (git log v1.0.0..v1.1.0).

## Task 5 — git switch vs git checkout vs git restore

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git switch -c cmd-compare
Switched to a new branch 'cmd-compare'

thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git branch
* cmd-compare
  feature/lab1
  feature/lab2
  git-reset-practice
  main
  side-branch
```

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git checkout -b cmd-compare-2 
Switched to a new branch 'cmd-compare-2'
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ git branch
  cmd-compare
* cmd-compare-2
  feature/lab1
  feature/lab2
  git-reset-practice
  main
  side-branch
```

- git switch — Use exclusively for branch operations (creating, switching, moving between branches) when you want a clean, focused command that only affects your branch context and nothing else.

- git checkout — Still useful for its original purpose of checking out specific commits or files from history (like git checkout v1.0.0), but avoid for branch switching now that switch exists and for file restoration now that restore exists.

- git restore — Use for all file-related operations: discarding working directory changes, unstaging files, or restoring files from specific commits; it's the modern, purpose-built tool that clearly separates file operations from branch management.

## GitHub Community

Starring repositories matters in open source because it serves as both a bookmark for interesting projects and a signal to maintainers about feature demand and community interest, helping popular projects gain visibility and attract contributors.

Following developers helps in team projects and professional growth by providing insight into their public contributions, coding patterns, and project involvement, which fosters knowledge sharing and creates networking opportunities within the developer community.
