I.

1. systemd-analyze:

Startup finished in 4.318s (kernel) + 11.311s (userspace) = 15.630s 
graphical.target reached after 11.239s in userspace.

Здесь указано, сколько по времени загружались основные компоненты для запуска ПК.
Ядро загрузилось быстро, а вот пользовательское пространство подтормаживает — 11 секунд.

2. systemd-analyze blame

6.432s snapd.seeded.service
6.237s snapd.service
5.584s logrotate.service
4.614s vboxadd.service
3.888s NetworkManager.service
2.901s systemd-udev-settle.service
2.884s blueman-mechanism.service
2.880s apport.service
2.735s dev-sda1.device
2.647s accounts-daemon.service
2.476s gpu-manager.service
2.123s polkit.service
2.061s rsyslog.service
2.043s dev-loop9.device
2.032s avahi-daemon.service
2.012s dev-loop8.device
2.004s dev-loop10.device
1.846s fwupd-refresh.service
1.841s udisks2.service
1.768s fwupd.service
1.696s grub-common.service
1.328s lm-sensors.service
1.261s switcheroo-control.service
1.031s dpkg-db-backup.service
1.005s apt-daily-upgrade.service

Здесь показаны все программы, которые потребовались для запуска, и время, которые было использовано для их запуска

3. uptime

18:11:06 up  5:22,  1 user,  load average: 0.19, 0.53, 0.67

Как долго система работает без выключения или перезагрузки, а также текущую информацию о нагрузке на сервер.
4. w

18:11:53 up  5:23,  1 user,  load average: 0.09, 0.45, 0.64
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
user     tty2     -                12:48    5:23m  1:22m  0.02s /usr/lib/x86_64-linux-gnu/sddm/sddm-helper --soc

Показывает всех пользователей и то, что они делаю на данный момент

5. ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6

PID    PPID CMD                         %MEM %CPU
2178    1300 /snap/firefox/7869/usr/lib/ 27.3  0.8
5049    2591 /snap/firefox/7869/usr/lib/  9.0  0.9
1239    1202 /usr/lib/xorg/Xorg -noliste  7.1 25.4
2773    2591 /snap/firefox/7869/usr/lib/  7.1  0.0
1479    1300 /usr/bin/pcmanfm-qt --deskt  6.2  0.0

Показывает информацию о тех программах, которые запущены на данный момент и ресурсы, которые они занимают

6. ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6    


PID    PPID CMD                         %MEM %CPU
   1239    1202 /usr/lib/xorg/Xorg -noliste  7.1 25.3
   5049    2591 /snap/firefox/7869/usr/lib/  8.0  0.9
   2178    1300 /snap/firefox/7869/usr/lib/ 26.7  0.8
   1494    1300 /usr/bin/picom               0.3  0.5
   1419    1414 /usr/bin/VBoxClient --draga  0.1  0.2

То же самое, но сортировка другая

Команда head - берет вывод прошлой команды и выводит просто -n первых строк

7. systemcls list-depencdencies

default.target
● ├─accounts-daemon.service
● ├─sddm.service
● ├─switcheroo-control.service
○ ├─systemd-update-utmp-runlevel.service
● ├─udisks2.service
● └─multi-user.target
○   ├─anacron.service
●   ├─apport.service
●   ├─avahi-daemon.service
○   ├─blueman-mechanism.service
●   ├─console-setup.service
●   ├─cron.service
●   ├─cups-browsed.service
●   ├─cups.path
●   ├─cups.service
●   ├─dbus.service
○   ├─dmesg.service
○   ├─e2scrub_reap.service
○   ├─grub-common.service
○   ├─grub-initrd-fallback.service
●   ├─kerneloops.service
●   ├─lm-sensors.service
●   ├─ModemManager.service
○   ├─networkd-dispatcher.service
lines 1-25

Зависимости между процессами для запуска системы

8. systemctl list-dependencies multi-user.target 

multi-user.target
○ ├─anacron.service
● ├─apport.service
● ├─avahi-daemon.service
○ ├─blueman-mechanism.service
● ├─console-setup.service
● ├─cron.service
● ├─cups-browsed.service
● ├─cups.path
● ├─cups.service
● ├─dbus.service
○ ├─dmesg.service
○ ├─e2scrub_reap.service
○ ├─grub-common.service
○ ├─grub-initrd-fallback.service
● ├─kerneloops.service
● ├─lm-sensors.service
● ├─ModemManager.service
○ ├─networkd-dispatcher.service
● ├─NetworkManager.service
● ├─openvpn.service
○ ├─plymouth-quit-wait.service
● ├─plymouth-quit.service
● ├─rsyslog.service
○ ├─secureboot-db.service

А тут мы указываем конкретную цель, для которой просим вывести все зависимости.

9.who -a

           system boot  2026-02-26 12:48
           run-level 5  2026-02-26 12:48
user     + tty2         2026-02-26 12:48 05:28        1300 (:0)

Показывает всю информацию о состоянии системы и пользователях.
(Время последней загрузки системы, текущий уровень запуска, имя пользователя ит.д.)

10. last | head -n 5

user     tty2         :0               Thu Feb 26 12:48   still logged in
reboot   system boot  6.14.0-27-generi Thu Feb 26 12:48   still running
user     tty2         :0               Wed Feb 25 17:44 - crash  (19:04)
reboot   system boot  6.14.0-27-generi Wed Feb 25 17:43   still running
user     tty2         :0               Wed Feb 18 19:05 - crash (6+22:38)

Последние действия различных юзеров, совмещенное с командой head.
Видно, что до этого система падала (crash) — вчера и 18 февраля.

11. cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
MemTotal:        2015960 kB
MemAvailable:     700652 kB
SwapTotal:             0 kB

cat - читает файл /proc/meminfo.
grep - выводит те строки, в которых есть слова, указанные после -e.
Сама команда - сколько памяти есть и сколько доступно, а также свап с жестким диском

What is the top memory-consuming process?
Ответ: /snap/firefox/7869/usr/lib/


ПК загружается почти 16 секунд. Ядро - быстро, а остальное долго (14 сек).
Нагрузка на процессор маленькая (0.09 за минуту), файла swap-подкачки нет, что не очень хорошо. Но я ведь на виртуальной машине сижу)

II.
12. dig github.com

; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 25267
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             29      IN      A       140.82.121.4

;; Query time: 25 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Sat Feb 28 14:04:43 MSK 2026
;; MSG SIZE  rcvd: 55

dig просто показал, что github.com лежит на адресе 140.82.121.4, запрос был осуществлен за 25 миллисекунд через локальный DNS.

13. sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes

0 packets captured
0 packets received by filter
0 packets dropped by kernel

за 10 секунд tcpdump ничего не обнаружил.

14. dig -x 8.8.4.4

; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 47320
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   3863    IN      PTR     dns.google.

;; Query time: 31 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Fri Feb 27 21:28:23 MSK 2026
;; MSG SIZE  rcvd: 73

Запрос длился 31 msec без ошибок и вернул dns.google.
15. dig -x 1.1.2.2

; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 59354
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         43      IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23597 7200 1800 604800 3600

;; Query time: 127 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Fri Feb 27 21:29:19 MSK 2026
;; MSG SIZE  rcvd: 137

Здесь уже статус не NOERROR, уперся в NXDOMAIN где на APNIC. И запрос был дольше - целых 137 секунд.

Сравнение: в первом все хорошо, без ошибок, во втором он столкнулся с NXDOMAIN. В первом получили dns.google, во втором - ns.apnic.net,
В первом потребовалось всего лишь 31 msc, а во втором 127.

Теперь я спецаильно через второе окно побросал запросы, чтобы увидеть примеры DNS query:

sudo tcpdump -c 10 -i any 'port 53' -nn
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
11:42:13.436794 eth0  Out IP 192.168.32.XXX.37111 > 192.168.32.1.53: 4955+ A? dl-cdn.alpinelinux.org. (40)
11:42:13.436860 eth0  Out IP 192.168.32.XXX.37111 > 192.168.32.1.53: 5155+ AAAA? dl-cdn.alpinelinux.org. (40)
11:42:13.462395 eth0  In  IP 192.168.32.1.53 > 192.168.32.XXX.37111: 4955- 2/0/0 CNAME dualstack.j.sni.global.fastly.net., A 146.75.118.XXX (158)
11:42:13.525752 eth0  In  IP 192.168.32.1.53 > 192.168.32.XXX.37111: 5155- 3/0/0 CNAME dualstack.j.sni.global.fastly.net., AAAA 2a04:4e42:8d::644, A 146.75.118.XXX (186)
11:43:21.565741 eth0  Out IP 192.168.32.XXX.51389 > 192.168.32.1.53: 32044+ A? dl-cdn.alpinelinux.org. (40)
11:43:21.565777 eth0  Out IP 192.168.32.XXX.51389 > 192.168.32.1.53: 32500+ AAAA? dl-cdn.alpinelinux.org. (40)
11:43:21.666877 eth0  In  IP 192.168.32.1.53 > 192.168.32.XXX.51389: 32044- 2/0/0 CNAME dualstack.j.sni.global.fastly.net., A 146.75.122.XXX (158)
11:43:21.812841 eth0  In  IP 192.168.32.1.53 > 192.168.32.XXX.51389: 32500- 3/0/0 CNAME dualstack.j.sni.global.fastly.net., AAAA 2a04:4e42:8e::644, A 146.75.122.XXX (186)
8 packets captured
8 packets received by filter
0 packets dropped by kernel

Видно, как система сначала просит А-запись (IPv4), потом AAAA (IPv6), а в ответ получает CNAME (псевдоним) и реальный IP.
Всего было получено 8 пакетов.


