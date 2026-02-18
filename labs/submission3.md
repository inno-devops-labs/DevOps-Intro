## Task 1.

https://github.com/klassgo/DevOps-Intro/actions/runs/22158159618/job/64067666824 - успешный запуск GitHub Actions

- jobs - задание, которое состоит из набора шагов, которые выполняет runner
- steps - задача внутри задания 
- runners - виртуальная машина, которая выполняет workflow
- triggers - запуск (push)

Workflow был запущен после выполнения `git push`, так как в конфигурации указано on: [push].

После push GitHub проверяет workflow файлы и создает виртуальную машину для выполнения шагов в yml файле

## Task 2.

https://github.com/klassgo/DevOps-Intro/actions/runs/22159849272/job/64074111651 - успешный ручной запуск 

Добавлено:

	on:
	  push:
	  workflow_dispatch:
	  

	      - name: Show system information
	        run: |
	          echo "===== SYSTEM INFO ====="
	          uname -a
	          echo ""
	          echo "CPU Info:"
	          lscpu
	          echo ""
	          echo "Memory Info:"
	          free -h
	          echo ""
	          echo "Disk Info:"
	          df -h

![[Pasted image 20260219012754.png]]

- Автоматический запускается после push и сразу проверяет код, ручной через интерфейс на GitHub Actions, не запускает код сразу, что удобно для деббага в команде
- Среда создается для выполнения кода, после чего сразу удаляется, имеет ограниченные ресурсы. Не имеет связи между запусками