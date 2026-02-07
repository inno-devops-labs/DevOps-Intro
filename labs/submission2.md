# Task 1

### 1. Command Execution

I created sample commits and inspected the underlying Git objects using `git cat-file` to understand how data is linked.

**Check the latest commit hash:**

Getting the short hash from the active branch:
```bash
$ git log --oneline -1
0c07879 (HEAD -> main) Add test file
```

**Inspect the Commit Object (`0c07879`):**

Here we see the metadata and the pointer to the main Tree:
```bash
$ git cat-file -p HEAD
tree 6d24b1df9aa3951f0b89cc466c0c0e821560ba13
parent 43617c6c2df7ccb04c199e70fa7d0567722107a9
author Egor Chernobrovkin <33jasooon33@gmail.com> 1770472655 +0300
committer Egor Chernobrovkin <33jasooon33@gmail.com> 1770472655 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
...
-----END SSH SIGNATURE-----

Add test file
```

**Inspect the Tree Object:**

Checking the tree (`6d24b1df9aa3951f0b89cc466c0c0e821560ba13`) referenced by the commit. It acts like a directory listing:
```bash
$ git cat-file -p 6d24b1df9aa3951f0b89cc466c0c0e821560ba13
040000 tree d474a2cab8082959663133f40aea44e8b11e4bad    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree eb79e5a468ab89b024bd4f3ed867c6a3954fe1f0    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt
```

**Inspect the Blob Object (`2eec599a1130d2ff231309bb776d1989b97c6ab2`):**
This shows the content of the `test.txt` file.
```bash
$ git cat-file -p 2eec599a1130d2ff231309bb776d1989b97c6ab2
Test content
```

### 2. Object Explanations

- **Blob:** Stores pure file content. It has no idea about filenames, timestamps, or permissions;
- **Tree:** Represents a directory structure. It maps names to blobs (files) or other trees (subdirectories), along with permissions;
- **Commit:** A snapshot wrapper. It points to a root tree and adds context: who saved it (author), when, why (message), and where it came from (parent commit).

### 3. Git Data Storage Analysis

Git functions as a content-addressable file system. It does not store changes (diffs) by default; it stores snapshots.
*   Everything is stored as an object identified by a SHA-1 hash;
*   **Commits** point to **Trees**;
*   **Trees** point to **Blobs** or other Trees;
*   When a file changes, Git creates a new blob and a new tree hash, linking them in a new commit object.

### 4. Examples from Repository

Based on the inspection above, here are the real IDs from my repo:

*   **Commit Object ID:** `0c07879`
*   **Tree Object ID (Root):** `6d24b1df9aa3951f0b89cc466c0c0e821560ba13`
*   **Blob Object ID (test.txt):** `2eec599a1130d2ff231309bb776d1989b97c6ab2`

# Task 2

### 1. Environment Setup

I created a practice branch `git-reset-practice` and made three sequential commits modifying `file.txt`.

```bash
$ git log --oneline
6613179 (HEAD -> git-reset-practice) Third commit
df8f81e Second commit
377404b First commit
0c07879 (main) Add test file
43617c6 (origin/main, origin/HEAD) Add PR template
```

### 2. Exploring Reset Modes

I used `git reset --soft` to undo the last commit while keeping the changes staged.

```bash
$ git reset --soft HEAD~1
$ git status

On branch git-reset-practice
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   file.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/img/
        labs/submission2.md

$ cat file.txt
First commit
Second commit
Third commit

$ git log --oneline
df8f81e (HEAD -> git-reset-practice) Second commit
377404b First commit
0c07879 (main) Add test file
43617c6 (origin/main, origin/HEAD) Add PR template
```

The "Third commit" (6613179) was removed from the log. The changes ("Third commit" line) remained as staged files awaiting commit. The file content remained intact.

Then I used `git reset --hard` to move back one more commit and discard all changes.

```bash
$ git reset --hard HEAD~1
HEAD is now at 377404b First commit

$ cat file.txt 
First commit

$ git log --oneline
377404b (HEAD -> git-reset-practice) First commit
0c07879 (main) Add test file
43617c6 (origin/main, origin/HEAD) Add PR template
```

The "Second commit" (df8f81e) was removed. All changes were discarded. file.txt reverted to its state at the "First commit".

### 3. Recovery with Reflog

Since I used a hard reset, the commits were lost from the standard git log. I used git reflog to find the lost commit hash.

I identified 6613179 as the hash of the "Third commit" before the resets occurred.

```bash
$ git reflog

377404b (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
df8f81e HEAD@{1}: reset: moving to HEAD~1
6613179 HEAD@{2}: commit: Third commit
df8f81e HEAD@{3}: commit: Second commit
377404b (HEAD -> git-reset-practice) HEAD@{4}: commit: First commit
```

Then I performed a hard reset to the target hash to restore everything.

```bash
$ git reset --hard 6613179
HEAD is now at 6613179 Third commit
$ cat test.txt 
Test content
$ cat file.txt 
First commit
Second commit
Third commit
```

### 4. Summary

The command `git reset` moves the HEAD pointer to a specific commit. Using `--soft` keeps your changes in the Staging Area, making it useful for undoing commits to edit them later. However, `--hard` is destructive because it deletes changes from both the Staging Area and the Working Directory. Despite this, `git reflog` acts as a safety net by tracking all HEAD movements, allowing you to recover "lost" commits.

# Task 3

### 1. Branch Setup

I created a new branch `side-branch` and added a commit to create a divergence in history.

```bash
git switch -c side-branch
echo "Branch commit" >> history.txt
git add history.txt && git commit -m "Side branch commit"
git switch -
```

### 2. Graph Visualization

I used `git log --oneline --graph --all` to view the commit tree structure.

Command output:
```
* a0e5762 (side-branch) Side branch commit
* 6613179 (HEAD -> git-reset-practice) Third commit
* df8f81e Second commit
* 377404b First commit
* 0c07879 (main) Add test file
* 43617c6 (origin/main, origin/HEAD) Add PR template
| * 03cbde5 (origin/feature/lab1, feature/lab1) docs: update lab1 submission
| * 8fb02ce feat: remove template from non-main branch
| * 6f7b927 docs: add lab1 submission
| * e34f230 docs: add lab1 submission stub
| * 852cd1e docs: add commit signing summary
|/  
* d6b6a03 Update lab2
...
```

### 3. Reflection

The graph visualization provides an instant overview of the repository structure. It makes it easy to spot where branches split and where they join back together, helping to track parallel development efforts without analyzing individual file changes.

# Task 4

### 1. Tag Creation

I created a tag v1.0.0 on the latest commit and pushed it to the remote repository.

```bash
$ git tag v1.0.0
$ git push origin v1.0.0
To https://github.com/lolyhop/DevOps-Intro.git
 * [new tag]         v1.0.0 -> v1.0.0
```

### 2. Verification and Associated Commit

I verified that the tag marks the correct commit hash (6613179).

```bash
$ git show v1.0.0 --oneline -s
6613179 (HEAD -> git-reset-practice, tag: v1.0.0) Third commit
```

### 3. Why Tags Matter

Tags are static pointers to specific commits, unlike branches which move with every new commit. 

They are essential for:
- **Versioning:** Marking stable releases (e.g., v1.0, v2.0) clearly in history;
- **CI/CD:** Pipelines often trigger automated deployments only when a new tag is pushed;
- **Release Notes:** Generating changelogs based on the difference between two tags.


# Task 5

### 1. Branch Operations

I compared the modern way to switch branches against the legacy command.

**Modern Approach (`git switch`):**

Dedicated solely to navigation.
```bash
$ git switch -c cmd-compare
Switched to a new branch 'cmd-compare'

$ git switch -
Switched to branch 'git-reset-practice'
```

**Legacy Approach (`git checkout`):**

Handles both files and branches.
```bash
$ git checkout -b cmd-compare-2
Switched to a new branch 'cmd-compare-2'
```

### 2. File Restoration

I modified `file.txt` and used the modern `git restore` command to discard changes in the working tree without using `checkout`.

```bash
$ echo "scratch content" >> file.txt

$ git restore file.txt

$ git status
On branch cmd-compare-2
nothing added to commit but untracked files present

$ cat file.txt
First commit
Second commit
Third commit
```

### 3. When to use each command

- **git switch:** Use exclusively for creating and changing branches. It is safer than `checkout` because it keeps file operations separate from navigation;
- **git restore:** Use to discard local changes in files or unstage them from the index. It replaces the confusing usage of `git checkout <file>`;
- **git checkout:** The legacy command. It is recommended to replace it with the specialized commands above to avoid accidents.


# Task 6

### GitHub Community

I have completed the community engagement tasks, including starring the required repositories and following the instructor, TAs, and classmates.

**Why starring repositories matters:**
- **Visibility:** It acts as a "vote" of confidence, helping open-source projects gain recognition and attract more contributors;
- **Bookmarking:** It allows me to easily find and reference useful projects later in my personal list.

**How following developers helps:**
- **Discovery:** The GitHub activity feed shows what repositories the people I follow are starring or forking, helping me discover new tools;
- **Networking:** It keeps me updated on their latest contributions and helps build professional connections within the industry.
