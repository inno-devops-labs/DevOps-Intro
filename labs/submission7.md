# Задание 1

Изначальная версия `desired-state.txt`

```
version: 1.0
app: myapp
replicas: 3
```

Далее выводы консоли:
```
root@ad7ff78d1314:/# ./reconcile.sh
Sun Mar 15 19:53:43 UTC 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun Mar 15 19:53:43 UTC 2026 - ✅ Reconciliation complete
root@ad7ff78d1314:/# diff desired-state.txt current-state.txt
root@ad7ff78d1314:/# cat current-state.txt
version: 1.0
app: myapp
replicas: 3
```

Затем вывод о синхронизации (`watch -n 5 ./reconcile.sh`):

```
Every 5.0s: ./reconcile.sh                                                                                  ad7ff78d1314: Mon Mar 16 14:09:50 2026

Mon Mar 16 14:09:50 UTC 2026 -     States synchronized
```

Это все нужно, чтобы желаемое состояние всегда совпадало с текущим. Например, если сисадмин захочет сделать изменение прямо на сервере, это может привести к ошибкам. Поэтому все изменения сразу откатываются до желаемых.

И про вопрос про разницу. Мы можем явно задать, что нужно сделать компьютеру (императивный способ), а можно просто сказать  "должно быть так" (то есть задать желаемое состояние -- декларативный способ). Преимущество в том, что система сама находит кратчайший способ добиться желаемого состояния. Также легко делать откаты (не те, о которых можно было подумать) в случае ошибок. А отсюда следует, что это можно масштабировать.


# Задание 2

Скрипт `healthcheck.sh`:
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

Статус OK:
```
Mon Mar 16 14:27:02 UTC 2026 - ✅ OK: States synchronized
```

Статус CRITICAL:
```
Mon Mar 16 14:27:30 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

Файл `health.log`:
```
Mon Mar 16 14:27:02 UTC 2026 - ✅ OK: States synchronized
Mon Mar 16 14:27:30 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Mon Mar 16 14:27:52 UTC 2026 - ✅ OK: States synchronized
```

Вывод монитора:
```
root@ad7ff78d1314:/# ./monitor.sh
Starting GitOps monitoring...
\n--- Check #1 ---
Mon Mar 16 14:30:50 UTC 2026 - ✅ OK: States synchronized
Mon Mar 16 14:30:50 UTC 2026 - ✅ States synchronized
\n--- Check #2 ---
Mon Mar 16 14:30:53 UTC 2026 - ✅ OK: States synchronized
Mon Mar 16 14:30:53 UTC 2026 - ✅ States synchronized
\n--- Check #3 ---
Mon Mar 16 14:30:56 UTC 2026 - ✅ OK: States synchronized
Mon Mar 16 14:30:56 UTC 2026 - ✅ States synchronized
\n--- Check #4 ---
Mon Mar 16 14:30:59 UTC 2026 - ✅ OK: States synchronized
Mon Mar 16 14:30:59 UTC 2026 - ✅ States synchronized
\n--- Check #5 ---
Mon Mar 16 14:31:02 UTC 2026 - ✅ OK: States synchronized
Mon Mar 16 14:31:02 UTC 2026 - ✅ States synchronized
\n--- Check #6 ---
Mon Mar 16 14:31:05 UTC 2026 - ✅ OK: States synchronized
Mon Mar 16 14:31:05 UTC 2026 - ✅ States synchronized
^C
```

Контрольные суммы -- это хеши, которые должны быть в идеальном мире уникальными для всех файлов (хотя возможны коллизии). Если они отличаются, значит файлы разные. Посчитать хеши для двух файлов и сравнить достаточно просто.

ArgoCD работает по такому принципу. Если совпадают хеши, устанавливается Sync Status.
