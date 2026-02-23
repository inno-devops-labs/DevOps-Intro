somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ systemd-analyze
Startup finished in 2.436s (userspace) 
graphical.target reached after 2.420s in userspace.
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ systemd-analyze blame
1.353s landscape-client.service
 568ms snapd.seeded.service
 467ms wsl-pro.service
 414ms snapd.service
 351ms dev-sdc.device
 273ms rsyslog.service
 234ms systemd-logind.service
 211ms logrotate.service
 204ms user@1000.service
 191ms systemd-udev-trigger.service
 165ms systemd-resolved.service
 154ms e2scrub_reap.service
 128ms systemd-journal-flush.service
 128ms systemd-udevd.service
 107ms systemd-timedated.service
 105ms systemd-timesyncd.service
  96ms systemd-journald.service
  93ms keyboard-setup.service
  90ms systemd-tmpfiles-setup.service
  75ms dpkg-db-backup.service
  72ms dbus.service
  61ms dev-hugepages.mount
  60ms dev-mqueue.mount
  56ms sys-kernel-debug.mount
  53ms sys-kernel-tracing.mount
  51ms modprobe@drm.service
  49ms modprobe@dm_mod.service
  48ms modprobe@configfs.service
  48ms modprobe@fuse.service
  46ms modprobe@efi_pstore.service
  41ms modprobe@loop.service
  40ms systemd-modules-load.service
  37ms systemd-tmpfiles-setup-dev-early.service
  37ms systemd-user-sessions.service
  35ms wsl-binfmt.service
  23ms setvtrgb.service
  20ms systemd-sysctl.service
  19ms systemd-remount-fs.service
  17ms user-runtime-dir@1000.service
  16ms systemd-tmpfiles-setup-dev.service
  16ms systemd-update-utmp.service
  14ms console-setup.service
  12ms systemd-update-utmp-runlevel.service
   9ms sys-fs-fuse-connections.mount
   1ms snapd.socket
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ uptime
 13:19:04 up 0 min,  1 user,  load average: 0.44, 0.13, 0.05
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ w
 13:19:13 up 0 min,  1 user,  load average: 0.37, 0.13, 0.04
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
somepatt pts/1    -                13:18   41.00s  0.03s  0.03s -bash
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
    PID    PPID CMD                         %MEM %CPU
    223       1 /usr/bin/python3 /usr/share  0.2  0.4
     55       1 /usr/lib/systemd/systemd-jo  0.2  0.4
    177       1 /usr/libexec/wsl-pro-servic  0.2  0.4
      1       0 /sbin/init                   0.1  2.5
    153       1 /usr/lib/systemd/systemd-re  0.1  0.2
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
    PID    PPID CMD                         %MEM %CPU
      1       0 /sbin/init                   0.1  2.2
    177       1 /usr/libexec/wsl-pro-servic  0.2  0.3
    174       1 /usr/lib/systemd/systemd-lo  0.1  0.3
    223       1 /usr/bin/python3 /usr/share  0.2  0.3
     80       1 /usr/lib/systemd/systemd-ud  0.0  0.3
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ systemctl list-dependencies
default.target
○ ├─display-manager.service
○ ├─systemd-update-utmp-runlevel.service
○ ├─wsl-binfmt.service
● └─multi-user.target
○   ├─apport.service
●   ├─console-setup.service
●   ├─cron.service
●   ├─dbus.service
○   ├─dmesg.service
○   ├─e2scrub_reap.service
○   ├─landscape-client.service
○   ├─networkd-dispatcher.service
●   ├─rsyslog.service
○   ├─snapd.apparmor.service
○   ├─snapd.autoimport.service
○   ├─snapd.core-fixup.service
○   ├─snapd.recovery-chooser-trigger.service
●   ├─snapd.seeded.service
○   ├─snapd.service
●   ├─systemd-ask-password-wall.path
●   ├─systemd-logind.service
○   ├─systemd-update-utmp-runlevel.service
●   ├─systemd-user-sessions.service
○   ├─ua-reboot-cmds.service
○   ├─ubuntu-advantage.service
●   ├─unattended-upgrades.service
●   ├─wsl-pro.service
●   ├─basic.target
○   │ ├─tmp.mount
●   │ ├─paths.target
○   │ │ └─apport-autoreport.path
●   │ ├─slices.target
●   │ │ ├─-.slice
●   │ │ └─system.slice
●   │ ├─sockets.target
●   │ │ ├─apport-forward.socket
●   │ │ ├─dbus.socket
●   │ │ ├─snapd.socket
●   │ │ ├─systemd-initctl.socket
●   │ │ ├─systemd-journald-dev-log.socket
●   │ │ ├─systemd-journald.socket
○   │ │ ├─systemd-pcrextend.socket
●   │ │ ├─systemd-sysext.socket
●   │ │ ├─systemd-udevd-control.socket
●   │ │ ├─systemd-udevd-kernel.socket
●   │ │ └─uuidd.socket
●   │ ├─sysinit.target
○   │ │ ├─apparmor.service
●   │ │ ├─dev-hugepages.mount
●   │ │ ├─dev-mqueue.mount
●   │ │ ├─keyboard-setup.service
○   │ │ ├─kmod-static-nodes.service
○   │ │ ├─ldconfig.service
○   │ │ ├─proc-sys-fs-binfmt_misc.automount
●   │ │ ├─setvtrgb.service
●   │ │ ├─sys-fs-fuse-connections.mount
○   │ │ ├─sys-kernel-config.mount
●   │ │ ├─sys-kernel-debug.mount
●   │ │ ├─sys-kernel-tracing.mount
●   │ │ ├─systemd-ask-password-console.path
○   │ │ ├─systemd-binfmt.service
○   │ │ ├─systemd-firstboot.service
○   │ │ ├─systemd-hwdb-update.service
○   │ │ ├─systemd-journal-catalog-update.service
●   │ │ ├─systemd-journal-flush.service
●   │ │ ├─systemd-journald.service
○   │ │ ├─systemd-machine-id-commit.service
●   │ │ ├─systemd-modules-load.service
○   │ │ ├─systemd-pcrmachine.service
○   │ │ ├─systemd-pcrphase-sysinit.service
○   │ │ ├─systemd-pcrphase.service
○   │ │ ├─systemd-pstore.service
○   │ │ ├─systemd-random-seed.service
○   │ │ ├─systemd-repart.service
●   │ │ ├─systemd-resolved.service
●   │ │ ├─systemd-sysctl.service
○   │ │ ├─systemd-sysusers.service
●   │ │ ├─systemd-timesyncd.service
●   │ │ ├─systemd-tmpfiles-setup-dev-early.service
●   │ │ ├─systemd-tmpfiles-setup-dev.service
●   │ │ ├─systemd-tmpfiles-setup.service
○   │ │ ├─systemd-tpm2-setup-early.service
○   │ │ ├─systemd-tpm2-setup.service
●   │ │ ├─systemd-udev-trigger.service
●   │ │ ├─systemd-udevd.service
○   │ │ ├─systemd-update-done.service
●   │ │ ├─systemd-update-utmp.service
●   │ │ ├─cryptsetup.target
●   │ │ ├─integritysetup.target
●   │ │ ├─local-fs.target
●   │ │ │ └─systemd-remount-fs.service
●   │ │ ├─swap.target
●   │ │ └─veritysetup.target
●   │ └─timers.target
○   │   ├─apport-autoreport.timer
●   │   ├─apt-daily-upgrade.timer
●   │   ├─apt-daily.timer
●   │   ├─dpkg-db-backup.timer
●   │   ├─e2scrub_all.timer
○   │   ├─fstrim.timer
●   │   ├─logrotate.timer
●   │   ├─man-db.timer
●   │   ├─motd-news.timer
○   │   ├─snapd.snap-repair.timer
●   │   ├─systemd-tmpfiles-clean.timer
○   │   └─ua-timer.timer
●   ├─getty.target
●   │ ├─console-getty.service
○   │ ├─getty-static.service
●   │ └─getty@tty1.service
●   └─remote-fs.target

somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ systemctl list-dependencies multi-user.target
multi-user.target
○ ├─apport.service
● ├─console-setup.service
● ├─cron.service
● ├─dbus.service
○ ├─dmesg.service
○ ├─e2scrub_reap.service
○ ├─landscape-client.service
○ ├─networkd-dispatcher.service
● ├─rsyslog.service
○ ├─snapd.apparmor.service
○ ├─snapd.autoimport.service
○ ├─snapd.core-fixup.service
○ ├─snapd.recovery-chooser-trigger.service
● ├─snapd.seeded.service
○ ├─snapd.service
● ├─systemd-ask-password-wall.path
● ├─systemd-logind.service
○ ├─systemd-update-utmp-runlevel.service
● ├─systemd-user-sessions.service
○ ├─ua-reboot-cmds.service
○ ├─ubuntu-advantage.service
● ├─unattended-upgrades.service
● ├─wsl-pro.service
● ├─basic.target
○ │ ├─tmp.mount
● │ ├─paths.target
○ │ │ └─apport-autoreport.path
● │ ├─slices.target
● │ │ ├─-.slice
● │ │ └─system.slice
● │ ├─sockets.target
● │ │ ├─apport-forward.socket
● │ │ ├─dbus.socket
● │ │ ├─snapd.socket
● │ │ ├─systemd-initctl.socket
● │ │ ├─systemd-journald-dev-log.socket
● │ │ ├─systemd-journald.socket
○ │ │ ├─systemd-pcrextend.socket
● │ │ ├─systemd-sysext.socket
● │ │ ├─systemd-udevd-control.socket
● │ │ ├─systemd-udevd-kernel.socket
● │ │ └─uuidd.socket
● │ ├─sysinit.target
○ │ │ ├─apparmor.service
● │ │ ├─dev-hugepages.mount
● │ │ ├─dev-mqueue.mount
● │ │ ├─keyboard-setup.service
○ │ │ ├─kmod-static-nodes.service
○ │ │ ├─ldconfig.service
○ │ │ ├─proc-sys-fs-binfmt_misc.automount
● │ │ ├─setvtrgb.service
● │ │ ├─sys-fs-fuse-connections.mount
○ │ │ ├─sys-kernel-config.mount
● │ │ ├─sys-kernel-debug.mount
● │ │ ├─sys-kernel-tracing.mount
● │ │ ├─systemd-ask-password-console.path
○ │ │ ├─systemd-binfmt.service
○ │ │ ├─systemd-firstboot.service
○ │ │ ├─systemd-hwdb-update.service
○ │ │ ├─systemd-journal-catalog-update.service
● │ │ ├─systemd-journal-flush.service
● │ │ ├─systemd-journald.service
○ │ │ ├─systemd-machine-id-commit.service
● │ │ ├─systemd-modules-load.service
○ │ │ ├─systemd-pcrmachine.service
○ │ │ ├─systemd-pcrphase-sysinit.service
○ │ │ ├─systemd-pcrphase.service
○ │ │ ├─systemd-pstore.service
○ │ │ ├─systemd-random-seed.service
○ │ │ ├─systemd-repart.service
● │ │ ├─systemd-resolved.service
● │ │ ├─systemd-sysctl.service
○ │ │ ├─systemd-sysusers.service
● │ │ ├─systemd-timesyncd.service
● │ │ ├─systemd-tmpfiles-setup-dev-early.service
● │ │ ├─systemd-tmpfiles-setup-dev.service
● │ │ ├─systemd-tmpfiles-setup.service
○ │ │ ├─systemd-tpm2-setup-early.service
○ │ │ ├─systemd-tpm2-setup.service
● │ │ ├─systemd-udev-trigger.service
● │ │ ├─systemd-udevd.service
○ │ │ ├─systemd-update-done.service
● │ │ ├─systemd-update-utmp.service
● │ │ ├─cryptsetup.target
● │ │ ├─integritysetup.target
● │ │ ├─local-fs.target
● │ │ │ └─systemd-remount-fs.service
● │ │ ├─swap.target
● │ │ └─veritysetup.target
● │ └─timers.target
○ │   ├─apport-autoreport.timer
● │   ├─apt-daily-upgrade.timer
● │   ├─apt-daily.timer
● │   ├─dpkg-db-backup.timer
● │   ├─e2scrub_all.timer
○ │   ├─fstrim.timer
● │   ├─logrotate.timer
● │   ├─man-db.timer
● │   ├─motd-news.timer
○ │   ├─snapd.snap-repair.timer
● │   ├─systemd-tmpfiles-clean.timer
○ │   └─ua-timer.timer
● ├─getty.target
● │ ├─console-getty.service
○ │ ├─getty-static.service
● │ └─getty@tty1.service
● └─remote-fs.target

somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ who -a
           system boot  2026-02-23 13:18
           run-level 5  2026-02-23 13:18
LOGIN      console      2026-02-23 13:18               198 id=cons
LOGIN      tty1         2026-02-23 13:18               205 id=tty1
somepatt - pts/1        2026-02-23 13:18 00:01         414
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ last -n 5
reboot   system boot  5.15.167.4-micro Mon Feb 23 13:18   still running
reboot   system boot  5.15.167.4-micro Fri Feb 20 19:19   still running
reboot   system boot  5.15.167.4-micro Tue Feb 17 10:32   still running
reboot   system boot  5.15.167.4-micro Mon Feb 16 23:12   still running
reboot   system boot  5.15.167.4-micro Fri Feb 13 19:12   still running

wtmp begins Fri Apr  4 21:03:33 2025
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ free -h
               total        used        free      shared  buff/cache   available
Mem:           7.4Gi       620Mi       6.6Gi       3.2Mi       427Mi       6.8Gi
Swap:          2.0Gi          0B       2.0Gi
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
MemTotal:        7718068 kB
MemAvailable:    7084860 kB
SwapTotal:       2097152 kB


1) systemd-analyze - показывает время загрузки системы
2) systemd-analyze blame - показывает какие из серисов грузило дольше всех
3) uptime - текущее время, сколько работает система, сколько пользователей, средняя нагрузка на CPU
4) w - показывает кто залогинен
5) ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6 - сортировка процессов по трате памяти топ 6
6) ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6 - сортировка процессов по нагрузке cpu топ 6
7) systemctl list-dependencies - дерево зависимости текущего target
8) systemctl list-dependencies multi-user.target - какие сервисыя запускаются в обычном серверном режиме
9) who -a - показывает когда был запуск, runlevel, кто залогинен
10) last -n 5 - история перезангрузок
11) free -h - память в удобном формате
12) at /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable - то же что и 11 команда, только в сыром виде


Больше всего памяти занимает    223       1 /usr/bin/python3 /usr/share  0.2  0.4
Очень низкая нагрузка на CPU, система простаивает. Быстрая загрузка системы. Нет тяжелых процессов.



somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ traceroute github.com
traceroute to github.com (140.82.121.4), 30 hops max, 60 byte packets
 1  DESKTOP-NG99BTO.mshome.net (172.30.208.1)  0.580 ms  0.511 ms  0.493 ms
 2  10.243.1.1 (10.243.1.1)  1.308 ms  1.236 ms  1.215 ms
 3  * * 10.250.0.2 (10.250.0.2)  1.104 ms
 4  10.252.6.1 (10.252.6.1)  1.102 ms *  1.049 ms
 5  * * *
 6  * * *
 7  * * *
 8  * * *
 9  * * *
10  83.169.204.82 (83.169.204.82)  45.095 ms 83.169.204.78 (83.169.204.78)  41.395 ms 83.169.204.82 (83.169.204.82)  46.880 ms
11  netnod-ix-ge-a-sth-1500.inter.link (194.68.123.180)  45.424 ms  42.413 ms  44.345 ms
12  * * *
13  * * *
14  * * *
15  * * *
16  * * *
17  r1-fra3-de.as5405.net (94.103.180.24)  58.448 ms  62.195 ms  58.342 ms
18  cust-sid435.r1-fra3-de.as5405.net (45.153.82.39)  60.721 ms cust-sid436.fra3-de.as5405.net (45.153.82.37)  54.202 ms  55.505 ms
19  * * *
20  * * *
21  * * *
22  * * *
23  * * *
24  * * *
25  * * *
26  * * *
27  * * *
28  * * *
29  * * *
30  * * *
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ dig github.com

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 28935
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             56      IN      A       140.82.121.4

;; Query time: 71 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Mon Feb 23 13:42:12 MSK 2026
;; MSG SIZE  rcvd: 55

somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
tcpdump: data link type LINUX_SLL2                                                                                                                           
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes

0 packets captured
0 packets received by filter
0 packets dropped by kernel
somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ dig -x 8.8.4.4

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 13060
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   5471    IN      PTR     dns.google.

;; Query time: 30 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Mon Feb 23 13:45:55 MSK 2026
;; MSG SIZE  rcvd: 73

somepatt@DESKTOP-NG99BTO:/mnt/c/Users/Mi/Desktop/projects/DevOps-Intro$ dig -x 1.1.2.2

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 12042
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         1294    IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23597 7200 1800 604800 3600

;; Query time: 20 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Mon Feb 23 13:45:59 MSK 2026
;; MSG SIZE  rcvd: 137

Многие узлы не отвечают на traceroute, маршрут через Франкфурт, трафик проходит через nethod. 
DNS содержит только одну запись(A), запрос идет через 10.255.255.254
PTR есть на 8.8.4.4. На 1.1.2.2 его нет - NXDOMAIN
Пример DNS:
Запрос - A github.com
Ответ - 140.82.121.4
DNS сервер - 10.255.255.254:53