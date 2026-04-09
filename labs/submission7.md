\# Лабораторная работа №7



\## Задание 1 



\### 1.1 Настройка желаемого состояния (Source of Truth)



\*\*desired-state.txt:\*\*
version: 1.0

app: myapp

replicas: 3




\*\*current-state.txt (начальное, скопировано из desired-state.txt):\*\*
version: 1.0

app: myapp

replicas: 3



\### 1.2 Скрипт reconcile.sh



```bash

\#!/bin/bash

\# reconcile.sh - GitOps reconciliation loop



DESIRED=$(cat desired-state.txt)

CURRENT=$(cat current-state.txt)



if \[ "$DESIRED" != "$CURRENT" ]; then

&#x20;   echo "$(date) - ⚠️  DRIFT DETECTED!"

&#x20;   echo "Reconciling current state with desired state..."

&#x20;   cp desired-state.txt current-state.txt

&#x20;   echo "$(date) - ✅ Reconciliation complete"

else

&#x20;   echo "$(date) - ✅ States synchronized"

fi

1.3 Ручное обнаружение дрейфа

Симуляция дрейфа (current-state.txt изменён вручную):
version: 2.0

app: myapp

replicas: 5

Запуск ./reconcile.sh:
Чт 09 апр 2026 20:54:06 MSK - ⚠️  DRIFT DETECTED!

Reconciling current state with desired state...

Чт 09 апр 2026 20:54:06 MSK - ✅ Reconciliation complete
diff desired-state.txt current-state.txt   # нет вывода

cat current-state.txt
version: 1.0

app: myapp

replicas: 3

1.4 Автоматический непрерывный цикл (watch)

В первом терминале: watch -n 5 ./reconcile.sh

Во втором терминале: echo "replicas: 10" >> current-state.txt



Наблюдение в первом терминале (вывод watch):
Чт 09 апр 2026 20:54:06 MSK - ⚠️  DRIFT DETECTED!

Reconciling current state with desired state...

Чт 09 апр 2026 20:54:06 MSK - ✅ Reconciliation complete
Анализ:

Цикл реконсиляции непрерывно сравнивает желаемое состояние (desired-state.txt) с текущим (current-state.txt). При обнаружении дрейфа он автоматически исправляет его, копируя desired-state.txt в current-state.txt. Это предотвращает накопление конфигурационного дрейфа. Декларативный подход (описываем ЧТО нужно) обеспечивает идемпотентность, предсказуемость и упрощает аудит по сравнению с императивными командами.

Задание 2
2.1 Скрипт healthcheck.sh

#!/bin/bash

\# healthcheck.sh - Monitor GitOps sync health



DESIRED\_MD5=$(md5sum desired-state.txt | awk '{print $1}')

CURRENT\_MD5=$(md5sum current-state.txt | awk '{print $1}')



if \[ "$DESIRED\_MD5" != "$CURRENT\_MD5" ]; then

&#x20;   echo "$(date) - ❌ CRITICAL: State mismatch detected!" | tee -a health.log

&#x20;   echo "  Desired MD5: $DESIRED\_MD5" | tee -a health.log

&#x20;   echo "  Current MD5: $CURRENT\_MD5" | tee -a health.log

else

&#x20;   echo "$(date) - ✅ OK: States synchronized" | tee -a health.log

fi

2.2 Тестирование healthcheck.sh

Синхронизированное состояние:

./reconcile.sh

./healthcheck.sh
Чт 09 апр 2026 20:56:15 MSK - ✅ States synchronized

Чт 09 апр 2026 20:56:15 MSK - ✅ OK: States synchronized

Симуляция дрейфа:

echo "unapproved-change: true" >> current-state.txt

./healthcheck.sh
Чт 09 апр 2026 20:56:24 MSK - ❌ CRITICAL: State mismatch detected!

&#x20; Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155

&#x20; Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Исправление дрейфа:
./reconcile.sh

./healthcheck.sh
Чт 09 апр 2026 20:56:29 MSK - ⚠️  DRIFT DETECTED!

Reconciling current state with desired state...

Чт 09 апр 2026 20:56:29 MSK - ✅ Reconciliation complete

Чт 09 апр 2026 20:56:29 MSK - ✅ OK: States synchronized

2.3 Непрерывный мониторинг (monitor.sh)

Скрипт monitor.sh:
#!/bin/bash

\# monitor.sh - Combined reconciliation and health monitoring



echo "Starting GitOps monitoring..."

for i in {1..10}; do

&#x20;   echo -e "\\n--- Check #$i ---"

&#x20;   ./healthcheck.sh

&#x20;   ./reconcile.sh

&#x20;   sleep 3

done
Запуск: ./monitor.sh



Вывод (сокращённо, первые и последние итерации):

Starting GitOps monitoring...



\--- Check #1 ---

Чт 09 апр 2026 20:57:04 MSK - ✅ OK: States synchronized

Чт 09 апр 2026 20:57:04 MSK - ✅ States synchronized



\--- Check #2 ---

Чт 09 апр 2026 20:57:07 MSK - ✅ OK: States synchronized

Чт 09 апр 2026 20:57:07 MSK - ✅ States synchronized

...

\--- Check #10 ---

Чт 09 апр 2026 20:57:32 MSK - ✅ OK: States synchronized

Чт 09 апр 2026 20:57:32 MSK - ✅ States synchronized

Итоговый health.log:
Чт 09 апр 2026 20:56:15 MSK - ✅ OK: States synchronized

Чт 09 апр 2026 20:56:24 MSK - ❌ CRITICAL: State mismatch detected!

&#x20; Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155

&#x20; Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5

Чт 09 апр 2026 20:56:29 MSK - ✅ OK: States synchronized

Чт 09 апр 2026 20:57:04 MSK - ✅ OK: States synchronized

Чт 09 апр 2026 20:57:07 MSK - ✅ OK: States synchronized

Чт 09 апр 2026 20:57:10 MSK - ✅ OK: States synchronized

Чт 09 апр 2026 20:57:14 MSK - ✅ OK: States synchronized

Чт 09 апр 2026 20:57:17 MSK - ✅ OK: States synchronized

Чт 09 апр 2026 20:57:20 MSK - ✅ OK: States synchronized

Чт 09 апр 2026 20:57:23 MSK - ✅ OK: States synchronized

Чт 09 апр 2026 20:57:26 MSK - ✅ OK: States synchronized

Чт 09 апр 2026 20:57:29 MSK - ✅ OK: States synchronized

Чт 09 апр 2026 20:57:32 MSK - ✅ OK: States synchronized


Анализ:

MD5-хеши позволяют однозначно детектировать любые изменения в конфигурации. При дрейфе healthcheck.sh сигнализирует CRITICAL и логирует хеши. reconcile.sh автоматически восстанавливает синхронизацию. Это похоже на механизм Sync Status в ArgoCD/Flux, где контрольные суммы ресурсов сравниваются между Git и кластером. Непрерывный мониторинг (monitor.sh) с логами обеспечивает наблюдаемость и проактивное обнаружение проблем.



Выводы

GitOps базируется на декларативном описании состояния в Git как едином источнике истины.



Автоматическая реконсиляция (reconcile.sh) и мониторинг здоровья (healthcheck.sh) являются ключевыми компонентами самоисцеляющихся систем.



Использование контрольных сумм (MD5) позволяет точно детектировать дрейф.



