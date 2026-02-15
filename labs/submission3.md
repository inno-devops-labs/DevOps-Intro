# Lab 3 — GitHub Actions

## Task 1 — First GitHub Actions Workflow

### Link to successful run (or screenshots)
- Push run: 

### Key concepts learned (jobs, steps, runners, triggers)
- **Workflow**: YAML-файл в `.github/workflows/`, который описывает автоматизацию.
- **Trigger (event)**: событие, запускающее workflow (в этой лабе `push` и `workflow_dispatch`).
- **Job**: набор шагов, выполняемых на одном runner (`jobs.info`).
- **Steps**: последовательные команды внутри job (выполнение `run`).
- **Runner**: машина, где выполняется job (в этой лабе `ubuntu-latest`, GitHub-hosted runner).

### What caused the run to trigger
- Запуск произошёл из-за события **push** в репозиторий (коммит(ы) в ветку `feature/lab3`).

### Analysis of workflow execution process
- GitHub получил событие `push`, сопоставил его с `on: push` в workflow.
- Создал job `info` и выделил runner `ubuntu-latest`.
- Runner выполнил шаги по порядку: сначала печать контекста GitHub (`github.*`), затем сбор данных о системе.

## Task 2 — Manual Trigger + System Information

### Changes made to the workflow file
- Добавлен ручной триггер `workflow_dispatch`.
- Добавлен шаг `Gather runner system info` для вывода OS/CPU/RAM/Disk информации.

### Gathered system information from runner
- Paste relevant output from logs (uname/os/cpu/mem/disk):
