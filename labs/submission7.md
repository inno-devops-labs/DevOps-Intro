# Задание 1 — Согласование состояния (Git State Reconciliation)

### Начальное состояние (desired-state.txt)

```text
version: 1.0
app: myapp
replicas: 3
```

### Начальное текущее состояние (current-state.txt)

```text
version: 1.0
app: myapp
replicas: 3
```

### Содержимое скрипта rec.sh

```bash
#!/bin/bash
# rec.sh — GitOps reconciliation loop

DESIRED=$(cat desired-state.txt)
CURRENT=$(cat current-state.txt)

if [ "$DESIRED" != "$CURRENT" ]; then
    echo "$(date) — DRIFT DETECTED!"
    echo "Reconciling current state with desired state..."
    cp desired-state.txt current-state.txt
    echo "$(date) — Reconciliation complete"
else
    echo "$(date) — States synchronized"
fi
```

### Вывод при синхронизированном состоянии

```text
четверг, 19 марта 2026 г. 19:32:50 (MSK) — States synchronized
```

### Обнаружение дрейфа и исправление

```text
четверг, 19 марта 2026 г. 19:33:07 (MSK) — DRIFT DETECTED!
Reconciling current state with desired state...
четверг, 19 марта 2026 г. 19:33:07 (MSK) — Reconciliation complete
```


### Состояние после исправления

```text
version: 1.0
app: myapp
replicas: 3
```
### Автоматическое восстановление (continuous reconciliation)

Автоматическое восстановление состояния подтверждено при многократных проверках в monitor.sh:

```text
четверг, 19 марта 2026 г. 19:35:13 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:16 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:19 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:22 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:25 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:28 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:31 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:34 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:37 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:40 (MSK) — OK: States synchronized
```
### Анализ

Цикл согласования (reconciliation loop) в GitOps сравнивает желаемое состояние системы (desired state) с текущим состоянием (current state).
Если обнаруживается различие (drift), система автоматически приводит текущее состояние к желаемому, копируя данные из источника истины.
Это предотвращает дрейф конфигурации, потому что любые изменения, внесённые вручную или случайно, автоматически исправляются.
Декларативный подход означает, что мы описываем, каким должно быть состояние системы, а не шаги для его достижения.

Преимущества:
* наличие единого источника истины (Git)
* автоматическое восстановление (self-healing)
* упрощение управления конфигурацией
* воспроизводимость среды
* удобство отката изменений

## Задание 2 — Мониторинг состояния (GitOps Health Monitoring)

### Содержимое healthcheck.sh

```bash
#!/bin/bash
# healthcheck.sh — Monitor GitOps sync health

DESIRED_MD5=$(md5 -q desired-state.txt)
CURRENT_MD5=$(md5 -q current-state.txt)

if [ "$DESIRED_MD5" != "$CURRENT_MD5" ]; then
    echo "$(date) — CRITICAL: State mismatch detected!" | tee -a health.log
    echo "Desired MD5: $DESIRED_MD5" | tee -a health.log
    echo "Current MD5: $CURRENT_MD5" | tee -a health.log
else
    echo "$(date) — OK: States synchronized" | tee -a health.log
fi
```


### Содержимое monitor.sh

```bash
#!/bin/bash
# monitor.sh — Combined reconciliation and health monitoring

echo "Starting GitOps monitoring..."
for i in {1..10}; do
    echo "--- Check #$i ---"
    ./healthcheck.sh
    ./rec.sh
    sleep 3
done
```


### Проверка нормального состояния

```text
четверг, 19 марта 2026 г. 19:34:40 (MSK) — OK: States synchronized
```


### Проверка при наличии drift

```text
четверг, 19 марта 2026 г. 19:34:47 (MSK) — CRITICAL: State mismatch detected!
Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

### Полный лог health.log

```text
четверг, 19 марта 2026 г. 19:34:40 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:34:47 (MSK) — CRITICAL: State mismatch detected!
Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
четверг, 19 марта 2026 г. 19:34:55 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:13 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:16 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:19 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:22 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:25 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:28 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:31 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:34 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:37 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:40 (MSK) — OK: States synchronized
```
### Вывод monitor.sh

```text
Starting GitOps monitoring...

--- Check #1 ---
четверг, 19 марта 2026 г. 19:35:13 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:13 (MSK) — States synchronized

--- Check #2 ---
четверг, 19 марта 2026 г. 19:35:16 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:16 (MSK) — States synchronized

--- Check #3 ---
четверг, 19 марта 2026 г. 19:35:19 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:19 (MSK) — States synchronized

--- Check #4 ---
четверг, 19 марта 2026 г. 19:35:22 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:22 (MSK) — States synchronized

--- Check #5 ---
четверг, 19 марта 2026 г. 19:35:25 (MSK) — OK: States synchronized
четверг, 19 марта 2026 г. 19:35:25 (MSK) — States synchronized
```


### Анализ

Контрольные суммы (MD5) позволяют определить изменения в файлах.
Даже незначительное изменение содержимого приводит к изменению хеша, поэтому можно быстро обнаружить расхождение между desired и current состояниями.

### Сравнение

Это аналогично механизму Sync Status в ArgoCD.
ArgoCD сравнивает состояние в Git (desired) с текущим состоянием кластера:
* Synced — если совпадает
* OutOfSync — если есть различия
В данной лабораторной работе это реализовано через сравнение файлов и контрольных сумм.

