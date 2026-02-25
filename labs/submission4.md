# Task 1.
  
### 1.1 Boot Performance Analysis

**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ systemd-analyze**

	Startup finished in 1.431s (userspace)
	graphical.target reached after 1.389s in userspace.
	
**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ systemd-analyze blame**
	785ms landscape-client.service
	312ms snapd.seeded.service
	249ms snapd.service
	200ms dev-sde.device
	143ms user@1000.service
	126ms dpkg-db-backup.service
	... (100ms<)

**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ uptime**
	 23:42:52 up 5 min,  1 user,  load average: 0.24, 0.09, 0.02

**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ w**

	 23:42:56 up 5 min,  1 user,  load average: 0.22, 0.09, 0.02
	USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
	georgiy  pts/1    -                23:40    2:48   0.00s   ?    -bash

---

### 1.2: Process Forensics

**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6**

    PID    PPID CMD                         %MEM %CPU
    234       1 /usr/bin/python3 /usr/share  0.5  0.0
     41       1 /usr/lib/systemd/systemd-jo  0.4  0.1
    147       1 /usr/lib/systemd/systemd-re  0.3  0.0
      1       0 /sbin/init                   0.3  0.4
    436       1 /usr/lib/systemd/systemd --  0.2  0.0
    
**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6**

    PID    PPID CMD                         %MEM %CPU
      1       0 /sbin/init                   0.3  0.4
     41       1 /usr/lib/systemd/systemd-jo  0.4  0.1
    103      91 (udev-worker)                0.1  0.1
     91       1 /usr/lib/systemd/systemd-ud  0.1  0.1
    158       1 @dbus-daemon --system --add  0.1  0.0

---

### 1.3: Service Dependencies

**systemctl list-dependencies**

	Выводится большое дерево иерархии целей системы, на вершине которого
	default.target
	○ ├─display-manager.service
	○ ├─systemd-update-utmp-runlevel.service
	○ ├─wslg.service
	● └─multi-user.target
	...

**systemctl list-dependencies multi-user.target**

	Выводит это же иерархическое дерево, но имеет корень в multi-user.target
	multi-user.target
	○ ├─apport.service
	● ├─console-setup.service
	● ├─cron.service
	● ├─dbus.service
	○ ├─dmesg.service
	...

---
### 1.4: User Sessions

**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ who -a**

	           system boot  2026-02-25 23:40
	           run-level 5  2026-02-25 23:40
	LOGIN      tty1         2026-02-25 23:40               200 id=tty1
	LOGIN      console      2026-02-25 23:40               184 id=cons
	georgiy  - pts/1        2026-02-25 23:40 00:08         449

**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ last -n 5**

	reboot   system boot  6.6.87.2-microso Wed Feb 25 23:40   still running
	reboot   system boot  6.6.87.2-microso Thu Feb  5 01:17   still running
	reboot   system boot  6.6.87.2-microso Thu Feb  5 01:05   still running
	
	wtmp begins Thu Feb  5 01:05:30 2026

---
### 1.5: Memory Analysis

**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ free -h**
		      total        used        free      shared  buff/cache   available
	Mem:          3.7Gi       399Mi       3.3Gi       3.4Mi       115Mi       3.3Gi
	Swap:         1.0Gi          0B       1.0Gi

**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable**
	MemTotal:        3857620 kB
	MemAvailable:    3444180 kB
	SwapTotal:       1048576 kB

---
- Больше всего памяти использует процесс - /usr/bin/python3 /usr/share - 0.5%
- ЦПУ имеет очень низкую нагрузку
- Малое потребление памяти
- Быстрая загрузка системы
- В системе в основном работают основные службы systemd
- Одна активная пользовательская сессия
---
# Task 2.

### 2.1: Network Path Tracing

**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ traceroute github.com**

	traceroute to github.com (140.82.121.3), 30 hops max, 60 byte packets
	 1  DESKTOP-QL0CRI2.mshome.net (172.22.80.1)  0.936 ms  0.873 ms  0.842 ms
	 2  * * *
	 3  * * *
	 4  1.123.18.84.in-addr.arpa (84.18.123.1)  12.258 ms  12.251 ms  16.122 ms
	 5  178.176.191.24 (178.176.191.24)  219.244 ms  219.226 ms  219.034 ms
	 6  * * *
	 7  * * *
	 8  * * *
	 9  * * *
	10  83.169.204.78 (83.169.204.78)  67.107 ms  47.023 ms  49.924 ms
	11  netnod-ix-ge-a-sth-1500.inter.link (194.68.123.180)  46.553 ms netnod-ix-ge-b-sth-1500.inter.link (194.68.128.180)  44.856 ms  44.454 ms
	12  * * *
	13  r3-ber1-de.as5405.net (94.103.180.2)  59.508 ms  61.607 ms  61.603 ms
	14  r4-fra1-de.as5405.net (94.103.180.7)  58.939 ms  58.925 ms  61.648 ms
	15  * * *
	16  r3-fra3-de.as5405.net (94.103.180.54)  61.214 ms  58.322 ms  63.886 ms
	17  r1-fra3-de.as5405.net (94.103.180.24)  63.814 ms  63.803 ms  63.771 ms
	18  cust-sid436.fra3-de.as5405.net (45.153.82.37)  63.764 ms cust-sid435.r1-fra3-de.as5405.net (45.153.82.39)  63.755 ms cust-sid436.fra3-de.as5405.net (45.153.82.37)  63.746 ms
	19 - 30 * * *

**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ dig github.com**

	; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> github.com
	;; global options: +cmd
	;; Got answer:
	;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 32239
	;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
	
	;; OPT PSEUDOSECTION:
	; EDNS: version: 0, flags:; udp: 4096
	;; QUESTION SECTION:
	;github.com.                    IN      A
	
	;; ANSWER SECTION:
	github.com.             25      IN      A       140.82.121.3
	
	;; Query time: 23 msec
	;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
	;; WHEN: Thu Feb 26 00:55:27 MSK 2026
	;; MSG SIZE  rcvd: 55

---
- Сетевой путь до github.com проходит через множество транзитных узлов (среди которых локальный WSL, провайдер, точка обмена трафиком, конечный адрес), часть из которых скрыта (* * * ). Конечный IP совпадает с полученным через DNS.
---
### 2.2: Packet Capture

**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ sudo tcpdump -c 5 -i any port 53 -nn**

	tcpdump: data link type LINUX_SLL2
	tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
	listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
	00:58:17.401051 lo    In  IP 10.255.255.254.53983 > 10.255.255.254.53: 63136+ [1au] A? google.com. (51)
	00:58:17.433070 lo    In  IP 10.255.255.254.53 > 10.255.255.254.53983: 63136* 2/0/1 CNAME forcesafesearch.google.com., A 216.239.38.120 (131)
	2 packets captured
	4 packets received by filter
	0 packets dropped by kernel

---
 Запрос: Клиент `10.255.255.254:53983` - сервер `10.255.255.254:53` - `google.com` с ID 63136.
 Ответ: Сервер `10.255.255.254.53` >  клиент `10.255.255.254.53983` - `CNAME forcesafesearch.google.com` - безопасный поиск google
 
---
### 2.3: Reverse DNS

**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ dig -x 8.8.4.4**

	; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 8.8.4.4
	;; global options: +cmd
	;; Got answer:
	;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 898
	;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
	
	;; OPT PSEUDOSECTION:
	; EDNS: version: 0, flags:; MBZ: 0x1507, udp: 4096
	;; QUESTION SECTION:
	;4.4.8.8.in-addr.arpa.          IN      PTR
	
	;; ANSWER SECTION:
	4.4.8.8.in-addr.arpa.   5383    IN      PTR     dns.google.
	
	;; Query time: 39 msec
	;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
	;; WHEN: Thu Feb 26 01:00:29 MSK 2026
	;; MSG SIZE  rcvd: 93

**georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs$ dig -x 1.1.2.2**

	;; communications error to 10.255.255.254#53: timed out
	;; communications error to 10.255.255.254#53: timed out
	
	; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 1.1.2.2
	;; global options: +cmd
	;; Got answer:
	;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 31350
	;; flags: qr rd ra ad; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
	
	;; OPT PSEUDOSECTION:
	; EDNS: version: 0, flags:; MBZ: 0x020e, udp: 4096
	;; QUESTION SECTION:
	;2.2.1.1.in-addr.arpa.          IN      PTR
	
	;; AUTHORITY SECTION:
	1.in-addr.arpa.         526     IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23597 7200 1800 604800 3600
	
	;; Query time: 2036 msec
	;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
	;; WHEN: Thu Feb 26 01:00:50 MSK 2026
	;; MSG SIZE  rcvd: 160

---
- **8.8.4.4** — успешный ответ `dns.google`
- **1.1.2.2** — долгое время ожидания, нет PTR
- ---
