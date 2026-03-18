## Task 1 — Git State Reconciliation

### 1.1 Setup Desired State Configuration

```bash
echo "version: 1.0" > desired-state.txt
echo "app: myapp" >> desired-state.txt
echo "replicas: 3" >> desired-state.txt
cp desired-state.txt current-state.txt
echo "Initial state synchronized"
```

**Вывод:**
```
Initial state synchronized
```

**Исходное содержимое `desired-state.txt`:**
```
version: 1.0
app: myapp
replicas: 3
```

**Исходное содержимое `current-state.txt` (идентично desired):**
```
version: 1.0
app: myapp
replicas: 3
```

### 1.2 Reconciliation Script

**`reconcile.sh`:**

```bash
#!/bin/bash
DESIRED=$(cat desired-state.txt)
CURRENT=$(cat current-state.txt)

if [ "$DESIRED" != "$CURRENT" ]; then
    echo "$(date) - ⚠️  DRIFT DETECTED!"
    echo "Reconciling current state with desired state..."
    cp desired-state.txt current-state.txt
    echo "$(date) - ✅ Reconciliation complete"
else
    echo "$(date) - ✅ States synchronized"
fi
```

```bash
chmod +x reconcile.sh
```

### 1.3 Manual Drift Detection

Симулируем дрейф, перезаписав `current-state.txt`:

```bash
echo "version: 2.0" > current-state.txt
echo "app: myapp" >> current-state.txt
echo "replicas: 5" >> current-state.txt
```

Запускаем согласование:

```bash
./reconcile.sh
```

**Вывод — дрейф обнаружен и исправлен:**
```
Wed Mar 18 21:06:31 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed Mar 18 21:06:31 MSK 2026 - ✅ Reconciliation complete
```

**Проверка через diff:**

```bash
diff desired-state.txt current-state.txt
```
```
(нет вывода — файлы идентичны)
```

**Содержимое `current-state.txt` после согласования:**

```bash
cat current-state.txt
```
```
version: 1.0
app: myapp
replicas: 3
```

Файл `current-state.txt` успешно восстановлен до состояния `desired-state.txt`. Дрейф исправлен.

### 1.4 Automated Continuous Reconciliation

Симулируем непрерывный цикл согласования. На итерации 3 автоматически инжектируется дрейф для демонстрации авто-восстановления:

```bash
for i in {1..5}; do
    echo ""
    echo "--- Iteration $i ---"
    if [ "$i" -eq 3 ]; then
        echo "replicas: 10" >> current-state.txt
        echo "[drift injected]"
    fi
    ./reconcile.sh
    sleep 2
done
```

**Вывод:**
```
--- Iteration 1 ---
Wed Mar 18 21:08:01 MSK 2026 - ✅ States synchronized

--- Iteration 2 ---
Wed Mar 18 21:08:03 MSK 2026 - ✅ States synchronized

--- Iteration 3 ---
[drift injected]
Wed Mar 18 21:08:05 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed Mar 18 21:08:05 MSK 2026 - ✅ Reconciliation complete

--- Iteration 4 ---
Wed Mar 18 21:08:07 MSK 2026 - ✅ States synchronized

--- Iteration 5 ---
Wed Mar 18 21:08:09 MSK 2026 - ✅ States synchronized
```

На итерации 3 был инжектирован дрейф (`replicas: 10`). Цикл автоматически обнаружил и исправил его в той же итерации без ручного вмешательства.

### Анализ: цикл согласования GitOps

Цикл согласования реализует непрерывный цикл наблюдение затем сравнение затем действие:

1. **Observe** — считать текущее состояние системы.
2. **Diff** — сравнить с желаемым состоянием из Git (единый источник истины).
3. **Act** — если есть расхождение, перезаписать текущее состояние желаемым.
4. **Repeat** — выполнять непрерывно с фиксированным интервалом.

Именно так работают ArgoCD и Flux CD: они непрерывно опрашивают Git и через Kubernetes API приводят кластер в соответствие с задекларированными манифестами. Любое ручное изменение в кластере, не отражённое в Git, будет автоматически откатано на следующем цикле. Это делает конфигурационный дрейф невозможным для сохранения — система всегда возвращается к состоянию из репозитория.

### Размышление: декларативная vs. императивная конфигурация

В production декларативная конфигурация критически важна: при десятках сервисов в нескольких кластерах невозможно надёжно отслеживать историю императивных команд. Задекларированное состояние в Git всегда является авторитетным источником истины, что делает систему проверяемой, воспроизводимой и самовосстанавливающейся по своей природе.

## Task 2 — GitOps Health Monitoring

### 2.1 Health Check Script

**`healthcheck.sh`:**

```bash
#!/bin/bash
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

```bash
chmod +x healthcheck.sh
```

### 2.2 Тестирование мониторинга

**Тест 1 — здоровое состояние:**

```bash
./healthcheck.sh
```
```
Wed Mar 18 22:45:03 MSK 2026 - ✅ OK: States synchronized
```

**Тест 2 — симуляция дрейфа:**

```bash
echo "unapproved-change: true" >> current-state.txt
./healthcheck.sh
```
```
Wed Mar 18 22:45:11 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

**Тест 3 — исправление дрейфа и повторная проверка:**

```bash
./reconcile.sh
./healthcheck.sh
```
```
Wed Mar 18 22:45:21 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed Mar 18 22:45:21 MSK 2026 - ✅ Reconciliation complete
Wed Mar 18 22:45:21 MSK 2026 - ✅ OK: States synchronized
```

### 2.3 Непрерывный мониторинг

**`monitor.sh`:**

```bash
#!/bin/bash
echo "Starting GitOps monitoring..."
for i in {1..10}; do
    echo -e "\n--- Check #$i ---"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 3
done
```

```bash
chmod +x monitor.sh
./monitor.sh
```

**Вывод `monitor.sh`:**

```
Starting GitOps monitoring...

--- Check #1 ---
Wed Mar 18 22:45:36 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:36 MSK 2026 - ✅ States synchronized

--- Check #2 ---
Wed Mar 18 22:45:39 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:39 MSK 2026 - ✅ States synchronized

--- Check #3 ---
Wed Mar 18 22:45:42 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:42 MSK 2026 - ✅ States synchronized

--- Check #4 ---
Wed Mar 18 22:45:45 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:45 MSK 2026 - ✅ States synchronized

--- Check #5 ---
Wed Mar 18 22:45:48 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:48 MSK 2026 - ✅ States synchronized

--- Check #6 ---
Wed Mar 18 22:45:51 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:51 MSK 2026 - ✅ States synchronized

--- Check #7 ---
Wed Mar 18 22:45:54 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:54 MSK 2026 - ✅ States synchronized

--- Check #8 ---
Wed Mar 18 22:45:57 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:57 MSK 2026 - ✅ States synchronized

--- Check #9 ---
Wed Mar 18 22:46:00 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:46:00 MSK 2026 - ✅ States synchronized

--- Check #10 ---
Wed Mar 18 22:46:03 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:46:03 MSK 2026 - ✅ States synchronized
```

**Полный `health.log`:**

```
Wed Mar 18 22:45:03 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:11 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Wed Mar 18 22:45:21 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:36 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:39 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:42 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:45 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:48 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:51 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:54 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:45:57 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:46:00 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 22:46:03 MSK 2026 - ✅ OK: States synchronized
```

Лог наглядно демонстрирует три стадии: здоровое состояние → обнаружение дрейфа → восстановление и стабильная работа.

### Анализ: чексуммы MD5 для обнаружения дрейфа

MD5 вычисляет 128-битный отпечаток содержимого файла. Любое изменение — даже одного символа — полностью меняет хэш. Это означает, что healthcheck не читает файлы построчно, а просто сравнивает две короткие строки, что делает проверку быстрой и надёжной. В нашем примере добавление строки `unapproved-change: true` изменило MD5 с `a15a1a4f...` на `48168ff3...` — дрейф был мгновенно обнаружен.

**Ограничение MD5:** алгоритм не является криптографически стойким, поэтому production-инструменты используют SHA-256. Однако для задачи обнаружения дрейфа (не обеспечения безопасности) MD5 полностью подходит.

### Сравнение с ArgoCD Sync Status

ArgoCD расширяет эту модель, дополнительно проверяя **liveness и readiness** ресурсов Kubernetes (рестарты подов, упавшие деплойменты), тогда как наш `healthcheck.sh` симулирует только проверку соответствия манифестов — аналог именно `Sync Status` в ArgoCD.


