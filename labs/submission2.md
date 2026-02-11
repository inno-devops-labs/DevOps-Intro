## Task 1.

1. Commit: по хэшу коммита выдает о нем всю информацию
![[Pasted image 20260211222017.png]]
2. Blobs and tree: хэш дерева переходит в папку, хэш blobs показывает содержимое файла 
![[Pasted image 20260211222338.png]]

---
## Task 2.

1. Создал новую ветку - *git switch -c git-reset-practice*
2. Создал три коммита с file.txt с разными названиями - 
	*echo "First commit" > file.txt && git add file.txt && git commit -m "First commit"
	echo "Second commit" >> file.txt && git add file.txt && git commit -m "Second commit"
	echo "Third commit"  >> file.txt && git add file.txt && git commit -m "Third commit"
3. Перенес HEAD на 1 коммит назад - *git reset --soft HEAD~1*
4. Перенес HEAD на 1 коммит назад, удалив изменения - *git reset --hard HEAD~1
5. История HEAD - *git reflog*
6. Восстановил шаг 5 - *git reset --hard c94369f*
![[Pasted image 20260211225921.png]]

![[Pasted image 20260211230058.png]]

---
## Task 3.

Граф позволяет наглядно увидеть где HEAD в истории коммитов, что позволяет проще ориентироваться.

![[Pasted image 20260211232004.png]]

___

## Task 4.

Тэги важны, чтобы быстро перемещаться по важным коммитам не через хэш.

Хэш:
*PS C:\Users\Георгий\DevOps-Intro> git show v1.0.0 --oneline
c94369f (tag: v1.0.0, git-reset-practice) Second commit
*PS C:\Users\Георгий\DevOps-Intro> git show v1.0.0 --oneline
c94369f (tag: v1.0.0, git-reset-practice) Second commit

![[Pasted image 20260211233130.png]]

---
## Task 5.

switch - создает и переносит в только что созданную ветку. restore - позволяет отменять незакоммиченные изменения, отменять и восстанавливать изменения из другого коммита

Когда делал по заданию наткнулся на ошибку, переделал с git add и доделал по заданию:
![[Pasted image 20260212004755.png]]

с восстановлением:
	*echo "scratch" >> demo1.txt
	git add demo1.txt
	git restore --staged demo1.txt
	git add demo1.txt
	git restore --source=HEAD~1 demo1.txt
![[Pasted image 20260212003931.png]]

---

## Task 6.

Звезды помогают добавить проекты в закладки для последующего использования. Подписка на разработчиков позволяет следить за их работой и проектами.

![[Pasted image 20260212011430.png]]
