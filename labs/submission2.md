## Задание 1

### Результаты выполненных команд

``` bash

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (feature/lab2)
$ git log --oneline -1
ea6d103 (HEAD -> feature/lab2) Add test file

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (feature/lab2)
$ git cat-file -p HEAD
tree 0b1af5dfbac819f4b038dfcab1dd239a2724795e
parent 0501766af31d6dead9956a6587e54bdc84aa5da0
author z0sh22 <dashamakeeva3000@gmail.com> 1770748679 +0300
committer z0sh22 <dashamakeeva3000@gmail.com> 1770748679 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
...
 -----END SSH SIGNATURE-----

Add test file

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (feature/lab2)
$ git cat-file -p 0b1af5dfbac819f4b038dfcab1dd239a2724795e
040000 tree 24a1f87f8f57cf1a2d4892e5bfe04dc80d9dad12    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree ae64d50b15dbf90ef3b7140501bc30344762b7d0    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (feature/lab2)
$ git cat-file -p 2eec599a1130d2ff231309bb776d1989b97c6ab2
Test content

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (feature/lab2)
$ git cat-file -p 0b1af5dfbac819f4b038dfcab1dd239a2724795e
040000 tree 24a1f87f8f57cf1a2d4892e5bfe04dc80d9dad12    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree ae64d50b15dbf90ef3b7140501bc30344762b7d0    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (feature/lab2)
$ git cat-file -p a1061247fd38ef2a568735939f86af7b1000f83c
100644 blob ece7bac66166c385e145b0a004d40973d7cc060c    index.html

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (feature/lab2)
$ git cat-file -p ae64d50b15dbf90ef3b7140501bc30344762b7d0
100644 blob 3160dd19bd05ce1496be0d8ead7011e0ab58bc63    image-1.png
100644 blob a54eeb406976a91fecbfd6ba32b1b80501f923d1    image-2.png
100644 blob a98a864c7ed7f4896c59316918eb82c581bfc2fc    image-3.png
100644 blob aa1129aa93b6fbd82ccd1607d2bcbb7cf0e2077d    image.png
100644 blob aa6b7b5c478b439d2c1e9b4f085257782dd68d25    lab1.md
100644 blob cf1ba99be683932b0a1e1cfd84f0d6f0dc0d184f    lab10.md
100644 blob ca6bbf33cb79a950fbf3c517e6b174ac65f5334b    lab11.md
040000 tree 16bf9eb348f7da4acbec0a94fc4a09e46c40064f    lab11
100644 blob fcd2509fd7a30ea3b5cc9e879f97fbb32d3e660d    lab12.md
040000 tree 129069dd8e40511c9ab6c889b375532b1d68fde3    lab12
100644 blob 3128f48b832e6592d02ae82a18f9b89af82c9658    lab2.md
100644 blob 6e453f5c97f02a4bca77db29549154072771ad4a    lab3.md
100644 blob 3aa4439565d04ff637e909ffc164d59a60749239    lab4.md
100644 blob 0435c3fcbd5d21b21cf253af0544a6536247cdb9    lab5.md
100644 blob af90a7fa02f582cd3d31f4d9f71360878f031e92    lab6.md
100644 blob ee11bdfb0d71048268ec439ad0c4ee2f7bf6fd1b    lab7.md
100644 blob 9df09119213b81f88f6b61c89f3bcf223a32ecf6    lab8.md
100644 blob 12e1b875e40d5ef91f11c36fb259f23069fc458f    lab9.md
100644 blob b1925ae955752c04fcceba2af3a584a7a155e674    submission1.md

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (feature/lab2)
$ git cat-file -p ea6d103
tree 0b1af5dfbac819f4b038dfcab1dd239a2724795e
parent 0501766af31d6dead9956a6587e54bdc84aa5da0
author z0sh22 <dashamakeeva3000@gmail.com> 1770748679 +0300
committer z0sh22 <dashamakeeva3000@gmail.com> 1770748679 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 ...-

Add test file
```

### Объяснение типов объектов
- **Blob (Binary Large Object)**: Хранит только содержимое файла (байт-код), не сохраняя имени файла, прав доступа или времени создания.
- **Tree (Дерево)**: Аналог директории в файловой системе. Хранит список файлов и вложенных папок, связывая их имена с соответствующими blob-объектами и правами доступа (например, `100644`).
- **Commit (Коммит)**: Снимок состояния проекта в конкретный момент времени. Содержит ссылку на корневой объект `tree`, метаданные (автор, email, дата, сообщение) и ссылку на родительский коммит (если он есть).

### Анализ хранения данных
Git — это **content-addressable filesystem** (файловая система, адресуемая по содержимому). В папке `.git/objects` данные хранятся в виде пар «ключ-значение», где ключом является SHA-1 хеш содержимого, а значением — сжатые данные.
Главная особенность: имя файла не влияет на хеш блоба, влияет только контент. Два файла с разным названием, но одинаковым содержимым будут указывать на один и тот же blob, что экономит место (дедупликация). Изменение любого бита информации меняет хеш, что гарантирует криптографическую целостность истории.

### Пример содержимого объектов

**1. Blob (содержимое файла)**
```text ```
Test content


## Занаие 2

### Результаты выполнения команд

```bash

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ echo "content 1" > 1.txt
git add 1.txt
git commit -m "feat: add first file"

echo "content 2" > 2.txt
git add 2.txt
git commit -m "feat: add second file"

echo "content 3" > 3.txt
git add 3.txt
git commit -m "feat: add third file"
warning: in the working copy of '1.txt', LF will be replaced by CRLF the next time Git touches it
[git-reset-practice 18d92ce] feat: add first file
 1 file changed, 1 insertion(+)
 create mode 100644 1.txt
warning: in the working copy of '2.txt', LF will be replaced by CRLF the next time Git touches it
[git-reset-practice faf24af] feat: add second file
 1 file changed, 1 insertion(+)
 create mode 100644 2.txt
warning: in the working copy of '3.txt', LF will be replaced by CRLF the next time Git touches it
[git-reset-practice 764b8a3] feat: add third file
 1 file changed, 1 insertion(+)
 create mode 100644 3.txt

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git log --oneline
764b8a3 (HEAD -> git-reset-practice) feat: add third file
faf24af feat: add second file
18d92ce feat: add first file
78168e8 Third commit
854ec7e Second commit
d101b5b First commit
ea6d103 (feature/lab2) Add test file
0501766 (origin/feature/lab1, feature/lab1) docs: for my first lab
0501766 (origin/feature/lab1, feature/lab1) docs: for my first lab
3ab1c3c docs: done
b42e848 docs: with photo
e760ad5 docs: done task 2
60fac05 docs: done task 2
870ef94 Merge branch 'main' into feature/lab1
266051b docs: add PR template structure
e9a00f0 docs: add lab1 submission
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
 ESCOC




/lab1



Policy




ised structure

thers







 ESCOD
3ab1c3c docs: done
b42e848 docs: with photo
e760ad5 docs: done task 2
60fac05 docs: done task 2
870ef94 Merge branch 'main' into feature/lab1
266051b docs: add PR template structure
e9a00f0 docs: add lab1 submission
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
 ESCOC




/lab1



Policy




ised structure

thers







 ESCOD
3ab1c3c docs: done
b42e848 docs: with photo
e760ad5 docs: done task 2
60fac05 docs: done task 2
870ef94 Merge branch 'main' into feature/lab1
266051b docs: add PR template structure
e9a00f0 docs: add lab1 submission
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
 ESCOD
3ab1c3c docs: done
b42e848 docs: with photo
e760ad5 docs: done task 2
60fac05 docs: done task 2
870ef94 Merge branch 'main' into feature/lab1
266051b docs: add PR template structure
e9a00f0 docs: add lab1 submission
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
 ESCOD
3ab1c3c docs: done
b42e848 docs: with photo
e760ad5 docs: done task 2
60fac05 docs: done task 2
870ef94 Merge branch 'main' into feature/lab1
266051b docs: add PR template structure
e9a00f0 docs: add lab1 submission
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
 ESCOD
764b8a3 (HEAD -> git-reset-practice) feat: add third file
faf24af feat: add second file
18d92ce feat: add first file
78168e8 Third commit
854ec7e Second commit
d101b5b First commit
ea6d103 (feature/lab2) Add test file
0501766 (origin/feature/lab1, feature/lab1) docs: for my first lab
3ab1c3c docs: done
b42e848 docs: with photo
e760ad5 docs: done task 2
60fac05 docs: done task 2
870ef94 Merge branch 'main' into feature/lab1
266051b docs: add PR template structure
e9a00f0 docs: add lab1 submission
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


Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git reset --soft HEAD~1

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git status
On branch git-reset-practice
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        new file:   3.txt

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   .github/pull_request_template.md

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/submission2.md


Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git reset --hard HEAD~1
HEAD is now at 18d92ce feat: add first file

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ ls
1.txt  README.md  app/  file.txt  labs/  lectures/  test.txt

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git log --oneline
18d92ce (HEAD -> git-reset-practice) feat: add first file
78168e8 Third commit
854ec7e Second commit
d101b5b First commit
ea6d103 (feature/lab2) Add test file
0501766 (origin/feature/lab1, feature/lab1) docs: for my first lab
3ab1c3c docs: done
b42e848 docs: with photo
e760ad5 docs: done task 2
60fac05 docs: done task 2
870ef94 Merge branch 'main' into feature/lab1
266051b docs: add PR template structure
e9a00f0 docs: add lab1 submission
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

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git reflog
18d92ce (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
faf24af HEAD@{1}: reset: moving to HEAD~1
764b8a3 HEAD@{2}: commit: feat: add third file
faf24af HEAD@{3}: commit: feat: add second file
18d92ce (HEAD -> git-reset-practice) HEAD@{4}: commit: feat: add first file
78168e8 HEAD@{5}: commit: Third commit
854ec7e HEAD@{6}: commit: Second commit
d101b5b HEAD@{7}: commit: First commit
ea6d103 (feature/lab2) HEAD@{8}: checkout: moving from feature/lab2 to git-reset-practice
ea6d103 (feature/lab2) HEAD@{9}: commit: Add test file
0501766 (origin/feature/lab1, feature/lab1) HEAD@{10}: checkout: moving from feature/lab1 to feature/lab2
0501766 (origin/feature/lab1, feature/lab1) HEAD@{11}: commit: docs: for my first lab
3ab1c3c HEAD@{12}: checkout: moving from main to feature/lab1
b6dc181 (origin/main, origin/HEAD, main) HEAD@{13}: reset: moving to HEAD
b6dc181 (origin/main, origin/HEAD, main) HEAD@{14}: commit: docs: this template
bae7d8e HEAD@{15}: checkout: moving from feature/lab1 to main
3ab1c3c HEAD@{16}: checkout: moving from main to feature/lab1
bae7d8e HEAD@{17}: commit: docs: finish
266051b HEAD@{18}: checkout: moving from feature/lab1 to main
3ab1c3c HEAD@{19}: commit: docs: done
b42e848 HEAD@{20}: commit: docs: with photo
e760ad5 HEAD@{21}: commit: docs: done task 2
60fac05 HEAD@{22}: commit: docs: done task 2
870ef94 HEAD@{23}: merge main: Merge made by the 'ort' strategy.
e9a00f0 HEAD@{24}: checkout: moving from main to feature/lab1
266051b HEAD@{25}: commit: docs: add PR template structure
d6b6a03 HEAD@{26}: checkout: moving from feature/lab1 to main
e9a00f0 HEAD@{27}: checkout: moving from main to feature/lab1
d6b6a03 HEAD@{28}: checkout: moving from feature/lab1 to main
e9a00f0 HEAD@{29}: commit: docs: add lab1 submission
d6b6a03 HEAD@{30}: checkout: moving from main to feature/lab1
d6b6a03 HEAD@{31}: clone: from github.com:z0sh22/DevOps-Intro.git

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git reset --hard 78168e8
HEAD is now at 78168e8 Third commit

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ ls
README.md  app/  file.txt  labs/  lectures/  test.txt

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git log --oneline
78168e8 (HEAD -> git-reset-practice) Third commit
854ec7e Second commit
d101b5b First commit
ea6d103 (feature/lab2) Add test file
0501766 (origin/feature/lab1, feature/lab1) docs: for my first lab
3ab1c3c docs: done
b42e848 docs: with photo
e760ad5 docs: done task 2
60fac05 docs: done task 2
870ef94 Merge branch 'main' into feature/lab1
266051b docs: add PR template structure
e9a00f0 docs: add lab1 submission
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


### Выполненные действия и анализ
В рамках задания была создана ветка `git-reset-practice` и сделано три последовательных коммита. Затем были протестированы механизмы сброса состояния.

#### 1. Soft Reset
Команда: `git reset --soft HEAD~1`
**Что произошло:**
- Указатель `HEAD` переместился на один коммит назад (на "feat: add second file").
- **Рабочее дерево (Working Tree):** Файл `3.txt` остался на диске без изменений.
- **Индекс (Staging Area):** Изменения из отмененного коммита (добавление `3.txt`) остались в индексе. Они помечены как готовые к коммиту ("Changes to be committed").
- **История:** Последний коммит исчез из `git log`.

#### 2. Hard Reset
Команда: `git reset --hard HEAD~1`
**Что произошло:**
- Указатель `HEAD` переместился еще на один коммит назад (на "feat: add first file").
- **Рабочее дерево:** Файл `2.txt` был физически удален с диска.
- **Индекс:** Очищен. Все изменения, накопленные после нового `HEAD`, были уничтожены.
- **История:** Коммит "feat: add second file" также исчез из лога.

### Восстановление через Reflog

После выполнения сбросов (resets) коммиты пропали из обычного `git log`, но остались в журнале ссылок (`reflog`).


## Задание 3

![alt text](image-4.png)

### Текстовое представление графа

* 338a8fa (side-branch) Side branch commit
* 78168e8 (HEAD -> git-reset-practice) Third commit
* 854ec7e Second commit
* d101b5b First commit
* ea6d103 (feature/lab2) Add test file
* 0501766 (origin/feature/lab1, feature/lab1) docs: for my first lab
* 3ab1c3c docs: done
* b42e848 docs: with photo
* e760ad5 docs: done task 2
* 60fac05 docs: done task 2
* 870ef94 Merge branch 'main' into feature/lab1
|\
* | e9a00f0 docs: add lab1 submission
| * ebe5f9a (refs/stash) WIP on main: b6dc181 docs: this template
| |
| * b6dc181 (origin/main, origin/HEAD, main) docs: this template
| * bae7d8e docs: finish
|/
* 266051b docs: add PR template structure
|/
* d6b6a03 Update lab2

Список сообщений коммитов
Side branch commit (в ветке side-branch)

Third commit (текущий HEAD в git-reset-practice)

Second commit

First commit

Add test file (точка начала работы над заданием 1)

docs: for my first lab (история предыдущей лабы)

... и коммиты слияния (Merge branch 'main'...), показывающие интеграцию изменений.

Размышление о визуализации
Команда git log --graph --oneline --all позволяет наглядно увидеть, как ветвилась история разработки: где именно отошли новые ветки (side-branch, feature/lab2) от основной линии и где происходили слияния. Это помогает мгновенно понять структуру проекта и отношений между ветками, что невозможно сделать, глядя только на линейный список коммитов.


## Задание 4

```bash

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git tag v1.0.0

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git push origin v1.0.0
Enumerating objects: 13, done.
Counting objects: 100% (13/13), done.
Delta compression using up to 8 threads
Compressing objects: 100% (8/8), done.
Writing objects: 100% (12/12), 1.35 KiB | 1.35 MiB/s, done.
Total 12 (delta 7), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (7/7), completed with 1 local object.
To github.com:z0sh22/DevOps-Intro.git
 [new tag]         v1.0.0 -> v1.0.0

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git show v1.0.0
commit 78168e8feb9c65953110b7727e982d53e359e57b (HEAD -> git-reset-practice, tag: v1.0.0)
Author: z0sh22 <dashamakeeva3000@gmail.com>
Date:   Tue Feb 10 21:58:58 2026 +0300

    Third commit

diff --git a/file.txt b/file.txt
index c133ee6..4775dab 100644
--- a/file.txt
+++ b/file.txt
@@ -1 +1 @@
-Second commit
+Third commit 
```

![alt text](image-5.png)

Теги критически важны для фиксирования стабильных точек в истории проекта (релизов), так как в отличие от веток они неизменяемы и всегда указывают на один и тот же код. В DevOps теги часто служат триггерами для CI/CD пайплайнов: например, создание тега v* может автоматически запускать сборку production-версии приложения и деплой на сервер, а также генерацию Release Notes.

## Задание 5

```bash
Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git switch -c cmd-compare
Switched to a new branch 'cmd-compare'

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare)
$ git switch -
Switched to branch 'git-reset-practice'

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git checkot -b cmd-compare-2
git: 'checkot' is not a git command. See 'git --help'.

The most similar command is
        checkout

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git status
On branch git-reset-practice
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/image-4.png
        labs/image-5.png
        labs/submission2.md

nothing added to commit but untracked files present (use "git add" to track)

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git branch
  cmd-compare
  feature/lab1
  feature/lab2
* git-reset-practice
  main
  side-branch

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (git-reset-practice)
$ git checkout -b cmd-compare-2
Switched to a new branch 'cmd-compare-2'

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ git branch
  cmd-compare
* cmd-compare-2
  feature/lab1
  feature/lab2
  git-reset-practice
  main
  side-branch

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ git status
On branch cmd-compare-2
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/image-4.png
        labs/image-5.png
        labs/submission2.md

nothing added to commit but untracked files present (use "git add" to track)

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ echo "base" > demo.txt
git add demo.txt
git commit -m "chore: add demo for restore"
warning: in the working copy of 'demo.txt', LF will be replaced by CRLF the next time Git touches it
On branch cmd-compare-2
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/image-4.png
        labs/image-5.png
        labs/submission2.md

nothing added to commit but untracked files present (use "git add" to track)

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ echo "base" > demo.txt      # создать/перезаписать файл
git add demo.txt            # добавить в индекс
git commit -m "chore: add demo for restore"
warning: in the working copy of 'demo.txt', LF will be replaced by CRLF the next time Git touches it
On branch cmd-compare-2
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/image-4.png
        labs/image-5.png
        labs/submission2.md

nothing added to commit but untracked files present (use "git add" to track)

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ echo "base" > demo.txt

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ git add demo.txt
warning: in the working copy of 'demo.txt', LF will be replaced by CRLF the next time Git touches it

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ git commit -m "chore: add demo for restore"
On branch cmd-compare-2
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/image-4.png
        labs/image-5.png
        labs/submission2.md

nothing added to commit but untracked files present (use "git add" to track)

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ git status
On branch cmd-compare-2
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/image-4.png
        labs/image-5.png
        labs/submission2.md

nothing added to commit but untracked files present (use "git add" to track)

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ echo "scratch" >> demo.txt

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ git status
On branch cmd-compare-2
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   demo.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/image-4.png
        labs/image-5.png
        labs/submission2.md

no changes added to commit (use "git add" and/or "git commit -a")

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ git restore demo.txt

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ git status
On branch cmd-compare-2
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/image-4.png
        labs/image-5.png
        labs/submission2.md

nothing added to commit but untracked files present (use "git add" to track)

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ echo "scratch" >> demo.txt

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ git add demo.txt
warning: in the working copy of 'demo.txt', LF will be replaced by CRLF the next time Git touches it

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ git status
On branch cmd-compare-2
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   demo.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/image-4.png
        labs/image-5.png
        labs/submission2.md


Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ git restore --staged demo.txt

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ git status
On branch cmd-compare-2
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   demo.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/image-4.png
        labs/image-5.png
        labs/submission2.md

no changes added to commit (use "git add" and/or "git commit -a")

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ git restore --source=HEAD~1 demo.txt

Дарья@LAPTOP-HVHDMKR2 MINGW64 /d/homeworkIU/DevOps-Intro (cmd-compare-2)
$ git status
On branch cmd-compare-2
Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        deleted:    demo.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        labs/image-4.png
        labs/image-5.png
        labs/submission2.md

no changes added to commit (use "git add" and/or "git commit -a")

```
### Короткое сравнение
- `git switch` — лучше для веток (понятнее: create/switch branch).
- `git checkout` — «универсальный» и из-за этого более запутанный (ветки и файлы одной командой).
- `git restore` — для файлов (вернуть изменения из рабочего дерева и/или из индекса).

## Задание 6

### Почему это важно (1–2 предложения)
Stars и подписки помогают поддерживать open-source, повышают видимость проектов и упрощают отслеживание обновлений. Это также помогает быстрее находить полезные репозитории и людей для взаимодействия в сообществе.



