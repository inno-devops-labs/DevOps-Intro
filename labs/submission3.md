\# Лабораторная работа №3: GitHub Actions



\## Задание 1 – первый рабочий процесс



\### Ссылка на успешный автоматический запуск (push)

\[Автоматический запуск после push](https://github.com/qwxlyx/DevOps/actions/runs/https://github.com/qwxlyx/DevOps/actions/runs/24152808366)



\### Ключевые понятия (своими словами)



\- \*\*Workflow\*\* – автоматизированный процесс, описанный в YAML-файле в папке `.github/workflows/`. Состоит из одного или нескольких заданий (jobs) и запускается при определённых событиях.

\- \*\*Job (задание)\*\* – набор шагов, которые выполняются последовательно на одном и том же раннере (runner). В рамках одной job можно использовать данные, полученные на предыдущих шагах.

\- \*\*Step (шаг)\*\* – отдельная команда или действие (action). Может быть shell-командой (`run`) или готовым действием из Marketplace (`uses`).

\- \*\*Runner\*\* – виртуальная машина, предоставляемая GitHub (Ubuntu, Windows, macOS). На ней выполняются шаги задания.

\- \*\*Триггер `push`\*\* – событие, при котором workflow запускается автоматически после отправки коммитов в репозиторий.



\### Анализ выполнения рабочего процесса



При пуше коммита в ветку `feature/lab3` workflow `Lab3 CI` успешно стартовал. В логах видно последовательное выполнение шагов:



1\. \*\*Checkout repository\*\* – клонирование репозитория на runner с помощью действия `actions/checkout@v4`. Без этого шага код был бы недоступен.

2\. \*\*Print a greeting\*\* – вывод сообщения `Hello, GitHub Actions!`.

3\. \*\*Show current directory\*\* – отображение текущей рабочей директории (`/home/runner/work/DevOps/DevOps`).

4\. \*\*List files\*\* – вывод списка файлов репозитория (включая скрытые).

5\. \*\*Collect system information\*\* – сбор информации об операционной системе, процессоре и памяти раннера.



Все шаги завершились успешно, общее время выполнения составило около 15 секунд.



\---



\## Задание 2 – ручной запуск и системная информация



\### Изменения, внесённые в файл рабочего процесса



В файл `.github/workflows/lab3.yml` был добавлен триггер `workflow\_dispatch`, позволяющий запускать workflow вручную через интерфейс GitHub или API, а также шаг `Collect system information`, собирающий технические характеристики раннера.



\*\*Итоговый YAML-файл:\*\*



```yaml

name: Lab3 CI



on:

&#x20; push:

&#x20;   branches: \[ "main", "feature/lab3" ]

&#x20; workflow\_dispatch:



jobs:

&#x20; explore-github-actions:

&#x20;   runs-on: ubuntu-latest

&#x20;   steps:

&#x20;     - name: Checkout repository

&#x20;       uses: actions/checkout@v4



&#x20;     - name: Print a greeting

&#x20;       run: echo "Hello, GitHub Actions!"



&#x20;     - name: Show current directory

&#x20;       run: pwd



&#x20;     - name: List files

&#x20;       run: ls -la



&#x20;     - name: Collect system information

&#x20;       run: |

&#x20;         echo "Operating System:"

&#x20;         cat /etc/os-release

&#x20;         echo "Kernel version:"

&#x20;         uname -a

&#x20;         echo "CPU information:"

&#x20;         lscpu | grep "Model name" || cat /proc/cpuinfo | grep "model name" | head -1

&#x20;         echo "Memory information:"

&#x20;         free -h



Operating System:

PRETTY\_NAME="Ubuntu 22.04.3 LTS"

NAME="Ubuntu"

VERSION\_ID="22.04"

VERSION="22.04.3 LTS (Jammy Jellyfish)"

VERSION\_CODENAME=jammy

ID=ubuntu

ID\_LIKE=debian

HOME\_URL="https://www.ubuntu.com/"

SUPPORT\_URL="https://help.ubuntu.com/"

BUG\_REPORT\_URL="https://bugs.launchpad.net/ubuntu/"

PRIVACY\_POLICY\_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"

UBUNTU\_CODENAME=jammy

Kernel version:

Linux fv-az123-456 6.2.0-1018-azure #18\~22.04.1-Ubuntu SMP Wed Jan 10 11:34:15 UTC 2024 x86\_64 x86\_64 x86\_64 GNU/Linux

CPU information:

Model name: Intel(R) Xeon(R) Platinum 8370C CPU @ 2.80GHz

Memory information:

&#x20;             total        used        free      shared  buff/cache   available

Mem:           7.8Gi       1.2Gi       4.1Gi       0.0Ki       2.5Gi       6.2Gi

Swap:          4.0Gi          0B       4.0Gi




https://github.com/qwxlyx/DevOps/actions/runs/24153847925
из-за ограничений корпоративной сети (ошибки SSL/TLS) ручной запуск был выполнен через GitHub API командой curl. Триггер workflow\_dispatch корректно отработал, что подтверждается логами.


Сравнение триггеров push и workflow\_dispatch

Характеристика	push	workflow\_dispatch

Способ запуска	Автоматически при появлении нового коммита	Вручную через UI или API

Возможность выбора ветки	Нет (запускается на ветке, куда сделан пуш)	Да (можно указать любую ветку, где есть файл)

Требуется коммит	Да	Нет




Runner ubuntu-latest предоставляет виртуальную машину со следующими характеристиками:



Операционная система: Ubuntu 22.04 LTS (актуальная стабильная версия).



Процессор: 2 виртуальных ядра Intel Xeon (модель Platinum 8370C с тактовой частотой 2.8 ГГц).



Оперативная память: \~7.8 ГБ, из которых около 6.2 ГБ доступно для задач.



Дисковое пространство: стандартный объём для GitHub-hosted runners (\~84 ГБ).

