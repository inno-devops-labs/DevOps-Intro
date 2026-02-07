# Lab 2 Submission
## Task 1: Git Object Model Exploration
### Command outputs for object inspection:
#### 1. Commit Object
```
arinapetuhova@192 DevOps-Intro % git log --oneline -1
74c38e3 (HEAD -> feature/lab2) Add test file

arinapetuhova@192 DevOps-Intro % git cat-file -p 74c38e3
tree b660713fc594e96a202a3eb9a00bfdceee997270
parent fcfd20b880bf4ce1ea665b92c0f087db645d79c4
author Arina Petuhova <119685834+arinapetukhova@users.noreply.github.com> 1770370868 +0300
committer Arina Petuhova <119685834+arinapetukhova@users.noreply.github.com> 1770370868 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgUDPLkiD0daseOoV9XP0Y0kgQg1
 G2jn3Herr0uZ2bnroAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQEE3uLqt0EDdiEL5Pz0DKJhHTAF9m3fNsvV1cNAq9d2OdA8ckqtH+KPp7kUrBnBfUV
 lG3dPPezDBMLQ3hTj1lQs=
 -----END SSH SIGNATURE-----

Add test file
```

#### 2. Tree Object
```
arinapetuhova@192 DevOps-Intro % git cat-file -p b660713fc594e96a202a3eb9a00bfdceee997270
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree f0fbfea6739bbc15d0f4a5408cdb109a9c6cbb4f    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt
```

#### 3. Blob Object
```
arinapetuhova@192 DevOps-Intro % git cat-file -p 2eec599a1130d2ff231309bb776d1989b97c6ab2
Test content
```

### Object Type Explanations

- **Blob**: Represents file content - a snapshot of a file at a specific point in time.
- **Tree**: Represents directory structure - a listing of files (blobs) and subdirectories (trees) with their permissions and names.
- **Commit**: Represents a snapshot of the repository - metadata including author, timestamp, parent commits, and a pointer to the root tree.

### Git Storage Analysis
Git stores repository data as a directed acyclic graph of objects where commits point to trees, trees point to blobs and other trees, and blobs contain actual file content. Each object is content-addressed using hashes, making Git a content-addressable filesystem where identical content is stored only once.

### Example Object Content

**Blob Example**: `2eec599a1130d2ff231309bb776d1989b97c6ab2` contains the exact file content "Test content".

**Tree Example**: `b660713fc594e96a202a3eb9a00bfdceee997270` shows the repository structure with 2 blobs (README.md and test.txt) and 3 trees (app, labs, lectures).

**Commit Example**: `74c38e3` contains metadata including parent commit `fcfd20b`, author information, timestamp, GPG signature, and commit message "Add test file".

## Task 2: Reset and Reflog Recovery
### Testing git reset --soft HEAD~1:
``` 
arinapetuhova@MacBook-Air-Arina DevOps-Intro % git log --oneline
6eec726 (HEAD -> git-reset-practice) Third commit
a7dbccb Second commit
c7cf749 First commit

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git reflog
6eec726 (HEAD -> git-reset-practice) HEAD@{0}: commit: Third commit
a7dbccb HEAD@{1}: commit: Second commit
c7cf749 HEAD@{2}: commit: First commit

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git reset --soft HEAD~1

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git log --oneline
a7dbccb (HEAD -> git-reset-practice) Second commit
c7cf749 First commit

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git reflog
a7dbccb (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
6eec726 HEAD@{1}: commit: Third commit
a7dbccb (HEAD -> git-reset-practice) HEAD@{2}: commit: Second commit
c7cf749 HEAD@{3}: commit: First commit

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git status
On branch git-reset-practice
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   file.txt
```

**Explanation:** here, I ran commands `git log --oneline` and `git reflog` to see the last commits and HEAD position. After running `git reset --soft HEAD~1` to reset the last commit while keeping index & working tree, I verified with `git log --oneline` (shows only 2 commits), `git reflog` (shows reset action), and `git status` (shows changes are staged). 

### Testing git reset --hard HEAD@{1}:
```
arinapetuhova@MacBook-Air-Arina DevOps-Intro % git reset --hard HEAD@{1}
HEAD is now at 6eec726 Third commit

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git log --oneline
6eec726 (HEAD -> git-reset-practice) Third commit
a7dbccb Second commit
c7cf749 First commit

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git reflog
6eec726 (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD@{1}
a7dbccb HEAD@{1}: reset: moving to HEAD~1
6eec726 (HEAD -> git-reset-practice) HEAD@{2}: commit: Third commit
a7dbccb HEAD@{3}: commit: Second commit
c7cf749 HEAD@{4}: commit: First commit
```
**Explanation:** here, I ran command `git reset --hard HEAD@{1}` recovered the repository to the state it was in before the previous `git reset --soft HEAD~1`.
I verified it with `git log --oneline` (shows all 3 commits) and `git reflog` (shows reset to previous HEAD@{1} action). 

### Testing git reset --hard HEAD~1:
```
arinapetuhova@MacBook-Air-Arina DevOps-Intro % git reset --hard HEAD~1 
HEAD is now at a7dbccb Second commit

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git log --oneline
a7dbccb (HEAD -> git-reset-practice) Second commit
c7cf749 First commit

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git reflog
a7dbccb (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
6eec726 HEAD@{1}: reset: moving to HEAD@{1}
a7dbccb (HEAD -> git-reset-practice) HEAD@{2}: reset: moving to HEAD~1
6eec726 HEAD@{3}: commit: Third commit
a7dbccb (HEAD -> git-reset-practice) HEAD@{4}: commit: Second commit
c7cf749 HEAD@{5}: commit: First commit

arinapetuhova@MacBook-Air-Arina DevOps-Intro %  git status
On branch git-reset-practice
nothing to commit, working tree clean

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git reset --hard HEAD@{1} 
HEAD is now at 6eec726 Third commit

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git log --oneline
6eec726 (HEAD -> git-reset-practice) Third commit
a7dbccb Second commit
c7cf749 First commit

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git reflog  
6eec726 (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD@{1}
a7dbccb HEAD@{1}: reset: moving to HEAD~1
6eec726 (HEAD -> git-reset-practice) HEAD@{2}: reset: moving to HEAD@{1}
a7dbccb HEAD@{3}: reset: moving to HEAD~1
6eec726 (HEAD -> git-reset-practice) HEAD@{4}: commit: Third commit
a7dbccb HEAD@{5}: commit: Second commit
c7cf749 HEAD@{6}: commit: First commit
```

**Explanation:** here, I ran command `git reset --hard HEAD~1` to reset the last commit without keeping index & working tree. I verified it with `git log --oneline` (shows only 2 commits), `git reflog` (shows reset action), and `git status` (shows that no changes are staged). Then everything is again recovered with `git reset --hard HEAD@{1}` nad checked with `git log --oneline` and `git reflog`.

### Reset Changes:
- `git reset --soft HEAD~1` moves HEAD back one commit while keeping both the index and working tree unchanged. The commit disappears from history, but all its changes remain staged.
- `git reset --hard HEAD~1` also moves HEAD back but discards everything, both the index and working tree revert to the previous commit's state, making changes permanently lost from the current branch.

### Recovery via Reflog:
The `reflog` records every HEAD movement. Even after a destructive `--hard` reset, the "lost" commit remains in reflog with a reference like HEAD@{1}. By using `git reset --hard HEAD@{1}`, it's possible to completely restore the repository to that earlier state, recovering both the commit history and all associated file changes.

## Task 3: Visualize Commit History
### Graph Output
```
arinapetuhova@MacBook-Air-Arina DevOps-Intro % git log --oneline --graph --all
* 44a6364 (side-branch) Side branch commit
* 736f6df (HEAD -> feature/lab2, origin/feature/lab2) task 2
* bcf2426 task 1
* 5a2f7d3 lab 2, task 1
* 74c38e3 Add test file
* fcfd20b (origin/feature/lab1, feature/lab1) feat: task 2 added
* 6b3604a feat: SSH screenshots added
* 3c838d9 remove .DS_Store file
* e7d91e0 remove screenshots folder
* d6b77e7 feat: SSH screenshots added
* 63466e5 feat: SSH screenshots added
* 71b5840 feat: SSH screenshots added
* 3cb6e7e verified commit
* b9a96c1 verified commit
* 0f2867f verified commit
```

**Commit messages list:**
- verified commit, 
- feat: SSH screenshots added, 
- remove screenshots folder, 
- remove .DS_Store file, 
- feat: task 2 added, 
- Add test file, 
- lab 2, task 1, 
- task 1, 
- task 2,
- Side branch commit

**Reflection:** the graph visualization provides insight into branch relationships and development flow. It clearly shows where branches diverge (at commit 736f6df for side-branch) and reveals that feature/lab1 stopped development while feature/lab2 continued, helping understand the project's evolution at a glance.

## Task 4: Tagging Commits
### Tag names and commands used:
**For the first tag:**
```
arinapetuhova@MacBook-Air-Arina DevOps-Intro % git tag v1.0.0
arinapetuhova@MacBook-Air-Arina DevOps-Intro % git push origin v1.0.0 
Enumerating objects: 7, done.
Counting objects: 100% (7/7), done.
Delta compression using up to 8 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 1.13 KiB | 1.13 MiB/s, done.
Total 4 (delta 3), reused 0 (delta 0), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (3/3), completed with 3 local objects.
To https://github.com/arinapetukhova/DevOps-Intro.git
 * [new tag]         v1.0.0 -> v1.0.0
```

**For the second tag:**
```
arinapetuhova@MacBook-Air-Arina DevOps-Intro % git tag v1.1.0
arinapetuhova@MacBook-Air-Arina DevOps-Intro % git push origin v1.1.0
Enumerating objects: 7, done.
Counting objects: 100% (7/7), done.
Delta compression using up to 8 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 619 bytes | 619.00 KiB/s, done.
Total 4 (delta 3), reused 0 (delta 0), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (3/3), completed with 3 local objects.
To https://github.com/arinapetukhova/DevOps-Intro.git
 * [new tag]         v1.1.0 -> v1.1.0
```

### Associated commit hashes:
```
arinapetuhova@MacBook-Air-Arina DevOps-Intro % git show v1.0.0 --quiet
commit dca8922603375fbf462fbd9cbc91ca01d529ae71 (tag: v1.0.0)
Author: Arina Petuhova <119685834+arinapetukhova@users.noreply.github.com>
Date:   Sat Feb 7 15:00:16 2026 +0300

    task 3 & 4
arinapetuhova@MacBook-Air-Arina DevOps-Intro % git show v1.1.0 --quiet
commit aedb4327ac1872dfb768603aaae29483bbc5994e (HEAD -> feature/lab2, tag: v1.1.0)
Author: Arina Petuhova <119685834+arinapetukhova@users.noreply.github.com>
Date:   Sat Feb 7 15:07:34 2026 +0300

    new tag
```

### Why tags matter:
1. Versioning: Tags provide immutable reference points for specific releases, enabling precise version tracking and rollback capabilities.

2. CI/CD Triggers: Automated pipelines can be configured to deploy or test only when specific tags are pushed (e.g., v1.* triggers production deployment).

3. Release Management: Tags create GitHub releases with downloadable source code, changelogs, and binary assets, facilitating organized software distribution.

## Task 5: git switch vs git checkout vs git restore
### Commands & Outputs:
```
arinapetuhova@MacBook-Air-Arina DevOps-Intro % git switch -c test-command-comparison
Switched to a new branch 'test-command-comparison'

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git branch
  feature/lab1
  feature/lab2
  main
* test-command-comparison

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git switch -c cmd-compare
Switched to a new branch 'cmd-compare'

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git switch -
Switched to branch 'test-command-comparison'

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git checkout -b cmd-compare-2
Switched to a new branch 'cmd-compare-2'

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git checkout test-command-comparison
Switched to branch 'test-command-comparison'

arinapetuhova@MacBook-Air-Arina DevOps-Intro % echo "original content" > demo.txt

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git add demo.txt

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git commit -m "Add demo.txt"
[test-command-comparison c4505a0] Add demo.txt
 1 file changed, 1 insertion(+)
 create mode 100644 demo.txt
arinapetuhova@MacBook-Air-Arina DevOps-Intro % git status
On branch test-command-comparison
nothing to commit, working tree clean

arinapetuhova@MacBook-Air-Arina DevOps-Intro % echo "scratch changes" >> demo.txt

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git status
On branch test-command-comparison
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   demo.txt

no changes added to commit (use "git add" and/or "git commit -a")

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git restore demo.txt

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git status
On branch test-command-comparison
nothing to commit, working tree clean

arinapetuhova@MacBook-Air-Arina DevOps-Intro % echo "new content" > demo.txt

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git add demo.txt

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git status
On branch test-command-comparison
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   demo.txt

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git restore --staged demo.txt

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git status
On branch test-command-comparison
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   demo.txt

no changes added to commit (use "git add" and/or "git commit -a")

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git restore --source=HEAD~1 demo.txt

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git status
On branch test-command-comparison
Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        deleted:    demo.txt

no changes added to commit (use "git add" and/or "git commit -a")

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git checkout -- demo.txt

arinapetuhova@MacBook-Air-Arina DevOps-Intro % git status
On branch test-command-comparison
nothing to commit, working tree clean
```

**Conclusion:** 
- Use `git restore` when discarding uncommitted changes in the working directory (unstaged changes) or unstaging files (staged changes)
- Use `git checkout` when wanting to switch branches, create new branches, or restore files to their committed state (older syntax)
- Use `git switch` specifically for switching between branches in a cleaner, more intuitive way, as it's designed only for branch operations unlike checkout which has multiple functions.

## Task 6: GitHub Community Engagement
### Challenges & Solutions:
The main challenges I faced were related to understanding the Git Object Model and commands I hadn't used before (reset, reflog, restore). After reading the theory, I understood how they work.

### GitHub Community:
Starring repositories matters in open source because it shows appreciation to maintainers, helps projects gain visibility in rankings, and serves as a bookmark to revisit useful code later.

Following developers helps in team projects by keeping you updated on their contributions, and supports professional growth by exposing you to their techniques, projects, and community insights.