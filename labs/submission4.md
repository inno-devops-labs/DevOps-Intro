\# Лабораторная работа №4



\## Задание 1 – Operating System Analysis



\### 1.1 Boot Performance



\*\*systemd-analyze\*\*
Startup finished in 2.961s (kernel) + 38.794s (userspace) = 41.756s

graphical.target reached after 38.172s in userspace.



\*\*systemd-analyze blame (топ-5)\*\*
26.857s snapd.seeded.service

9.142s fwupd-refresh.service

8.156s plymouth-quit-wait.service

4.894s snapd.apparmor.service

4.667s apt-daily-upgrade.service



\*\*uptime\*\*
00:10:47 up 1:54, 1 user, load average: 0,46, 0,90, 0,52



\*\*w\*\*
00:10:54 up 1:54, 1 user, load average: 0,43, 0,89, 0,52

USER TTY FROM LOGIN@ IDLE JCPU PCPU WHAT

ilya tty2 - 05мар26 34days 0.05s 0.05s /usr/libexec/gnome-session-binary --session=ubuntu



\*\*Наблюдения:\*\* Загрузка \~42 сек, медленнее всего snapd.seeded (26.8с). Нагрузка низкая, один пользователь.



\### 1.2 Process Forensics



\*\*Топ по памяти (%MEM)\*\*
PID PPID CMD %MEM %CPU

5020 2543 /snap/firefox/7766/usr/lib/ 10.1 8.1

6188 5179 /snap/firefox/7766/usr/lib/ 7.1 5.1

2543 2183 /usr/bin/gnome-shell 5.3 5.7

8382 5179 /snap/firefox/7766/usr/lib/ 3.5 9.7

5914 5179 /snap/firefox/7766/usr/lib/ 3.1 0.5



\*\*Топ по CPU (%CPU)\*\*
PID PPID CMD %MEM %CPU

8382 5179 /snap/firefox/7766/usr/lib/ 3.2 9.6

5020 2543 /snap/firefox/7766/usr/lib/ 10.1 8.1

2543 2183 /usr/bin/gnome-shell 5.2 5.7

6188 5179 /snap/firefox/7766/usr/lib/ 7.1 5.1

8084 5179 /snap/firefox/7766/usr/lib/ 2.9 2.4



\*\*Ответ:\*\* Самый потребляющий память процесс – Firefox (PID 5020, 10.1% RAM).



\### 1.3 Service Dependencies



\*\*systemctl list-dependencies multi-user.target (сокращённо)\*\*
multi-user.target

● ├─anacron.service

● ├─apport.service

● ├─avahi-daemon.service

● ├─cron.service

● ├─cups.service

● ├─dbus.service

● ├─NetworkManager.service

● ├─openvpn.service

● ├─rsyslog.service

● └─snap-\*.mount



\*\*Наблюдения:\*\* multi-user.target запускает основные сервисы: сеть, печать, cron, логи, монтирования Snap.



\### 1.4 User Sessions



\*\*who -a\*\*
загрузка системы 2026-03-05 17:33

уровень выполнения 5 2026-03-05 17:35

ilya ? seat0 2026-03-05 17:36 ? 2292 (login screen)

ilya + tty2 2026-03-05 17:36 да 2292 (tty2)



\*\*last -n 5\*\*
ilya tty2 tty2 Thu Mar 5 17:36 gone - no logout

ilya seat0 login screen Thu Mar 5 17:36 gone - no logout

reboot system boot 6.17.0-14-generi Thu Mar 5 17:33 still running



\*\*Наблюдения:\*\* Локальный вход через экран входа и tty2. Удалённых подключений нет.



\### 1.5 Memory Analysis



\*\*free -h\*\*
всего занят своб общая буф/врем. доступно

Память: 8,3Gi 2,3Gi 2,9Gi 73Mi 2,7Gi 5,9Gi

Подкачка: 4,0Gi 0B 4,0Gi



\*\*/proc/meminfo\*\*
MemTotal: 8664180 kB (\~8.3 GiB)

MemAvailable: 6227116 kB (\~5.9 GiB)

SwapTotal: 4194300 kB (\~4.0 GiB)



\*\*Вывод:\*\* Памяти достаточно, swap не используется.



\## Задание 2 – Networking Analysis



\### 2.1 Path Tracing \& DNS



\*\*traceroute github.com\*\*
traceroute to github.com (140.82.121.3), 30 hops max

1 \_gateway (10.0.2.2) 1.145 ms 1.100 ms 0.981 ms

2 \* \* \*

...

30 \* \* \*



\*\*dig github.com\*\*
;; ANSWER SECTION:

github.com. 46 IN A 140.82.121.3

;; SERVER: 127.0.0.53#53(127.0.0.53)



\*\*Наблюдения:\*\* IP github.com = 140.82.121.3. DNS через локальный резолвер. Дальнейшие хопы скрыты (ICMP блокируется).



\### 2.2 DNS Packet Capture



\*\*sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn\*\*
0 packets captured

2 packets received by filter

0 packets dropped by kernel



\*\*Пояснение:\*\* За время захвата не было активных DNS-запросов (кэш). При ручной генерации (например, `dig google.com`) появляются пакеты вида:
IP 192.168.x.x.54321 > 8.8.8.8.53: A? google.com.

IP 8.8.8.8.53 > 192.168.x.x.54321: A 142.250.185.46



\### 2.3 Reverse DNS



\*\*dig -x 8.8.4.4\*\*
;; ANSWER SECTION:

4.4.8.8.in-addr.arpa. 86400 IN PTR dns.google.



\*\*dig -x 1.1.2.2\*\*
;; QUESTION SECTION:

;2.2.1.1.in-addr.arpa. IN PTR

;; STATUS: NXDOMAIN



\*\*Сравнение:\*\* У 8.8.4.4 есть PTR (dns.google), у 1.1.2.2 – нет. PTR-записи обычно есть только у публичных сервисов.

