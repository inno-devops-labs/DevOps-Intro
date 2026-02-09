# Lab 2 Submission

## Task 1 — Git Object Model Exploration (2 pts)

### Commands & Outputs

#### Create sample commit
echo "Test content" > test.txt  
git add test.txt  
git commit -m "Add test file"  
git log --oneline -1  

Output:  
3ab6647 (HEAD -> feature/lab2, origin/feature/lab2) docs: complete lab2 submission

#### Inspect commit object (HEAD)
git cat-file -p HEAD  

Output:  
tree 7066bcf8bd9ce72d49adaf28a32f459fc4c46255  
parent 25b3bb81f56f1991c8bca46e8a194e0c3b52e68e  
author Strelkov_Vladislav <79036529+StrVlad@users.noreply.github.com> 1770621298 +0300  
committer Strelkov_Vladislav <79036529+StrVlad@users.noreply.github.com> 1770621298 +0300  

docs: complete lab2 submission

#### Inspect tree object
git cat-file -p 7066bcf8bd9ce72d49adaf28a32f459fc4c46255  

Output:  
040000 tree 27f499e9865b4c58dedf40cf848d8373dd67a8a4    .github  
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md  
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app  
040000 tree e7a09b7737f29ffde746b1e363af98e55f0027c4    labs  
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures  
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt  

#### Inspect blob object (test.txt)
git cat-file -p 2eec599a1130d2ff231309bb776d1989b97c6ab2  

Output:  
Test content

### What each object type represents
Blob: Stores the raw contents of a file without filename or directory information.  
Tree: Represents a directory by mapping file names to blob or subtree hashes.  
Commit: Stores metadata and a reference to a tree snapshot, linking it into history.

### Analysis
Git stores repository data as content-addressed objects. File contents are saved as blobs, directories as trees, and commits reference trees and parent commits. This design ensures data integrity, automatic deduplication, and efficient version history management.

## Task 2 — Reset and Reflog Recovery (2 pts)

### The exact commands I ran and why
1) Create/switch to practice branch to safely test destructive commands:  
git switch git-reset-practice  

2) Create 3 commits to have a history to rewind:  
echo "First commit" > file.txt  
git add file.txt  
git commit -m "First commit"  

echo "Second commit" >> file.txt  
git add file.txt  
git commit -m "Second commit"  

echo "Third commit" >> file.txt  
git add file.txt  
git commit -m "Third commit"  

3) Inspect history and working tree before reset:  
git log --oneline --decorate -3  
git status  

4) Test reset --soft (remove last commit from history, keep changes staged):  
git reset --soft HEAD~1  
git log --oneline --decorate -3  
git status  

5) Test reset --hard (remove last commit and discard changes):  
git reset --hard HEAD~1  
git log --oneline --decorate -3  
git status  

6) Use reflog to find lost commits and recover:  
git reflog -10  
git reset --hard d8cab3c  

### Snippets of git log --oneline and git reflog

Before reset:
git log --oneline --decorate -3  
d8cab3c (HEAD -> git-reset-practice) Third commit  
bb5c142 Second commit  
90a7b35 First commit  

After reset --soft HEAD~1:
git log --oneline --decorate -3  
bb5c142 (HEAD -> git-reset-practice) Second commit  
90a7b35 First commit  
25b3bb8 docs: add lab2 submission  

git status  
Changes to be committed:  
modified: file.txt  

After reset --hard HEAD~1:
HEAD is now at 90a7b35 First commit  
git log --oneline --decorate -3  
90a7b35 (HEAD -> git-reset-practice) First commit  
25b3bb8 docs: add lab2 submission  
57803e7 Add test file  

git status  
nothing to commit, working tree clean  

Reflog snippet (last 10):
git reflog -10  
90a7b35 (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1  
bb5c142 HEAD@{1}: reset: moving to HEAD~1  
d8cab3c HEAD@{2}: checkout: moving from feature/lab2 to git-reset-practice  
...  

Recovery:
git reset --hard d8cab3c  
HEAD is now at d8cab3c Third commit  

### What changed in working tree, index, and history for each reset
- reset --soft HEAD~1:  
History: HEAD moved back one commit (Third commit removed from branch history).  
Index (staging): changes from the removed commit stayed staged (git status showed “Changes to be committed: modified file.txt”).  
Working tree: matched index (no unstaged changes).  

- reset --hard HEAD~1:  
History: HEAD moved back one more commit (Second commit removed as well).  
Index + working tree: both were reset to match the target commit; changes from removed commits were discarded (git status clean).  

### Analysis of recovery process using reflog
Even after hard resets, Git recorded the previous HEAD positions in reflog. By finding the commit hash d8cab3c in reflog and running git reset --hard d8cab3c, the branch pointer was moved back to the lost commit, restoring the previous state.

## Task 3 — Visualize Commit History (2 pts)

### Commands & Output (graph)
Command:
git log --oneline --graph --all

Output snippet:
*   057f934 (refs/stash) On feature/lab2: wip: submission2
|\
| * dd6da5f index on feature/lab2: 5b134a3 Third commit
|/
* 5b134a3 (feature/lab2) Third commit
* 3172981 Second commit
* 8d90cba First commit
* 3ab6647 (origin/feature/lab2) docs: complete lab2 submission
| * d8cab3c (HEAD -> git-reset-practice) Third commit
| * bb5c142 Second commit
| * 90a7b35 First commit
|/
* 25b3bb8 docs: add lab2 submission
* 57803e7 Add test file

### Commit messages list
- On feature/lab2: wip: submission2
- index on feature/lab2: 5b134a3 Third commit
- Third commit
- Second commit
- First commit
- docs: complete lab2 submission
- docs: add lab2 submission
- Add test file

### Reflection
The graph shows where branches diverge and merge, and how HEAD and branch pointers relate to the same underlying commits. Using --all helps verify that commits are not “lost” (e.g., stash and practice-branch commits are visible in the full history).


## Task 4 — Tagging Commits (1 pt)

### Tag names and commands used
git show -s --oneline 3ab6647
git tag -a v2.0 -m "Lab2 submission" 3ab6647
git show -s --oneline v2.0
git rev-parse v2.0
git push origin v2.0

### Associated commit hashes
Tagged commit:
3ab6647 docs: complete lab2 submission

Annotated tag object hash:
b5310d4fd678a58f27eaf70a21818161b5cbcf1c

### Why tags matter
Tags provide stable human-readable names for specific commits (versions/releases). They are commonly used for versioning, CI/CD release triggers, and for generating release notes tied to an exact snapshot.



## Task 5 — git switch vs git checkout vs git restore (2 pts)

### Commands and outputs

Current branch:
git branch --show-current
git-reset-practice

Create and switch to a new branch (switch):
git switch -c switch-test
Switched to a new branch 'switch-test'
git branch --show-current
switch-test

Switch branches using checkout (legacy):
git checkout git-reset-practice
Switched to branch 'git-reset-practice'
git branch --show-current
git-reset-practice

Modify a file and check status:
echo "temp line" >> file.txt
git status
Changes not staged for commit:
modified: file.txt
modified: labs/submission2.md

Discard working tree changes for a file (restore):
git restore file.txt
git status
Changes not staged for commit:
modified: labs/submission2.md

### git status / git branch outputs showing state changes
- git branch --show-current showed branch changes: git-reset-practice -> switch-test -> git-reset-practice.
- git status showed file.txt as modified after editing, and after git restore file.txt the modification disappeared.

### When to use each
Use git switch to move between branches and create new branches (branch-focused, simpler). Use git checkout mainly for older workflows or when switching both branches and detached commits in one command. Use git restore to discard changes in the working tree or unstage files without switching branches.

## Task 6 — GitHub Community Engagement (1 pt)

### GitHub Community
Starring a repository is a lightweight way to bookmark useful projects and signal appreciation to maintainers. Following users helps you keep track of their activity (new repos, contributions) and discover related work through their updates.


