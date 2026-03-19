## Задание 1

### Исходное содержимое `desired-state.txt`

version: 1.0
app: myapp
replicas: 3

### Исходное содержимое `current-state.txt`
version: 1.0
app: myapp
replicas: 3

### Pезультат обнаружения и согласования дрейфа
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ echo "version: 2.0" > current-state.txt
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ echo "app: myapp" >> current-state.txt
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ echo "replicas: 5" >> current-state.txt
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ cat current-state.txt
version: 2.0
app: myapp
replicas: 5
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ ./reconcile.sh
Thu Mar 19 14:02:45 MSK 2026 - Reconciliation complete
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ diff desired-state.txt current-state.txt

### Вывод, отображающий синхронизированное состояние после согласования.

gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3

### Выходные данные из цикла непрерывного согласования, обнаруживающего автоматическое восстановление

Я запускала цикл непрерывного согласования командой:

gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ watch -n 5 ./reconcile.sh

Во время выполнения watch экран обновлялся автоматически, поэтому отдельный текстовый вывод в терминале не сохранился. Однако сам цикл непрерывного согласования был успешно запущен и использовался для периодической проверки состояния.


### Анализ

Цикл согласования GitOps постоянно сравнивает текущее состояние системы с желаемым состоянием, сохранённым в Git. В этой лабораторной работе `desired-state.txt` задаёт правильную конфигурацию, а `current-state.txt` показывает фактическое состояние. Скрипт `reconcile.sh` проверяет, совпадают ли эти файлы, и при обнаружении различий автоматически восстанавливает текущее состояние.

Это предотвращает расхождение конфигурации, потому что любые случайные или ручные изменения быстро обнаруживаются и исправляются. В результате система остаётся синхронизированной с конфигурацией, объявленной в Git.

### Размышление

Декларативная конфигурация удобнее и надёжнее, потому что описывает конечное желаемое состояние системы, а не набор ручных команд. Её проще хранить в Git, проверять, изменять и повторно применять в разных окружениях.

Императивные команды сильнее зависят от человека и поэтому чаще приводят к ошибкам. В production-среде декларативный подход лучше поддерживает повторяемость, прозрачность изменений и автоматическое восстановление после drift.ss

## Задание 2

### Содержимое скрипта healthcheck.sh

#!/bin/bash
# healthcheck.sh - Monitor GitOps sync health

DESIRED_MD5=$(md5sum desired-state.txt | awk '{print $1}')
CURRENT_MD5=$(md5sum current-state.txt | awk '{print $1}')

if [ "$DESIRED_MD5" != "$CURRENT_MD5" ]; then
    echo "$(date) - CRITICAL: State mismatch detected!" | tee -a health.log
    echo "  Desired MD5: $DESIRED_MD5" | tee -a health.log
    echo "  Current MD5: $CURRENT_MD5" | tee -a health.log
else
    echo "$(date) - OK: States synchronized" | tee -a health.log
fi

### Вывод, отображающий статус «OK», когда состояния совпадают

gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ cat desired-state.txt
version: 1.0
app: myapp
replicas: 3
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ ./healthcheck.sh
Thu Mar 19 18:32:52 MSK 2026 - OK: States synchronized

### При обнаружении дрейфа отображается статус CRITICAL

gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ echo "unapproved-change: true" >> current-state.txt
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3
unapproved-change: true
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ ./healthcheck.sh
Thu Mar 19 19:15:13 MSK 2026 - CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5

### Содержимое скрипта monitor.sh

#!/bin/bash
# monitor.sh - Combined reconciliation and health monitoring

echo "Starting GitOps monitoring..."
for i in {1..10}; do
    echo ""
    echo "--- Check #$i ---"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 3
done 

### Полный файл health.log, содержащий результаты многочисленных проверок

gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ cat health.log
Thu Mar 19 18:32:52 MSK 2026 - OK: States synchronized
Thu Mar 19 19:15:13 MSK 2026 - CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Thu Mar 19 19:16:53 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:31 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:34 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:37 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:40 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:43 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:46 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:49 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:52 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:55 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:58 MSK 2026 - OK: States synchronized

### Вывод команды monitor.sh, демонстрирующий непрерывный мониторинг

gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/gitops-lab$ ./monitor.sh
Starting GitOps monitoring...

--- Check #1 ---
Thu Mar 19 20:04:31 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:31 MSK 2026 - States synchronized

--- Check #2 ---
Thu Mar 19 20:04:34 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:34 MSK 2026 - States synchronized

--- Check #3 ---
Thu Mar 19 20:04:37 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:37 MSK 2026 - States synchronized

--- Check #4 ---
Thu Mar 19 20:04:40 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:40 MSK 2026 - States synchronized

--- Check #5 ---
Thu Mar 19 20:04:43 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:43 MSK 2026 - States synchronized

--- Check #6 ---
Thu Mar 19 20:04:46 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:46 MSK 2026 - States synchronized

--- Check #7 ---
Thu Mar 19 20:04:49 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:49 MSK 2026 - States synchronized

--- Check #8 ---
Thu Mar 19 20:04:52 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:52 MSK 2026 - States synchronized

--- Check #9 ---
Thu Mar 19 20:04:55 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:55 MSK 2026 - States synchronized

--- Check #10 ---
Thu Mar 19 20:04:58 MSK 2026 - OK: States synchronized
Thu Mar 19 20:04:58 MSK 2026 - States synchronized

### Анализ

Контрольные суммы MD5 помогают быстро обнаруживать изменения конфигурации. Если содержимое двух файлов одинаковое, их MD5 совпадают. Если меняется даже один символ, контрольные суммы становятся разными.

`healthcheck.sh` сравнивает MD5 файлов `desired-state.txt` и `current-state.txt`. Благодаря этому можно быстро определить, синхронизированы ли состояния, и обнаружить drift.

### Сравнение с ArgoCD

Эта лабораторная работа показывает тот же принцип, что и ArgoCD Sync Status. ArgoCD сравнивает текущее состояние системы с конфигурацией в Git и показывает, совпадают ли они.

В нашей работе `reconcile.sh` восстанавливает правильное состояние, а `healthcheck.sh` проверяет, есть ли различия. То есть здесь реализована упрощённая модель того, как GitOps-инструменты находят и исправляют drift.