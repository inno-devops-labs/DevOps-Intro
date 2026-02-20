# Task 1

Run URL: https://github.com/Milterr/DevOps-Intro/actions/runs/22242729586
Key concepts:
- `workflow` описывает автоматизацию в `.github/workflows`.
- `trigger` (`on: push`) запускает workflow при пуше.
- `job` (`Explore-GitHub-Actions`) выполняется на раннере.
- `step` это отдельная команда/действие внутри job.
- `runner` это среда выполнения (`ubuntu-latest`).
Trigger reason:
- Workflow запустился автоматически после пуша в ветку `feature/lab3`.
Analysis:
- Все шаги отработали успешно: checkout репозитория, вывод контекста GitHub и списка файлов.
- Лог показывает корректные значения контекстов (`github.event_name`, `runner.os`, `github.ref`, `github.repository`), значит YAML настроен корректно.

# Task 2

Workflow changes:
- Добавлен ручной триггер `workflow_dispatch` в блок `on`.
- Добавлен шаг `Gather runner system information` с командами:
  - `echo` для `RUNNER_NAME`, `RUNNER_OS`, `RUNNER_ARCH`
  - `uname -sr`, `lscpu`, `free -h`, `df -h /`
Push run URL: https://github.com/Milterr/DevOps-Intro/actions/runs/22242752002
Manual run URL: https://github.com/Milterr/DevOps-Intro/actions/runs/22242777921
System information:
- Runner name: `GitHub Actions 1000000002`
- Runner OS: `Linux`
- Runner architecture: `X64`
- Kernel: `Linux 6.11.0-1018-azure`
- CPU: `AMD EPYC 7763 64-Core Processor`, `4 vCPU` (`CPU(s): 4`)
- RAM (`free -h`): `15Gi total`, `967Mi used`, `13Gi free`
- Disk (`df -h /`): `/dev/root 145G total, 53G used, 92G avail (37%)`
Manual vs automatic trigger:
- Push-run стартует автоматически при `git push` (`event_name=push`).
- Manual-run стартует вручную через кнопку `Run workflow` (`event_name=workflow_dispatch`).
- Логика выполнения шагов одинаковая, различается только источник запуска и конкретный инстанс раннера.
Runner analysis:
- Оба запуска выполнены на GitHub-hosted `ubuntu-latest`, раннеры были разные: `1000000001` (push) и `1000000002` (manual).
- Это подтверждает эпемерную природу hosted runner: под каждый запуск поднимается отдельная виртуальная машина.
