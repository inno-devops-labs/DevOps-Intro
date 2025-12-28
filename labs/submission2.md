# Lab 2 Submission

## Task 1 — Git Object Model Exploration

### Blob Object

```bash 
> % git cat-file -p 4775dabc914d1d91749b24a5a2a5d550747d5ebe 
> Third commit
```

**Explanation:** A blob object stores raw file content without any metadata (filename, permissions, etc). It represents the actual data of a file at a specific point in time.

### Tree Object

```bash
> % git cat-file -p c8cd80979e74f107436e6db69ba3a5dfeb763b66
> 040000 tree 37fd115266dfb22bc7ccb4f848fed82c342c5d89    .github
100644 blob 4db373667a50f14a411bb5c7e879690fd08aacc1    README.md
100644 blob 4775dabc914d1d91749b24a5a2a5d550747d5ebe    file.txt
040000 tree 61d4d824c8deb93779f2620042486ccda0cd241b    labs
040000 tree 1865343f08695045014e0ed223b464e5403fca25    lectures
```

**Explanation:** A tree object represents a directory structure, containing references to blobs and other trees with their names, permissions, and object hashes.

### Commit Object

```bash 
> % git cat-file -p 1762ae3330152ca6827a789a539eafcaa873d37e
> tree c8cd80979e74f107436e6db69ba3a5dfeb763b66
parent 697e5047d4bf17eb219c8d142e0e34d7f1cd1a3c
author RailSab <railsabirov2005@gmail.com> 1757365975 +0300
committer RailSab <railsabirov2005@gmail.com> 1757365975 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgV4ltBZjIaWnhPsouIvOwFwLe7/
 cRyMWk6ylDJ/J1ckMAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQGI6XGjasPvdrrqHGMHr1KIeyIorOEHL2tCkW92zhJbr33QGh83flR7NyyLuXwNSp7
 gCt4wqwWBiji81VMKJBwY=
 -----END SSH SIGNATURE-----

Task1: Third commit
```

**Explanation:** A commit object contains metadata about a specific commit including the tree hash, parent commit, author, committer, signature, commit message.

## Task 2 — Reset and Reflog Recovery

### Commands

#### Initial Setup

```bash
# Created practice branch and commits
git switch -c git-reset-practice
echo "First commit" > file.txt && git add file.txt && git commit -m "Task2:First commit"
echo "Second commit" >> file.txt && git add file.txt && git commit -m "Task2:Second commit"  
echo "Third commit" >> file.txt && git add file.txt && git commit -m "Task2:Third commit"
```

#### Initial State After Setup

```bash
> git log --oneline
> 9dabe82 (HEAD -> git-reset-practice) Task2:Third commit
83349a5 Task2:Second commit
e798c9f Task2:First commit
```

#### File content

```bash
> cat file.txt
> First commit
Second commit
Third commit
```

#### Soft reset

Moves HEAD back one commit but keeps changes in the index (staged).

```bash
> git reset --soft HEAD~1
> git log --oneline
  cat file.txt

83349a5 (HEAD -> git-reset-practice) Task2:Second commit
e798c9f Task2:First commit

First commit
Second commit
Third commit
```

**Explanation**:

- **Working tree:** file.txt still contains all three lines
- **Index:** Contains the "Task2:Third commit" changes (staged)
- **History:** HEAD moved back one commit (to "Task2:Second commit")

#### Hard reset

Moves HEAD back one commit and discards all changes in index and working tree.

```bash
> git reset --hard HEAD~1
> git log --oneline
  cat file.txt

e798c9f (HEAD -> git-reset-practice) Task2:First commit

First commit
```

**Explanation**:

- **Working tree:** file.txt reverted to "Task2:First commit" state (only "First commit" in file)
- **Index:** Clean, no staged changes
- **History:** HEAD moved back, "Second commit" lost from history

#### Reflog Recovery

```bash
> git reflog
> e798c9f (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
83349a5 HEAD@{1}: reset: moving to HEAD~1
9dabe82 HEAD@{2}: commit: Task2:Third commit
83349a5 HEAD@{3}: commit: Task2:Second commit
e798c9f (HEAD -> git-reset-practice) HEAD@{4}: commit: Task2:First commit
```

Using reflog to find the hash of "Task2:Third commit" and restore the complete state.

```bash
> git reset --hard 9dabe82
> HEAD is now at 9dabe82 Task2:Third commit
```

#### After recovery

```bash
> git log --oneline
> 9dabe82 (HEAD -> git-reset-practice) Task2:Third commit
83349a5 Task2:Second commit
e798c9f Task2:First commit

> cat file.txt
> First commit
Second commit
Third commit
```

- **--soft**: Moves HEAD only, keeps index and working tree unchanged
- **--hard**: Moves HEAD and resets both index and working tree to match the target commit
- **reflog**: Records all HEAD movements, allowing recovery of "lost" commits

## Task 3 - Visualize Commit History

```bash
> git log --oneline --graph --all
> * d5e3acd (side-branch) Task3: Side branch commit
* d5e3acd (side-branch) Task3: Side branch commit
| * 9dabe82 (git-reset-practice) Task2:Third commit
| * 9dabe82 (git-reset-practice) Task2:Third commit
* d5e3acd (side-branch) Task3: Side branch commit
| * 9dabe82 (git-reset-practice) Task2:Third commit
| * 83349a5 Task2:Second commit
| * e798c9f Task2:First commit
|/  
* 1762ae3 (HEAD -> feature/lab2) Task1: Third commit
* 697e504 Task1: Second commit
* b2734de Task1: First commit
*   8c1c451 (origin/main, origin/HEAD, main) Merge branch 'inno-devops-labs:main' into main
|\  
| * 3f80c83 feat: publish lec2
| * 499f2ba feat: publish lab2
| * af0da89 feat: update lab1
| | * b4edc5c (origin/feature/lab1, feature/lab1) docs: add commit signing summary
| |/  
|/|   
* | 3b06b2f docs: add PR template
|/  
* 74a8c27 Publish lab1
* f0485c0 Publish lec1
* 31dd11b Publish README.md
```

### Graph structure explanation

The Git graph visualization clearly shows the branching structure and parallel development paths, making it easy to understand when branches diverged and how commits relate to each other. The * and connecting lines provide an intuitive visual representation of the project's development timeline and branch relationships. There are present branches with related to them commits.

## Task 4 — Tagging Commits

### Commands Executed

```bash
> git tag v1.0.0
> git tag -l
v1.0.0
> git show v1.0.0 --oneline -s
1762ae3 (HEAD -> feature/lab2, tag: v1.0.0) Task1: Third commit
> git push origin v1.0.0
> git log --oneline --decorate
1762ae3 (HEAD -> feature/lab2, tag: v1.0.0) Task1: Third commit
697e504 Task1: Second commit
b2734de Task1: First commit
> git show v1.0.0
commit 1762ae3330152ca6827a789a539eafcaa873d37e (HEAD -> feature/lab2, tag: v1.0.0)
Author: RailSab <railsabirov2005@gmail.com>
Date:   Tue Sep 9 00:12:55 2025 +0300
...
```

### Why tags matters

**Release Notes**: Tags are like anchor points for generating release notes and changelogs, making it easy to identify what changes were included in each version.

**Versioning**: Tags provide semantic versioning that marks different releases and helps track software evolution over time.

**CI/CD Triggers**: Many continuous integration and deployment systems use tags as triggers for automated builds, testing, and deployment pipelines.

## Task 5 - git switch vs git checkout vs git restore

### Git switch demonstration

```bash
> git switch -c cmd-compare
Switched to a new branch 'cmd-compare'
> git branch
* cmd-compare
  feature/lab1
  feature/lab2
  git-reset-practice
  main
  side-branch
> git status
On branch cmd-compare
...
> git switch -
Switched to branch 'feature/lab2'
```

### Git checkout demonstration

```bash
> git checkout -b cmd-compare-2
Switched to a new branch 'cmd-compare-2'
> git branch
  cmd-compare
* cmd-compare-2
  feature/lab1
  feature/lab2
  git-reset-practice
  main
  side-branch
> git status
On branch cmd-compare-2
...
> git checkout feature/lab2
Switched to branch 'feature/lab2'
```

### Git restore demonstration

```bash
# git restore
> echo "scratch" >> demo.txt
> git add demo.txt
> git commit -m "Task5: Add demo.txt"
> echo "scratch2" >> demo.txt
> cat demo.txt
scratch
scratch2
> git status
On branch feature/lab2
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   demo.txt
> git restore demo.txt
> cat demo.tx
scratch
> git status
On branch feature/lab2
... # without not staged demo.txt
```

```bash
# git restore --staged
> echo "staged changes" >> demo.txt
> git add demo.txt
> git status
On branch feature/lab2
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   demo.txt
> git restore --staged demo.txt
> git status
On branch feature/lab2
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   demo.txt
> cat demo.txt
scratch
staged changes
```

```bash
# git restore --source
> echo "New line" >> demo.txt
> git add demo.txt
> git commit -m "Task5: Update demo.txt"
> git restore --source=HEAD~1 demo.txt
> cat demo.txt
scratch
> git status
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   demo.txt
```

### Differences and when to use

- **git switch** is the modern, purpose-built command for branch operations that eliminates the confusion of `git checkout`'s dual purpose. It provides clearer error messages and safer defaults when working with branches.

- **git checkout** remains functional but is discouraged for new workflows because it serves two completely different purposes (branch switching and file restoration), which can lead to accidental data loss and user confusion.

- **git restore** explicitly handles file restoration operations with clear options (`--staged`, `--source`) that make the intended action obvious, replacing the confusing `git checkout -- <file>` syntax.
