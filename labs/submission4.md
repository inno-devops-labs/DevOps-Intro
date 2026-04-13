# Задание 1.

Запуск команд:

## Секция 1. Boot Performance Analysis

### `systemd-analyze`

```
Startup finished in 16.296s (kernel) + 56.322s (userspace) = 1min 12.618s 
graphical.target reached after 55.548s in userspace.
```

### `systemd-analyze blame`

```
6min 53.165s snapd.service
     50.056s man-db.service
     28.534s snapd.seeded.service
     24.304s vboxadd.service
     21.584s NetworkManager.service
     18.519s dev-sda1.device
     16.103s logrotate.service
     15.551s systemd-udev-settle.service
     13.966s apport.service
     13.829s gpu-manager.service
     11.731s rsyslog.service
     11.384s dev-loop8.device
     11.274s grub-common.service
     11.073s dev-loop11.device
     11.049s dev-loop9.device
     10.757s accounts-daemon.service
      9.503s avahi-daemon.service
      9.143s apt-daily.service
      8.976s udisks2.service
      8.495s polkit.service
      7.273s lm-sensors.service
      6.711s apparmor.service
      5.684s alsa-restore.service
      4.775s apt-daily-upgrade.service
      4.747s ModemManager.service
      4.669s fstrim.service
      4.564s e2scrub_all.service
      4.557s fwupd-refresh.service
      4.455s sysstat-summary.service
      4.437s dbus.service
      4.397s e2scrub_reap.service
      4.300s systemd-udev-trigger.service
      4.244s systemd-logind.service
      4.201s switcheroo-control.service
      4.127s dev-loop5.device
      3.937s dpkg-db-backup.service
      3.797s wpa_supplicant.service
      3.757s dev-loop2.device
      3.663s dev-loop4.device
      3.627s dev-loop3.device
      3.603s dev-loop7.device
      3.602s dev-loop6.device
      3.580s snapd.apparmor.service
      3.358s dev-loop1.device
      3.332s dev-loop0.device
      3.097s systemd-journal-flush.service
      3.057s sysstat.service
      2.511s fwupd.service
      2.378s systemd-resolved.service
      1.979s motd-news.service
      1.901s keyboard-setup.service
      1.806s blueman-mechanism.service
      1.726s snap-bare-5.mount
      1.714s user@1000.service
      1.659s systemd-udevd.service
      1.642s snap-core22-2111.mount
      1.499s systemd-modules-load.service
      1.498s snap-core22-2292.mount
      1.466s plymouth-start.service
      1.446s systemd-tmpfiles-setup.service
      1.425s sys-kernel-debug.mount
      1.415s dev-mqueue.mount
      1.388s NetworkManager-wait-online.service
      1.379s sys-kernel-tracing.mount
      1.344s dev-hugepages.mount
      1.337s snap-firefox-7766.mount
      1.277s modprobe@configfs.service
      1.273s kerneloops.service
      1.273s systemd-tmpfiles-setup-dev-early.service
      1.259s kmod-static-nodes.service
      1.246s lvm2-monitor.service
      1.207s modprobe@drm.service
      1.157s grub-initrd-fallback.service
      1.122s systemd-remount-fs.service
      1.119s systemd-journald.service
      1.095s sysstat-collect.service
      1.093s snap-firefox-7836.mount
       986ms modprobe@fuse.service
       982ms vboxadd-service.service
       966ms sys-kernel-config.mount
       867ms sys-fs-fuse-connections.mount
       860ms systemd-random-seed.service
       860ms systemd-binfmt.service
       838ms snap-firmware\x2dupdater-210.mount
       830ms systemd-user-sessions.service
       820ms systemd-sysctl.service
       797ms upower.service
       775ms openvpn.service
       746ms systemd-update-utmp.service
       694ms systemd-update-utmp-runlevel.service
       679ms setvtrgb.service
       676ms snap-firmware\x2dupdater-216.mount
       664ms snap-gtk\x2dcommon\x2dthemes-1535.mount
       630ms sddm.service
       603ms plymouth-quit.service
       561ms systemd-timesyncd.service
       550ms snap-snapd-25935.mount
       482ms console-setup.service
       475ms modprobe@efi_pstore.service
       447ms ufw.service
       417ms snap-gnome\x2d42\x2d2204-202.mount
       402ms systemd-tmpfiles-setup-dev.service
       392ms plymouth-read-write.service
       378ms snap-gnome\x2d42\x2d2204-247.mount
       378ms modprobe@loop.service
       355ms proc-sys-fs-binfmt_misc.mount
       330ms modprobe@dm_mod.service
       232ms cups.service
       205ms snap-snapd-26382.mount
       137ms rtkit-daemon.service
       128ms dev-loop12.device
       128ms user-runtime-dir@1000.service
       100ms systemd-tmpfiles-clean.service
        16ms snapd.socket
        63us blk-availability.service
lines 96-115/115 (END)
```

### `uptime`

```
13:24:37 up  5:23,  1 user,  load average: 0.42, 0.97, 1.15
```

### `w`
```
 13:25:15 up  5:24,  1 user,  load average: 1.27, 1.15, 1.20
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
user     tty2     -                Sun16   21:15m  1:52m  0.10s /usr/lib/x86_64-linux-gnu/
```

Все эти команды по

Эти команды нужны для анализа производительности загрузки, мониторинга времени работы системы и активности пользователей.

## Секция 2. Process Forensics

### `ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6`

```
    PID    PPID CMD                         %MEM %CPU
   1523    1344 /usr/bin/lxqt-panel          4.1  0.0
   1510    1344 /usr/bin/pcmanfm-qt --deskt  4.0  0.0
   3393    1510 featherpad file:///home/use  3.7  3.2
   1737    1510 qterminal                    3.5  0.0
   1281    1267 /usr/lib/xorg/Xorg -noliste  3.4 34.6
```

### `ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6`

```
    PID    PPID CMD                         %MEM %CPU
   3432    1740 ps -eo pid,ppid,cmd,%mem,%c  0.1  133
   1281    1267 /usr/lib/xorg/Xorg -noliste  3.4 34.5
   3433    1740 head -n 6                    0.0 33.3
   3393    1510 featherpad file:///home/use  3.7  3.3
   1531    1344 /usr/bin/picom               0.2  1.3
```

Эти команды нужны для мониторинга процессов в системе.

## Секция 3. Service Dependencies

### `systemctl list-dependencies`

```
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
●   ├─NetworkManager.service
●   ├─openvpn.service
○   ├─plymouth-quit-wait.service
●   ├─plymouth-quit.service
●   ├─rsyslog.service
○   ├─secureboot-db.service
●   ├─snap-bare-5.mount
●   ├─snap-core22-2111.mount
●   ├─snap-core22-2292.mount
●   ├─snap-firefox-7766.mount
●   ├─snap-firefox-7836.mount
●   ├─snap-firmware\x2dupdater-210.mount
●   ├─snap-firmware\x2dupdater-216.mount
●   ├─snap-gnome\x2d42\x2d2204-202.mount
●   ├─snap-gnome\x2d42\x2d2204-247.mount
●   ├─snap-gtk\x2dcommon\x2dthemes-1535.mount
●   ├─snap-snapd-25935.mount
●   ├─snap-snapd-26382.mount
●   ├─snapd.apparmor.service
○   ├─snapd.autoimport.service
○   ├─snapd.core-fixup.service
○   ├─snapd.recovery-chooser-trigger.service
●   ├─snapd.seeded.service
●   ├─snapd.service
○   ├─ssl-cert.service
●   ├─sysstat.service
●   ├─systemd-ask-password-wall.path
●   ├─systemd-logind.service
○   ├─systemd-update-utmp-runlevel.service
●   ├─systemd-user-sessions.service
○   ├─thermald.service
○   ├─ua-reboot-cmds.service
○   ├─ubuntu-advantage.service
●   ├─ufw.service
●   ├─unattended-upgrades.service
●   ├─vboxadd-service.service
●   ├─vboxadd.service
●   ├─whoopsie.path
●   ├─wpa_supplicant.service
●   ├─basic.target
●   │ ├─-.mount
○   │ ├─tmp.mount
●   │ ├─paths.target
○   │ │ ├─apport-autoreport.path
○   │ │ └─tpm-udev.path
●   │ ├─slices.target
●   │ │ ├─-.slice
●   │ │ └─system.slice
●   │ ├─sockets.target
○   │ │ ├─apport-forward.socket
●   │ │ ├─avahi-daemon.socket
●   │ │ ├─cups.socket
●   │ │ ├─dbus.socket
●   │ │ ├─dm-event.socket
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
●   │ │ ├─apparmor.service
●   │ │ ├─blk-availability.service
●   │ │ ├─dev-hugepages.mount
●   │ │ ├─dev-mqueue.mount
●   │ │ ├─keyboard-setup.service
●   │ │ ├─kmod-static-nodes.service
○   │ │ ├─ldconfig.service
●   │ │ ├─lvm2-lvmpolld.socket
●   │ │ ├─lvm2-monitor.service
●   │ │ ├─plymouth-read-write.service
●   │ │ ├─plymouth-start.service
●   │ │ ├─proc-sys-fs-binfmt_misc.automount
●   │ │ ├─setvtrgb.service
●   │ │ ├─sys-fs-fuse-connections.mount
●   │ │ ├─sys-kernel-config.mount
●   │ │ ├─sys-kernel-debug.mount
●   │ │ ├─sys-kernel-tracing.mount
○   │ │ ├─systemd-ask-password-console.path
●   │ │ ├─systemd-binfmt.service
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
●   │ │ ├─systemd-random-seed.service
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
●   │ │ │ ├─-.mount
○   │ │ │ ├─systemd-fsck-root.service
●   │ │ │ └─systemd-remount-fs.service
●   │ │ ├─swap.target
●   │ │ └─veritysetup.target
●   │ └─timers.target
●   │   ├─anacron.timer
○   │   ├─apport-autoreport.timer
●   │   ├─apt-daily-upgrade.timer
●   │   ├─apt-daily.timer
●   │   ├─dpkg-db-backup.timer
●   │   ├─e2scrub_all.timer
●   │   ├─fstrim.timer
●   │   ├─fwupd-refresh.timer
●   │   ├─logrotate.timer
●   │   ├─man-db.timer
●   │   ├─motd-news.timer
○   │   ├─snapd.snap-repair.timer
●   │   ├─systemd-tmpfiles-clean.timer
○   │   └─ua-timer.timer
●   ├─getty.target
○   │ ├─getty-static.service
○   │ └─getty@tty1.service
●   └─remote-fs.target
lines 142-161/161 (END)
```

### `systemctl list-dependencies multi-user.target`
```  
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
● ├─snap-bare-5.mount
● ├─snap-core22-2111.mount
● ├─snap-core22-2292.mount
● ├─snap-firefox-7766.mount
● ├─snap-firefox-7836.mount
● ├─snap-firmware\x2dupdater-210.mount
● ├─snap-firmware\x2dupdater-216.mount
● ├─snap-gnome\x2d42\x2d2204-202.mount
● ├─snap-gnome\x2d42\x2d2204-247.mount
● ├─snap-gtk\x2dcommon\x2dthemes-1535.mount
● ├─snap-snapd-25935.mount
● ├─snap-snapd-26382.mount
● ├─snapd.apparmor.service
○ ├─snapd.autoimport.service
○ ├─snapd.core-fixup.service
○ ├─snapd.recovery-chooser-trigger.service
● ├─snapd.seeded.service
● ├─snapd.service
○ ├─ssl-cert.service
● ├─sysstat.service
● ├─systemd-ask-password-wall.path
● ├─systemd-logind.service
○ ├─systemd-update-utmp-runlevel.service
● ├─systemd-user-sessions.service
○ ├─thermald.service
○ ├─ua-reboot-cmds.service
○ ├─ubuntu-advantage.service
● ├─ufw.service
● ├─unattended-upgrades.service
● ├─vboxadd-service.service
● ├─vboxadd.service
● ├─whoopsie.path
● ├─wpa_supplicant.service
● ├─basic.target
● │ ├─-.mount
○ │ ├─tmp.mount
● │ ├─paths.target
○ │ │ ├─apport-autoreport.path
○ │ │ └─tpm-udev.path
● │ ├─slices.target
● │ │ ├─-.slice
● │ │ └─system.slice
● │ ├─sockets.target
○ │ │ ├─apport-forward.socket
● │ │ ├─avahi-daemon.socket
● │ │ ├─cups.socket
● │ │ ├─dbus.socket
● │ │ ├─dm-event.socket
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
● │ │ ├─apparmor.service
● │ │ ├─blk-availability.service
● │ │ ├─dev-hugepages.mount
● │ │ ├─dev-mqueue.mount
● │ │ ├─keyboard-setup.service
● │ │ ├─kmod-static-nodes.service
○ │ │ ├─ldconfig.service
● │ │ ├─lvm2-lvmpolld.socket
● │ │ ├─lvm2-monitor.service
● │ │ ├─plymouth-read-write.service
● │ │ ├─plymouth-start.service
● │ │ ├─proc-sys-fs-binfmt_misc.automount
● │ │ ├─setvtrgb.service
● │ │ ├─sys-fs-fuse-connections.mount
● │ │ ├─sys-kernel-config.mount
● │ │ ├─sys-kernel-debug.mount
● │ │ ├─sys-kernel-tracing.mount
○ │ │ ├─systemd-ask-password-console.path
● │ │ ├─systemd-binfmt.service
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
● │ │ ├─systemd-random-seed.service
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
● │ │ │ ├─-.mount
○ │ │ │ ├─systemd-fsck-root.service
● │ │ │ └─systemd-remount-fs.service
● │ │ ├─swap.target
● │ │ └─veritysetup.target
● │ └─timers.target
● │   ├─anacron.timer
○ │   ├─apport-autoreport.timer
● │   ├─apt-daily-upgrade.timer
● │   ├─apt-daily.timer
● │   ├─dpkg-db-backup.timer
● │   ├─e2scrub_all.timer
● │   ├─fstrim.timer
● │   ├─fwupd-refresh.timer
● │   ├─logrotate.timer
● │   ├─man-db.timer
● │   ├─motd-news.timer
○ │   ├─snapd.snap-repair.timer
● │   ├─systemd-tmpfiles-clean.timer
○ │   └─ua-timer.timer
● ├─getty.target
○ │ ├─getty-static.service
○ │ └─getty@tty1.service
● └─remote-fs.target
```

Эти команды позволяют проследить дерево зависимостей между процессами.

## Секция 4. User Sessions

### `who -a`

```
           system boot  2026-04-12 16:02
           run-level 5  2026-04-12 16:03
user     + tty2         2026-04-12 16:03 21:20        1344 (:0)

```

### `last -n 5`

```
user     tty2         :0               Sun Apr 12 16:03    gone - no logout
reboot   system boot  6.14.0-27-generi Sun Apr 12 16:02   still running
user     tty2         :0               Wed Apr  8 16:01 - crash (4+00:00)
reboot   system boot  6.14.0-27-generi Wed Apr  8 16:00   still running
user     tty2         :0               Wed Apr  1 16:05 - crash (6+23:54)

wtmp begins Tue Sep  2 22:32:25 2025
```

Эти команды позволяют отслеживать сессии пользователей.

## Секция 5. Memory Analysis

### `free -h`

```
               total        used        free      shared  buff/cache   available
Mem:           2.9Gi       717Mi       1.2Gi        14Mi       1.1Gi       2.2Gi
Swap:             0B          0B          0B

```

### `cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable`

```
MemTotal:        3003092 kB
MemAvailable:    2268560 kB
SwapTotal:             0 kB
```

Эти команды позволяют детально проверить состояние оперативки и файла подкачки.

## Ответ на вопрос
Самое потребляемое приложение -- это Featherpad, в котором я создавал этот файл.

# Задание 2.

## Команды

## Секция 1. Network Path Tracing

### `traceroute github.com`

```
traceroute to github.com (140.82.121.4), 30 hops max, 60 byte packets
 1  _gateway (10.0.2.2)  58.677 ms  3.466 ms  2.681 ms
 2  * * *
 3  * * *
 4  * * *
 5  * * *
 6  * * *
 7  * * *
 8  * * *
 9  * * *
10  * * *
11  * * *
12  * * *
13  * * *
14  * * *
15  * * *
16  * * *
17  * * *
18  * * *
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
```

### `dig github.com`

```
; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 53544
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             10      IN      A       140.82.121.3

;; Query time: 7 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Mon Apr 13 13:37:21 MSK 2026
;; MSG SIZE  rcvd: 55
```

## Секция 2. Packet Capture

### `sudo timeout 10 tcpdump -c 5 -i any 'port 53' -n`

```
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes

0 packets captured
0 packets received by filter
0 packets dropped by kernel
```

## Секция 3. Reverse DNS

### `dig -x 8.8.4.4`
```
; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 41629
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   785     IN      PTR     dns.google.

;; Query time: 42 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Mon Apr 13 13:39:36 MSK 2026
;; MSG SIZE  rcvd: 73
```

### `dig -x 1.1.2.2`

```
; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 14292
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         900     IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23743 7200 1800 604800 3600

;; Query time: 509 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Mon Apr 13 13:40:16 MSK 2026
;; MSG SIZE  rcvd: 137
```

## Вывод

Запрос был отправлен по протоколу UDP на порт 53. Тип запроса A-запись. Ответ содержал одну запись в секции `ANSWER` с коротким TTL (10 секунд).

У `8.8.4.4` статус `NOERROR`. Найдена PTR-запись. Найден один быстрый ответ (42 мс). У `1.1.2.2` нет PTR-записи. Статус `NXDOMAIN` -- домен не найден. Ответ не найден, запрос выполнялся долго (509 мс).
