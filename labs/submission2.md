# Lab 2 — Version Control & Advanced Git

## Task 1 — Git Object Model Exploration

### What each object represents

* Blob: stores the content of a file (bytes). It does not store filename or path.
* Tree: stores a directory snapshot: filenames + file modes + pointers to blobs (files) and other trees (subdirectories).
* Commit: stores metadata (author, message, timestamp) and points to a single root tree (snapshot) plus parent commit(s).

### Analysis: how Git stores repository data

Git is a content-addressable object store: each object (blob/tree/commit) is identified by its hash.
A commit represents a full snapshot via a root tree; trees reference blobs/trees, so the repository history is a chain of snapshots linked by parent pointers.

### Commands and outputs

**Create a sample commit**
```bash
echo "Test content" > test.txt
git add test.txt
git commit -m "Add test file"
git log --oneline -1
```

```text
31c58a9 (HEAD -> feature/lab2) Add test file
```

**Inspect tree entries referenced by HEAD**

```bash
git ls-tree HEAD
```

```text
100644 blob a38dbc03f5f790c14c955f7cc235f89bef651095    .gitignore
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree 47f8b14e105dc6c7b484342b01f7d9e03c452bb4    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 418a98ced2ac70b5bdee0be9732ecdaae7264515    test.txt
```

**Inspect blob content (test.txt)**

```bash
git cat-file -p 418a98ced2ac70b5bdee0be9732ecdaae7264515
```

```text
Test content
```

**Inspect commit object (HEAD)**

```bash
git cat-file -p HEAD
```

```text
tree bc3fdac9ed1c923ddb4d97cc1cbc9eb2f76da041
parent 31c58a917df7998afb6953b5a13b4e7705612974
author Batsiev Oleg <122930346+zv3zdochka@users.noreply.github.com> 1770464616 +0300
committer Batsiev Oleg <122930346+zv3zdochka@users.noreply.github.com> 1770464616 +0300
(gpgsig omitted)
rename 1 lab screenshots
```

**Inspect tree object content**

```bash
git cat-file -p bc3fdac9ed1c923ddb4d97cc1cbc9eb2f76da041
```

```text
100644 blob a38dbc03f5f790c14c955f7cc235f89bef651095    .gitignore
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree 31b249783e5b1d21eb16fea27bbb1c4a975dea70    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 418a98ced2ac70b5bdee0be9732ecdaae7264515    test.txt
```

### Screenshots
![Task 1 — cat-file](./screenshots/lab_2_1.png)
![Task 1 — ls-tree ](./screenshots/lab_2_2.png)
![Task 1 — (cat-file -p HEAD)](./screenshots/lab_2_3.png)

## Task 2 — Reset and Reflog Recovery

### 2.1 Practice branch and commits

```bash
git switch -c git-reset-practice
echo "First commit" > file.txt
git add file.txt
git commit -m "First commit"
echo "Second commit" >> file.txt
git add file.txt
git commit -m "Second commit"
echo "Third commit" >> file.txt
git add file.txt
git commit -m "Third commit"
```

**State after creating commits**

```bash
git log --oneline -3
```

```text
4930492 (HEAD -> git-reset-practice) Third commit
18c9b06 Second commit
7cb6166 First commit
```

---

### 2.2 Reset modes

#### A) `git reset --soft HEAD~1`

**Commands**

```bash
git reset --soft HEAD~1
git log --oneline -3
git status
git diff --cached
```

**Outputs**

```text
18c9b06 (HEAD -> git-reset-practice) Second commit
7cb6166 First commit
```

```text
Changes to be committed:
  modified: file.txt
```

**Explanation**

* **History:** HEAD moved back by one commit.
* **Index:** changes from the removed commit remained staged.
* **Working tree:** unchanged.

---

#### B) `git reset --hard HEAD~1`

Before applying hard reset, the removed commit was recreated:

```bash
git commit -m "Recommit third (after soft reset)"
```

Then:

```bash
git reset --hard HEAD~1
git log --oneline -3
git status
```

```text
18c9b06 (HEAD -> git-reset-practice) Second commit
7cb6166 First commit
```

**Explanation**

* **History:** last commit was removed.
* **Index:** cleared.
* **Working tree:** reset to match HEAD.

---

#### C) Recovery using `git reflog`

```bash
git reflog -10
```

```text
4930492 HEAD@{3}: commit: Third commit
1988c9c HEAD@{1}: commit: Recommit third (after soft reset)
18c9b06 HEAD@{0}: reset: moving to HEAD~1
```

**Recovery**

```bash
git reset --hard 4930492
```

**Analysis**
Reflog stores previous positions of HEAD even after destructive operations like `reset --hard`.
By selecting the appropriate reflog entry, the lost commit history can be fully restored.



### Screenshots
![Task 2 — commits](./screenshots/lab_2_4.png)
![Task 1 — git reflog](./screenshots/lab_2_5.png)


## Task 3 — Visualize Commit History


### Commands

```bash
git switch feature/lab2
git switch -c side-branch
echo "Branch commit" >> history.txt
git add history.txt
git commit -m "Side branch commit"
git switch -
git log --oneline --graph --all --decorate
```

### Graph snippet

```text
(.venv) PS D:\PyCharmProjects\DevOps_Inno> git log --oneline --graph --all --decorate
* 3d98f3e (side-branch) Side branch commit
* 5f97d04 (HEAD -> feature/lab2, origin/feature/lab2) finish 2 task
| * 4930492 (git-reset-practice) Third commit
| * 18c9b06 Second commit
| * 7cb6166 First commit
|/  
* 5c85ae7 finish 1 task
* a0a4e17 finish 1 task
* fff44e8 rename 1 lab screenshots
* 31c58a9 Add test file
* 95510e1 prepare lab 2
* 657b71a (origin/feature/lab1, feature/lab1) finish 2 task with screenshot
* a08b92f docs: add task 2 report
* 10e8ae5 complete task 1
* d9ea462 docs: add commit signing summary
| * 49c941b (origin/main, main) chore: add PR template
|/  
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10
* 1826c36 feat: update lab7
* 3049f08 feat: publish lec8
* da8f635 feat: introduce all labs and revised structure
* 04b174e feat: publish lab and lec #5
* 67f12f1 feat: publish labs 4&5, revise others
* 82d1989 feat: publish lab3 and lec3
* 3f80c83 feat: publish lec2
* 499f2ba feat: publish lab2
* af0da89 feat: update lab1
* 74a8c27 Publish lab1
* f0485c0 Publish lec1
* 31dd11b Publish README.md
```

### Reflection

The `--graph --all` view makes branch divergence and branch pointers visible at a glance, so it’s easier to understand which commits belong to which branch and how HEAD moved during branching/merging.

### Screenshot

![Task 3 — git log graph](./screenshots/lab_2_6.png)









## Task 4 — Tagging Commits

## Task 5 — git switch vs git checkout vs git restore

## Task 6 — GitHub Community Engagement

## Challenges & Solutions
