# Task 1
CPU Usage
Rank PID(s) Process CPU%
1 237, 278 python3 0.3% 
2 1062–1065 /usr/libexec/packagekitd 0.3%
3 203, 247–253, 272 /usr/libexec/wsl-pro-service 0.2% 

Memory Usage
Rank PID(s) Process RES
1 1062–1065 /usr/libexec/packagekitd 17,556 KB
2 55 /usr/lib/systemd/systemd-journald 14,980 KB
3 237, 278 python3 13,172 KB

I/O Usage
Rank PID(s) Process Disk R/W
1 326 -bash (somepatt) 0.00 B/s
2 430 -bash (somepatt) 0.00 B/s
3 1119 htop 0.00 B/s

![alt text](image-1.png)


435M    /var/log
431M    /var/log/journal/063c46c6485847879e7ee0198b50efff
431M    /var/log/journal

Система практически простаивает — ни один процесс не превышает 0.3% CPU. Главные наблюдения:

Дублирование процессов: wsl-pro-service запущен 7+ раз, packagekitd — 4 раза. Суммарно жрут больше, чем кажется по отдельности.
Фоновые демоны — главные потребители, а не пользовательские задачи.
Журнал на 431 МБ — самая конкретная проблема.

Оптимизация
1. Почистить журнал
2. Отключить ненужные для WSL демоны

# Task 2

https://github.com
![alt text](image-2.png)
![alt text](image-3.png)
![alt text](image-4.png)
![alt text](image-5.png)

Проверка Status code = 200 — минимально необходимое условие: сайт должен отвечать. Если он вернёт 5xx или 404, это немедленно триггерит алерт.
Частота 10 секунд — максимально быстрое обнаружение проблем.
Алерт на email — базовый канал уведомлений настроен.

Эта конфигурация даёт раннее обнаружение проблем:

Если github.com упадёт или замедлится — уведомление придёт в течение секунд, а не минут.
Разделение на degraded и failed позволяет различать «медленно» и «совсем сломано» — разные уровни инцидента, разная реакция.