\#### \*\*# Задание 1 #\*\*







\###### 1) Blob — это содержимое файла. Git хранит его отдельно от имени и структуры.







$  git cat-file -p f5752e6592548f6b566007c4eca93d329ee8c58d (Blob hash) :







Have a good day



Good Luck !







\###### 2\\) Tree — это снимок директории: список файлов и папок с их хэшами и правами доступа.







$ git cat-file -p 53dc22008264707d6e0065d8925c6d21a32e3c88 (Tree hash) :







040000 tree ea20ed92e3aec2e4fc623db4fda9b049f41145ae    .github



100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md



040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app



040000 tree 0fcb5d85071b256d4d135b8209cb3d1f952be63a    labs



040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures



100644 blob f5752e6592548f6b566007c4eca93d329ee8c58d    test.txt







\###### 3) Commit — метаданные коммита: автор, дата, ссылка на tree, родительский коммит и подпись.







$ git cat-file -p ec5eb52 (Commit hash):



tree 53dc22008264707d6e0065d8925c6d21a32e3c88



parent 48535f49e81b284afd97dc153f0f30409f330663



author Ilya Vdovin \[qwxlyx@gmail.com](mailto:qwxlyx@gmail.com) 1770848740 +0300



committer Ilya Vdovin \[qwxlyx@gmail.com](mailto:qwxlyx@gmail.com) 1770848740 +0300



gpgsig -----BEGIN SSH SIGNATURE-----



 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgj6riQ8bpp9kexTl0gY2NoLc7Bo



 cwXImE2M5TZ4wRxH8AAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5



 AAAAQES8mitLgQvnO4TFnEtlCQNUZi6i0Yi50K2yWdrO/6hYITCp5YIrfkMo5Oeuq5s0NQ



 rhgYrhDnijkhbeqnkU6w8=



 -----END SSH SIGNATURE-----







test: update test.txt















\#### \*\*# Задание 2 #\*\*







\###### Создание ветки с тремя коммитами :







git switch -c git-reset-practice



echo "First commit" > file.txt \\\&\\\& git add file.txt \\\&\\\& git commit -m "First commit"



echo "Second commit" >> file.txt \\\&\\\& git add file.txt \\\&\\\& git commit -m "Second commit"



echo "Third commit" >> file.txt \\\&\\\& git add file.txt \\\&\\\& git commit -m "Third commit"







\###### Проверка результатов :







$ git log --oneline







f7f765b (HEAD -> git-reset-practice) Third commit



6b2f788 Second commit



df1bb84 First commit







$ cat file.txt







First commit



Second commit



Third commit







\##### 1) git reset --soft HEAD~1







$ git reset --soft HEAD~1



$ git log --oneline







6b2f788 (HEAD -> git-reset-practice) Second commit



df1bb84 First commit







$ cat file.txt







First commit



Second commit



Third commit







\###### Анализ:



HEAD переместился на коммит "Second commit";



Индекс остался с изменениями из "Third commit";



Рабочий каталог не изменился;



--soft полезен, когда нужно исправить сообщение коммита или объединить изменения.







\##### 2\\) git reset --hard HEAD~1







$ git reset --hard HEAD~1







HEAD is now at df1bb84 First commit







$ git log --oneline







df1bb84 First commit







$ cat file.txt







First commit







\###### Анализ:



HEAD переместился на "First commit";



Индекс и рабочий каталог синхронизированы с этим коммитом;



Изменения из второго и третьего коммитов полностью удалены;



--hard используется для жёсткого сброса состояния.







\#### 3\\) git reflog







$ git reflog







df1bb84 (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1



6b2f788 HEAD@{1}: reset: moving to HEAD~1



f7f765b HEAD@{2}: commit: Third commit



6b2f788 HEAD@{3}: commit: Second commit



df1bb84 (HEAD -> git-reset-practice) HEAD@{4}: commit: First commit



ec5eb52 (feature/lab2) HEAD@{5}: checkout: moving from feature/lab2 to git-reset-practice







Анализ:

reflog — это журнал всех перемещений HEAD. Позволяет вернуться даже после «потери» коммитов











\###### 4\\) git reset --hard <...>







$ git reset --hard 6b2f788







HEAD is now at 6b2f788 Second commit











$ cat file.txt







First commit



Second commit







\###### Анализ:



При помощи reset мы вернулись к выбранному нами коммиту.







\#### \*\*# Задание 3 #\*\*







\*\*Визуализация коммитов :\*\*







$ git switch -c side-branch



$ echo "Branch commit" >> history.txt



$ git add history.txt \\\&\\\& git commit -m "Side branch commit"



$ git switch -



$ git log --oneline --graph --all











\\\* aa2117c (side-branch) Фиксация в боковой ветке



\\\* 6b2f788 (HEAD -> git-reset-practice) Second commit



\\\* df1bb84 First commit



\\\* ec5eb52 (feature/lab2) test: update test.txt



\\\* 48535f4 test: add test.txt



\\\* 81cba7a (origin/feature/lab1, feature/lab1) docs: add verification screenshots



\\\*   ea4af4c Merge branch 'main' into feature/lab1



|\\\\



| \\\* bd1b56d (origin/main, origin/HEAD, main) chore: add PR template from open-source projects



\\\* | f2af6b4 docs: update submission1.md with task progress



\\\* | 5aa2655 docs: add verification screenshots



\\\* | bff4e4a docs: add submission for lab1



|/



\\\* d6b6a03 Update lab2



\\\* 87810a0 feat: remove old Exam Exemption Policy



\\\* 1e1c32b feat: update structure



\\\* 6c27ee7 feat: publish lecs 9 \\\& 10



\\\* 1826c36 feat: update lab7



\\\* 3049f08 feat: publish lec8



\\\* da8f635 feat: introduce all labs and revised structure



\\\* 04b174e feat: publish lab and lec #5



\\\* 67f12f1 feat: publish labs 4\\\&5, revise others



\\\* 82d1989 feat: publish lab3 and lec3



\\\* 3f80c83 feat: publish lec2







\*\*Список сообщений о коммитах :\*\*







Фиксация в боковой ветке







(HEAD -> git-reset-practice) Second commit



First commit



(feature/lab2) test: update test.txt



test: add test.txt



(origin/feature/lab1, feature/lab1) docs: add verification screenshots



…







\*\*Граф наглядно показывает, где произошло ветвление, какие коммиты относятся к какой ветке, и как развивалась история. Это сильно упрощает анализ изменений в проекте\*\*







\#### \*\*# Задание 4 #\*\*







$ git tag v1.0.0



$ git push origin v1.0.0







\*\*Хэш коммита :\*\*



v1.0.0 -> 6b2f7884ff82366c020e7d9590f025f06dfec8c3







\*\*Теги фиксируют релизные версии проекта. Это позволяет:\*\*







Быстро переключаться между версиями ;







Чётко отслеживать, какой код ушёл в продакшн;







В отличие от веток, теги не перемещаются — они навсегда привязаны к конкретному коммиту.



\*\*# Задание 5 #\*\*

---







1\\)



git switch -c cmd-compare







Switched to a new branch 'cmd-compare'







git branch







\\\* cmd-compare



\&nbsp; feature/lab1



\&nbsp; feature/lab2



\&nbsp; git-reset-practice



\&nbsp; main



\&nbsp; side-branch







git switch -







Switched to branch 'git-reset-practice'







git branch







\&nbsp;cmd-compare



\&nbsp; feature/lab1



\&nbsp; feature/lab2



\\\* git-reset-practice



\&nbsp; main



\&nbsp; side-branch





Используется только для переключения и создания веток.

Никак не влияет на файлы — безопасная замена git checkout в контексте веток.



2\\)



$ git checkout -b cmd-compare-2







Switched to a new branch 'cmd-compare-2'







$ echo "line 1" > checkout-test.txt



$ git add checkout-test.txt



$ git commit -m "checkout-test: init"







\\\[cmd-compare-2 89ed15d] checkout-test: init



\&nbsp;1 file changed, 1 insertion(+)



\&nbsp;create mode 100644 checkout-test.txt







$ echo "line 2" >> checkout-test.txt



$ git status







On branch cmd-compare-2



Changes not staged for commit:



\&nbsp; (use "git add <file>..." to update what will be committed)



\&nbsp; (use "git restore <file>..." to discard changes in working directory



\&nbsp;       modified:   checkout-test.txt







Untracked files:



\&nbsp; (use "git add <file>..." to include in what will be committed)



\&nbsp;       labs/submission2.md







no changes added to commit (use "git add" and/or "git commit -a")







$ git checkout -- checkout-test.txt



$ git status







On branch cmd-compare-2



Untracked files:



\&nbsp; (use "git add <file>..." to include in what will be committed)



\&nbsp;       labs/submission2.md







nothing added to commit but untracked files present (use "git add" to







$ cat checkout-test.txt







line 1



Устаревшая, перегруженная команда: умеет и ветки, и файлы.

Из‑за этого легко ошибиться — например, вместо отмены изменений случайно переключить ветку



3\)



$ echo "line 1" > checkout-demo.txt

$ git add checkout-demo.txt

$ git commit -m "checkout-demo: init"



\[cmd-compare-2 9be272a] checkout-demo: init

&nbsp;1 file changed, 1 insertion(+)

&nbsp;create mode 100644 checkout-demo.txt





$ echo "line 2" >> checkout-demo.txt

$ git add checkout-demo.txt

$ git status



On branch cmd-compare-2

Changes to be committed:

&nbsp; (use "git restore --staged <file>..." to unstage)

&nbsp;       modified:   checkout-demo.txt



Changes not staged for commit:

&nbsp; (use "git add <file>..." to update what will be committed)

&nbsp; (use "git restore <file>..." to discard changes in working directory)

&nbsp;       modified:   demo.txt



Untracked files:

&nbsp; (use "git add <file>..." to include in what will be committed)

&nbsp;       labs/submission2.md







$ git restore --staged checkout-demo.txt

$ git status



On branch cmd-compare-2

Changes not staged for commit:

&nbsp; (use "git add <file>..." to update what will be committed)

&nbsp; (use "git restore <file>..." to discard changes in working directory)

&nbsp;       modified:   checkout-demo.txt

&nbsp;       modified:   demo.txt



Untracked files:

&nbsp; (use "git add <file>..." to include in what will be committed)

&nbsp;       labs/submission2.md



no changes added to commit (use "git add" and/or "git commit -a")





$ git restore checkout-demo.txt

$ git status



On branch cmd-compare-2

Changes not staged for commit:

&nbsp; (use "git add <file>..." to update what will be committed)

&nbsp; (use "git restore <file>..." to discard changes in working directory)

&nbsp;       modified:   demo.txt



Untracked files:

&nbsp; (use "git add <file>..." to include in what will be committed)

&nbsp;       labs/submission2.md



no changes added to commit (use "git add" and/or "git commit -a")







$ cat checkout-demo.txt

line 1



$ git restore --source=HEAD~1 checkout-demo.txt

$ cat checkout-demo.txt

cat: checkout-demo.txt: No such file or directory





git restore --source=<commit> восстанавливает состояние файла на момент указанного коммита.

Если в том коммите файла не было — команда удаляет его из рабочей копии и индекса.

Это удобно, когда нужно откатить файл к более ранней версии или вовсе убрать его.





\# Задание 6 #



\- Поставлена звезда (⭐) репозиторию курса.

\- Поставлена звезда (⭐) проекту `simple-container-com/api`.

\- Оформлены подписки (Follow) на преподавателя @Cre-eD и ассистентов @marat-biriushev, @pierrepicaud.

\- Оформлены подписки на 3 однокурсников:  Mirletti, dan-khaiaa, klassgo



Звёзды на GitHub помогают отслеживать полезные проекты и показывают признание авторам.  

Подписка на разработчиков позволяет быть в курсе их активности и перенимать опыт





