# Task1 

![alt text](image-1.png)
![alt text](image-2.png)
![alt text](image-3.png)

somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ echo "replicas: 5" >> current-state.txt
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ diff desired-state.txt current-state.txt
Binary files desired-state.txt and current-state.txt differ
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ ./reconcile.sh
./reconcile.sh: line 1: warning: command substitution: ignored null byte in input
./reconcile.sh: line 2: warning: command substitution: ignored null byte in input
Sun Mar 15 00:39:58 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun Mar 15 00:39:58 MSK 2026 - ✅ Reconciliation complete

Reconciliation loop помогает откатывать изменения в конфиге к изначальному состоянию. Это очень полезно, если кто-то меняет конфиг руками, то есть вероятность, что сервер может упасть из-за изменения, поэтому этот цикл каждые N секунд/минут сбрасывает конфиг до изначального рабочего состояния.

Декларативный конфиг имеет преимущество, так как мы не диктуем системе шаги, которые нужно предпринять, а говорим ей, то, что должно получиться в итоге. В отличие от декларативного конфига, императивный требует описание шагов, и в случае ошибки на k-ом шаге, система не знает, что должно быть дальше и все ломается


# Task2 

somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ ./healthcheck.sh
Sun Mar 15 00:51:38 MSK 2026 - ✅ OK: States synchronized
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ cat health.log
Sun Mar 15 00:51:38 MSK 2026 - ✅ OK: States synchronized
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ echo "unapproved-change: true" >> current-state.txt
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ cat health.log
./reconcile.sh: line 2: warning: command substitution: ignored null byte in input
Sun Mar 15 00:52:09 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun Mar 15 00:52:09 MSK 2026 - ✅ Reconciliation complete
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ ./healthcheck.sh
Sun Mar 15 00:52:13 MSK 2026 - ✅ OK: States synchronized
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ cat health.log
Sun Mar 15 00:51:38 MSK 2026 - ✅ OK: States synchronized
Sun Mar 15 00:51:53 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: 71a29f10311a1948c950c6f5528a5937
  Current MD5: 6ed6f9d4d12daea40d2144e2e22f1914
Sun Mar 15 00:52:13 MSK 2026 - ✅ OK: States synchronized
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ chmod +x monitor.sh                  
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ ./monitor.sh
Starting GitOps monitoring...
\n--- Check #1 ---
Sun Mar 15 00:52:47 MSK 2026 - ✅ OK: States synchronized
./reconcile.sh: line 1: warning: command substitution: ignored null byte in input
./reconcile.sh: line 2: warning: command substitution: ignored null byte in input
Sun Mar 15 00:52:47 MSK 2026 - ✅ States synchronized
\n--- Check #2 ---
Sun Mar 15 00:52:50 MSK 2026 - ✅ OK: States synchronized
./reconcile.sh: line 1: warning: command substitution: ignored null byte in input
./reconcile.sh: line 2: warning: command substitution: ignored null byte in input
Sun Mar 15 00:52:50 MSK 2026 - ✅ States synchronized
\n--- Check #3 ---
Sun Mar 15 00:52:53 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: 71a29f10311a1948c950c6f5528a5937
  Current MD5: 0d39e77fb04dc93d4c2379569d2491bd
./reconcile.sh: line 1: warning: command substitution: ignored null byte in input
./reconcile.sh: line 2: warning: command substitution: ignored null byte in input
Sun Mar 15 00:52:54 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun Mar 15 00:52:54 MSK 2026 - ✅ Reconciliation complete
\n--- Check #4 ---
Sun Mar 15 00:52:57 MSK 2026 - ✅ OK: States synchronized
./reconcile.sh: line 1: warning: command substitution: ignored null byte in input
./reconcile.sh: line 2: warning: command substitution: ignored null byte in input
Sun Mar 15 00:52:57 MSK 2026 - ✅ States synchronized
\n--- Check #5 ---
Sun Mar 15 00:53:00 MSK 2026 - ✅ OK: States synchronized
./reconcile.sh: line 1: warning: command substitution: ignored null byte in input
./reconcile.sh: line 2: warning: command substitution: ignored null byte in input
Sun Mar 15 00:53:00 MSK 2026 - ✅ States synchronized
\n--- Check #6 ---
Sun Mar 15 00:53:03 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: 71a29f10311a1948c950c6f5528a5937
  Current MD5: 0d39e77fb04dc93d4c2379569d2491bd
./reconcile.sh: line 1: warning: command substitution: ignored null byte in input
./reconcile.sh: line 2: warning: command substitution: ignored null byte in input
Sun Mar 15 00:53:03 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun Mar 15 00:53:03 MSK 2026 - ✅ Reconciliation complete
\n--- Check #7 ---
Sun Mar 15 00:53:06 MSK 2026 - ✅ OK: States synchronized
./reconcile.sh: line 1: warning: command substitution: ignored null byte in input
./reconcile.sh: line 2: warning: command substitution: ignored null byte in input
Sun Mar 15 00:53:06 MSK 2026 - ✅ States synchronized
\n--- Check #8 ---
Sun Mar 15 00:53:09 MSK 2026 - ✅ OK: States synchronized
./reconcile.sh: line 1: warning: command substitution: ignored null byte in input
./reconcile.sh: line 2: warning: command substitution: ignored null byte in input
Sun Mar 15 00:53:09 MSK 2026 - ✅ States synchronized
\n--- Check #9 ---
Sun Mar 15 00:53:12 MSK 2026 - ✅ OK: States synchronized
./reconcile.sh: line 1: warning: command substitution: ignored null byte in input
./reconcile.sh: line 2: warning: command substitution: ignored null byte in input
Sun Mar 15 00:53:12 MSK 2026 - ✅ States synchronized
\n--- Check #10 ---
Sun Mar 15 00:53:15 MSK 2026 - ✅ OK: States synchronized
./reconcile.sh: line 1: warning: command substitution: ignored null byte in input
./reconcile.sh: line 2: warning: command substitution: ignored null byte in input
Sun Mar 15 00:53:15 MSK 2026 - ✅ States synchronized


Мы сохраняем изначально состояние файла определенным хэшем. Любое измененый файл будет иметь уже другой хэш. Поэтому удобно сравнивать изменения не целыми файлами, а только хэшами.

Checksums - это механизм, а ArgoCD's "Sync Status" интерфейс, благодаря которому удобно пользоваться этим алгоритмом. Этот интерфейс удобно показывает результат сравнения хэшей.