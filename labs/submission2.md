# Lab 2 — Version Control & Advanced Git

## Task 1 — Git Object Model Exploration

### Blob object

Command:
```bash
git cat-file -p d329320010da9e34850f76bf7c2954aac19d9377
```

Output:
```
Signing commits (with GPG, SSH, or S/MIME) helps to:

1. **Prove authorship** – ensures the commit truly comes from the person who owns the signing key.

2. **Protect integrity** – prevents undetected tampering with commit history, as the signature is cryptographically verifiable.

3. **Build trust** – signed commits are marked as Verified on GitHub, making code review and collaboration more secure.

4. **Support auditing and compliance** – even if a key is rotated or revoked later, the verification record persists, ensuring stable contribution history.
```
Description:

A blob stores the raw file contents without metadata such as filename or permissions.

### Tree object 
Command:
```
git cat-file -p e7eae0fda04b129164a49683809b1a321c12779a
```

Output:
```bash
100644 blob 4db373667a50f14a411bb5c7e879690fd08aacc1    README.md
040000 tree 33cd41e211a69f89ca99df6bbf00fda169f2f0da    labs
040000 tree 1c31e5c1fc7c98b6fd92659e55e0c03a46229c75    lectures
```

Description:

A tree represents a directory: it links filenames to their corresponding blobs (files) or subtrees (subdirectories).

### Commit object

Command:
```bash
git cat-file -p 37c84dcc3d1e14c0473996fa48fb97a79b07b3d7
```

Output:
```bash
tree e7eae0fda04b129164a49683809b1a321c12779a
parent 6c9d08c2101c1ecbe4a03ccd7aaa65d73d5cb78f
author belyakova-anna <belyakova.anna.st@yandex.ru> 1757775358 +0300
committer belyakova-anna <belyakova.anna.st@yandex.ru> 1757775358 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgjtPuFdA6G+Y+uAJ/Y1al4WVSE5
 uDORTebA+oc0gOzk4AAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQFCYz3h1jntL0CX3oPr9FxeMWVqsDKHsI68H8/T5Dop6B6ORtZpxAgwXUkwtKe96Ws
 YbiTyi16do8Aak8ctNYw4=
 -----END SSH SIGNATURE-----
```

Description:

A commit points to a tree (project snapshot) and contains metadata like parent commit(s), author, committer, signature, and the commit message.

## Task 2 — Reset and Reflog Recovery

### Commands and Purpose
```bash
# Create a practice branch for reset experiments
git switch -c git-reset-practice

# Create three commits
echo "First commit" > file.txt && git add file.txt && git commit -m "First commit"
echo "Second commit" >> file.txt && git add file.txt && git commit -m "Second commit"
echo "Third commit"  >> file.txt && git add file.txt && git commit -m "Third commit"

# View commit history
git log --oneline

# Soft reset: move HEAD back 1 commit, keep index & working tree
git reset --soft HEAD~1
git status
git log --oneline

# Hard reset using reflog: recover previous HEAD state
git reset --hard HEAD@{1}

# Hard reset to one commit before HEAD
git reset --hard HEAD~1
git status
git log --oneline

# View reflog to track HEAD movement
git reflog

# Reset to a specific commit (by hash) to fully restore that state
git reset --hard 37c84dc
git log --oneline
git status
```

### Snippets of git log --oneline

After creating three commits:

```bash
f452dbe (HEAD -> git-reset-practice) Third commit
6761636 Second commit
b4a1b11 First commit
```

After soft reset (HEAD~1):
```bash
6761636 (HEAD -> git-reset-practice) Second commit
b4a1b11 First commit
```

After hard reset to reflog (HEAD@{1}):
```bash
f452dbe (HEAD -> git-reset-practice) Third commit
6761636 Second commit
b4a1b11 First commit
```

After hard reset to specific commit (37c84dc):
```bash
37c84dc (HEAD -> git-reset-practice, origin/feature/lab2, feature/lab2) feat: delete Task 1.txt
6c9d08c feat: add Task 1.txt
b4a1b11 First commit
```

### Snippet of git reflog
```bash
6761636 (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
f452dbe HEAD@{1}: reset: moving to HEAD@{1}
6761636 HEAD@{2}: reset: moving to HEAD~1
f452dbe HEAD@{3}: commit: Third commit
6761636 HEAD@{4}: commit: Second commit
b4a1b11 HEAD@{5}: commit: First commit
...
37c84dc (origin/feature/lab2, feature/lab2) HEAD@{6}: checkout: moving from feature/lab2 to git-reset-practice
```

### Changes in Working Tree, Index, and History
| Reset Type            | Working Tree                        | Index (Staging)                | History (HEAD)                           |
|-----------------------|------------------------------------|--------------------------------|-----------------------------------------|
| `--soft HEAD~1`       | unchanged                           | unchanged                      | HEAD moved back 1 commit                 |
| `--hard HEAD@{1}`     | restored to state of previous commit| matches working tree           | HEAD restored to previous commit         |
| `--hard HEAD~1`       | file updated to previous commit     | matches working tree           | HEAD moved back 1 commit                 |
| `--hard <hash>`       | files match the specified commit    | matches working tree           | HEAD set to specified commit             |


## Task 3 — Visualize Commit History

### A snippet of the graph.

```bash
* 1913eaa (side-branch) Side branch commit
* 56b3b04 (HEAD -> main, origin/main, origin/HEAD) docs: add PR template
| * 37c84dc (origin/feature/lab2, git-reset-practice, feature/lab2) feat: delete Task 1.txt
| * 6c9d08c feat: add Task 1.txt
| * 1ecadc6 (origin/feature/lab1, feature/lab1) docs: add lab1 submission stub
| * c9b38e2 chore: configure ssh
| * 7688a20 docs: add commit signing summary
|/
* af0da89 feat: update lab1
* 74a8c27 Publish lab1
* f0485c0 Publish lec1
* 31dd11b Publish README.md
```

### Commit messages list

- Side branch commit
- docs: add PR template
- feat: delete Task 1.txt
- feat: add Task 1.txt
- docs: add lab1 submission stub
- chore: configure ssh
- docs: add commit signing summary
- feat: update lab1
- Publish lab1
- Publish lec1
- Publish README.md

### Reflection
The graph shows the branching structure of the repository, making it easy to see where side branches diverged and how commits are related.
This helps understand the project history and the relationship between branches.

## Task 4 — Tagging Commits

### Commands Used
```
# Switch to the lab branch
git switch feature/lab2

# Create a lightweight tag for the latest commit
git tag v1.0.0

# Verify the tag and see associated commit
git show v1.0.0

# Push the tag to the remote repository
git push origin v1.0.0
```

### Tag Name and Associated Commit

- Tag: v1.0.0
- Commit Hash: 37c84dcc3d1e14c0473996fa48fb97a79b07b3d7
- Commit Message: feat: delete Task 1.txt

### Note on Tags

Tags are used to mark specific points in history as releases. They are important for versioning, triggering CI/CD pipelines, and generating release notes, ensuring a clear reference to stable or released code.

## Task 5 — git switch vs git checkout vs git restore

### Branch Switching with `git switch`
Command:
```bash
git switch feature/lab2
```
Output:
```
Already on 'feature/lab2'
Your branch is up to date with 'origin/feature/lab2'.
```

- Switches to the feature/lab2 branch (already on it).

Command:
```bash
git switch -c cmd-compare
```
Output:
```
Switched to a new branch 'cmd-compare'
```

- Creates a new branch cmd-compare and switches to it.

Command:
```bash
git switch -
```
Output:
```
Switched to branch 'feature/lab2'
Your branch is up to date with 'origin/feature/lab2'.
```

- Switches back to the previous branch (feature/lab2).

Command:
```bash
git branch
```
Output:
```bash
  cmd-compare
  feature/lab1
* feature/lab2
  git-reset-practice
  main
  side-branch
```

- Shows all branches and indicates the current branch with *.

### Branch Creation with Legacy `git checkout`

Command:
```bash
git checkout -b cmd-compare-2
```
Output:
```
Switched to a new branch 'cmd-compare-2'
```

- Creates and switches to a new branch (cmd-compare-2) using the legacy git checkout command.

Command:
```bash
git branch
```
Output:
```bash
  cmd-compare
* cmd-compare-2
  feature/lab1
  feature/lab2
  git-reset-practice
  main
  side-branch
```

- Confirms that cmd-compare-2 is now the current branch.

### Working with Files Using `git restore`
Command:
```bash
git add demo.txt
echo "scratch" >> demo.txt
git status
```
Output:
```
On branch cmd-compare-2
Changes to be committed:
        new file:   demo.txt

Changes not staged for commit:
        modified:   demo.txt
```

- Adds demo.txt to staging, then appends text to it. Status shows staged changes (new file) and unstaged modifications (new content).

Command:
```bash
git restore demo.txt
git status
```
Output:
```
On branch cmd-compare-2
Changes to be committed:
        new file:   demo.txt
```

- Discards changes in the working directory (unstaged changes). Staging area remains unchanged.

Command:
```bash
git restore --staged demo.txt
git status
```
Output:
```
On branch cmd-compare-2
Untracked files:
        demo.txt
```

- Removes the file from staging area. The file is now untracked.

Command:
```bash
git add demo.txt
git restore --source=HEAD~1 demo.txt
git status
```
Output:
```
On branch cmd-compare-2
Changes to be committed:
        new file:   demo.txt

Changes not staged for commit:
        deleted:    demo.txt
```

- Restores the file to the state from the previous commit (HEAD~1).

- Since demo.txt did not exist in that commit, Git shows it as deleted in the working directory.

### Summary of Differences

| Command                         | Purpose / Effect |
|---------------------------------|-----------------|
| `git switch`                     | Modern, clear way to create and switch branches. |
| `git checkout -b`                | Legacy way to create + switch branches. Can also restore files (less clear). |
| `git restore <file>`             | Discards changes in working directory for tracked files. |
| `git restore --staged <file>`    | Removes files from staging area without touching working directory. |
| `git restore --source=<commit>`  | Restores file from a specific commit. Deletes file if it didn’t exist in that commit. |


## Bonus — GitHub Social Interactions

Starring repositories helps show appreciation for valuable projects and makes it easier to find them later. Following people allows you to keep up with their contributions and updates, fostering collaboration and community awareness in open source and team projects.