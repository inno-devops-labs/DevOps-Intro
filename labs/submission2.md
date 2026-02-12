# Task 1

## All command outputs for object inspection
`git cat-file -p <blob_hash>`

```
Test content
```

`git cat-file -p <tree_hash>`

```
040000 tree 575b85bca196c3e9e6cb7121dbd95c4485ccc76a    .github
100644 blob db7abc0be45b7051f5e4d6c5bf99208a9ddf8e7a    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree 788b221a8787de2ff117bef28485d13dd331d9a0    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt
```

`git cat-file -p <commit_hash>`

```
tree d2f65253f5354a0d0249f5a23664980ae29f7839
parent 15e88b52f752da4bb3cc2c006272af9e0a02d05b
author |-y6o-| <mailkirill17@gmail.com> 1770906476 +0300
committer |-y6o-| <mailkirill17@gmail.com> 1770906476 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgqfOj49/F6JTTUDN4JPswV8L9v2
 6g785vQOZBFhnanpcAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQDl5KD1ZA4FioejmPmCPTlE7/ChHMj4FnDdLHQwj8qDVc2OzAv4ONEqUDtjmDMkYXm
 WeIfSdJ+Vkzf0hwOZAqQU=
 -----END SSH SIGNATURE-----

Add test file
```

## A 1–2 sentence explanation of what each object type represents
**Blob** – represents the raw contents of a file. It stores only the file’s data, not its name or location in the directory.

**Tree** – represents a directory snapshot. It maps filenames to blob objects (files) and other tree objects (subdirectories), including their permissions.

**Commit** – represents a project snapshot at a point in time. It points to a root tree and stores metadata: author, message, and parent commit.

## Analysis of how Git stores repository data
Git stores repository data as a content-addressed object database, where every file and directory snapshot is saved as an object identified by a hash of its contents. The main object types are blobs, trees, and commits, forming a DAG of project history. Git records full snapshots, but achieves efficiency through hash-based deduplication and structural sharing—unchanged files and directories reuse existing objects. Objects are compressed and stored either individually (loose objects) or in optimized packfiles, while branches and tags are lightweight references that point to commit hashes.

## Example of blob, tree, and commit object content
Examples of these objects content can be viewed by `git cat-file -p <hash>` command. Examples were provided in **All command outputs for object inspection** section.

# Task 2
## The exact commands you ran and why
Commands was run:
```
git reset --soft HEAD~1
git reset --hard HEAD~1
git reflog
git reset --hard <reflog_hash>
```

## Snippets of `git log --oneline` and `git reflog`

First reset `git log`
```
b8f243b (HEAD -> git-reset-practice) Second commit
0e8ab8a First commit
```

Second reset `git log`
```
0e8ab8a (HEAD -> git-reset-practice) First commit
```

Third reset `git log`
```
b8f243b (HEAD -> git-reset-practice) Second commit
0e8ab8a First commit
```

`git reflog` snippet
```
b8f243b (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to b8f243b
0e8ab8a HEAD@{1}: reset: moving to HEAD~1
b8f243b (HEAD -> git-reset-practice) HEAD@{2}: reset: moving to HEAD~1
5926d71 HEAD@{3}: commit: Third commit
b8f243b (HEAD -> git-reset-practice) HEAD@{4}: commit: Second commit
0e8ab8a HEAD@{5}: commit: First commit
```

## What changed in the working tree, index, and history for each reset
Initial commits history
`First -> Second -> Third (HEAD)`


First reset (soft)

History: `First -> Second (HEAD)`
Index and working tree is kept (file contains three lines)

Second reset (hard)
History: `First (HEAD)`
Index and working tree is reverted (file contains one line)

Third reset (hard reflog hash)
History: `First -> Second (HEAD)`
Reverts second reset
Index and working tree correspond to second commit head

## Analysis of recovery process using reflog
`reflog` output

```
b8f243b (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to b8f243b
0e8ab8a HEAD@{1}: reset: moving to HEAD~1
b8f243b (HEAD -> git-reset-practice) HEAD@{2}: reset: moving to HEAD~1
5926d71 HEAD@{3}: commit: Third commit
b8f243b (HEAD -> git-reset-practice) HEAD@{4}: commit: Second commit
0e8ab8a HEAD@{5}: commit: First commit
```

Recovery process:
Reset to second commit -> reset to first commit -> reset to second commit again (revert first commit reset)


# Task 3
## A snippet/screenshot of the graph
```
* 866e511 (side-branch) Side branch commit
* b8f243b (HEAD -> git-reset-practice) Second commit
* 0e8ab8a First commit
* 4df7a4b (feature/lab2) Add test file
*   15e88b5 (origin/main, origin/HEAD, main) Merge branch 'inno-devops-labs:main' into main
|\  
| * 6f044dd Replace IPFS with Nix
| * 0a87e1c refactor: reduce prescriptiveness in GitLab CI instructions
| * eaea715 feat: add GitLab CI alternative instructions to lab3
* | aaa5269 feat: created PR template
|/ 
```

## Commit messages list
Commit messages list can be viewed in branches graph after branch name:
`<commit hash> (branch name) commit message`

## A 1–2 sentence reflection on how the graph aids understanding
The `--graph` view visually shows how commits diverge and relate, making branch structure and parallel histories immediately clear. It helps you see where side-branch split from the main line and how development progressed independently.

# Task 4
## Tag names and commands used
Tag: v1.0.0, command `git tag v1.0.0`

## Associated commit hashes
`835a9a4 (HEAD -> feature/lab2, tag: v1.0.0, origin/feature/lab2) Task 3 completed`
Hash: `835a9a4`

## A short note on why tags matter (versioning, CI/CD triggers, release notes)
Tags matter because they provide stable, human-readable markers for important commits (e.g., releases like v1.0.0), making versioning explicit and reproducible. They are commonly used in CI/CD pipelines to trigger release builds and deployments, and they serve as fixed reference points for generating release notes and tracking shipped features

# Task 5
## Commands you ran and their outputs
`git switch -c cmd-compare`
Output:
`Switched to a new branch 'cmd-compare'`

`git switch -`
Output:
```
M       labs/submission2.md
Switched to branch 'feature/lab2'
Your branch is up to date with 'origin/feature/lab2'.
```

`git checkout -b cmd-compare-2`
Output:
`Switched to a new branch 'cmd-compare-2'`

```
git restore demo.txt                 # discard working tree changes
git restore --staged demo.txt        # unstage (keep working tree)
git restore --source=HEAD~1 demo.txt # restore from another commit
```
No output

## git status/git branch outputs showing state changes
Initial git status:
```
On branch feature/lab2
Your branch is up to date with 'origin/feature/lab2'.
```

After switch: `On branch cmd-compare`

After checkout: `On branch cmd-compare-2`

## 2–3 sentences on when to use each command
Use git switch when working with branches—switching between them, creating a new branch, or detaching HEAD—since it’s purpose-built and safer for branch operations.

Use git restore when you want to discard changes or restore specific files from the index or a commit without affecting branch history.

Use git checkout mainly for backward compatibility or in older workflows, as it combines both behaviors but is more ambiguous and easier to misuse.

# Task 6
## GitHub Community
Starring repositories signals appreciation, helps track projects of interest, and can boost a project’s visibility in the open-source community.

Following developers lets you stay updated on their work, learn best practices, and facilitates collaboration, mentorship, and professional networking.
