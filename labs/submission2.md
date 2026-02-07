1) Task 1
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git cat-file -p 418a98ced2ac70b5bdee0be9732ecdaae7264515
��Test content

PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git cat-file -p 51fca9b718f1b61012f84f6941b2dafe21bb7453
040000 tree 0612e4a8fde5e7ac428588c73a9e40fb67213e4b    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree 5226d64a6fb1c2c3313ef015b2f2c1ae309a5e3b    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 418a98ced2ac70b5bdee0be9732ecdaae7264515    test.txt

PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git cat-file -p 659450b
tree 51fca9b718f1b61012f84f6941b2dafe21bb7453
parent 6bcb40f7e2c821460907c8a3ed4b472cfb141d7d
author Ilya Prockofiev <125394064+somepatt@users.noreply.github.com> 1770462499 +0300
committer Ilya Prockofiev <125394064+somepatt@users.noreply.github.com> 1770462499 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgbtCXVS0Sr/0c0TLbJUixn3uxB4
 5LVfH/p42Wi8fDuiUAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQNl6YgvDs/BE1dWpxCfqhAcahIguHlgMTi2t2YmIUg/w0Kh41X53Wa6Oj6AnvY9QsR
 QGddbovP154EUo6cSm5Ao=
 -----END SSH SIGNATURE-----

Add test file

Blob - содержит данные файла
Commit - содержит метаданные файла: указатель на tree, parent, автора, сообщение
Tree - содержит данные о файлах и поддиректориях в текущей дериктории

Каждый объект индентифицируется по SHA-1 хешу и его содержимого

2) Task 2
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> echo "First commit" > file.txt
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git add file.txt
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git commit -m "First commit"
[get-reset-practice bf91060] First commit
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 file.txt
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> echo "Second commit" >> file.txt
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git add file.txt
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git commit -m "Second commit"
[get-reset-practice 8042707] Second commit
 1 file changed, 0 insertions(+), 0 deletions(-)
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> echo "Third commit"  >> file.txt
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git add file.txt
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git commit -m "Third commit"
[get-reset-practice 77a2a9d] Third commit
 1 file changed, 0 insertions(+), 0 deletions(-)
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git reset --soft HEAD~1
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git reset --hard HEAD~1
HEAD is now at bf91060 First commit
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git reflog 
bf91060 (HEAD -> get-reset-practice) HEAD@{0}: reset: moving to HEAD~1
8042707 HEAD@{1}: reset: moving to HEAD~1
77a2a9d HEAD@{2}: commit: Third commit
8042707 HEAD@{3}: commit: Second commit
bf91060 (HEAD -> get-reset-practice) HEAD@{4}: commit: First commit
659450b (feature/lab2) HEAD@{5}: checkout: moving from feature/lab2 to get-reset-practice
659450b (feature/lab2) HEAD@{6}: commit: Add test file
6bcb40f (origin/feature/lab1, feature/lab1) HEAD@{7}: checkout: moving from feature/lab1 to feature/lab2
6bcb40f (origin/feature/lab1, feature/lab1) HEAD@{8}: commit: docs: add lab1 submission
b5da1d3 HEAD@{9}: pull: Merge made by the 'ort' strategy.
78a14f5 HEAD@{10}: commit: prove
505a980 HEAD@{11}: reset: moving to HEAD
505a980 HEAD@{12}: commit: prove
8f17664 HEAD@{13}: commit: docs: add lab1 submission stub
10d097f (main) HEAD@{14}: checkout: moving from main to feature/lab1
10d097f (main) HEAD@{15}: reset: moving to HEAD~1
44c24b2 HEAD@{16}: commit: new doc
10d097f (main) HEAD@{17}: commit: docs: add commit signing summary
d6b6a03 HEAD@{18}: clone: from https://github.com/somepatt/DevOps-Intro.git
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git reset --hard 77a2a9d      
HEAD is now at 77a2a9d Third commit
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git reset --hard HEAD~2
HEAD is now at bf91060 First commit
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git reflog
bf91060 (HEAD -> get-reset-practice) HEAD@{0}: reset: moving to HEAD~2
77a2a9d HEAD@{1}: reset: moving to 77a2a9d
bf91060 (HEAD -> get-reset-practice) HEAD@{2}: reset: moving to HEAD~1
8042707 HEAD@{3}: reset: moving to HEAD~1
77a2a9d HEAD@{4}: commit: Third commit
8042707 HEAD@{5}: commit: Second commit
bf91060 (HEAD -> get-reset-practice) HEAD@{6}: commit: First commit
659450b (feature/lab2) HEAD@{7}: checkout: moving from feature/lab2 to get-reset-practice
659450b (feature/lab2) HEAD@{8}: commit: Add test file
6bcb40f (origin/feature/lab1, feature/lab1) HEAD@{9}: checkout: moving from feature/lab1 to feature/lab2
6bcb40f (origin/feature/lab1, feature/lab1) HEAD@{10}: commit: docs: add lab1 submission
b5da1d3 HEAD@{11}: pull: Merge made by the 'ort' strategy.
78a14f5 HEAD@{12}: commit: prove
505a980 HEAD@{13}: reset: moving to HEAD
505a980 HEAD@{14}: commit: prove
8f17664 HEAD@{15}: commit: docs: add lab1 submission stub
10d097f (main) HEAD@{16}: checkout: moving from main to feature/lab1
10d097f (main) HEAD@{17}: reset: moving to HEAD~1
44c24b2 HEAD@{18}: commit: new doc
10d097f (main) HEAD@{19}: commit: docs: add commit signing summary
d6b6a03 HEAD@{20}: clone: from https://github.com/somepatt/DevOps-Intro.git
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git reset --hard 77a2a9d
HEAD is now at 77a2a9d Third commit

3) Task 3
PS C:\Users\Mi\Desktop\projects\DevOps-Intro> git log --oneline --graph --all
* ea9d53a (side-branch) Side branch commit
* 77a2a9d (HEAD -> get-reset-practice) Third commit
* 8042707 Second commit
* bf91060 First commit
* 659450b (feature/lab2) Add test file
* 6bcb40f (origin/feature/lab1, feature/lab1) docs: add lab1 submission
*   b5da1d3 Merge branch 'feature/lab1' of https://github.com/somepatt/DevOps-Intro into feature/lab1
|\  
* | 78a14f5 prove
* | 505a980 prove
| | *   9688b20 (origin/main, origin/HEAD) Merge pull request #1 from somepatt/feature/lab1
| | |\  
| | |/  
| |/|   
| * | 45ebb74 Merge branch 'main' into feature/lab1
|/| |
| |/
| * 44c24b2 new doc
* | 8f17664 docs: add lab1 submission stub
|/
* 10d097f (main) docs: add commit signing summary
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

![alt text](image-3.png)

Граф помогает понять историю коммитов последовательно.