# Lab 2 — Version Control & Advanced Git

#### 1.2: Inspect Git Objects

Inputs:
```sh
# Get commit hash
git log --oneline -1

# Get tree hash from commit
git cat-file -p HEAD

# Get blob hash from tree
git cat-file -p <tree_hash>
```

Outputs:
```sh
8e7f548 (HEAD -> feature/lab1) Add test file

tree 3eb295db7c76e5d94965fc2c889eefcb22782f09
parent a2ca2a04740036c188b72cf0901ef9dffcf0b0e6
author Lexi <sashulya-starikova2005@mail.ru> 1770620914 +0300
committer Lexi <sashulya-starikova2005@mail.ru> 1770620914 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgjQDnQWcKY1asptwvw+57ITa+a0
 zYQpTrg5haW1kF2XoAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQJ0+WuDSV9lSmHkxWxNwuvtqfdYe6pIbxg63UCSZNSex022ivFYbYhHuw/1DV9S6X0
 J0YDzUUPV6C8NFm2k2Yw4=
 -----END SSH SIGNATURE-----

Add test file

040000 tree 5a690f1a64a1193cbf9bdc55c9290c4594e9dfc0    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree 29ab69203352e52c06802f8f4191e4627b3f6f0e    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt
```

A **tree** object in Git represents a directory and contains references to the blobs (files) and other trees (subdirectories) within it, along with their names and modes.
A **blob** object holds the actual data contents of a file, but does not store any filename or directory information—only the raw file data.
**Commit**: Contains a reference to the root tree, metadata (author, message, parent commit), and marks a snapshot in the project history

#### 2.1: Create Practice Branch

1. **Set Up Practice Environment:**

   ```sh
   git switch -c git-reset-practice
   echo "First commit" > file.txt && git add file.txt && git commit -m "First commit"
   echo "Second commit" >> file.txt && git add file.txt && git commit -m "Second commit"
   echo "Third commit"  >> file.txt && git add file.txt && git commit -m "Third commit"
   ```

#### 2.2: Explore Reset Modes

1. **Test Different Reset Options:**

   ```sh
   git reset --soft HEAD~1   # move HEAD; keep index & working tree
   git reset --hard HEAD~1   # move HEAD; discard index & working tree
   git reflog                # view HEAD movement
   git reset --hard <reflog_hash>  # recover a previous state
   ```

Commands that I ran:
```sh
# the changes from “Third commit” stay staged; only the commit is removed
(base) lexi@LEXI:~/DevOps-Intro$ git reset --soft HEAD~1

# all changes from “Second commit” (and anything staged) are discarded
(base) lexi@LEXI:~/DevOps-Intro$ git reset --hard HEAD~1
HEAD is now at f03f400 First commit

# shows the reflog for the current branch,
# a log of where HEAD has been (checkouts, commits, resets)
(base) lexi@LEXI:~/DevOps-Intro$ git reflog
f03f400 (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
2374148 HEAD@{1}: reset: moving to HEAD~1
5ac47d1 HEAD@{2}: commit: Third commit
2374148 HEAD@{3}: commit: Second commit
f03f400 (HEAD -> git-reset-practice) HEAD@{4}: commit: First commit
8e7f548 (feature/lab1) HEAD@{5}: checkout: moving from feature/lab1 to git-reset-practice
8e7f548 (feature/lab1) HEAD@{6}: commit: Add test file

# moves the current branch to the commit 5ac47d1 (“Third commit”)
(base) lexi@LEXI:~/DevOps-Intro$ git reset --hard 5ac47d1
HEAD is now at 5ac47d1 Third commit
```

### Task 3 — Visualize Commit History (2 pts)

**Objective:** Use Git's log graph to see branching and merges.

1. **Create a short-lived branch, commit, then view the graph:**

   ```sh
   git switch -c side-branch
   echo "Branch commit" >> history.txt
   git add history.txt && git commit -m "Side branch commit"
   git switch -
   git log --oneline --graph --all
   ```

Outputs:
```sh
* ccca2bd (side-branch) Side branch commit
* 5ac47d1 (HEAD -> git-reset-practice) Third commit
* 2374148 Second commit
* f03f400 First commit
* 8e7f548 (feature/lab1) Add test file
```


### Task 4 — Tagging Commits (1 pt)

**Objective:** Create and push lightweight tags to mark releases.

1. **Tag the latest commit and push:**

   ```sh
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. Optionally make one more commit and tag `v1.1.0`.

Commands and Outputs:
```sh
git tag v1.0.0
(base) lexi@LEXI:~/DevOps-Intro$ git push origin v1.0.0
Enumerating objects: 13, done.
Counting objects: 100% (13/13), done.
Delta compression using up to 4 threads
Compressing objects: 100% (8/8), done.
Writing objects: 100% (12/12), 1.38 KiB | 176.00 KiB/s, done.
Total 12 (delta 7), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (7/7), completed with 1 local object.
To https://github.com/LexiStarikova/DevOps-Intro
 * [new tag]         v1.0.0 -> v1.0.0
(base) lexi@LEXI:~/DevOps-Intro$ echo "v1.1.0" >> file.txt
(base) lexi@LEXI:~/DevOps-Intro$ git add file.txt
(base) lexi@LEXI:~/DevOps-Intro$ git commit -m "Bump to v1.1.0"
[git-reset-practice 16f225a] Bump to v1.1.0
 1 file changed, 1 insertion(+)
(base) lexi@LEXI:~/DevOps-Intro$ git tag v1.1.0
(base) lexi@LEXI:~/DevOps-Intro$ git push origin v1.1.0
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 4 threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 530 bytes | 265.00 KiB/s, done.
Total 3 (delta 1), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (1/1), completed with 1 local object.
To https://github.com/LexiStarikova/DevOps-Intro
 * [new tag]         v1.1.0 -> v1.1.0

(base) lexi@LEXI:~/DevOps-Intro$ git rev-parse --short v1.1.0
16f225a
(base) lexi@LEXI:~/DevOps-Intro$ git rev-parse --short v1.0.0
5ac47d1
(base) lexi@LEXI:~/DevOps-Intro$ git show-ref --tags
5ac47d1f6bf79299ed30913e59b979099df69d4e refs/tags/v1.0.0
16f225a8e0dc6e0eada89099090e9ab409b323ad refs/tags/v1.1.0
```

1. Versioning:
Tags (e.g. v1.0.0, v1.1.0) are stable names for a specific commit. “v1.1.0” always means that exact snapshot. That’s what we use for “version X” in docs, support, and dependency specs.
2. CI/CD triggers:
Pipelines can run when a tag is pushed, e.g. “on tag v* run tests and deploy to production” or “on tag v* build and publish a release artifact.”



### Task 5 — git switch vs git checkout vs git restore (2 pts)

**Objective:** Learn modern Git commands and when to use each.

<details>
<summary>🔄 Option A: git switch (Modern - Recommended)</summary>

```sh
git switch -c cmd-compare   # create and switch
git switch -                # toggle back to previous branch
```

**Purpose:** Branch switching only (clear and focused)

</details>

<details>
<summary>🔄 Option B: git checkout (Legacy - Overloaded)</summary>

```sh
git checkout -b cmd-compare-2   # also creates + switches branches
# Note: `git checkout -- <file>` used to restore files (confusing!).
```

**Problem:** Does too many things - branches AND files

</details>

<details>
<summary>📂 git restore (Modern - File Operations)</summary>

```sh
echo "scratch" >> demo.txt
git restore demo.txt                 # discard working tree changes
git restore --staged demo.txt        # unstage (keep working tree)
git restore --source=HEAD~1 demo.txt # restore from another commit
```

**Purpose:** File restoration only (clear and focused)

</details>

Commands and Outputs:
```sh
(base) lexi@LEXI:~/DevOps-Intro$ git switch -c cmd-compare
Switched to a new branch 'cmd-compare'
(base) lexi@LEXI:~/DevOps-Intro$ git switch -
Switched to branch 'git-reset-practice'
(base) lexi@LEXI:~/DevOps-Intro$ echo "scratch" >> demo.txt
(base) lexi@LEXI:~/DevOps-Intro$ git add demo.txt
(base) lexi@LEXI:~/DevOps-Intro$ git commit -m "Add demo.txt"
[git-reset-practice 8b5f778] Add demo.txt
 1 file changed, 1 insertion(+)
 create mode 100644 demo.txt
# removing demo.txt from the working tree
(base) lexi@LEXI:~/DevOps-Intro$ git restore --source=HEAD~1 demo.txt
```

When to use:
- `git restore <file>` when you edited a tracked file and want to throw away your edits and match the last committed (or staged) version.
- `git restore --staged <file>` when you ran git add and want to unstage the file but keep your edits on disk.
- `git restore --source=<commit> <file>` when you need the contents of a file as they were at a specific commit (to compare, copy, or fix a mistake)


### Task 6 — GitHub Community Engagement (1 pt)

**Objective:** Explore GitHub's social features that support collaboration and discovery.

**Actions Required:**
1. **Star** the course repository
2. **Star** the [simple-container-com/api](https://github.com/simple-container-com/api) project — a promising open-source tool for container management
3. **Follow** your professor and TAs on GitHub:
   - Professor: [@Cre-eD](https://github.com/Cre-eD)
   - TA: [@marat-biriushev](https://github.com/marat-biriushev)
   - TA: [@pierrepicaud](https://github.com/pierrepicaud)
4. **Follow** at least 3 classmates from the course

**GitHub Community**

- **Starring repositories** signals appreciation and visibility in open source: it helps maintainers gauge interest, boosts discoverability (e.g. in “trending” lists), and builds a personal list of projects to revisit—all without contributing code.
- **Following developers** keeps you in the loop on their public activity and repos, which helps in team projects (e.g. seeing what teammates are building) and professional growth (learning from others’ contributions and project choices).

