# Lab 2 Submission - Version Control & Advanced Git

## Task 1 — Git Object Model Exploration (2 pts)

### Commands and Outputs

**Commit Object (3dba6e3ebdfabb1edae18603ad25e5444a8ebbad):**
```bash
$ git cat-file -p HEAD
tree a786f2b5ea04cec24ab6b9ed1c10d7221a9e7257
parent cbeca4e903147ce87d7375eaa0f893b7ab0a41d3
author Arthur Babkin <artur.babkin.2015@gmail.com> 1758056551 +0300
committer Arthur Babkin <artur.babkin.2015@gmail.com> 1758056551 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgdUHUC3uAyyiAFr7GXLGXFjh6Oe
 2WDoAI1y3blWwXGdoAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQKoexSYikpZXR7GKKnR31PybxEwrlIJf4yHrT28C1CvSYWWy1bZ7yf7R3R0mEmNnur
 DNjD23vnGLm3IvoAexNAg=
 -----END SSH SIGNATURE-----

feat: update test file content
```

**Tree Object (a786f2b5ea04cec24ab6b9ed1c10d7221a9e7257):**
```bash
$ git cat-file -p HEAD^{tree}
040000 tree 6c09998f23b0b1ce80cc196191ad447c1353f7a2    .github
100644 blob 4db373667a50f14a411bb5c7e879690fd08aacc1    README.md
040000 tree cb1959162a7ad6f2263ccf0136246e3f36a8f5cf    labs
040000 tree 2f0387f9eebb6ad846cd02dbd1e7a4a151c06a7e    lectures
100644 blob 0ebbb9ac9f7f5ded65759de45964daece16c5645    test-object.txt
```

**Blob Object (0ebbb9ac9f7f5ded65759de45964daece16c5645):**
```bash
$ git cat-file -p 0ebbb9ac9f7f5ded65759de45964daece16c5645
This is a test file for Git object exploration
Additional content for object demo
```

### Explanation

- **Commit objects** store metadata about a snapshot including tree hash, parent commit(s), author/committer info, timestamps, and commit message.
- **Tree objects** represent directory structures, containing references to blobs (files) and other trees (subdirectories) with their permissions and names.
- **Blob objects** store the actual file content as binary data, identified by the SHA-1 hash of their content.

## Task 2 — Reset and Reflog Recovery (3 pts)

### Commands and Process

**Initial Setup:**
```bash
$ git switch -c git-reset-practice
$ echo "First commit" > file.txt && git add file.txt && git commit -m "First commit"
$ echo "Second commit" >> file.txt && git add file.txt && git commit -m "Second commit"  
$ echo "Third commit" >> file.txt && git add file.txt && git commit -m "Third commit"
```

**Initial State:**
```bash
$ git log --oneline -3
d8d9f7e (HEAD -> git-reset-practice) Third commit
3b47be4 Second commit
0983940 First commit

$ cat file.txt
First commit
Second commit
Third commit
```

**Soft Reset (--soft HEAD~1):**
```bash
$ git reset --soft HEAD~1
$ git status
On branch git-reset-practice
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   file.txt

$ cat file.txt
First commit
Second commit
Third commit
```

**Hard Reset (--hard HEAD~1):**
```bash
$ git reset --hard HEAD~1
HEAD is now at 0983940 First commit

$ git status
On branch git-reset-practice
nothing to commit, working tree clean

$ cat file.txt
First commit
```

**Using Reflog for Recovery:**
```bash
$ git reflog
0983940 (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
3b47be4 HEAD@{1}: reset: moving to HEAD~1
d8d9f7e HEAD@{2}: commit: Third commit
3b47be4 HEAD@{3}: commit: Second commit
0983940 (HEAD -> git-reset-practice) HEAD@{4}: commit: First commit

$ git reset --hard d8d9f7e
HEAD is now at d8d9f7e Third commit

$ cat file.txt
First commit
Second commit
Third commit
```

### Explanation

- **--soft reset**: Moves HEAD pointer but keeps the index (staging area) and working tree unchanged. The "Third commit" changes remained staged.
- **--hard reset**: Moves HEAD, resets index, and discards working tree changes completely. All traces of "Second commit" and "Third commit" were lost from the working directory.
- **git reflog**: Shows the history of HEAD movements, allowing recovery of seemingly "lost" commits by their hash, even after hard reset operations.

## Task 3 — Visualize Commit History (2 pts)

### Commands and Process

**Creating a side branch:**
```bash
$ git switch -c side-branch
$ echo "Branch commit content" > history.txt
$ git add history.txt && git commit -m "Side branch commit"
$ git switch -
```

**Visualizing with graph:**
```bash
$ git log --oneline --graph --all
* 49134d9 (side-branch) Side branch commit
| * d8d9f7e (git-reset-practice) Third commit
| * 3b47be4 Second commit
| * 0983940 First commit
|/  
* 3dba6e3 (HEAD -> feature/lab2) feat: update test file content
* cbeca4e feat: add test file for object exploration
* 8b4f42b (main) docs: add commit signing summary
* 049fbeb (origin/main, origin/HEAD) docs: add PR template
| * 336529e (origin/feature/lab1, feature/lab1) docs: add commit signing summary
|/  
* 82d1989 feat: publish lab3 and lec3
* 3f80c83 feat: publish lec2
* 499f2ba feat: publish lab2
* af0da89 feat: update lab1
* 74a8c27 Publish lab1
* f0485c0 Publish lec1
* 31dd11b Publish README.md
```

**Commit Messages List:**
- 49134d9: Side branch commit
- d8d9f7e: Third commit  
- 3b47be4: Second commit
- 0983940: First commit
- 3dba6e3: feat: update test file content
- cbeca4e: feat: add test file for object exploration
- 8b4f42b: docs: add commit signing summary
- 049fbeb: docs: add PR template

### Reflection

The graph visualization clearly shows the branching structure and relationships between commits. The asterisks (*) represent commits, vertical lines (|) show branch continuity, and the forward slashes (/) indicate where branches diverge or merge, making it easy to understand the development flow and identify parallel work streams.

## Task 4 — Tagging Commits (1 pt)

### Commands and Process

**Creating and pushing tags:**
```bash
$ git tag v1.0.0
$ git push origin v1.0.0

$ echo "Additional content for v1.1.0" >> test-object.txt
$ git add test-object.txt && git commit -m "feat: prepare for v1.1.0 release"
$ git tag v1.1.0
$ git push origin v1.1.0
```

**Verifying tags:**
```bash
$ git tag -l
v1.0.0
v1.1.0

$ git show v1.0.0 --no-patch --format="Tag: %D, Commit: %H"
Tag: tag: v1.0.0, Commit: 3dba6e3ebdfabb1edae18603ad25e5444a8ebbad

$ git show v1.1.0 --no-patch --format="Tag: %D, Commit: %H"
Tag: HEAD -> feature/lab2, tag: v1.1.0, Commit: 2bf6c87a94008328625172c1763b6d4d879b0c8a
```

### Tag Information

- **v1.0.0**: Associated with commit `3dba6e3ebdfabb1edae18603ad25e5444a8ebbad`
- **v1.1.0**: Associated with commit `2bf6c87a94008328625172c1763b6d4d879b0c8a`

### Importance of Tags

Tags are crucial for versioning and release management, providing immutable references to specific commits that trigger CI/CD pipelines, enable rollbacks, and facilitate release notes generation for production deployments.

## Task 5 — git switch vs git checkout vs git restore (2 pts)

### Commands and Process

**Branch switching with git switch (modern):**
```bash
$ git switch -c cmd-compare
Switched to a new branch 'cmd-compare'

$ git status
On branch cmd-compare
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/submission2.md
nothing added to commit but untracked files present (use "git add" to track)

$ git switch -
Switched to branch 'feature/lab2'

$ git branch
  cmd-compare
* feature/lab2
  git-reset-practice
  main
  side-branch
```

**Legacy git checkout (overloaded):**
```bash
$ git checkout -b cmd-compare-2
Switched to a new branch 'cmd-compare-2'
```

**File restoration with git restore (modern):**
```bash
$ echo "scratch content" >> demo.txt
$ git add demo.txt && git commit -m "Add demo file"
$ echo "modified content" >> demo.txt
$ git status
On branch cmd-compare-2
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   demo.txt

$ git restore demo.txt  # Discard working tree changes
$ cat demo.txt
scratch content

# Demonstrating --staged option
$ echo "new changes" >> demo.txt
$ git add demo.txt
$ git status
On branch cmd-compare-2
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   demo.txt

$ git restore --staged demo.txt  # Unstage while keeping working tree
$ git status
On branch cmd-compare-2
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   demo.txt
```

### Summary of Differences

**git switch**: Modern, dedicated command for branch operations - creating, switching, and toggling between branches. Clearer intent than the overloaded checkout.

**git checkout**: Legacy command that handles both branch switching AND file restoration, making it confusing. Still works but less explicit about intent.

**git restore**: Modern, explicit command for file operations - discarding working tree changes, unstaging files, or restoring from specific commits. Replaces the confusing `git checkout -- <file>` syntax with clear options like `--staged` and `--source`.

