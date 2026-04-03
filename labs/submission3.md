# Lab 3 Submission
**Platform: GitHub Actions**

## Task 1 — First GitHub Actions Workflow (6 pts)

### Workflow file location:
`.github/workflows/learn-github-actions.yml`

### Key concepts learned:

- **Jobs**: набор шагов, которые выполняются на одном runner'е
- **Steps**: отдельные команды или действия внутри job'а
- **Runners**: виртуальные машины, на которых выполняются workflow'ы (ubuntu-latest, windows-latest, macos-latest)
- **Triggers**: события, которые запускают workflow (push, workflow_dispatch, pull_request и др.)

### What triggered the workflow:

Workflow запустился автоматически после push в ветки main или feature/lab3.

### Link to successful run:
https://github.com/ImilB/Baltaniazov/actions/runs/23961020670

### Analysis of workflow execution process:
При push в репозиторий GitHub автоматически запускает workflow. Runner (ubuntu-latest) скачивает код, выполняет каждый шаг по очереди. Если какой-то шаг пад>

## Task 2 — Manual Trigger + System Information (4 pts)

### Changes made to workflow file:
Добавлен `workflow_dispatch:` под секцией `on:`. Это позволяет запускать workflow вручную из UI GitHub.

### How to trigger manually:
1. Зайти в Actions → Выбрать workflow "Learn GitHub Actions"
2. Нажать "Run workflow" → Выбрать ветку → Нажать "Run workflow"

### Gathered system information:
Run echo "=== System Information ==="
=== System Information ===
Operating System: Linux runnervm727z3 6.17.0-1008-azure #8~24.04.1-Ubuntu SMP Mon Jan 26 18:35:40 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
Current user: runner
Current directory: /home/runner/work/Baltaniazov/Baltaniazov
CPU info:
model name      : AMD EPYC 7763 64-Core Processor
Memory info:
               total        used        free      shared  buff/cache   available
Mem:            15Gi       1.3Gi        12Gi        39Mi       2.5Gi        14Gi
Swap:          3.0Gi          0B       3.0Gi
Disk space:
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       145G   56G   89G  39% /
tmpfs           7.9G   84K  7.9G   1% /dev/shm
tmpfs           3.2G 1004K  3.2G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
efivarfs        128M   26K  128M   1% /sys/firmware/efi/efivars
/dev/sda16      881M   64M  756M   8% /boot
/dev/sda15      105M  6.2M   99M   6% /boot/efi
tmpfs           1.6G   12K  1.6G   1% /run/user/1001
Git version:
git version 2.53.0

### Comparison of manual vs automatic triggers:
При ручном запуске (`workflow_dispatch`) вы контролируете процесс, но нужно не забыть его активировать, а при автоматическом (`push`) он срабатывает при каж>
### Analysis of runner environment:
GitHub Actions runner на ubuntu-latest предоставляет: 2-core CPU, 7GB RAM, 14GB SSD. Включает предустановленные инструменты: Git, Docker, Node.js, Python и >

