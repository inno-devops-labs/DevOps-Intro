# Lab 7 — GitOps Fundamentals Submission

## Task 1 — Git State Reconciliation

### Initial State Configurations
`cat desired-state.txt`
```text
version: 1.0
app: myapp
replicas: 3
```

`cat current-state.txt`
```text
version: 1.0
app: myapp
replicas: 3
```

### Manual Drift Detection and Reconciliation
`./reconcile.sh`
```text
Wed Mar 18 05:55:21 PM UTC 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed Mar 18 05:55:21 PM UTC 2026 - ✅ Reconciliation complete
```

### Synchronized State After Reconciliation
`cat current-state.txt`
```text
version: 1.0
app: myapp
replicas: 3
```

### Continuous Reconciliation Auto-Healing
`echo "replicas: 10" >> current-state.txt`
```text
Every 5.0s: ./reconcile.sh                  UbuntuLab5: Wed Mar 18 18:03:33 2026

Wed Mar 18 06:03:33 PM UTC 2026 - ✅ States synchronized
```

### Analysis
**Explain the GitOps reconciliation loop. How does this prevent configuration drift?**
Цикл согласования (reconciliation loop) в GitOps работает как бесконечный процесс сверки. Он непрерывно сравнивает фактическое состояние системы (current state) с желаемым эталонным состоянием, описанным в репозитории (desired state). Если кто-то или что-то вручную изменяет конфигурацию на сервере, возникает "дрейф конфигурации" (drift). Цикл согласования моментально замечает эту разницу и автоматически перезаписывает текущее состояние эталонным, тем самым жестко пресекая любые несанкционированные или случайные изменения.

**What advantages does declarative configuration have over imperative commands in production?**
Декларативный подход позволяет описать конечный результат (например, "мне нужно 3 реплики приложения"), а не команды, как этого достичь. Главные преимущества:
1. **Воспроизводимость и читаемость:** Инфраструктура описана как код, который легко читать и версионировать в Git.
2. **Самовосстановление (Self-healing):** Система сама понимает, что нужно сделать, чтобы вернуть всё в норму при сбоях.
3. **Безопасность и аудит:** Все изменения проходят через Git (Pull Requests), что снижает риск человеческой ошибки и сохраняет историю изменения каждого параметра.


## Task 2 — GitOps Health Monitoring

### Healthcheck Script Contents
```bash
#!/bin/bash
# healthcheck.sh - Monitor GitOps sync health

DESIRED_MD5=$(md5sum desired-state.txt | awk '{print $1}')
CURRENT_MD5=$(md5sum current-state.txt | awk '{print $1}')

if [ "$DESIRED_MD5" != "$CURRENT_MD5" ]; then
    echo "$(date) - ❌ CRITICAL: State mismatch detected!" | tee -a health.log
    echo "  Desired MD5: $DESIRED_MD5" | tee -a health.log
    echo "  Current MD5: $CURRENT_MD5" | tee -a health.log
else
    echo "$(date) - ✅ OK: States synchronized" | tee -a health.log
fi
```

### Healthy State Output
`./healthcheck.sh`
`cat health.log`
```text
Wed Mar 18 06:10:15 PM UTC 2026 - ✅ OK: States synchronized
Wed Mar 18 06:10:15 PM UTC 2026 - ✅ OK: States synchronize
```

### Drifted State Output (CRITICAL)
`echo "unapproved-change: true" >> current-state.txt`
`./healthcheck.sh`
`cat health.log`
```
echo "unapproved-change: true" >> current-state.txt
./healthcheck.sh
cat health.log```
```text
Wed Mar 18 06:11:59 PM UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Wed Mar 18 06:10:15 PM UTC 2026 - ✅ OK: States synchronized
Wed Mar 18 06:11:59 PM UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

### Complete Health Log
`./reconcile.sh`
`./healthcheck.sh`
`cat health.log`
```text
Wed Mar 18 06:12:58 PM UTC 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed Mar 18 06:12:58 PM UTC 2026 - ✅ Reconciliation complete
Wed Mar 18 06:12:58 PM UTC 2026 - ✅ OK: States synchronized
Wed Mar 18 06:10:15 PM UTC 2026 - ✅ OK: States synchronized
Wed Mar 18 06:11:59 PM UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Wed Mar 18 06:12:58 PM UTC 2026 - ✅ OK: States synchronize
```

### Continuous Monitoring Output
`./monitor.sh`
```text
Starting GitOps monitoring...

--- Check #1 ---
Wed Mar 18 06:19:27 PM UTC 2026 - ✅ OK: States synchronized
Wed Mar 18 06:19:27 PM UTC 2026 - ✅ States synchronized

--- Check #2 ---
Wed Mar 18 06:19:30 PM UTC 2026 - ✅ OK: States synchronized
Wed Mar 18 06:19:30 PM UTC 2026 - ✅ States synchronized

--- Check #3 ---
Wed Mar 18 06:19:33 PM UTC 2026 - ✅ OK: States synchronized
Wed Mar 18 06:19:33 PM UTC 2026 - ✅ States synchronized

--- Check #4 ---
Wed Mar 18 06:19:36 PM UTC 2026 - ✅ OK: States synchronized
Wed Mar 18 06:19:36 PM UTC 2026 - ✅ States synchronized

--- Check #5 ---
Wed Mar 18 06:19:39 PM UTC 2026 - ✅ OK: States synchronized
Wed Mar 18 06:19:39 PM UTC 2026 - ✅ States synchronized

--- Check #6 ---
Wed Mar 18 06:19:42 PM UTC 2026 - ✅ OK: States synchronized
Wed Mar 18 06:19:42 PM UTC 2026 - ✅ States synchronized

--- Check #7 ---
Wed Mar 18 06:19:45 PM UTC 2026 - ✅ OK: States synchronized
Wed Mar 18 06:19:45 PM UTC 2026 - ✅ States synchronized

--- Check #8 ---
Wed Mar 18 06:19:48 PM UTC 2026 - ✅ OK: States synchronized
Wed Mar 18 06:19:48 PM UTC 2026 - ✅ States synchronized

--- Check #9 ---
Wed Mar 18 06:19:51 PM UTC 2026 - ✅ OK: States synchronized
Wed Mar 18 06:19:51 PM UTC 2026 - ✅ States synchronized

--- Check #10 ---
Wed Mar 18 06:19:55 PM UTC 2026 - ✅ OK: States synchronized
Wed Mar 18 06:19:55 PM UTC 2026 - ✅ States synchronized
```

### Analysis
**How do checksums (MD5) help detect configuration changes?**
Алгоритмы хеширования (например, MD5) преобразуют содержимое файла любой длины в уникальную строку фиксированного размера. Главная особенность хеша в том, что изменение даже одного пробела или символа в исходном файле приведет к совершенно другому результату хеширования. Это позволяет скриптам практически мгновенно сравнивать короткие MD5-строки вместо того, чтобы построчно анализировать и сравнивать тяжелые текстовые файлы конфигурации.

**How does this relate to GitOps tools like ArgoCD's "Sync Status"?**
Наш скрипт проверки MD5 — это упрощенная симуляция того, как ArgoCD определяет статус "Sync Status". Под капотом ArgoCD постоянно сравнивает манифесты Kubernetes, хранящиеся в Git-репозитории, с реальными объектами, запущенными в кластере. Если хеши или конкретные поля объектов совпадают, ArgoCD показывает статус `Synced` (как наше `✅ OK`). Если манифесты в Git изменились или кто-то вручную поправил ресурс в кластере (дрейф), ArgoCD мгновенно видит несовпадение и переводит статус в `Out of Sync` (как наше `❌ CRITICAL`).