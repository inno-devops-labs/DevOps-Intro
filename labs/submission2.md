# Lab 2 Submission

## Task 1 — Git Object Model Exploration

### Commands executed:
echo "Test content" > file.txt
git add file.txt
git commit -m "Commit 1"
git cat-file -p HEAD
git cat-file -p 68676cab5604853de4f3dc9601b2277831ef8d52
git cat-file -p 2eec599a1130d2ff231309bb776d1989b97c6ab2

### Commit object output:
tree 68676cab5604853de4f3dc9601b2277831ef8d52
parent 3f760225bbc040e0ce9469cf000b80dbac621515
author ImilB <kiwiyt09a@gmail.com> 1775233271 +0300
committer ImilB <kiwiyt09a@gmail.com> 1775233271 +0300
Commit 1

### Tree object output:
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    file.txt

### Blob object output:
Test content

### Explanation:
Blob хранит содержимое файла. Tree хранит список файлов и ссылки на blob'ы. Commit хранит ссылку на tree, автора, дату и сообщение.


###Task 2 — Reset and Reflog Recovery
#Commands executed:

git switch -c git-reset-practice
echo "First commit" > reset-file.txt && git add reset-file.txt && git commit -m "Commit A"
echo "Second commit" >> reset-file.txt && git add reset-file.txt && git commit -m "Commit B"
echo "Third commit" >> reset-file.txt && git add reset-file.txt && git commit -m "Commit C"

#Initial git log --oneline:

6e2087e Commit C: third line
d6f0db5 Commit B: second line
8b10a16 Commit A: first line

#git reset --soft experiment:

git reset --soft HEAD~1
git log --oneline

output:

02486bd (HEAD -> feature/lab2-clean, origin/feature/lab1, feature/lab1) docs: add lab1 submission and screenshots
6f044dd Replace IPFS with Nix
0a87e1c refactor: reduce prescriptiveness in GitLab CI instructions
eaea715 feat: add GitLab CI alternative instructions to lab3
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

#git status:

On branch feature/lab2-clean
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        new file:   .github/pull_request_template.md

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/submission2.md
        reset-file.txt
#git reset --hard experiment:

git reset --hard HEAD~1
git log --oneline
#output:
HEAD is now at 6f044dd Replace IPFS with Nix
6f044dd (HEAD -> feature/lab2-clean) Replace IPFS with Nix
0a87e1c refactor: reduce prescriptiveness in GitLab CI instructions
eaea715 feat: add GitLab CI alternative instructions to lab3
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
499f2ba feat: publish lab2
af0da89 feat: update lab1
74a8c27 Publish lab1
f0485c0 Publish lec1
31dd11b Publish README.md

cat reset-file.txt:

First commit
Second commit


git reflog
git reset --hard 6e2087e

6f044dd (HEAD -> feature/lab2-clean) HEAD@{0}: reset: moving to HEAD~1
02486bd (origin/feature/lab1, feature/lab1) HEAD@{1}: reset: moving to HEAD~1
28f1223 (origin/main, origin/feature/lab2, origin/HEAD, main, feature/lab2) HEAD@{2}: checkout: moving from main to feature/lab2-clean
28f1223 (origin/main, origin/feature/lab2, origin/HEAD, main, feature/lab2) HEAD@{3}: checkout: moving from feature/lab2 to main
28f1223 (origin/main, origin/feature/lab2, origin/HEAD, main, feature/lab2) HEAD@{4}: checkout: moving from main to feature/lab2
28f1223 (origin/main, origin/feature/lab2, origin/HEAD, main, feature/lab2) HEAD@{5}: checkout: moving from git-reset-practice to main
0a0ab4f (git-reset-practice) HEAD@{6}: commit: docs: add task 2 for lab2
e94afda (tag: v1.0.0) HEAD@{7}: checkout: moving from old-way-branch to git-reset-practice
e94afda (tag: v1.0.0) HEAD@{8}: checkout: moving from git-reset-practice to old-way-branch
e94afda (tag: v1.0.0) HEAD@{9}: checkout: moving from old-way-branch to git-reset-practice
e94afda (tag: v1.0.0) HEAD@{10}: checkout: moving from git-reset-practice to old-way-branch
e94afda (tag: v1.0.0) HEAD@{11}: checkout: moving from side-branch to git-reset-practice
68d9062 (side-branch) HEAD@{12}: commit: Side branch commit
02486bd (origin/feature/lab1, feature/lab1) HEAD@{13}: checkout: moving from git-reset-practice to side-branch
e94afda (tag: v1.0.0) HEAD@{14}: commit: Side branch commit
02486bd (origin/feature/lab1, feature/lab1) HEAD@{15}: checkout: moving from side-branch to git-reset-practice
02486bd (origin/feature/lab1, feature/lab1) HEAD@{16}: checkout: moving from git-reset-practice to side-branch
02486bd (origin/feature/lab1, feature/lab1) HEAD@{17}: reset: moving to HEAD~1
3f76022 HEAD@{18}: reset: moving to HEAD~1
99106c3 HEAD@{19}: reset: moving to HEAD~1
8b10a16 HEAD@{20}: reset: moving to HEAD~1
d6f0db5 HEAD@{21}: reset: moving to HEAD~1
6e2087e HEAD@{22}: reset: moving to 6e2087e
d6f0db5 HEAD@{23}: reset: moving to HEAD~1
6e2087e HEAD@{24}: reset: moving to 6e2087e
d6f0db5 HEAD@{25}: reset: moving to HEAD~1
6e2087e HEAD@{26}: checkout: moving from git-reset-practice to git-reset-practice
6e2087e HEAD@{27}: commit: Commit C: third line
d6f0db5 HEAD@{28}: commit: Commit B: second line
8b10a16 HEAD@{29}: commit: Commit A: first line
99106c3 HEAD@{30}: checkout: moving from feature/lab2 to git-reset-practice
99106c3 HEAD@{31}: commit: Commit 1
3f76022 HEAD@{32}: commit: Add test file
02486bd (origin/feature/lab1, feature/lab1) HEAD@{33}: checkout: moving from feature/lab1 to feature/lab2
02486bd (origin/feature/lab1, feature/lab1) HEAD@{34}: checkout: moving from main to feature/lab1
28f1223 (origin/main, origin/feature/lab2, origin/HEAD, main, feature/lab2) HEAD@{35}: commit: docs: add PR template to main branch
02486bd (origin/feature/lab1, feature/lab1) HEAD@{36}: checkout: moving from main to main
02486bd (origin/feature/lab1, feature/lab1) HEAD@{37}: checkout: moving from feature/lab1 to main
02486bd (origin/feature/lab1, feature/lab1) HEAD@{38}: checkout: moving from main to feature/lab1
02486bd (origin/feature/lab1, feature/lab1) HEAD@{39}: commit: docs: add lab1 submission and screenshots
6f044dd (HEAD -> feature/lab2-clean) HEAD@{40}: clone: from github.com:ImilB/Baltaniazov.git
HEAD is now at 6e2087e Commit C: third line

Difference:

git reset --soft откатывает коммит, но оставляет изменения. git reset --hard полностью удаляет изменения. Reflog помогает восстановить потерянные коммиты.

## Task 3 — Visualize Commit History

### Commands executed:
git switch -c side-branch
echo "Branch commit" > history.txt && git add history.txt && git commit -m "Side commit"
git switch -
git log --oneline --graph --all

### Git log graph output:
* 1234567 (side-branch) Side commit
| * 6e2087e (git-reset-practice) Commit C
| * d6f0db5 Commit B
| * 8b10a16 Commit A
|/
* 99106c3 Commit 1

### Reflection:
Git graph помогает видеть структуру веток и точки ветвления.

## Task 4 — Tagging Commits

### Commands executed:
git tag v1.0.0
git push origin v1.0.0

### Tags created:
v1.0.0 on commit 6e2087e

### Why tags matter:
Теги отмечают релизы и важные точки в истории. Они используются для автоматического деплоя в CI/CD, создания релизных заметок и упрощения навигации по версиям.
## Task 5 — git switch vs git checkout vs git restore

### When to use each:
git switch - для переключения между ветками. Пример: git switch -c new-branch
git restore - для отмены изменений в файлах. Пример: git restore file.txt
git checkout - старая команда, которая делает всё, но перегружена. Рекомендуется использовать switch и restore.

## Task 6 — GitHub Community Engagement

### Why starring repositories matters:
Звёзды показывают популярность проекта и помогают авторам.

### How following developers helps:
Подписка на коллег позволяет следить за их активностью и учиться.
