I.

1.
Изначально в обоих файлах

version: 1.0
app: myapp
replicas: 3

2. 
./reconcile.sh
diff desired-state.txt current-state.txt

Thu Mar 19 11:58:37 PM MSK 2026 - ⚠  DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 19 11:58:37 PM MSK 2026 - ✅ Reconciliation complete

3.
А этот вывод уже из auto-healing:

Fri Mar 20 12:00:10 AM MSK 2026 - ⚠  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 12:00:10 AM MSK 2026 - ✅ Reconciliation complete

4. Этот цикл в режиме реального времени синхронизирует содержимое двух документов. Это позволяет избежать configuration drift.
5. Декларативная версия фиксирует ожидаемый результат, а не действия. В production это важно для автоматического восстановления после сбоев.

II.

1.
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

2.
user@user-pc:~/Desktop$ echo "replicas: 10" >> current-state.txt
user@user-pc:~/Desktop$ echo "replicas: 10" >> current-state.txt
user@user-pc:~/Desktop$ chmod +x healthcheck.sh
user@user-pc:~/Desktop$ 
./healthcheck.sh
cat health.log
Fri Mar 20 12:02:19 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:02:19 AM MSK 2026 - ✅ OK: States synchronized
user@user-pc:~/Desktop$ echo "unapproved-change: true" >> current-state.txt
user@user-pc:~/Desktop$ 
./healthcheck.sh
cat health.log
Fri Mar 20 12:02:40 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:02:19 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:02:40 AM MSK 2026 - ✅ OK: States synchronized
user@user-pc:~/Desktop$ 
./reconcile.sh
./healthcheck.sh
cat health.log
Fri Mar 20 12:02:53 AM MSK 2026 - ✅ States synchronized
Fri Mar 20 12:02:53 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:02:19 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:02:40 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:02:53 AM MSK 2026 - ✅ OK: States synchronized

3. CRITICAL высвечено не было ни разу.

4. Fri Mar 20 12:02:19 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:02:40 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:02:53 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:06:58 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:01 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:04 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:07 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:10 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:13 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:16 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:19 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:22 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:26 AM MSK 2026 - ✅ OK: States synchronized

5. user@user-pc:~/Desktop$ ./monitor.sh
Starting GitOps monitoring...
\n--- Check #1 ---
Fri Mar 20 12:06:58 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:06:58 AM MSK 2026 - ✅ States synchronized
\n--- Check #2 ---
Fri Mar 20 12:07:01 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:01 AM MSK 2026 - ✅ States synchronized
\n--- Check #3 ---
Fri Mar 20 12:07:04 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:04 AM MSK 2026 - ✅ States synchronized
\n--- Check #4 ---
Fri Mar 20 12:07:07 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:07 AM MSK 2026 - ✅ States synchronized
\n--- Check #5 ---
Fri Mar 20 12:07:10 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:10 AM MSK 2026 - ✅ States synchronized
\n--- Check #6 ---
Fri Mar 20 12:07:13 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:13 AM MSK 2026 - ✅ States synchronized
\n--- Check #7 ---
Fri Mar 20 12:07:16 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:16 AM MSK 2026 - ✅ States synchronized
\n--- Check #8 ---
Fri Mar 20 12:07:19 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:19 AM MSK 2026 - ✅ States synchronized
\n--- Check #9 ---
Fri Mar 20 12:07:22 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:23 AM MSK 2026 - ✅ States synchronized
\n--- Check #10 ---
Fri Mar 20 12:07:26 AM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:07:26 AM MSK 2026 - ✅ States synchronized

6. MD5 создает уникальный хэш на основе содержимого файла. Если хэши разные, то и файлы (скорее всего) разные, поэтому нет нужды анализировать огромные файлы построчно.
7. ArgoCD использует аналогичный принцип для определения статуса синхронизации: он сравнивает хэш желаемого состояния в Git с хэшем текущего состояния
