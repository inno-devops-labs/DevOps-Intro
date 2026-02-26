# Lab 4

Note: commands were executed in WSL (Ubuntu).

## Task 1

`systemd-analyze`
```
Startup finished in 877ms (userspace)
graphical.target reached after 867ms in userspace.
```

`systemd-analyze blame`
```
470ms landscape-client.service
165ms snapd.seeded.service
144ms dev-sdc.device
109ms wsl-pro.service
96ms packagekit.service
...
```

`uptime`
```
up 4 min, 1 user, load average: 0.23, 0.13, 0.04
```

`w`
```
USER  TTY    FROM  LOGIN@  IDLE  WHAT
ubu   pts/1  -     21:41   ...   -bash
```

`ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6`
```
PID  PPID  CMD                              %MEM  %CPU
196  1     /usr/bin/python3 /usr/share...  0.2   0.0
730  1     /usr/libexec/packagekitd         0.2   0.0
48   1     /usr/lib/systemd/systemd-jo...   0.2   0.0
...
```

`ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6`
```
PID  PPID  CMD                              %MEM  %CPU
1    0     /sbin/init                       0.1   0.4
90   1     /usr/lib/systemd/systemd-ud...   0.0   0.0
...
```

`systemctl list-dependencies`
```
default.target
\- multi-user.target
  |- cron.service
  |- dbus.service
  |- rsyslog.service
  |- systemd-logind.service
  \- ...
```

`systemctl list-dependencies multi-user.target`
```
multi-user.target
|- cron.service
|- dbus.service
|- rsyslog.service
|- systemd-logind.service
\- ...
```

`who -a`
```
system boot 2026-02-26 21:41
run-level 5 2026-02-26 21:41
ubu - pts/1 2026-02-26 21:41
```

`last -n 5`
```
reboot system boot 5.15.167.4-micro Thu Feb 26 21:41 still running
reboot system boot 5.15.167.4-micro Thu Feb 26 21:40 still running
reboot system boot 5.15.167.4-micro Thu Feb 26 21:39 still running
```

`free -h`
```
total  used  free  shared  buff/cache  available
7.4Gi  673Mi 6.2Gi 3.0Mi   765Mi       6.7Gi
Swap: 2.0Gi  0B    2.0Gi
```

`cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable`
```
MemTotal: 7717204 kB
MemAvailable: 7027364 kB
SwapTotal: 2097152 kB
```

Top memory-consuming process: `python3` (~0.2% MEM).  
Pattern: low load, high free memory, swap not used.

## Task 2

`traceroute github.com`
```
traceroute to github.com (140.82.121.XXX), 30 hops max, 60 byte packets
1  HOME-PC.mshome.net (172.31.16.XXX) ...
2  10.8.1.XXX (10.8.1.XXX) ...
3  172.29.172.XXX (172.29.172.XXX) ...
4  5.83.151.XXX ...
5  * * *
...
30 * * *
```

`dig github.com`
```
status: NOERROR
QUESTION: github.com. IN A
ANSWER: github.com. 25 IN A 140.82.121.XXX
SERVER: 10.255.255.XXX#53
```

`sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn`
```
IP 10.255.255.XXX.51179 > 10.255.255.XXX.53: A? github.com.
IP 10.255.255.XXX.53 > 10.255.255.XXX.51179: A 140.82.121.XXX
IP 10.255.255.XXX.52010 > 10.255.255.XXX.53: PTR? 4.4.8.8.in-addr.arpa.
IP 10.255.255.XXX.53 > 10.255.255.XXX.52010: PTR dns.google.
```

`dig -x 8.8.4.4`
```
status: NOERROR
ANSWER: 4.4.8.8.in-addr.arpa. PTR dns.google.
```

`dig -x 1.1.2.2`
```
communications error to 10.255.255.XXX#53: timed out
status: NXDOMAIN
QUESTION: 2.2.1.1.in-addr.arpa. IN PTR
```

Path insight: route has filtered hops (`* * *`) after early transit nodes.  
DNS insight: `github.com` resolves normally, reverse lookups differ (`NOERROR` vs `NXDOMAIN`).  
Packet example: `A? github.com` query captured in `tcpdump`.
