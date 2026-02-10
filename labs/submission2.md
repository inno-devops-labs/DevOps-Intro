# Lab 2 — Version Control & Advanced Git

## Task 1 — Git Object Model Exploration


```bash
git log --oneline -1
```

```
ca1e6ee (HEAD -> feature/lab2) Add test file
```

**Commit object:**

```bash
git cat-file -p HEAD
```

```
tree d9041f89c1bb682e05a28324c07a7c135338b156
parent 1e57791d270d64407e5a2f3bba5c9ba48431cd00
author nikita <kirnikita7@gmail.com> 1770716796 +0300
committer nikita <kirnikita7@gmail.com> 1770716796 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
...
 -----END SSH SIGNATURE-----

Add test file
```

**Tree object:**

```bash
git cat-file -p d9041f89c1bb682e05a28324c07a7c135338b156
```

```
040000 tree f2891c667a25c77eaa792cda1b440aa554ae24d9    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree 00993759254bd143834216256aee18306418eb00    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    text.txt
```

**Blob object (example - `text.txt`):**

```bash
git cat-file -p 2eec599a1130d2ff231309bb776d1989b97c6ab2
```

```
Test content
```

### Explanation of Object Types

* **Blob:** Stores the raw contents of a file. It does not contain the filename or metadata-only the data itself.
* **Tree:** Represents a directory. It maps filenames to blobs or other trees along with their permissions.
* **Commit:** Represents a snapshot of the repository. It points to a tree and includes metadata such as author, message, parent commit(s), and signatures.

### Analysis of Git’s Data Storage Model

Git stores repository data as immutable objects identified by SHA-1 hashes. Commits reference trees, trees reference blobs (and other trees), and blobs store file contents. This content-addressable design ensures data integrity, efficient storage, and allows Git to reconstruct any version of the project history reliably.
![alt text](image-1.png)


## Task 2 — Reset and Reflog Recovery

### Commit History Before and After Reset

```bash
git log --oneline
```

```
a59a239 (HEAD -> git-reset-practice) Third commit
68aed5e Second commit
fbbd2e0 First commit
ca1e6ee (feature/lab2) Add test file
1e57791 (origin/feature/lab1, feature/lab1) Merge branch 'feature/lab1' of github.com:Nikitjjj/DevOps-Intro into feature/lab1 R
```

### Reset Operations and Reflog

The following reset commands were executed to move backward through history:

```bash
git reset --soft HEAD~1
git reset --hard HEAD~1
```

After running resets, the reflog was inspected:

```bash
git reflog
```

```
fbbd2e0 (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
68aed5e HEAD@{1}: reset: moving to HEAD~1
a59a239 HEAD@{2}: commit: Third commit
68aed5e HEAD@{3}: commit: Second commit
fbbd2e0 (HEAD -> git-reset-practice) HEAD@{4}: commit: First commit
ca1e6ee (feature/lab2) HEAD@{5}: checkout: moving from feature/lab2 to git-reset-practice
```

### Analysis

* `git reset --soft HEAD~1` moved HEAD to the previous commit while keeping changes staged in the index.
* `git reset --hard HEAD~1` moved HEAD again and discarded changes from both the index and working tree.
* Although commits appeared "lost" after the hard reset, `git reflog` preserved a complete history of HEAD movements.

Using reflog entries (e.g., `HEAD@{2}`), it is possible to safely recover any previous commit state even after destructive operations. This makes reflog a critical safety net when rewriting history.


## Task 3 — Visualize Commit History 

```bash
git switch -c side-branch
echo "Branch commit" >> history.txt
git add history.txt && git commit -m "Side branch commit"
git switch -
git log --oneline --graph --all
```
Output:

![alt text](image-2.png)

**Reflection:** The graph makes branching and parallel work visually clear and easier to reason about.

## Task 4 — Tagging Commits

### Commands and Outputs

```bash
git tag v1.0.0
git push origin v1.0.0
```

```bash
Enumerating objects: 4, done.
Counting objects: 100% (4/4), done.
Delta compression using up to 12 threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 507 bytes | 507.00 KiB/s, done.
Total 3 (delta 1), reused 0 (delta 0), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (1/1), completed with 1 local object.
To github.com:Nikitjjj/DevOps-Intro.git
 * [new tag]         v1.0.0 -> v1.0.0
```

Commit hash:
```bash
ca1e6ee (HEAD -> feature/lab2, tag: v1.0.0) Add test file
```

Tags are used to mark important points in history such as releases. They provide stable references for versioning, CI/CD pipelines, and generating release notes.


## Task 5 — git switch vs git checkout vs git restore

### Branch Switching Commands and Outputs

```bash
git switch -c cmd-compare
```

```
Switched to a new branch 'cmd-compare'
```

```bash
git switch -
```

```
Switched to branch 'feature/lab2'
```

```bash
git checkout -b cmd-compare-2
```

```
Switched to a new branch 'cmd-compare-2'
```

### File Restore Commands and State Changes

A new file was created and committed:

```bash
echo "something" > demo.txt
git add demo.txt
git commit -m "Add demo.txt"
```

After modifying the file:

```bash
git status
```

```
On branch cmd-compare-2
Changes not staged for commit:
  modified:   demo.txt
```

Discarding working tree changes:

```bash
git restore demo.txt
```

```bash
git status
```

```
On branch cmd-compare-2
nothing added to commit but untracked files present
```

Unstaging a file while keeping changes:

```bash
echo "new" > demo.txt
git add demo.txt
git restore --staged demo.txt
```

```bash
git status
```

```
Changes not staged for commit:
  modified:   demo.txt
```

Restoring a file from a previous commit:

```bash
git restore --source=HEAD~1 demo.txt
```

```bash
git status
```

```
Changes not staged for commit:
  deleted:    demo.txt
```

### When to Use Each Command

* **git switch:** Use when changing branches or creating new branches. It has a single, clear purpose and avoids accidental file operations.
* **git checkout:** Legacy command that can switch branches and restore files, but its overloaded behavior makes it easier to misuse.
* **git restore:** Use when undoing changes to files, unstaging files, or restoring content from another commit. It cleanly separates file operations from branch management.

## Task 6 — GitHub Community Engagement

Starring repositories helps surface quality projects and supports maintainers. Following developers builds professional networks, improves collaboration, and exposes me to real-world workflows and ideas.