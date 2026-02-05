# Lab 2 — Version Control & Advanced Git



## Task 1 — Git Object Model Exploration

## All command outputs for object inspection.

`git cat-file -p f4ace6cb161d54680a20de8b2dc9edba7242bbad`

```bash
tree 4ec8539e4bf0750303a439f8668821efff1ae364
parent 91750fad1af69732c3cd01dbc9e8133ef5731a2b
author Mirletti <Ladutskam@yandex.ru> 1770313653 +0300
committer Mirletti <Ladutskam@yandex.ru> 1770313653 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAge31wv...
 7WUOCSsbLwGoyDf/40EA4=
 -----END SSH SIGNATURE-----
```

`git cat-file -p 4ec8539e4bf0750303a439f8668821efff1ae364`

```bash
040000 tree 1c9dbb1dbd58e5d8c98d8501f7b8116ec8199f4d    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree eb79e5a468ab89b024bd4f3ed867c6a3954fe1f0    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt
```

`git cat-file -p 6e60bebec0724892a7c82c52183d0a7b467cb6bb`

```bash
# 🚀 DevOps Introduction Course: Principles, Practices & Tooling

[![Labs](https://img.shields.io/badge/Labs-80%25-blue)](#-lab-based-learning-experience)
[![Exam](https://img.shields.io/badge/Exam-20%25-orange)](#-evaluation-framework)
[![Hands-On](https://img.shields.io/badge/Focus-Hands--On%20Labs-success)](#-lab-based-learning-experience)
[![Duration](https://img.shields.io/badge/Duration-10%20Weeks-lightgrey)](#-course-roadmap)

Welcome to the **DevOps Introduction Course**, where you will gain a **solid foundation in DevOps principles and practical skills**.  
This course is designed to provide a comprehensive understanding of DevOps and its key components.
...
```

## A 1–2 sentence explanation of what each object type represents.

**blob** — stores the contents of a file as a set of bytes without a name or metadata; this is exactly the file data in the repository

**tree** — represents a directory: it contains a list of files and subfolders with their types and links to blob and other tree objects

**commit** — represents a snapshot of the project: refers to the root tree, includes metadata (author, date, message) and links to parent commits

## Analysis of how Git stores repository data.

Git stores the entire repository as an object database, where each object receives a unique SHA hash based on its contents; commits form a history, referring to trees, and trees to files, forming a content-addressable data structure without duplication.



## Task 2 — Reset and Reflog Recovery

## The exact commands you ran.

`git switch -c git-reset-practice`

```bash
Switched to a new branch 'git-reset-practice'
```

`echo "First commit" > file.txt && git add file.txt && git commit -m "First commit"`

```bash
[git-reset-practice 36357b4] First commit
 1 file changed, 1 insertion(+)
 create mode 100644 file.txt
```

`echo "Second commit" >> file.txt && git add file.txt && git commit -m "Second commit"`

```bash
[git-reset-practice d1f6378] Second commit
 1 file changed, 1 insertion(+)
```

`echo "Third commit"  >> file.txt && git add file.txt && git commit -m "Third commit"`

```bash
[git-reset-practice 66f923d] Third commit
 1 file changed, 1 insertion(+)
```

`git reset --soft HEAD~1`

(moved the HEAD one commit back, saved the changes in the index and the working tree)
```bash
```

`git reset --hard HEAD~1`

(moved HEAD one commit back and reset the index and work tree to this commit)
```bash
HEAD is now at 36357b4 First commit
```

`git reset --hard 36357b`

(restored the state indicated by the reflog entry)
```bash
HEAD is now at 36357b4 First commit
```

## Snippets of `git log --oneline` and `git reflog`

`git reflog`

```bash
36357b4 (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
d1f6378 HEAD@{1}: reset: moving to HEAD~1
66f923d HEAD@{2}: commit: Third commit
d1f6378 HEAD@{3}: commit: Second commit
36357b4 (HEAD -> git-reset-practice) HEAD@{4}: commit: First commit
f4ace6c (feature/lab2) HEAD@{5}: checkout: moving from feature/lab2 to git-reset-practice
f4ace6c (feature/lab2) HEAD@{6}: commit: Add test file
91750fa (origin/main, origin/HEAD, main) HEAD@{7}: checkout: moving from main to feature/lab2
91750fa (origin/main, origin/HEAD, main) HEAD@{8}: checkout: moving from feature/lab1 to main
1300224 (origin/feature/lab1, feature/lab1) HEAD@{9}: commit: submission fix
b248093 HEAD@{10}: checkout: moving from main to feature/lab1
91750fa (origin/main, origin/HEAD, main) HEAD@{11}: checkout: moving from main to main
91750fa (origin/main, origin/HEAD, main) HEAD@{12}: commit: template
d6b6a03 (upstream/main) HEAD@{13}: checkout: moving from feature/lab1 to main
b248093 HEAD@{14}: checkout: moving from main to feature/lab1
d6b6a03 (upstream/main) HEAD@{15}: reset: moving to HEAD
d6b6a03 (upstream/main) HEAD@{16}: checkout: moving from feature/lab1 to main
b248093 HEAD@{17}: rebase (finish): returning to refs/heads/feature/lab1
b248093 HEAD@{18}: rebase (pick): docs: add lab1 submission stub
423c1d9 HEAD@{19}: rebase (pick): docs: add commit signing summary
7ca3635 HEAD@{20}: rebase (pick): docs: add commit signing summary
08cc7d0 HEAD@{21}: rebase (pick): docs: add commit signing summary
d6b6a03 (upstream/main) HEAD@{22}: rebase (start): checkout upstream/main
97a930d (upstream/feature/lab1) HEAD@{23}: checkout: moving from feature/lab1 to feature/lab1
97a930d (upstream/feature/lab1) HEAD@{24}: checkout: moving from main to feature/lab1
d6b6a03 (upstream/main) HEAD@{25}: clone: from github.com:Mirletti/DevOps-Intro.git
```

`git log --oneline`

```bash
36357b4 (HEAD -> git-reset-practice) First commit
f4ace6c (feature/lab2) Add test file
91750fa (origin/main, origin/HEAD, main) template
d6b6a03 (upstream/main) Update lab2
87810a0 feat: remove old Exam Exemption Policy
1e1c32b feat: update structure
6c27ee7 feat: publish lecs 9 & 10
1826c36 feat: update lab7
3049f08 feat: publish lec8
da8f635 feat: introduce all labs and revised structure
04b174e feat: publish lab and lec #5
67f12f1 feat: publish labs 4&5, revise others
82d1989 feat: publish lab3 and lec3
3f80c83 feat: publish lec2
499f2ba feat: publish lab2
af0da89 feat: update lab1
74a8c27 Publish lab1
f0485c0 Publish lec1
31dd11b Publish README.md
```

## What changed in the working tree, index, and history for each reset.

`git reset --soft HEAD~1`

- History: HEAD moved to the previous commit (the last commit was deleted from the branch history).
- Index: changes from the cancelled commit remained staged.
- Working tree: files have not changed.

`git reset --hard HEAD~1`

- History: HEAD moved to the previous commit.
- Index: reset to the state of this commit.
- Work tree: all changes, including uncomplicated ones, have been deleted — the files correspond to the target commit.

## Analysis of recovery process using reflog.

`git reflog` records every HEAD move regardless of the current branch history, even if commits are "deleted" from the history. You can find the necessary reflog hash and perform a `git reset --hard <reflog_hash>` to restore the repository state that was previously accessible via HEAD. This works as a safety net — even after a hard reset, lost commits remain available through the reflog until they are finally cleaned up by the garbage collector.



## Task 3 — Visualize Commit History

## A snippet/screenshot of the graph.

`git log --oneline --graph --all`

```bash
* 84bd0c7 (side-branch) Side branch commit
* 36357b4 (HEAD -> git-reset-practice) First commit
* f4ace6c (feature/lab2) Add test file
* 91750fa (origin/main, origin/HEAD, main) template
| * 1300224 (origin/feature/lab1, feature/lab1) submission fix
| * b248093 docs: add lab1 submission stub
| * 423c1d9 docs: add commit signing summary
| * 7ca3635 docs: add commit signing summary
| * 08cc7d0 docs: add commit signing summary
|/  
* d6b6a03 (upstream/main) Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
| * 97a930d (upstream/feature/lab1) docs: add lab1 submission stub
| * 175406d docs: add commit signing summary
| * 7118ab7 docs: add commit signing summary
| * a381ba3 docs: add commit signing summary
| * 6529180 Initial commit
| * 0a09c16 (upstream/release/f25, origin/release/f25) feat: remove old Exam Exemption Policy
|/  
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

The commit graph visually shows how the side-branch diverged from main, making it easy to see where commits were added in each branch and how they relate to each other - this helps understand branching and merge relationships in the project history.



## Task 4 — Tagging Commits

## Tag names and commands used.

`git tag v1.0.0`

(36357b4b2d1fecdd7a2c77d1fa082266f144f237)
```bash
```

`git push origin v1.0.0`

```bash
Enumerating objects: 7, done.
Counting objects: 100% (7/7), done.
Delta compression using up to 8 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (6/6), 815 bytes | 815.00 KiB/s, done.
Total 6 (delta 3), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (3/3), completed with 1 local object.
To github.com:Mirletti/DevOps-Intro.git
 * [new tag]         v1.0.0 -> v1.0.0
```

`git tag v1.1.0`

(36357b4b2d1fecdd7a2c77d1fa082266f144f237)
```bash
```

`git push origin v1.1.0`

```bash
git push origin v1.1.0
Total 0 (delta 0), reused 0 (delta 0), pack-reused 0
To github.com:Mirletti/DevOps-Intro.git
 * [new tag]         v1.1.0 -> v1.1.0
```

## A short note on why tags matter

Tags allow you to capture important points in the repository's history, such as release versions, which makes it easier to navigate between versions, create release notes, and automate in CI/CD - they serve as "bookmarks" for specific code snapshots.



## Task 5 — git switch vs git checkout vs git restore

## Commands ran and their outputs.

`git switch -c cmd-compare`

(create and switch)
```bash
Switched to a new branch 'cmd-compare'
```

`git switch -`

(toggle back to previous branch)
```bash
Switched to branch 'git-reset-practice'
```

**Purpose**: Branch switching only (clear and focused)



## Task 6 — GitHub Community Engagement

Starring repositories on GitHub serves as a lightweight endorsement that increases a project’s visibility and helps others discover quality open-source work, while also signaling community interest and appreciation to maintainers.

Following other developers allows you to stay updated on their activity and contributions, fostering collaboration, expanding your professional network, and supporting growth both within your team and in the broader developer ecosystem.
