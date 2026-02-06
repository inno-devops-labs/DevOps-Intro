# Lab 1 Submission — Version Control & Advanced Git

**Student:** Diana Minnakhmetova
**Date:** 07-02-2026

---

## Task 1

[X] All command outputs for object inspection.

[X] A 1–2 sentence explanation of what each object type represents.

[X] Analysis of how Git stores repository data.

[X] Example of blob, tree, and commit object content.

### 1.1 Sample Commits Created

Created a test file and committed it:

```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "Test content" > test.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git add test.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat test.txt
Test content
```

### 1.2 Git Objects Inspection

**Step 1: Get commit hash**

```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git log --oneline -1
97fa04a (HEAD -> feature/lab2, origin/main, origin/HEAD, main) feat: add PR template
```

**Step 2: Inspect commit (get tree hash)**
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git cat-file -t HEAD
commit
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git cat-file -p HEAD
tree 93a278bb933629b424592fd082690049d49a8d1f
parent 97fa04a9ab52ac0a6cc7f3ce6a80cba705a0122e
author d.minnakhmetova <d.minnakhmetova@innopolis.university> 1770405471 +0300
committer d.minnakhmetova <d.minnakhmetova@innopolis.university> 1770405471 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAg9/03d56TF63uUejbUr94J4SWx4
 cXBXCdoIz4Vu9bq7EAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQFJitl9mCpddPCjvF18k9dZUmsINFJc3mR8lm2DjO8uy1QoTowku+L4oKGFheUTx8A
 kJ2Yj3TQum7oWFYV3xow4=
 -----END SSH SIGNATURE-----

Add test file
```

**Step 3: Inspect tree (get blob hash)**
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git cat-file -t 93a278bb933629b424592fd082690049d49a8d1f
tree
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git cat-file -p 93a278bb933629b424592fd082690049d49a8d1f
040000 tree 2ab7b3c7679e8cb698ff11802dc937457138ca32    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree eb79e5a468ab89b024bd4f3ed867c6a3954fe1f0    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt
```

**Step 4: Inspect blob (get content)**
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git cat-file -t 2eec599a1130d2ff231309bb776d1989b97c6ab2
blob
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git cat-file -p 2eec599a1130d2ff231309bb776d1989b97c6ab2
Test content
```

### 1.3 Analysis

#### What each object represents:

**Blob:** Raw file content. Git stores the actual data ("Test content") as a blob, identified by its SHA-1 hash. Identical content always produces the same hash, enabling deduplication.

**Tree:** Directory snapshot. A tree is a list of blobs and subtrees with their names and permissions. It's like a filesystem directory listing. Each tree points to specific blob versions, capturing the exact state of files at one moment.

**Commit:** Historical wrapper. A commit contains:
  - A tree (snapshot of all files)
  - Parent commits (creating a chain)
  - Metadata (author, timestamp, message)
  - Cryptographic signature for integrity

**How Git stores data:**

Git uses a **content-addressable storage** model. Each object (blob, tree, commit) is hashed (SHA-1), and the hash becomes its permanent ID. Git stores these objects in `.git/objects/`. The directed acyclic graph structure — where commits point to parents—creates the history chain. Because hashes are deterministic based on content, identical files share the same blob across commits and any tampering changes the hash.

## Task 2 — Reset and Reflog Recovery

[X] The exact commands you ran and why.

[X] Snippets of git log --oneline and git reflog.

[X] What changed in the working tree, index, and history for each reset.

[X] Analysis of recovery process using reflog.


### 2.1 Practice Branch Setup

Created a practice branch with 3 commits:

```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git switch -c git-reset-practice
Переключились на новую ветку «git-reset-practice»
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git branch
  feature/lab1
  feature/lab2
* git-reset-practice
  main
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "First commit" > file.txt && git add file.txt && git commit -m "First commit"
[git-reset-practice 8ba871d] First commit
 1 file changed, 1 insertion(+)
 create mode 100644 file.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "Second commit" >> file.txt && git add file.txt && git commit -m "Second commit"
[git-reset-practice 0d0d8cf] Second commit
 1 file changed, 1 insertion(+)
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "Third commit"  >> file.txt && git add file.txt && git commit -m "Third commit"
[git-reset-practice 9a547b4] Third commit
 1 file changed, 1 insertion(+)
```

### 2.2 Reset Modes Explored

**Initial state (before reset):**
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git log --oneline
9a547b4 (HEAD -> git-reset-practice) Third commit
0d0d8cf Second commit
8ba871d First commit
08eabbe (feature/lab2) docs: task 1 - git object model exploration
91caa5f Add test file
97fa04a (origin/main, origin/HEAD, main) feat: add PR template
d6b6a03 Update lab2
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

**Test 1: git reset --soft HEAD~1**

Command:
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git reset --soft HEAD~1 
```

Status after soft reset:
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git status
Текущая ветка: git-reset-practice
Изменения, которые будут включены в коммит:
  (используйте «git restore --staged <файл>...», чтобы убрать из индекса)
        изменено:      file.txt

Изменения, которые не в индексе для коммита:
  (используйте «git add <файл>...», чтобы добавить файл в индекс)
  (используйте «git restore <файл>...», чтобы отменить изменения в рабочем каталоге)
        изменено:      labs/submission2.md
```

Log after soft reset:
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git log --oneline -3
0d0d8cf (HEAD -> git-reset-practice) Second commit
8ba871d First commit
08eabbe (feature/lab2) docs: task 1 - git object model exploration
```

**What changed:**
1) HEAD moved from 9a547b4 → 0d0d8cf
2) Index: Changes staged (file.txt modifications are in staging area)
3) Working tree: Unchanged (file still contains all 3 lines)
3) The "Third commit" is unreachable but still exists in reflog


**Test 2: git reset --hard HEAD~1**

Command:
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git reset --hard HEAD~1
Указатель HEAD сейчас на коммите 8ba871d First commit
```

Log after hard reset:
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git log --oneline -3
8ba871d (HEAD -> git-reset-practice) First commit
08eabbe (feature/lab2) docs: task 1 - git object model exploration
91caa5f Add test file
```

**What changed:**
1) HEAD moved to 8ba871d
2) Index: Cleared
3) Working tree: Reverted to "First commit" state (file.txt has only "First commit" line)
4) Both "Second commit" (0d0d8cf) and "Third commit" (9a547b4) are now unreachable


**Test 3: git reflog (Recovery)**

```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git reflog
8ba871d (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
0d0d8cf HEAD@{1}: reset: moving to HEAD~1
9a547b4 HEAD@{2}: commit: Third commit
0d0d8cf HEAD@{3}: commit: Second commit
8ba871d (HEAD -> git-reset-practice) HEAD@{4}: commit: First commit
08eabbe (feature/lab2) HEAD@{5}: checkout: moving from feature/lab2 to git-reset-practice
08eabbe (feature/lab2) HEAD@{6}: commit: docs: task 1 - git object model exploration
91caa5f HEAD@{7}: commit: Add test file
97fa04a (origin/main, origin/HEAD, main) HEAD@{8}: checkout: moving from main to feature/lab2
97fa04a (origin/main, origin/HEAD, main) HEAD@{9}: checkout: moving from feature/lab1 to main
e02372e (origin/feature/lab1, feature/lab1) HEAD@{10}: commit: docs: add lab1 submission
43d9753 HEAD@{11}: commit: docs: add lab1 submission stub
206c1df HEAD@{12}: checkout: moving from main to feature/lab1
97fa04a (origin/main, origin/HEAD, main) HEAD@{13}: commit: feat: add PR template
d6b6a03 HEAD@{14}: checkout: moving from feature/lab1 to main
206c1df HEAD@{15}: commit: docs: add commit signing summary
0a558e3 HEAD@{16}: commit: docs: add commit signing summary
d6b6a03 HEAD@{17}: checkout: moving from main to feature/lab1
d6b6a03 HEAD@{18}: clone: from https://github.com/mnkhmtv/DevOps-Intro.git
```

Recovery command:
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git reset --hard 9a547b4
Указатель HEAD сейчас на коммите 9a547b4 Third commit
```

Log after recovery:
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git log --oneline -3
9a547b4 (HEAD -> git-reset-practice) Third commit
0d0d8cf Second commit
8ba871d First commit
```

**Result:** The lost commits are recovered

### 2.3 Analysis

**Reset modes explained:**

**`--soft`:** Moves HEAD to the target commit, but keeps the index and working tree intact. Useful when you want to restructure commits — you can keep your changes staged and recommit them differently.

**`--hard`:** Moves HEAD, clears the index, and reverts the working tree to match the target commit. Everything is discarded. Use with caution, but remember: nothing is truly lost while it's in reflog.

**`--mixed` (default):** Moves HEAD and clears the index, but keeps working tree changes. Useful for unstaging changes without losing them.

**Reflog rescue:**

Git's reflog keeps a record of HEAD movements for ~90 days. Even after `git reset --hard`, commits aren't deleted immediately—they become orphaned (unreachable from any branch). Reflog lets you recover them by resetting to their hash. This is why reflog is essential: it's your safety net for accidental history rewrites. Always check reflog before panicking!


## Task 3 — Visualize Commit History

[X] A snippet of the graph.

[X] Commit messages list.

[X] A 1–2 sentence reflection on how the graph aids understanding.

### 3.1 Graph Creation

Created a short-lived branch with a commit:

```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git switch -c side-branch
Переключились на новую ветку «side-branch»
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "Branch commit" >> history.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git branch
  feature/lab1
  feature/lab2
  git-reset-practice
  main
* side-branch
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git add history.txt && git commit -m "Side branch commit"
[side-branch 0923100] Side branch commit
 1 file changed, 1 insertion(+)
 create mode 100644 history.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git switch -
Переключились на ветку «feature/lab2»
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git branch
  feature/lab1
* feature/lab2
  git-reset-practice
  main
  side-branch
```

### 3.2 Graph Output

```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git log --oneline --graph --all
* 0923100 (side-branch) Side branch commit
* 79342bb (HEAD -> feature/lab2) docs: task 2 - reset and reflog recovery
| * 9a547b4 (git-reset-practice) Third commit
| * 0d0d8cf Second commit
| * 8ba871d First commit
|/  
* 08eabbe docs: task 1 - git object model exploration
* 91caa5f Add test file
* 97fa04a (origin/main, origin/HEAD, main) feat: add PR template
| * e02372e (origin/feature/lab1, feature/lab1) docs: add lab1 submission
| * 43d9753 docs: add lab1 submission stub
| * 206c1df docs: add commit signing summary
| * 0a558e3 docs: add commit signing summary
|/  
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
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

### 3.3 Reflection

The `--graph` flag visually represents the branching structure as ASCII art. Each `*` is a commit, `|` represents a branch line, and `/` or `\` show divergence and convergence points. This makes it immediately clear which commits belong to which branches and where they split/merge. Far better than a linear list for understanding the repository's structure and development history.


## Task 4 — Tagging Commits

[X] Tag names and commands used.

[X] Associated commit hashes.

[X] A short note on why tags matter (versioning, CI/CD triggers, release notes).

### 4.1 Tags Created

```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git tag v1.0.0
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git tag
v1.0.0
```

### 4.2 Tag Information

**v1.0.0:** Points to commit `c5a1625` (docs: task 3 - visualize commit history)

Verified with:
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git show v1.0.0
commit c5a16250fa7ff393af59b1ca97c2bd3f51dc3af0 (HEAD -> feature/lab2, tag: v1.0.0)
Author: d.minnakhmetova <d.minnakhmetova@innopolis.university>
Date:   Fri Feb 6 23:42:55 2026 +0300

    docs: task 3 - visualize commit history

diff --git a/labs/submission2.md b/labs/submission2.md
index 7c24b8a..7005b2d 100644
--- a/labs/submission2.md
+++ b/labs/submission2.md
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git rev-parse v1.0.0
c5a16250fa7ff393af59b1ca97c2bd3f51dc3af0
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git push origin v1.0.0
Перечисление объектов: 21, готово.
Подсчет объектов: 100% (21/21), готово.
При сжатии изменений используется до 8 потоков
Сжатие объектов: 100% (18/18), готово.
Запись объектов: 100% (19/19), 6.55 КиБ | 6.55 МиБ/с, готово.
Total 19 (delta 13), reused 0 (delta 0), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (13/13), completed with 1 local object.
To https://github.com/mnkhmtv/DevOps-Intro.git
 * [new tag]         v1.0.0 -> v1.0.0
```

### 4.3 Why Tags Matter

Tags mark specific points in history for releases and versioning. CI/CD pipelines often trigger builds on new tags, automating deployment workflows. Tags make it easy to find release versions without scrolling through hundreds of commits. They also improve discoverability on GitHub—each release gets its own "Release" page with downloads and release notes. Tags are essential for semantic versioning (v1.0.0, v1.1.0, etc.) and help teams quickly identify which code corresponds to which production version.


## Task 5 — git switch vs checkout vs restore

[X] Commands you ran and their outputs.

[X] git status/git branch outputs showing state changes.

[X] 2–3 sentences on when to use each command.

### 5.1 Commands Tested

**Option A: git switch (Modern - Recommended)**

Creating and switching to a branch:
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git switch -c cmd-compare
Переключились на новую ветку «cmd-compare»
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git branch
* cmd-compare
  feature/lab1
  feature/lab2
  git-reset-practice
  main
  side-branch
```

Toggling back to previous branch:
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git switch -
Переключились на ветку «feature/lab2»
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git branch
  cmd-compare
  feature/lab1
* feature/lab2
  git-reset-practice
  main
  side-branch
```


**Option B: git checkout (Legacy - Overloaded)**

Creating and switching with legacy command:
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git checkout -b cmd-compare-2
Переключились на новую ветку «cmd-compare-2»
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git branch
  cmd-compare
* cmd-compare-2
  feature/lab1
  feature/lab2
  git-reset-practice
  main
  side-branch
```

Note: `git checkout` can also be used for file operations (`git checkout -- <file>`), which makes it confusing. Modern Git separates concerns with `git switch` (branches) and `git restore` (files).


**Option C: git restore (Modern - File Operations)**

Setup - create test file:
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "Demo code" > demo.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git add demo.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git commit -m "Add demo file"
[feature/lab2 501507e] Add demo file
 1 file changed, 1 insertion(+)
 create mode 100644 demo.txt
```

Test 1 - Discard working tree changes:
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "scratch" >> demo.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat demo.txt
Demo code
scratch

dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git status
Текущая ветка: feature/lab2
Изменения, которые не в индексе для коммита:
  (используйте «git add <файл>...», чтобы добавить файл в индекс)
  (используйте «git restore <файл>...», чтобы отменить изменения в рабочем каталоге)
        изменено:      demo.txt

Неотслеживаемые файлы:
  (используйте «git add <файл>...», чтобы добавить в то, что будет включено в коммит)
        .DS_Store

индекс пуст (используйте «git add» и/или «git commit -a»)

dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git restore demo.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat demo.txt
Demo code

dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git status
Текущая ветка: feature/lab2
Неотслеживаемые файлы:
  (используйте «git add <файл>...», чтобы добавить в то, что будет включено в коммит)
        .DS_Store

индекс пуст, но есть неотслеживаемые файлы
(используйте «git add», чтобы проиндексировать их)
```


Test 2 - Restore from another commit:
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git restore --staged demo.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git restore --source=HEAD~1 demo.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat demo.txt
cat: demo.txt: No such file or directory
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git status
Текущая ветка: feature/lab2
Изменения, которые не в индексе для коммита:
  (используйте «git add/rm <файл>...», чтобы добавить или удалить файл из индекса)
  (используйте «git restore <файл>...», чтобы отменить изменения в рабочем каталоге)
        удалено:       demo.txt

Неотслеживаемые файлы:
  (используйте «git add <файл>...», чтобы добавить в то, что будет включено в коммит)
        .DS_Store

индекс пуст (используйте «git add» и/или «git commit -a»)
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git restore demo.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat demo.txt

Demo code
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git status
Текущая ветка: feature/lab2
Неотслеживаемые файлы:
  (используйте «git add <файл>...», чтобы добавить в то, что будет включено в коммит)
        .DS_Store

индекс пуст, но есть неотслеживаемые файлы
(используйте «git add», чтобы проиндексировать их)
```

### 5.2 When to Use Each Command

**`git switch`:** Use for **branch operations only**. Modern, clear, and focused. Replaces `git checkout <branch>`. Examples: switching branches, creating new branches, toggling between two branches with `git switch -`.

**`git checkout`:** Legacy command that does too many things (branches AND files). Still works, but avoid in new workflows. Only use if you're working with older team standards. The confusion between branch and file operations was why Git split this into `switch` and `restore`.

**`git restore`:** Use for **file operations only**. Modern replacement for `git checkout -- <file>`. Three main uses:
1) Discard working tree changes: `git restore <file>`
2) Unstage without losing changes: `git restore --staged <file>`
3) Restore from a specific commit: `git restore --source=<commit> <file>`

**Best Practice:** Use `git switch` for branches and `git restore` for files. Avoid `git checkout` in new code—it's confusing and outdated.

## Task 6 — GitHub Community Engagement

### 6.1 Actions Completed

[X] Starred the [course repository](https://github.com/inno-devops-labs/DevOps-Intro)

[X] Starred [simple-container-com/api](https://github.com/simple-container-com/api)

[X] Followed [@Cre-eD](https://github.com/Cre-eD) (Professor)

[X] Followed [@marat-biriushev](https://github.com/marat-biriushev) (TA)

[X] Followed [@pierrepicaud](https://github.com/pierrepicaud) (TA)

[X] Followed 3 classmates on GitHub: [Arthur](https://github.com/ArthurBabkin), [Danis](https://github.com/DanisSharafiev), [Janna](https://github.com/iJeannne)

### 6.2 GitHub Community Impact

**Why starring matters in open source:**

Stars serve as bookmarks for valuable projects and signal community appreciation. A high star count indicates project quality, maturity, and adoption—helping others discover reliable tools. Starring shows you actively evaluate open-source work and respect maintainers' efforts. On your GitHub profile, stars demonstrate awareness of industry best practices and quality tools relevant to your tech stack.

**How following developers helps:**

Following developers keeps you informed about their projects, contributions, and professional growth. In team collaborations, it builds awareness of teammates' interests and work patterns. Professionally, it expands your network, helps you discover emerging trends, and connects you with thought leaders in your field. Following classmates strengthens your learning community and makes it easier to find future project partners.
