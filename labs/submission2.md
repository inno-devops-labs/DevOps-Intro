# Lab 2 Submission

## Task 1: Git Object Model


$ git log --oneline -1


25e5541 (HEAD -> feature/lab2) Add test file

```
$ git cat-file -p 25e5541
tree abe22c39e214852ffa286a0d9d5bfdb1dc4eb999
parent 5f704ed3fc31d9f4e03b8133ea3d4779d4a9b577
author mishin-mikhail <mngtrfn@gmail.com> 1770561450 +0300
committer mishin-mikhail <mngtrfn@gmail.com> 1770561450 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgI4OohC2h8iqNW6WJLqyNEh099Q
 YY6s8ijzXoW3P8FeUAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQPF71FN4al9yvZaKoPmFDGs+CWhgAFn5SrSiY2oyyTA5TY+XsDeiYQqa5tAZ3hhgRi
 9TBlWAEKXKpiRkuV28HAA=
 -----END SSH SIGNATURE-----
```


```
$ git cat-file -p abe22c39e214852ffa286a0d9d5bfdb1dc4eb999
040000 tree b2efec4d0a10c0632fb5f32d67f7be429f5c2dd8    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree 81100a3c9af72daeedbf951ee0c5e6b4e5635866    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
```


$ git cat-file -p 6e60bebec0724892a7c82c52183d0a7b467cb6bb


# 🚀 DevOps Introduction Course: Principles, Practices & Tooling

[![Labs](https://img.shields.io/badge/Labs-80%25-blue)](#-lab-based-learning-experience)
[![Exam](https://img.shields.io/badge/Exam-20%25-orange)](#-evaluation-framework)
[![Hands-On](https://img.shields.io/badge/Focus-Hands--On%20Labs-success)](#-lab-based-learning-experience)
[![Duration](https://img.shields.io/badge/Duration-10%20Weeks-lightgrey)](#-course-roadmap)

Welcome to the **DevOps Introduction Course**, where you will gain a **solid foundation in DevOps principles and practical skills**.
This course is designed to provide a comprehensive understanding of DevOps and its key components.

Through **hands-on labs and lectures**, you'll explore version control, software distribution, CI/CD, containerization, cloud computing, and beyond — the same workflows used by modern engineering teams.

---

## 📚 Course Roadmap

**10-week intensive course** with practical modules designed for incremental skill development:


(Not full output)(too much text)


------------------------------------------------------------------------------------


**Questions:**


Blob object: blob represents the contents of a file in Git. It stores raw data without filenames or directory structure.

Tree object: tree represents a directory in Git. It contains references to blobs and other trees along with filenames and permissions.

Commit object: commit represents a snapshot of the repository at a specific point in time. It links to a tree object and includes metadata such as author, date, and commit message.

How Git stores repository data: all data as objects in a content-addressable database using SHA-1 (or SHA-256) hashes. Files are stored as blobs, directories as trees, and history as commits that reference other objects.

Example object contents:

Blob: plain text or binary file data

Tree: list of filenames with their blob or tree hashes

Commit: tree hash, parent commit hash(es), author/committer info, and commit message


## Task 2: Reset and Reflog


**Commands Executed and Purpose**


"git switch -c git-reset-practice":


New branch to safely practice git reset without affecting other branches.


*Commits creating:*


echo "First commit" > file.txt && git add file.txt && git commit -m "First commit"


echo "Second commit" >> file.txt && git add file.txt && git commit -m "Second commit"


echo "Third commit"  >> file.txt && git add file.txt && git commit -m "Third commit"


"git reset --soft HEAD~1":


Moved HEAD back by one commit while keeping changes from the last commit staged in the index.


"git reset --hard HEAD~1":


Moved HEAD back another commit and discarded changes from the working tree and index.


"git reflog":


Displayed the reference log to track previous HEAD positions and enable recovery.


"git reset --hard 14b0a79":


Recovered the repository state by resetting HEAD back to the commit labeled “Third commit”.


"git log --oneline" (snippet):


14b0a79 (HEAD -> git-reset-practice) Third commit


9434991 Second commit


54ee4e6 First commit


25e5541 (feature/lab2) Add test file


....................................................


"git reflog" (snippet):


14b0a79 (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to 14b0a79


54ee4e6 HEAD@{1}: reset: moving to HEAD~1


9434991 HEAD@{2}: reset: moving to HEAD~1


14b0a79 (HEAD -> git-reset-practice) HEAD@{3}: commit: Third commit


9434991 HEAD@{4}: commit: Second commit


54ee4e6 HEAD@{5}: commit: First commit


25e5541 (feature/lab2) HEAD@{6}: checkout: moving from feature/lab2 to git-reset-practice


**Effect of Each Reset**


"git reset --soft HEAD~1":


Working tree: No changes


Index (staging area): Changes from “Third commit” remained staged


Commit history: HEAD moved from “Third commit” to “Second commit”


"git reset --hard HEAD~1":


Working tree: Reverted to the state of “First commit”


Index: Cleared to match HEAD


Commit history: “Second commit” and “Third commit” were removed from the current branch history


Recovery Using Reflog


Although the commits were no longer visible in the branch history after the hard reset, they were still accessible through git reflog.


By identifying the commit hash 14b0a79 in the reflog and running git reset --hard 14b0a79, the repository was successfully restored to the state of the “Third commit”.


## Task 3: Visualization(snippet)


```
* c394079 (side-branch) Side branch commit
| * 14b0a79 (git-reset-practice) Third commit
| * 9434991 Second commit
| * 54ee4e6 First commit
|/
* 25e5541 (HEAD -> feature/lab2) Add test file
* 5f704ed (origin/feature/lab1, feature/lab1) docs: complete lab1 submission with eviden
* 9acd4b4 docs: complete lab1 submission with evidence
* b60dca8 chore: add pull request template
* 2f7abf4 docs: add lab1 submission draft
* d9f33d6 docs: add lab1 submission stub
* 16eadab (origin/main, origin/HEAD, main) docs: add pull request template
* 329111c docs: add commit signing summary
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10
* 1826c36 feat: update lab7
* 3049f08 feat: publish lec8
* da8f635 feat: introduce all labs and revised structure
* 04b174e feat: publish lab and lec #5
:...skipping...
* c394079 (side-branch) Side branch commit
| * 14b0a79 (git-reset-practice) Third commit
| * 9434991 Second commit
| * 54ee4e6 First commit
|/
* 25e5541 (HEAD -> feature/lab2) Add test file

```


The commit graph visually shows the linear sequence of commits with branch movements caused by reset operations. This visualization helps clearly understand how HEAD changes over time and how commits can be recovered using the reflog.


## Task 4: Tagging


**Commands used:**


```
git tag v1.0.0
git push origin v1.0.0
#Optional part
echo "..." >> test.txt && git commit ...
git tag v1.1.0
git push origin v1.1.0
```

**Tags and Hashes:**


commit 25e55416a155cd1359c4ba691d56c8e769da320c (tag: v1.0.0)

commit 3635a841ea9f2315b7bbd9e66ac38614b311bcc9 (HEAD -> feature/lab2, tag: v1.1.0)


**Why tags matter:**


Tags are critical for semantic versioning (marking release points). They allow CI/CD pipelines to automatically build and deploy specific versions of the software and generate release notes based on the differences between tags.


## Task 5: Switch vs Restore


**Commands and outputs:**


```
mngtr@MM MINGW64 ~/DevOps-Intro/labs (feature/lab2)
$ git switch cmd-compare
Switched to branch 'cmd-compare'

mngtr@MM MINGW64 ~/DevOps-Intro/labs (cmd-compare)
$ git switch -
Switched to branch 'feature/lab2'

mngtr@MM MINGW64 ~/DevOps-Intro/labs (feature/lab2)
$ echo "Initial content" > demo.txt

mngtr@MM MINGW64 ~/DevOps-Intro/labs (feature/lab2)
$ git add demo.txt
warning: in the working copy of 'labs/demo.txt', LF will be replaced by CRLF the next time Git touches it

mngtr@MM MINGW64 ~/DevOps-Intro/labs (feature/lab2)
$ git commit -m "Add demo file for restore practice"
Enter passphrase for "C:/Users/mngtr/.ssh/id_ed25519":
[feature/lab2 d368792] Add demo file for restore practice
 1 file changed, 1 insertion(+)
 create mode 100644 labs/demo.txt

mngtr@MM MINGW64 ~/DevOps-Intro/labs (feature/lab2)
$ echo "scratch - bad changes" >> demo.txt

mngtr@MM MINGW64 ~/DevOps-Intro/labs (feature/lab2)
$ git status
On branch feature/lab2
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   demo.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        submission2.md

no changes added to commit (use "git add" and/or "git commit -a")

mngtr@MM MINGW64 ~/DevOps-Intro/labs (feature/lab2)
$ git restore demo.txt

mngtr@MM MINGW64 ~/DevOps-Intro/labs (feature/lab2)
$ git status
On branch feature/lab2
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        submission2.md

nothing added to commit but untracked files present (use "git add" to track)

```


git switch is used specifically for changing branches and is safer and clearer than older commands because it cannot modify files.


git checkout is a legacy, multi-purpose command that can switch branches or restore files, but its mixed behavior can be confusing and error-prone.


git restore is used to discard or recover changes in the working directory or staging area without affecting branch history.


## GitHub Community


Starring repositories helps signal appreciation for a project, increases its visibility in the open-source community, and makes it easier to track useful tools or codebases.


Following developers helps you stay updated on their work, learn from their practices, and build professional connections within a team or the wider developer community.