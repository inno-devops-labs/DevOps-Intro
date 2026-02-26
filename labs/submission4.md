# Лабораторная 4

1.1

```sh
$ systemd-analyze
Startup finished in 1.313s (userspace)
graphical.target reached after 1.305s in userspace.
```

```sh
$ systemd-analyze blame
727ms landscape-client.service
290ms snapd.seeded.service
223ms snapd.service
190ms dev-sdc.device
153ms wsl-pro.service
...
```

```sh
$ uptime
23:17:54 up 0 min, 1 user, load average: 0.00, 0.00, 0.00
```

```sh
$ w
23:17:54 up 0 min, 1 user, load average: 0.00, 0.00, 0.00
USER   TTY    FROM LOGIN@ IDLE JCPU PCPU WHAT
Milter pts/1  -    23:17 14.00s 0.00s ?   -bash
```

1.2

```sh
$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
PID   PPID CMD                          %MEM %CPU
157   1    /usr/lib/snapd/snapd          0.4  0.5
187   1    /usr/bin/python3 ...          0.2  0.3
51    1    /usr/lib/systemd/systemd-...  0.2  0.4
161   1    /usr/libexec/wsl-pro-...      0.2  0.3
1     0    /sbin/init                    0.1  3.4
```

```sh
$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
PID   PPID CMD                          %MEM %CPU
1     0    /sbin/init                    0.1  3.4
157   1    /usr/lib/snapd/snapd          0.4  0.5
310   1    /usr/lib/systemd/systemd ...  0.1  0.4
151   1    dbus-daemon ...               0.0  0.4
95    1    /usr/lib/systemd/systemd-...  0.0  0.4
```

1.3

```sh
$ systemctl list-dependencies
default.target
└─multi-user.target
  ├─cron.service
  ├─dbus.service
  ├─rsyslog.service
  ├─snapd.service
  └─...
```

```sh
$ systemctl list-dependencies multi-user.target
multi-user.target
├─cron.service
├─dbus.service
├─rsyslog.service
├─snapd.service
└─...
```

1.4

```sh
$ who -a
system boot 2026-02-26 23:17
run-level 5 2026-02-26 23:17
Milter - pts/1 2026-02-26 23:17
```

```sh
$ last -n 5
reboot system boot 5.15.167.4-micro Thu Feb 26 23:17 still running
reboot system boot 5.15.167.4-micro Thu Feb 26 23:16 still running
wtmp begins Thu Feb 26 23:16:46 2026
```

1.5

```sh
$ free -h
total 7.4Gi
used  631Mi
free  6.7Gi
swap  2.0Gi (used 0B)
```

```sh
$ cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
MemTotal:     7810228 kB
MemAvailable: 7163948 kB
SwapTotal:    2097152 kB
```

Наблюдения по задаче 1:
- Загрузка быстрая (около 1.3 c).
- Самый "тяжелый" по памяти процесс: `snapd` (PID 157, ~0.4%).
- Общая нагрузка низкая, памяти свободно много.

2.1

```sh
$ traceroute github.com
1 172.20.160.XXX 0.391 ms 0.366 ms 0.354 ms
2 * * *
...
30 * * *
```

```sh
$ dig github.com
status: NOERROR
ANSWER: github.com. 55 IN A 140.82.121.4
SERVER: 1.1.1.1#53
```

2.2

```sh
$ sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
In  IP 1.1.1.1.53 > 172.20.163.XXX.39005: ... A 140.82.121.3
Out IP 172.20.163.XXX.43338 > 1.1.1.1.53: ... A? github.com
In  IP 1.1.1.1.53 > 172.20.163.XXX.43338: ... A 140.82.121.4
Out IP 172.20.163.XXX.60870 > 1.1.1.1.53: ... A? github.com
In  IP 1.1.1.1.53 > 172.20.163.XXX.60870: ... A 140.82.121.4
```

2.3

```sh
$ dig -x 8.8.4.4
status: NOERROR
ANSWER: 4.4.8.8.in-addr.arpa. PTR dns.google.
```

```sh
$ dig -x 1.1.2.2
status: NXDOMAIN
PTR запись не найдена.
```

Наблюдения по задаче 2:
- В `traceroute` виден только первый хоп (остальные скрыты/фильтруются).
- DNS-запросы и ответы идут к `1.1.1.1`.
- Пример DNS-паттерна: `A? github.com` -> `A 140.82.121.4`.
- Для `8.8.4.4` есть PTR (`dns.google`), для `1.1.2.2` PTR нет (`NXDOMAIN`).
