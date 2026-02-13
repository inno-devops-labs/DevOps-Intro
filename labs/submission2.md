# Lab 2 — Version Control & Advanced Git

**Student:** Kamilya Shakirova
**Date:** 12-02-2026

---

## Task 1 — Git Object Model Exploration

- [x] All command outputs for object inspection.
- [x] A 1–2 sentence explanation of what each object type represents.
- [x] Analysis of how Git stores repository data.
- [x] Example of blob, tree, and commit object content.

### 1.1: Sample Commits Created
``` sh
PS D:\Programs\DevOps-Intro> echo "Test content" > test.txt
PS D:\Programs\DevOps-Intro> git add test.txt
PS D:\Programs\DevOps-Intro> git commit -m "Add test file"
[feature/lab2 5ec7cf4] Add test file
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 test.txt
```
### 1.2: Inspection of Git Objects
Finding objects' hashes. \
**Get commit hash**
``` sh
PS D:\Programs\DevOps-Intro> git log --oneline -1
5ec7cf4 (HEAD -> feature/lab2) Add test file
```
**Get tree hash from commit**
``` sh
PS D:\Programs\DevOps-Intro> git cat-file -p HEAD
tree 41d94804accf3a3ecf75e1727453aa732970fcba
parent 54bd17fad12ef27baa683be885a511009e142678
author Kamilya Shakirova <94891282+Kamilya05@users.noreply.github.com> 1770904418 +0300
committer Kamilya Shakirova <94891282+Kamilya05@users.noreply.github.com> 1770904418 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgTq8Y3An3dqp1qK8NzZqtGd2rlP
 NCv//QZIL2P7QI0JoAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQKlGcRLbkEbWXxPV9hennSs5ukgP5H+fYQsy8zNBCq+cFsA4jgZjRXwHbFcnmL7tSJ
 6HNYvLaMMCBwRzJ5zkmgg=
 -----END SSH SIGNATURE-----

Add test file
```

**Get blob hash from tree**
``` sh
PS D:\Programs\DevOps-Intro> git cat-file -p 41d94804accf3a3ecf75e1727453aa732970fcba
040000 tree 4c530fb14ed774958906540e7f66da8babf2f1fd    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree eb79e5a468ab89b024bd4f3ed867c6a3954fe1f0    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 418a98ced2ac70b5bdee0be9732ecdaae7264515    test.txt
```
Object Types:

**Blob:** Binary Large Object representing the compressed contents of a file (data only, no metadata or filename).

**Tree:** Directory listing that maps filenames to the blobs (or subtrees) they contain, along with file permissions.

**Commit:** Snapshot object storing metadata (author, message, timestamp) and pointing to a root tree and parent commit(s).

**Data Storage Analysis:**
Git stores data as a **content-addressable filesystem**: objects are saved in `.git/objects` as compressed files named by the SHA-1 hash of their content. This cryptographic hash serves as the unique key to retrieve the object, making the system immutable—any change to a file generates a completely new object with a new hash. This structure ensures data integrity and enables efficient branching, as identical content is never duplicated.

``` sh
# Blob content
PS D:\Programs\DevOps-Intro> git cat-file -p 418a98ced2ac70b5bdee0be9732ecdaae7264515
��Test content

# Tree content
PS D:\Programs\DevOps-Intro> git cat-file -p eb79e5a468ab89b024bd4f3ed867c6a3954fe1f0
100644 blob aa6b7b5c478b439d2c1e9b4f085257782dd68d25    lab1.md
100644 blob cf1ba99be683932b0a1e1cfd84f0d6f0dc0d184f    lab10.md
100644 blob ca6bbf33cb79a950fbf3c517e6b174ac65f5334b    lab11.md
040000 tree 16bf9eb348f7da4acbec0a94fc4a09e46c40064f    lab11
100644 blob fcd2509fd7a30ea3b5cc9e879f97fbb32d3e660d    lab12.md
040000 tree 129069dd8e40511c9ab6c889b375532b1d68fde3    lab12
100644 blob 3128f48b832e6592d02ae82a18f9b89af82c9658    lab2.md
100644 blob 6e453f5c97f02a4bca77db29549154072771ad4a    lab3.md
100644 blob 3aa4439565d04ff637e909ffc164d59a60749239    lab4.md
100644 blob 0435c3fcbd5d21b21cf253af0544a6536247cdb9    lab5.md
100644 blob af90a7fa02f582cd3d31f4d9f71360878f031e92    lab6.md
100644 blob ee11bdfb0d71048268ec439ad0c4ee2f7bf6fd1b    lab7.md
100644 blob 9df09119213b81f88f6b61c89f3bcf223a32ecf6    lab8.md
100644 blob 12e1b875e40d5ef91f11c36fb259f23069fc458f    lab9.md

# Commit content
PS D:\Programs\DevOps-Intro> git cat-file -p 5ec7cf4                                 
tree 41d94804accf3a3ecf75e1727453aa732970fcba
parent 54bd17fad12ef27baa683be885a511009e142678
author Kamilya Shakirova <94891282+Kamilya05@users.noreply.github.com> 1770904418 +0300
committer Kamilya Shakirova <94891282+Kamilya05@users.noreply.github.com> 1770904418 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgTq8Y3An3dqp1qK8NzZqtGd2rlP
 NCv//QZIL2P7QI0JoAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQKlGcRLbkEbWXxPV9hennSs5ukgP5H+fYQsy8zNBCq+cFsA4jgZjRXwHbFcnmL7tSJ
 6HNYvLaMMCBwRzJ5zkmgg=
 -----END SSH SIGNATURE-----

Add test file
```


---

### Task 2 — Reset and Reflog Recovery 
- [x] The exact commands you ran and why.
- [x] Snippets of `git log --oneline` and `git reflog`.
- [x] What changed in the working tree, index, and history for each reset.
- [x] Analysis of recovery process using reflog.

### 2.1: Create Practice Branch
Created a practice branch with 3 commits:
``` sh
PS D:\Programs\DevOps-Intro> git switch -c git-reset-practice
Switched to a new branch 'git-reset-practice'

PS D:\Programs\DevOps-Intro> echo "First commit" > file.txt    
PS D:\Programs\DevOps-Intro> git add file.txt
PS D:\Programs\DevOps-Intro> git commit -m "First commit"                        
[git-reset-practice 87aa74b] First commit
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 file.txt

PS D:\Programs\DevOps-Intro> echo "Second commit" >> file.txt
PS D:\Programs\DevOps-Intro> git add file.txt
PS D:\Programs\DevOps-Intro> git commit -m "Second commit"   
[git-reset-practice 980daa0] Second commit
 1 file changed, 0 insertions(+), 0 deletions(-)

PS D:\Programs\DevOps-Intro> echo "Third commit" >> file.txt 
PS D:\Programs\DevOps-Intro> git add file.txt               
PS D:\Programs\DevOps-Intro> git commit -m "Third commit"   
[git-reset-practice e3a30e6] Third commit
 1 file changed, 0 insertions(+), 0 deletions(-)
 ```

### 2.2: Explore Reset Modes
Initial state (before reset):
``` sh
PS D:\Programs\DevOps-Intro> git log --oneline
cbac137 (HEAD -> git-reset-practice) Third commit
a6a8268 Second commit
b8fc990 First commit
5ec7cf4 Add test file
54bd17f (origin/main, origin/HEAD, main, feature/lab3) chore: add PR template
...
```

Test 1: git reset --soft HEAD~1
``` sh
PS D:\Programs\DevOps-Intro> git reset --soft HEAD~1 

# log after soft reset
PS D:\Programs\DevOps-Intro> git log --oneline       
a6a8268 (HEAD -> git-reset-practice) Second commit
b8fc990 First commit
5ec7cf4 Add test file
54bd17f (origin/main, origin/HEAD, main, feature/lab3) chore: add PR template
...
```
**What changed:**
1) HEAD moved from cbac137 → a6a8268
2) Index: Changes staged (file.txt modifications are in staging area)
3) Working tree: Unchanged (file still contains all 3 lines)
3) The "Third commit" is unreachable but still exists in reflog

Test 2: git reset --hard HEAD~1
``` sh
PS D:\Programs\DevOps-Intro> git reset --hard HEAD~1 
HEAD is now at b8fc990 First commit

# log after hard reset
PS D:\Programs\DevOps-Intro> git log --oneline  
b8fc990 (HEAD -> git-reset-practice) First commit
5ec7cf4 Add test file
54bd17f (origin/main, origin/HEAD, main, feature/lab3) chore: add PR template  
```

**What changed:**
1) HEAD moved to b8fc990
2) Index: Cleared
3) Working tree: Reverted to "First commit" state (file.txt has only "First commit" line)
4) Both "Second commit" (a6a8268) and "Third commit" (cbac137) are now unreachable


Test 3: git reflog (Recovery)
``` sh
PS D:\Programs\DevOps-Intro> git reflog
b8fc990 (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
a6a8268 HEAD@{1}: reset: moving to HEAD~1
cbac137 HEAD@{2}: checkout: moving from feature/lab2 to git-reset-practice 
1483389 (origin/feature/lab2, feature/lab2) HEAD@{3}: commit: docs: add task1
5ec7cf4 HEAD@{4}: checkout: moving from git-reset-practice to feature/lab2 
cbac137 HEAD@{5}: commit: Third commit
a6a8268 HEAD@{6}: commit: Second commit
b8fc990 (HEAD -> git-reset-practice) HEAD@{7}: commit: First commit
5ec7cf4 HEAD@{8}: checkout: moving from feature/lab2 to git-reset-practice 
5ec7cf4 HEAD@{9}: checkout: moving from git-reset-practice to feature/lab2 
6c27ee7 HEAD@{10}: reset: moving to HEAD~4
54bd17f (origin/main, origin/HEAD, main, feature/lab3) HEAD@{11}: reset: moving to HEAD~1
5ec7cf4 HEAD@{12}: reset: moving to HEAD~1
87aa74b HEAD@{13}: reset: moving to HEAD~1
980daa0 HEAD@{14}: reset: moving to HEAD~1
e3a30e6 HEAD@{15}: commit: Third commit
980daa0 HEAD@{16}: commit: Second commit
87aa74b HEAD@{17}: commit: First commit

# recovery command
PS D:\Programs\DevOps-Intro> git reset --hard cbac137
HEAD is now at cbac137 Third commit

# log after recovery
PS D:\Programs\DevOps-Intro> git log --oneline
cbac137 (HEAD -> git-reset-practice) Third commit
a6a8268 Second commit
b8fc990 First commit
5ec7cf4 Add test file
54bd17f (origin/main, origin/HEAD, main, feature/lab3) chore: add PR template
...
```
**Result:** The lost commits are recovered

### 2.3 Analysis

**Reset modes explained:**

**`--soft`:** Moves HEAD to the target commit, but keeps the index and working tree intact. Useful when you want to restructure commits — you can keep your changes staged and recommit them differently.

**`--hard`:** Moves HEAD, clears the index, and reverts the working tree to match the target commit. Everything is discarded. Use with caution, but remember: nothing is truly lost while it's in reflog.

**`--mixed` (default):** Moves HEAD and clears the index, but keeps working tree changes. Useful for unstaging changes without losing them.

**Reflog rescue:**

Git's reflog keeps a record of HEAD movements for ~90 days. Even after `git reset --hard`, commits aren't deleted immediately—they become orphaned (unreachable from any branch). Reflog lets you recover them by resetting to their hash. This is why reflog is essential: it's your safety net for accidental history rewrites. Always check reflog before panicking!


---

### Task 3 — Visualize Commit History 
- [x] A snippet/screenshot of the graph.
- [x] Commit messages list.
- [x] A 1–2 sentence reflection on how the graph aids understanding.

``` sh
PS D:\Programs\DevOps-Intro> git switch -c side-branch
Switched to a new branch 'side-branch'

PS D:\Programs\DevOps-Intro> echo "Branch commit" >> history.txt
PS D:\Programs\DevOps-Intro> git add history.txt
PS D:\Programs\DevOps-Intro> git commit -m "Side branch commit"
[side-branch 82784b3] Side branch commit
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 history.txt

PS D:\Programs\DevOps-Intro> git switch -
Switched to branch 'git-reset-practice'

PS D:\Programs\DevOps-Intro> git log --oneline --graph --all
* 82784b3 (side-branch) Side branch commit
* cbac137 (HEAD -> git-reset-practice) Third commit
* a6a8268 Second commit
* b8fc990 First commit
| * 1483389 (origin/feature/lab2, feature/lab2) docs: add task1
|/
* 5ec7cf4 Add test file
| * 48f40fd (origin/feature/lab1, feature/lab1) fix: checkboxes in file
| * 5b1a036 fix: checkboxes in file
| * 6b12fd7 docs: lab1 submission
| * 8a906c8 docs: add screenshot
| * bb2d7f6 docs: add commit signing summary
|/
* 54bd17f (origin/main, origin/HEAD, main, feature/lab3) chore: add PR template
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10
* 1826c36 feat: update lab7
```
The `--graph` flag visually represents the branching structure as ASCII art. Each `*` is a commit, `|` represents a branch line, and `/` or `\` show divergence and convergence points. This makes it immediately clear which commits belong to which branches and where they split/merge. Far better than a linear list for understanding the repository's structure and development history.



---

### Task 4 — Tagging Commits (1 pt)
- [x] Tag names and commands used.
- [x] Associated commit hashes.
- [x] A short note on why tags matter (versioning, CI/CD triggers, release notes).

``` sh
PS D:\Programs\DevOps-Intro> git tag v1.0.0
PS D:\Programs\DevOps-Intro> git tag
v1.0.0
PS D:\Programs\DevOps-Intro> git push origin v1.0.0
Total 0 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To https://github.com/Kamilya05/DevOps-Intro.git
 * [new tag]         v1.0.0 -> v1.0.0
PS D:\Programs\DevOps-Intro> git show v1.0.0       
commit 39eb0326793f74fa2fab14929b1bf21a33c6bb41 (HEAD -> feature/lab2, tag:
 v1.0.0, origin/feature/lab2)
Author: Kamilya Shakirova <94891282+Kamilya05@users.noreply.github.com>    
Date:   Fri Feb 13 23:56:06 2026 +0300

    docs: add task2&3

diff --git a/labs/submission2.md b/labs/submission2.md
index 2c772d3..ac2a939 100644
--- a/labs/submission2.md
+++ b/labs/submission2.md
@@ -8,8 +8,8 @@
 ## Task 1 — Git Object Model Exploration

 - [x] All command outputs for object inspection.
-- [] A 1–2 sentence explanation of what each object type represents.      
-- [] Analysis of how Git stores repository data.
+- [x] A 1–2 sentence explanation of what each object type represents.     
+- [x] Analysis of how Git stores repository data.
 - [x] Example of blob, tree, and commit object content.
```

**v1.0.0:** Points to commit `39eb032`

Tags matter because they create **immutable, human-readable snapshots** of the codebase at significant points (e.g., `v1.2.0`). They enable precise **versioning** for dependency management, trigger automated **CI/CD pipelines** for deployment, and provide a stable anchor for generating **release notes** and rollbacks.

---

### Task 5 — git switch vs git checkout vs git restore

- [x] Commands you ran and their outputs.
- [] `git status`/`git branch` outputs showing state changes.
- [x] 2–3 sentences on when to use each command.

**Option A: git switch (Modern - Recommended)**
``` sh
PS D:\Programs\DevOps-Intro> git switch -c cmd-compare
Switched to a new branch 'cmd-compare'
PS D:\Programs\DevOps-Intro> git switch - 
M       labs/submission2.md
Switched to branch 'feature/lab2'
Your branch is up to date with 'origin/feature/lab2'.

PS D:\Programs\DevOps-Intro> git branch
  cmd-compare
  feature/lab1
* feature/lab2
  git-reset-practice
  main
  side-branch
```
**Purpose:** Branch switching only (clear and focused)

**Option B: git checkout (Legacy - Overloaded)**
``` sh
PS D:\Programs\DevOps-Intro> git checkout -b cmd-compare-2 
Switched to a new branch 'cmd-compare-2'

PS D:\Programs\DevOps-Intro> git branch
  cmd-compare
* cmd-compare-2
  feature/lab1
  feature/lab2
  git-reset-practice
  main
  side-branch
```
**Problem:** Does too many things - branches AND files

`git checkout` can also be used for file operations (`git checkout -- <file>`), which makes it confusing. Modern Git separates concerns with `git switch` (branches) and `git restore` (files).

**git restore (Modern - File Operations)**
Discard working tree changes:
``` sh
PS D:\Programs\DevOps-Intro> echo "scratch" >> demo.txt
PS D:\Programs\DevOps-Intro> cat demo.txt
scratch
PS D:\Programs\DevOps-Intro> git status
On branch feature/lab2
Your branch is up to date with 'origin/feature/lab2'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)    
        modified:   labs/submission2.md

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        demo.txt

no changes added to commit (use "git add" and/or "git commit -a")
PS D:\Programs\DevOps-Intro> git restore demo.txt
error: pathspec 'demo.txt' did not match any file(s) known to git
PS D:\Programs\DevOps-Intro> cat demo.txt
scratch
PS D:\Programs\DevOps-Intro> git status
On branch feature/lab2
Your branch is up to date with 'origin/feature/lab2'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)    
        modified:   labs/submission2.md

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        demo.txt

no changes added to commit (use "git add" and/or "git commit -a")
PS D:\Programs\DevOps-Intro> 
```

**Using commands**
**`git switch`:** Use for **branch operations only**. Modern, clear, and focused. Replaces `git checkout <branch>`. Examples: switching branches, creating new branches, toggling between two branches with `git switch -`.

**`git checkout`:** Legacy command that does too many things (branches AND files). Still works, but avoid in new workflows. Only use if you're working with older team standards. The confusion between branch and file operations was why Git split this into `switch` and `restore`.

**`git restore`:** Use for **file operations only**. Modern replacement for `git checkout -- <file>`. Three main uses:
1) Discard working tree changes: `git restore <file>`
2) Unstage without losing changes: `git restore --staged <file>`
3) Restore from a specific commit: `git restore --source=<commit> <file>`

**Best Practice:** Use `git switch` for branches and `git restore` for files. Avoid `git checkout` in new code—it's confusing and outdated.

---

### Task 6 — GitHub Community Engagement

- [x] Starred [course repository](https://github.com/inno-devops-labs/DevOps-Intro), [simple-container-com/api](https://github.com/simple-container-com/api)

- [x] Followed [@Cre-eD](https://github.com/Cre-eD), [@marat-biriushev](https://github.com/marat-biriushev), [@pierrepicaud](https://github.com/pierrepicaud)

- [x] Followed 3 classmates on GitHub: [Danis](https://github.com/DanisSharafiev), [Diana](https://github.com/mnkhmtv), [Arina](https://github.com/arinapetukhova)

**GitHub Community Section**

**Why Starring Repositories Matters:** Starring bookmarks useful projects for future reference and signals appreciation to maintainers, while the star count helps you discover popular, community-trusted tools and showcases your professional interests on your profile.

**Why Following Developers Helps:** Following experienced developers exposes you to new projects and coding patterns for continuous learning, while keeping you updated on classmates' work to build a stronger, more connected team environment.