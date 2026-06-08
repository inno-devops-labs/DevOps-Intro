# Lab 2 Submission

## Task 1 - Git Object Model + Reflog Recovery

### 1.1 Explore the repository plumbing

Command:

```bash
git rev-parse HEAD
```

Output:

```text
fc232949952da1c22808b27a4daf4d765eae728b
```

Command:

```bash
git cat-file -t HEAD
```

Output:

```text
commit
```

Command:

```bash
git cat-file -p HEAD
```

Output:

```text
tree 73922848a67905b425a5bb1037f19850ea920b28
parent e5e8d7851c59e23baef470e55890e74b14a7e60c
author Mostafa Kira <m.kira@innopolis.university> 1780758878 +0300
committer Mostafa Kira <m.kira@innopolis.university> 1780758878 +0300

test: unsigned commit (should fail)

Signed-off-by: Mostafa Kira <m.kira@innopolis.university>
```

Command:

```bash
git cat-file -p 73922848a67905b425a5bb1037f19850ea920b28
```

Output:

```text
040000 tree af080e474767b4931935c2b4565f66bc9f0b8d22    .github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree b243921ca8b3357577da55c0ef0b9bd75332e911    images
040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures
```

Command:

```bash
git cat-file -p d10c04c6e7e0014f4fe883599c11747c15012d4e
```

Output excerpt:

```text
# DevOps Intro - Modern DevOps Practices Through One Project

[![Course](https://img.shields.io/badge/Course-DevOps%20Intro-blue)](#course-roadmap)
[![Project](https://img.shields.io/badge/Project-QuickNotes%20(Go)-success)](#the-project-quicknotes)
[![Duration](https://img.shields.io/badge/Duration-10%20Weeks-lightgrey)](#course-roadmap)
[![Grading](https://img.shields.io/badge/Grading-70--14--5--30--30-orange)](#grading)

A 10-week practical introduction to DevOps at Innopolis University. You will package, ship, observe, harden, and deploy **one** Go service - QuickNotes - across every lab.
```

This chain shows that `HEAD` resolves to commit `fc232949952da1c22808b27a4daf4d765eae728b`. That commit points to tree `73922848a67905b425a5bb1037f19850ea920b28`, and the tree maps repository paths to child trees and blobs. The selected blob `d10c04c6e7e0014f4fe883599c11747c15012d4e` stores the contents of `README.md`.

### 1.2 Look inside `.git/`

Command:

```bash
ls -la .git/
```

Output:

```text
total 64
drwxrwxr-x  8 mostafa mostafa 4096 Jun  8 11:27 .
drwxrwxr-x 11 mostafa mostafa 4096 Jun  8 11:26 ..
drwxrwxr-x  2 mostafa mostafa 4096 Jun  6 16:49 branches
-rw-rw-r--  1 mostafa mostafa   18 Jun  7 13:48 COMMIT_EDITMSG
-rw-rw-r--  1 mostafa mostafa  636 Jun  8 11:27 config
-rw-rw-r--  1 mostafa mostafa   73 Jun  6 16:49 description
-rw-rw-r--  1 mostafa mostafa  258 Jun  8 11:30 FETCH_HEAD
-rw-rw-r--  1 mostafa mostafa   29 Jun  8 11:27 HEAD
drwxrwxr-x  2 mostafa mostafa 4096 Jun  6 16:49 hooks
-rw-rw-r--  1 mostafa mostafa 3347 Jun  8 11:27 index
drwxrwxr-x  2 mostafa mostafa 4096 Jun  6 16:49 info
drwxrwxr-x  3 mostafa mostafa 4096 Jun  6 16:49 logs
drwxrwxr-x 56 mostafa mostafa 4096 Jun  8 11:30 objects
-rw-rw-r--  1 mostafa mostafa   41 Jun  8 11:26 ORIG_HEAD
-rw-rw-r--  1 mostafa mostafa  499 Jun  8 11:26 packed-refs
drwxrwxr-x  6 mostafa mostafa 4096 Jun  6 16:51 refs
```

Command:

```bash
cat .git/HEAD
```

Output:

```text
ref: refs/heads/feature/lab2
```

Command:

```bash
ls .git/refs/heads/
```

Output:

```text
feature  main
```

Command:

```bash
ls .git/objects/ | head
```

Output:

```text
00
0f
27
2b
34
38
49
4a
4b
54
```

Command:

```bash
find .git/objects -type f | wc -l
```

Output:

```text
69
```

Interpretation:

The `.git/HEAD` file points to the active branch reference, `refs/heads/feature/lab2`. The `.git/refs/heads/` directory contains local branch references, including `main` and the `feature/` directory. The `.git/objects/` directory stores Git objects by the first two hexadecimal characters of their SHA, and this repository had 69 loose object files at the time of inspection.

### 1.3 Simulate disaster and recover

Commands:

```bash
echo "# Lab 2 Submission" > submissions/lab2.md
git add submissions/lab2.md
git commit -S -s -m "wip(lab2): start"
echo "more important work" >> submissions/lab2.md
git commit -S -s -am "wip(lab2): more progress"
```

Output:

```text
[feature/lab2 32d6bbd] wip(lab2): start
 1 file changed, 1 insertion(+)
 create mode 100644 submissions/lab2.md
[feature/lab2 3a32244] wip(lab2): more progress
 1 file changed, 1 insertion(+)
```

Command:

```bash
git reset --hard HEAD~2
```

Output:

```text
HEAD is now at fc23294 test: unsigned commit (should fail)
```

Command:

```bash
git status
```

Output:

```text
On branch feature/lab2
nothing to commit, working tree clean
```

Command:

```bash
git log --oneline
```

Output excerpt:

```text
fc23294 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) test: unsigned commit (should fail)
e5e8d78 Merge branch 'main' of github.com:software-engineering-toolkit/DevOps-Intro
ad4d525 test: unsigned commit (should fail)
f6c165b test: unsigned commit (should fail)
96bd289 docs: add PR template
66bbd4d (upstream/main) docs(lab1): align Task 3 GitHub Community engagement with other courses
```

Command:

```bash
git reflog
```

Output:

```text
fc23294 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{0}: reset: moving to HEAD~2
3a32244 HEAD@{1}: commit: wip(lab2): more progress
32d6bbd HEAD@{2}: commit: wip(lab2): start
fc23294 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{3}: checkout: moving from main to feature/lab2
fc23294 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{4}: reset: moving to HEAD~1
f45c97c HEAD@{5}: checkout: moving from feature/lab2 to main
c002918 (origin/feature/lab1, feature/lab1) HEAD@{6}: checkout: moving from feature/lab1 to feature/lab2
c002918 (origin/feature/lab1, feature/lab1) HEAD@{7}: commit: Updating lab file
6ee25e1 HEAD@{8}: commit: Updating images
ff3dd17 HEAD@{9}: commit: Updating images paths
58f0a9b HEAD@{10}: commit: docs(lab1): update submission with new images and restructure tasks
```

Recovery command:

```bash
git reset --hard 3a32244
```

Output:

```text
HEAD is now at 3a32244 wip(lab2): more progress
```

Command:

```bash
git status
```

Output:

```text
On branch feature/lab2
nothing to commit, working tree clean
```

The restore SHA was `3a32244` because it was the most recent lost commit, `wip(lab2): more progress`. Since that commit was created on top of `32d6bbd`, resetting to `3a32244` restored both lost Lab 2 commits.

If `git gc` had run aggressively between the bad reset and the recovery, the unreachable commit objects could eventually have been pruned. In a normal local repository, reflog entries usually protect recent commits for a grace period, but that protection depends on Git's garbage collection settings. The safest recovery step is to copy the wanted reflog SHA immediately and restore it before experimenting further.

## Task 2 - Tag a Release and Rebase a Feature

### 2.1 Annotated, signed release tag

Commands:

```bash
git switch main
git pull --ff-only upstream main
git tag -a -s "v0.1.0-lab2-${USER}" -m "Lab 2 milestone - version control deep dive"
git push origin "v0.1.0-lab2-${USER}"
```

Output:

```text
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
From https://github.com/inno-devops-labs/DevOps-Intro
 * branch            main       -> FETCH_HEAD
Already up to date.
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 417 bytes | 417.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0
To github.com:software-engineering-toolkit/DevOps-Intro.git
 * [new tag]         v0.1.0-lab2-mostafa -> v0.1.0-lab2-mostafa
```

Command:

```bash
git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'
```

Output:

```text
v0.0.1 tag commit
v0.1.0-lab2-mostafa tag commit
```

The `v0.1.0-lab2-mostafa tag commit` line shows that the release tag is an annotated tag object that points to a commit.

Command:

```bash
git tag -v "v0.1.0-lab2-${USER}"
```

Output:

```text
object fc232949952da1c22808b27a4daf4d765eae728b
type commit
tag v0.1.0-lab2-mostafa
tagger Mostafa Kira <m.kira@innopolis.university> 1780910758 +0300

Lab 2 milestone - version control deep dive
Good "git" signature for m.kira@innopolis.university with ED25519 key SHA256:QT/alMbAtk5/wi2J6KpxQn16LgNmkOSTkeh/Q1al2QY
```

The `Good "git" signature` line confirms that the tag signature was valid.

### 2.2 Rebase and force-with-lease

Before rebase, I switched back to `feature/lab2` and captured the branch graph.

Command:

```bash
git switch feature/lab2
git log --oneline --graph --decorate --all -n 20
```

Output:

```text
Switched to branch 'feature/lab2'
Your branch is up to date with 'origin/feature/lab2'.
* 92c0af7 (HEAD -> feature/lab2, origin/feature/lab2) Solving task 1
* 3a32244 wip(lab2): more progress
* 32d6bbd wip(lab2): start
* fc23294 (tag: v0.1.0-lab2-mostafa, origin/main, origin/HEAD, main) test: unsigned commit (should fail)
*   e5e8d78 Merge branch 'main' of github.com:software-engineering-toolkit/DevOps-Intro
|\
| * f6c165b test: unsigned commit (should fail)
* | ad4d525 test: unsigned commit (should fail)
|/
* 96bd289 docs: add PR template
| * c002918 (origin/feature/lab1, feature/lab1) Updating lab file
| * 6ee25e1 Updating images
```

Then I simulated `main` moving while the feature branch was in progress.

Commands:

```bash
git switch main
git commit -S -s --allow-empty -m "docs: upstream moved while you worked"
git push origin main
```

Output:

```text
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
[main 84a9832] docs: upstream moved while you worked

Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 458 bytes | 458.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0
To github.com:software-engineering-toolkit/DevOps-Intro.git
   fc23294..84a9832  main -> main
```

After that, I rebased `feature/lab2` onto the updated `origin/main`.

Commands:

```bash
git switch feature/lab2
git fetch origin
git rebase origin/main
git status
```

Output:

```text
Switched to branch 'feature/lab2'
Your branch is up to date with 'origin/feature/lab2'.
Successfully rebased and updated refs/heads/feature/lab2.
On branch feature/lab2
Your branch and 'origin/feature/lab2' have diverged,
and have 4 and 3 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

nothing to commit, working tree clean
```

I also ran `git rebase --continue` afterward, but Git reported that there was no rebase left to continue because the rebase had already finished successfully.

Command:

```bash
git rebase --continue
```

Output:

```text
fatal: No rebase in progress?
```

After rebase, I captured the branch graph again.

Command:

```bash
git log --oneline --graph --decorate --all -n 20
```

Output:

```text
*   c427df8 (HEAD -> feature/lab2, origin/feature/lab2) Merge branch 'feature/lab2' of github.com:software-engineering-toolkit/DevOps-Intro into feature/lab2
|\
| * 92c0af7 Solving task 1
| * 3a32244 wip(lab2): more progress
| * 32d6bbd wip(lab2): start
* | 9e9b286 Solving task 1
* | c457fc0 wip(lab2): more progress
* | b7dbc03 wip(lab2): start
* | 84a9832 (origin/main, origin/HEAD, main) docs: upstream moved while you worked
|/
* fc23294 (tag: v0.1.0-lab2-mostafa) test: unsigned commit (should fail)
```

Finally, I pushed the feature branch with `--force-with-lease`.

Command:

```bash
git push --force-with-lease origin feature/lab2
```

Output:

```text
Everything up-to-date
```

### 2.3 Merge vs rebase reflection

I would choose rebase for a private feature branch when I want to replay my work on top of the latest `main` and keep the PR history easier to read. I would choose merge when the branch is shared with other people or when preserving the exact historical integration point is more important than a linear history. I would avoid rebasing commits that other people may already have based work on, because rewriting shared history can disrupt their branches.
