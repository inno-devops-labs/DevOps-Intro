## Task 1.

```
/mnt/c/Users/Георгий/gitops-lab7$ ls
current-state.txt  desired-state.txt

georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/gitops-lab7$ cat desired-state.txt
version: 1.0
app: myapp
replicas: 3

georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/gitops-lab7$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3

./reconcile.sh
Thu Mar 19 21:57:36 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 19 21:57:36 MSK 2026 - ✅ Reconciliation complete
```

Цикл согласования непрерывно сравнивает желаемое и текущее состояние. При обнаружении отклонения он автоматически восстанавливает правильную конфигурацию.
Декларативный подход безопаснее, обеспечивает повторяемость и позволяет автоматизировать процессы, подобно самовосстанавливающимся системам.

![[lab7_1.png]]

## Task 2.
```
nano healthcheck.sh

chmod +x healthcheck.sh

./healthcheck.sh
Thu Mar 19 22:17:01 MSK 2026 - ✅ OK: States synchronized

cat health.log
Thu Mar 19 22:17:01 MSK 2026 - ✅ OK: States synchronized

echo "hack: true" >> current-state.txt

./healthcheck.sh
Thu Mar 19 22:17:25 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: d89d00cb648345e04af5f1020f16c49f
  
cat health.log
Thu Mar 19 22:17:01 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:17:25 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: d89d00cb648345e04af5f1020f16c49f
  
./reconcile.sh
Thu Mar 19 22:17:40 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 19 22:17:40 MSK 2026 - ✅ Reconciliation complete

./healthcheck.sh
Thu Mar 19 22:17:44 MSK 2026 - ✅ OK: States synchronized

cat health.log
Thu Mar 19 22:17:01 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:17:25 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: d89d00cb648345e04af5f1020f16c49f
Thu Mar 19 22:17:44 MSK 2026 - ✅ OK: States synchronized

nano monitor.sh

chmod +x monitor.sh

./monitor.sh
Starting GitOps monitoring...
\n--- Check #1 ---
Thu Mar 19 22:19:39 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:19:39 MSK 2026 - ✅ States synchronized
\n--- Check #2 ---
Thu Mar 19 22:19:42 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:19:42 MSK 2026 - ✅ States synchronized
\n--- Check #3 ---
Thu Mar 19 22:19:45 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:19:45 MSK 2026 - ✅ States synchronized
\n--- Check #4 ---
Thu Mar 19 22:19:48 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:19:48 MSK 2026 - ✅ States synchronized
\n--- Check #5 ---
Thu Mar 19 22:19:51 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:19:51 MSK 2026 - ✅ States synchronized
\n--- Check #6 ---
Thu Mar 19 22:19:54 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:19:54 MSK 2026 - ✅ States synchronized
\n--- Check #7 ---
Thu Mar 19 22:19:57 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:19:57 MSK 2026 - ✅ States synchronized
\n--- Check #8 ---
Thu Mar 19 22:20:00 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:20:00 MSK 2026 - ✅ States synchronized
\n--- Check #9 ---
Thu Mar 19 22:20:03 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:20:03 MSK 2026 - ✅ States synchronized
\n--- Check #10 ---
Thu Mar 19 22:20:06 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:20:06 MSK 2026 - ✅ States synchronized

cat health.log
Thu Mar 19 22:17:01 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:17:25 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: d89d00cb648345e04af5f1020f16c49f
Thu Mar 19 22:17:44 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:19:39 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:19:42 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:19:45 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:19:48 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:19:51 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:19:54 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:19:57 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:20:00 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:20:03 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 22:20:06 MSK 2026 - ✅ OK: States synchronized
```
Контрольные суммы MD5 позволяют быстро сравнивать содержимое файлов, что делает обнаружение дрейфа надежным.
Аналогично функции ArgoCD Sync Status, где система сравнивает желаемое состояние Git с состоянием работающего кластера и сообщает о рассинхронизации или синхронизации.
