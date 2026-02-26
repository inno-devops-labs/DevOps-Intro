# Lab 4 Submission: Operating Systems & Networking

## Task 1 — Operating System Analysis

### 1.1: Boot Performance Analysis
`systemd-analyze`
```
Startup finished in 982ms (userspace)
graphical.target reached after 974ms in userspace.
```

`systemd-analyze blame | head -n 5`
```
600ms landscape-client.service
196ms snapd.seeded.service
152ms snapd.service
131ms dev-sdc.device
128ms wsl-pro.service
```

`uptime` и `w`
```
22:08:29 up 3 min,  1 user,  load average: 0.00, 0.00, 0.00
 22:08:29 up 3 min,  1 user,  load average: 0.00, 0.00, 0.00
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
amust    pts/1    -                22:04    3:30   0.01s  0.01s -bash
```
Наблюдения: Система загрузилась чрезвычайно быстро (менее чем за 1 секунду). Это типично для WSL, так как ей не нужно загружать полноценное ядро оборудования. Load average равна 0.00, что означает, что она пуста.

### 1.2: Process Forensics
`ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6`
```
    PID    PPID CMD                         %MEM %CPU
    224       1 /usr/bin/python3 /usr/share  0.2  0.0
    175       1 /usr/libexec/wsl-pro-servic  0.1  0.0
     39       1 /usr/lib/systemd/systemd-jo  0.1  0.0
      1       0 /sbin/init                   0.1  0.1
    140       1 /usr/lib/systemd/systemd-re  0.1  0.0
```

`ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6`
```
    PID    PPID CMD                         %MEM %CPU
      1       0 /sbin/init                   0.1  0.1
    148       1 @dbus-daemon --system --add  0.0  0.0
     39       1 /usr/lib/systemd/systemd-jo  0.1  0.0
    224       1 /usr/bin/python3 /usr/share  0.2  0.0
     84       1 /usr/lib/systemd/systemd-ud  0.0  0.0
```
Ответ: Процесс, потребляющий больше всего памяти — python3 (0.2%).

### 1.3: Service Dependencies
`systemctl list-dependencies | head -n 6`
```
default.target
○ ├─display-manager.service
○ ├─systemd-update-utmp-runlevel.service
○ ├─wsl-binfmt.service
● └─multi-user.target
○   ├─apport.service
```
Наблюдения: `default.target` зависит от `multi-user.target`.

`systemctl list-dependencies multi-user.target | head -n 6`
```
multi-user.target
○ ├─apport.service
● ├─console-setup.service
● ├─cron.service
● ├─dbus.service
○ ├─dmesg.service
```
Наблюдения: `multi-user.target` зависит от нескольких важных фоновых служб, таких как `cron` и `dbus`.

### 1.4: User Sessions
`who -a` и `last -n 5`
```
           system boot  2026-02-26 22:04
           run-level 5  2026-02-26 22:04
LOGIN      console      2026-02-26 22:04               203 id=cons
LOGIN      tty1         2026-02-26 22:04               218 id=tty1
amust    - pts/1        2026-02-26 22:04 00:16         462
reboot   system boot  5.15.167.4-micro Thu Feb 26 22:04   still running
reboot   system boot  5.15.167.4-micro Sat Feb 21 16:27   still running
reboot   system boot  5.15.167.4-micro Tue Feb  3 23:04   still running
reboot   system boot  5.15.167.4-micro Tue Feb  3 22:41   still running
reboot   system boot  5.15.167.4-micro Sun Dec 21 22:24   still running

wtmp begins Mon Sep 29 04:27:12 2025
```
Наблюдения: Пользователь amust (я) успешно вошел в систему через псевдотерминал (pts/1), что стандартно для WSL. Команда last показывает историю последних загрузок системы.

### 1.5: Memory Analysis
`free -h`
```
               total        used        free      shared  buff/cache   available
Mem:           7.6Gi       593Mi       7.1Gi       3.2Mi       124Mi       7.0Gi
Swap:          2.0Gi          0B       2.0Gi
```

`cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable`
```
MemTotal:        7993712 kB
MemAvailable:    7387316 kB
SwapTotal:       2097152 kB
```
Наблюдения: В системе много доступной памяти (~7.3 ГБ из 7.9 ГБ). Файл подкачки совершенно не используется, что означает отсутствие нехватки памяти в системе.

#### Resource Utilization Patterns:
В целом, использование ресурсов крайне низкое. Система потребляет минимум процессора (максимум 0.1%) и памяти (максимум 0.2%). Это говорит о том, что у меня на компьютере чистая, простаивающая среда WSL без запущенных тяжелых фоновых приложений.

## Task 2 — Networking Analysis

### 2.1: Network Path Tracing
`traceroute github.com | head -n 3`
```
traceroute to github.com (20.205.243.166), 64 hops max
  1   172.17.208.1  0.323ms  0.318ms  0.110ms
  2   *  *  *
  3   *  *  *
```

`dig github.com`
```

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 29405
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             1692    IN      A       140.82.113.3

;; Query time: 689 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Thu Feb 26 22:36:21 MSK 2026
;; MSG SIZE  rcvd: 55

```
Анализ сетевых путей: Traceroute успешно достигла первого узла `172.17.208.1`, который является внутренним виртуальным шлюзом для WSL. Последующие узлы скрыты (* * *). Несмотря на это, разрешение DNS с помощью команды dig прошло успешно, определив IP домена через локальный DNS-резолвер `10.255.255.254`.

### 2.2: Packet Capture
`sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn`
```
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
23:13:56.745480 eth0  Out IP 172.17.222.XXX.44383 > 8.8.8.8.53: 17629+ [1au] A? github.com. (51)
23:13:57.401763 eth0  In  IP 8.8.8.8.53 > 172.17.222.211.44383: 17629 1/0/1 A 20.205.243.166 (55)
```
#### DNS query/response patterns:
- Example DNS query: `Out IP 172.17.222.XXX.44383 > 8.8.8.8.53: 17629+ [1au] A? github.com.` 
Моя локальная машина WSL (с затёртым IP-адресом 172.17.222.XXX) отправила исходящий запрос к публичному DNS-серверу Google (8.8.8.8) по порту 53, запрашивая 'A' запись (IPv4 адрес) для github.com.
- Example response: `In  IP 8.8.8.8.53 > 172.17.222.XXX.44383: ... A 20.205.243.166` 
DNS-сервер успешно ответил, преобразовав доменное имя в IP-адрес 20.205.243.166.

### 2.3: Reverse DNS
`dig -x 8.8.4.4`
```

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 56822
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   5755    IN      PTR     dns.google.

;; Query time: 1021 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Thu Feb 26 22:40:51 MSK 2026
;; MSG SIZE  rcvd: 73

```

`dig -x 1.1.2.2`
```
;; communications error to 10.255.255.254#53: timed out
;; communications error to 10.255.255.254#53: timed out

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 23100
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         3590    IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23597 7200 1800 604800 3600

;; Query time: 1803 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Thu Feb 26 22:41:20 MSK 2026
;; MSG SIZE  rcvd: 160

```
Comparison of reverse lookup results: Reverse lookup для 8.8.4.4 успешно разрешился в dns.google., подтверждая, что Google настроил действительную PTR-запись для этого IP. С другой стороны, поиск для 1.1.2.2 завершился по тайм-ауту и вернул NXDOMAIN (несуществующий домен), что означает отсутствие обратной DNS (PTR) записи, связанной с этим IP-адресом.
