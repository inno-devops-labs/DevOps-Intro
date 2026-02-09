# Lab 2 Submission

## Task 1 - Git Object Model Exploration

### Create Sample Commits

I created a sample commit with a text file.

```bash
C:\...\DevOps-Intro>git log --oneline -1
5f285cf (HEAD -> feature/lab2) Add test file
```

### Examine Git objects

#### Commit

```bash
C:\...\DevOps-Intro>git cat-file -p 5f285cf
tree 1224dd883e1cf96d570a88abad0e56eb9925730f
parent e9ed6a30b9691399a700b8547c449acf48e112da
author Seva Peretiatko <peretyatkosewa06@mail.ru> 1770580107 +0300
committer Seva Peretiatko <peretyatkosewa06@mail.ru> 1770580107 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
...
 -----END SSH SIGNATURE-----

Add test file
```

#### Tree
```bash
C:\...\DevOps-Intro>git cat-file -p 1224dd883e1cf96d570a88abad0e56eb9925730f
040000 tree 3bf77bb9f2fc406e8bd52bd72f5ad1f5ba477e63    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree eb79e5a468ab89b024bd4f3ed867c6a3954fe1f0    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob a4210048363c68b1a9fca2aaec800056ff96018e    test.txt
```

#### Blob
```bash
C:\...\DevOps-Intro>git cat-file -p a4210048363c68b1a9fca2aaec800056ff96018e
"Test content"
```

### Explanation of Git Object types

`Commit` - stores metadata (author, committer, message) and references a tree object that represents the state of the repository at this commit.

`Tree` - directory snapshot, list of blobs and subtrees with their names and hash. Each tree points to specific blob versions, capturing the exact state of files at one moment.

`Blob` - stores the actual contents of files.

### Analysis of how Git stores repository data

Git uses a content-addressable storage model, where each object is identified by a hash of its contents. Commits reference trees, trees reference blobs, and this structure allows Git to efficiently track history, reuse identical objects, and guarantee data integrity. The commit history forms a directed acyclic graph (DAG).


## Task 2 - Reset and Reflog Recovery

### Practice Branch Setup

I created a practice branch with three sequential commits.

```bash
C:\...\DevOps-Intro>git switch -c git-reset-practice
Switched to a new branch 'git-reset-practice'

C:\...\DevOps-Intro>echo "First commit" > file.txt && git add file.txt && git commit -S -m "First commit"
[git-reset-practice e0a39bd] First commit
 1 file changed, 1 insertion(+)
 create mode 100644 file.txt

C:\...\DevOps-Intro>echo "Second commit" >> file.txt && git add file.txt && git commit -S -m "Second commit"
[git-reset-practice 6d87d0b] Second commit
 1 file changed, 1 insertion(+)

C:\...\DevOps-Intro>echo "Third commit"  >> file.txt && git add file.txt && git commit -S -m "Third commit"
[git-reset-practice 30500c9] Third commit
 1 file changed, 1 insertion(+)
```

### Explore Reset Modes

Current commit history:
```bash
C:\...\DevOps-Intro>git log --oneline --graph --decorate -5
* 30500c9 (HEAD -> git-reset-practice) Third commit
* 6d87d0b Second commit
* e0a39bd First commit
* 5f285cf (feature/lab2) Add test file
* e9ed6a3 (origin/main, origin/HEAD, main) docs: add PR template

C:\...\DevOps-Intro>git cat-file -p 30500c9
tree 1e93cafe23ef52d06cf08e54b13aee48e29990be
...
Third commit

C:\...\DevOps-Intro>git cat-file -p 1e93cafe23ef52d06cf08e54b13aee48e29990be
...
100644 blob 31ddca34d816a0dffd46aae9e62d6af0d1b9d857    file.txt
...

C:\...\DevOps-Intro>git cat-file -p 31ddca34d816a0dffd46aae9e62d6af0d1b9d857
"First commit"
"Second commit"
"Third commit"
```

### git reset --soft HEAD~1

```bash
C:\...\DevOps-Intro>git reset --soft HEAD~1

C:\...\DevOps-Intro>git status
On branch git-reset-practice
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   file.txt

C:\...\DevOps-Intro>git log --oneline --graph -3
* 6d87d0b (HEAD -> git-reset-practice) Second commit
* e0a39bd First commit
* 5f285cf (feature/lab2) Add test file
```

#### What changed
1) HEAD moved from 30500c9 to 6d87d0b
2) Index: changes remain staged
3) Working tree: unchanged (file still contains all three lines)
4) The removed commit is no longer reachable from the branch, but still exists in reflog


### git reset --hard HEAD~1

```bash
C:\...\DevOps-Intro>git reset --hard HEAD~1
HEAD is now at e0a39bd First commit

C:\...\DevOps-Intro>git log --oneline --graph -2
* e0a39bd (HEAD -> git-reset-practice) First commit
* 5f285cf (feature/lab2) Add test file
```

#### What changed
1) HEAD moved to e0a39bd
2) Index: cleared
3) Working tree: reverted to the state of the first commit
4) Later commits became unreachable


### git reflog

Commits that became unreachable after reset were successfully recovered using reflog, demonstrating that Git does not immediately delete history.

```bash
C:\...\DevOps-Intro>git reflog
e0a39bd (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
6d87d0b HEAD@{1}: reset: moving to HEAD~1
30500c9 HEAD@{2}: commit: Third commit
6d87d0b HEAD@{3}: commit: Second commit
e0a39bd (HEAD -> git-reset-practice) HEAD@{4}: commit: First commit
5f285cf (feature/lab2) HEAD@{5}: checkout: moving from feature/lab2 to git-reset-practice
5f285cf (feature/lab2) HEAD@{6}: commit: Add test file
...

C:\...\DevOps-Intro>git reset --hard 30500c9
HEAD is now at 30500c9 Third commit

C:\...\DevOps-Intro>git log --oneline --graph -4
* 30500c9 (HEAD -> git-reset-practice) Third commit
* 6d87d0b Second commit
* e0a39bd First commit
* 5f285cf (feature/lab2) Add test file
```

#### What changed
1) Previously lost commits were fully recovered using reflog

### 2.3 Analysis

`--soft` - moves HEAD but keeps both the index and working tree unchanged. It is useful when you want to rewrite or combine commits without losing changes.

`--hard` - moves HEAD and resets both the index and working tree to the target commit. All local changes are discarded.

`git reflog` - records all HEAD movements for a limited time. Even after hard resets, commits are not deleted immediately. Reflog allows recovering unreachable commits and serves as a safety net when rewriting history.


## Task 3 - Visualize Commit History

### Graph Creation

Created a short-lived branch with a commit:

```bash
C:\...\DevOps-Intro>git switch -
Switched to branch 'feature/lab2'

C:\...\DevOps-Intro>git switch -c side-branch
Switched to a new branch 'side-branch'

C:\...\DevOps-Intro>echo "Branch commit" >> history.txt

C:\...\DevOps-Intro>git add history.txt && git commit -S -m "Side branch commit"
[side-branch d3e106b] Side branch commit
 1 file changed, 1 insertion(+)
 create mode 100644 history.txt

C:\...\DevOps-Intro>git switch -
Switched to branch 'feature/lab2'
```

### Graph Output

The output shows multiple branches diverging from and coexisting alongside the main line of development, each identified by branch labels next to commits.

```bash
C:\...\DevOps-Intro>git log --oneline --graph --all
* d3e106b (side-branch) Side branch commit
| * 30500c9 (git-reset-practice) Third commit
| * 6d87d0b Second commit
| * e0a39bd First commit
|/
* 5f285cf (HEAD -> feature/lab2) Add test file
| * b2cb210 (origin/feature/lab1, feature/lab1) docs: complete lab1 task 2
| * 4a5e0b3 docs: add commit signing summary
| * e72c438 docs: add lab1 submission stub
|/
* e9ed6a3 (origin/main, origin/HEAD, main) docs: add PR template
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10
* 1826c36 feat: update lab7
* 3049f08 feat: publish lec8
```

### Reflection

The `--graph option` visualizes the commit history as ASCII art. Each `*` represents a commit, vertical lines indicate ongoing branches, and slashes show where branches diverge or converge. This view makes branch structure and relationships between commits much clearer than a simple linear log.


## Task 4 - Tagging Commits

### Tags Created

This command creates a lightweight tag that points directly to the current commit.

```bash
C:\...\DevOps-Intro>git tag v1.0.0
```

### Tag Information

The tag v1.0.0 was successfully created, verified, and pushed to the remote repository, making it available to other collaborators.

Verified with:
```bash
C:\...\DevOps-Intro>git show v1.0.0
commit 5f285cf372cd56b65d97adca36e437a8bba04585 (HEAD -> feature/lab2, tag: v1.0.0)
Author: Seva Peretiatko <peretyatkosewa06@mail.ru>
Date:   Sun Feb 8 22:48:27 2026 +0300

    Add test file

diff --git a/test.txt b/test.txt
new file mode 100644
index 0000000..a421004
--- /dev/null
+++ b/test.txt
@@ -0,0 +1 @@
+"Test content"

C:\...\DevOps-Intro>git push origin v1.0.0
Total 0 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To github.com:GreatDruk/DevOps-Intro.git
 * [new tag]         v1.0.0 -> v1.0.0
```

### Why Tags Matter

Tags mark specific points in history, typically used for releases and versioning. They are often used in CI/CD pipelines to trigger builds and deployments. Tags make it easy to locate release versions without scanning the entire commit history and improve discoverability on platforms like GitHub. They also support semantic versioning (e.g. v1.0.0, v1.1.0), helping teams clearly associate code states with production releases.


## Task 5 - git switch vs checkout vs restore

### Commands Tested

#### git switch

A new branch `cmd-compare` was created and set as the current branch
```bash
C:\...\DevOps-Intro>git branch
  feature/lab1
* feature/lab2
  git-reset-practice
  main
  side-branch

C:\...\DevOps-Intro>git switch -c cmd-compare
Switched to a new branch 'cmd-compare'

C:\...\DevOps-Intro>git branch
* cmd-compare
  feature/lab1
  feature/lab2
  git-reset-practice
  main
  side-branch
```

Git switched back to the previously checked-out branch (feature/lab2)
```bash
C:\...\DevOps-Intro>git switch -
Switched to branch 'feature/lab2'
Your branch is up to date with 'origin/feature/lab2'.

C:\...\DevOps-Intro>git branch
  cmd-compare
  feature/lab1
* feature/lab2
  git-reset-practice
  main
  side-branch
```


#### git checkout

A new branch was created and checked out using the legacy `git checkout` command
```bash
C:\...\DevOps-Intro>git checkout -b cmd-compare-2
Switched to a new branch 'cmd-compare-2'

C:\...\DevOps-Intro>git branch
  cmd-compare
* cmd-compare-2
  feature/lab1
  feature/lab2
  git-reset-practice
  main
  side-branch

C:\...\DevOps-Intro>git checkout feature/lab2
Switched to branch 'feature/lab2'
Your branch is up to date with 'origin/feature/lab2'.

C:\...\DevOps-Intro>git branch
  cmd-compare
  cmd-compare-2
  feature/lab1
* feature/lab2
  git-reset-practice
  main
  side-branch
```

The current branch was changed back to `feature/lab2` using `git checkout`.


#### git restore

A new branch was created and a tracked file `demo.txt` was added in the initial commit.
```bash
C:\...\DevOps-Intro>git switch -c git-restore-practice
Switched to a new branch 'git-restore-practice'

C:\...\DevOps-Intro>echo "Demo 1" > demo.txt

C:\...\DevOps-Intro>git add demo.txt && git commit -S -m "create demo file"
[git-restore-practice 24102e0] create demo file
 1 file changed, 1 insertion(+)
 create mode 100644 demo.txt
```

Discard working tree changes:
```bash
C:\...\DevOps-Intro>echo "scratch" >> demo.txt

C:\...\DevOps-Intro>type demo.txt
"Demo 1"
"scratch"

C:\...\DevOps-Intro>git restore demo.txt

C:\...\DevOps-Intro>type demo.txt
"Demo 1"
```
Local uncommitted changes in the working tree were discarded.

The file was removed from the staging area while keeping the changes in the working tree:
```bash
C:\...\DevOps-Intro>echo "Demo 2" >> demo.txt && git add demo.txt

C:\...\DevOps-Intro>git status
On branch git-restore-practice
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   demo.txt
...

C:\...\DevOps-Intro>git restore --staged demo.txt

C:\...\DevOps-Intro>git status
On branch git-restore-practice
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   demo.txt
...

no changes added to commit (use "git add" and/or "git commit -a")

C:\...\DevOps-Intro>type demo.txt
"Demo 1"
"Demo 2"
```

Restore from another commit:
```bash
C:\...\DevOps-Intro>git add demo.txt && git commit -S -m "add demo 2"
[git-restore-practice 32374ae] add demo 2
 1 file changed, 1 insertion(+)

C:\...\DevOps-Intro>git restore --source=HEAD~1 demo.txt

C:\...\DevOps-Intro>type demo.txt
"Demo 1"

C:\...\DevOps-Intro>git status
On branch git-restore-practice
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   demo.txt
...

no changes added to commit (use "git add" and/or "git commit -a")

C:\...\DevOps-Intro>git log --oneline -3
32374ae (HEAD -> git-restore-practice) add demo 2
24102e0 create demo file
5f285cf (tag: v1.0.0, origin/feature/lab2, feature/lab2, cmd-compare-2, cmd-compare) Add test file

C:\...\DevOps-Intro>git restore --source=32374ae demo.txt

C:\...\DevOps-Intro>type demo.txt
"Demo 1"
"Demo 2"

C:\...\DevOps-Intro>git status
On branch git-restore-practice
...

nothing added to commit but untracked files present (use "git add" to track)
```
The file content was restored to its state from the previous commit. Later the file was restored to the version from the specified commit.

### When to Use Each Command

`git switch` - only for branch operations. A modern and clear replacement for `git checkout <branch>`, including branch creation and switching.

`git checkout` - legacy command that combines branch and file operations. Still supported, but generally avoided in new workflows due to its overloaded behavior.

`git restore` - only for file operations. A modern replacement for `git checkout -- <file>`. Use cases:
1) Discard working tree changes: `git restore <file>`
2) Unstage changes without losing them: `git restore --staged <file>`
3) Restore a file from a specific commit: `git restore --source=<commit> <file>`


## Task 6 - GitHub Community Engagement

### Actions

Star the course repository - done

Star the [simple-container-com/api](https://github.com/simple-container-com/api) - done

Follow [@Cre-eD](https://github.com/Cre-eD) - done

Follow [@marat-biriushev](https://github.com/marat-biriushev) - done

Follow [@pierrepicaud](https://github.com/pierrepicaud) - done

Follow classmates: [Oleg](https://github.com/zv3zdochka), [Aleksei](https://github.com/pixel4lex), [Platon](https://github.com/revlze) - done

### Why starring matters in open source

Stars act as bookmarks for useful projects and show appreciation to maintainers. A large number of stars often signals that a project is actively used and trusted by the community. Starring also helps highlight quality repositories on profile.

### How following developers helps in team projects and professional growth

Following developers lets you track their activity, projects, and areas of interest. This improves collaboration in team environments and helps you learn from others’ work. Over time, it also expands your professional network and exposure to new tools and practices.