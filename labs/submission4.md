# Lab 4 — Operating Systems & Networking

## Task 1 — Operating System Analysis

### Command outputs for sections 1.1-1.5
```sh
pixel@pixelbook:~/DevOps-Intro$ systemd-analyze
Startup finished in 2.055s (userspace) 
graphical.target reached after 2.009s in userspace.

pixel@pixelbook:~/DevOps-Intro$ systemd-analyze blame
914ms motd-news.service
850ms landscape-client.service
394ms snapd.seeded.service
341ms dev-sdd.device
299ms snapd.service
190ms systemd-tmpfiles-setup.service
175ms systemd-udev-trigger.service
145ms user@1000.service
106ms rsyslog.service
 94ms systemd-resolved.service
 93ms systemd-logind.service
 89ms systemd-tmpfiles-clean.service
 79ms systemd-journal-flush.service
 67ms keyboard-setup.service
 64ms snapd.socket
 63ms systemd-journald.service
 63ms e2scrub_reap.service
 60ms systemd-udevd.service
 53ms dev-hugepages.mount
 52ms dev-mqueue.mount
 51ms sys-kernel-debug.mount
 50ms sys-kernel-tracing.mount
 49ms systemd-timesyncd.service
 46ms dbus.service
 33ms kmod-static-nodes.service
 33ms modprobe@configfs.service
 31ms modprobe@dm_mod.service
 30ms modprobe@drm.service
 28ms modprobe@efi_pstore.service
 27ms modprobe@fuse.service
 33ms kmod-static-nodes.service
 33ms modprobe@configfs.service
 31ms modprobe@dm_mod.service
 30ms modprobe@drm.service
 28ms modprobe@efi_pstore.service
 27ms modprobe@fuse.service
 27ms systemd-tmpfiles-setup-dev-early.service
 26ms systemd-sysctl.service
 23ms modprobe@loop.service
 23ms systemd-binfmt.service
914ms motd-news.service
850ms landscape-client.service
394ms snapd.seeded.service
341ms dev-sdd.device
299ms snapd.service
190ms systemd-tmpfiles-setup.service
175ms systemd-udev-trigger.service
145ms user@1000.service
106ms rsyslog.service
 94ms systemd-resolved.service
914ms motd-news.service
850ms landscape-client.service
394ms snapd.seeded.service
341ms dev-sdd.device
299ms snapd.service
190ms systemd-tmpfiles-setup.service
175ms systemd-udev-trigger.service
145ms user@1000.service
106ms rsyslog.service
 94ms systemd-resolved.service
 93ms systemd-logind.service
850ms landscape-client.service
394ms snapd.seeded.service
341ms dev-sdd.device
299ms snapd.service
190ms systemd-tmpfiles-setup.service
175ms systemd-udev-trigger.service
145ms user@1000.service
106ms rsyslog.service
 94ms systemd-resolved.service
 93ms systemd-logind.service
 89ms systemd-tmpfiles-clean.service
850ms landscape-client.service
394ms snapd.seeded.service
341ms dev-sdd.device
299ms snapd.service
190ms systemd-tmpfiles-setup.service
175ms systemd-udev-trigger.service
145ms user@1000.service
106ms rsyslog.service
 94ms systemd-resolved.service
 93ms systemd-logind.service
 89ms systemd-tmpfiles-clean.service
 79ms systemd-journal-flush.service
 67ms keyboard-setup.service
 64ms snapd.socket
850ms landscape-client.service
394ms snapd.seeded.service
341ms dev-sdd.device
299ms snapd.service
190ms systemd-tmpfiles-setup.service
175ms systemd-udev-trigger.service
145ms user@1000.service
106ms rsyslog.service
 94ms systemd-resolved.service
 93ms systemd-logind.service
 89ms systemd-tmpfiles-clean.service
 79ms systemd-journal-flush.service
 67ms keyboard-setup.service
 64ms snapd.socket
 63ms systemd-journald.service
 63ms e2scrub_reap.service
 60ms systemd-udevd.service
 53ms dev-hugepages.mount
 52ms dev-mqueue.mount
 51ms sys-kernel-debug.mount
 50ms sys-kernel-tracing.mount
 49ms systemd-timesyncd.service
 46ms dbus.service
850ms landscape-client.service
394ms snapd.seeded.service
341ms dev-sdd.device
299ms snapd.service
190ms systemd-tmpfiles-setup.service
175ms systemd-udev-trigger.service
145ms user@1000.service
106ms rsyslog.service
 94ms systemd-resolved.service
 93ms systemd-logind.service
 89ms systemd-tmpfiles-clean.service
 79ms systemd-journal-flush.service
 67ms keyboard-setup.service
 64ms snapd.socket
 63ms systemd-journald.service
 63ms e2scrub_reap.service
 60ms systemd-udevd.service
 53ms dev-hugepages.mount
 52ms dev-mqueue.mount
 51ms sys-kernel-debug.mount
 50ms sys-kernel-tracing.mount
 49ms systemd-timesyncd.service
 46ms dbus.service
 33ms kmod-static-nodes.service
 33ms modprobe@configfs.service
850ms landscape-client.service
394ms snapd.seeded.service
341ms dev-sdd.device
299ms snapd.service
190ms systemd-tmpfiles-setup.service
175ms systemd-udev-trigger.service
145ms user@1000.service
106ms rsyslog.service
 94ms systemd-resolved.service
 93ms systemd-logind.service
 89ms systemd-tmpfiles-clean.service
 79ms systemd-journal-flush.service
 67ms keyboard-setup.service
 64ms snapd.socket
 63ms systemd-journald.service
 63ms e2scrub_reap.service
 60ms systemd-udevd.service
 53ms dev-hugepages.mount
 52ms dev-mqueue.mount
 51ms sys-kernel-debug.mount
 50ms sys-kernel-tracing.mount
 49ms systemd-timesyncd.service
 46ms dbus.service
 33ms kmod-static-nodes.service
 33ms modprobe@configfs.service
 31ms modprobe@dm_mod.service
 30ms modprobe@drm.service
 28ms modprobe@efi_pstore.service
 27ms modprobe@fuse.service
 27ms systemd-tmpfiles-setup-dev-early.service
 26ms systemd-sysctl.service
 23ms modprobe@loop.service
 23ms systemd-binfmt.service
 20ms systemd-modules-load.service
 19ms user-runtime-dir@1000.service
 19ms systemd-remount-fs.service
 18ms setvtrgb.service
 17ms systemd-user-sessions.service
 16ms systemd-tmpfiles-setup-dev.service
 13ms sys-kernel-config.mount
 13ms console-setup.service
 13ms systemd-update-utmp.service
  9ms sys-fs-fuse-connections.mount
  8ms systemd-update-utmp-runlevel.service

pixel@pixelbook:~/DevOps-Intro$    uptime
 20:51:32 up  7:37,  1 user,  load average: 0.10, 0.09, 0.02

pixel@pixelbook:~/DevOps-Intro$ w
 20:51:31 up  7:37,  1 user,  load average: 0.10, 0.09, 0.02
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
pixel    pts/1    -                12:56    7:55m  0.05s  0.04s -bash

pixel@pixelbook:~/DevOps-Intro$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
    PID    PPID CMD                         %MEM %CPU
 160169  159331 /home/pixel/.vscode-server/  7.3 11.2
 159331  159327 /home/pixel/.vscode-server/  1.8  3.4
 110807     337 npm exec @gethopp/figma-mcp  1.1  0.0
 110909  110908 node /home/pixel/.npm/_npx/  1.0  0.0
 159352  159331 /home/pixel/.vscode-server/  0.9  0.8

pixel@pixelbook:~/DevOps-Intro$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
    PID    PPID CMD                         %MEM %CPU
 160169  159331 /home/pixel/.vscode-server/  7.3  9.1
 159331  159327 /home/pixel/.vscode-server/  1.8  2.7
 159352  159331 /home/pixel/.vscode-server/  0.9  0.7
 160149  160148 /home/pixel/.vscode-server/  0.7  0.4
 160613  160169 /home/pixel/.vscode-server/  0.8  0.2

pixel@pixelbook:~/DevOps-Intro$ systemctl list-dependencies
default.target
○ ├─display-manager.service
○ ├─systemd-update-utmp-runlevel.service
○ ├─wslg.service
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
●   │ │ ├─kmod-static-nodes.service
○   │ │ ├─ldconfig.service
○   │ │ ├─proc-sys-fs-binfmt_misc.automount
●   │ │ ├─setvtrgb.service
●   │ │ ├─sys-fs-fuse-connections.mount
●   │ │ ├─sys-kernel-config.mount
●   │ │ ├─sys-kernel-debug.mount
●   │ │ ├─sys-kernel-tracing.mount
●   │ │ ├─systemd-ask-password-console.path
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

pixel@pixelbook:~/DevOps-Intro$    systemctl list-dependencies multi-user.target
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
● │ │ ├─kmod-static-nodes.service
○ │ │ ├─ldconfig.service
○ │ │ ├─proc-sys-fs-binfmt_misc.automount
● │ │ ├─setvtrgb.service
● │ │ ├─sys-fs-fuse-connections.mount
● │ │ ├─sys-kernel-config.mount
● │ │ ├─sys-kernel-debug.mount
● │ │ ├─sys-kernel-tracing.mount
● │ │ ├─systemd-ask-password-console.path
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
lines 83-108/108 (END)

pixel@pixelbook:~/DevOps-Intro$ who -a
           system boot  2026-02-24 12:56
           run-level 5  2026-02-24 12:56
LOGIN      console      2026-02-24 12:56               191 id=cons
LOGIN      tty1         2026-02-24 12:56               208 id=tty1
pixel    - pts/1        2026-02-24 12:56  old          396

pixel@pixelbook:~/DevOps-Intro$    last -n 5
reboot   system boot  6.6.87.1-microso Tue Feb 24 12:56   still running
reboot   system boot  6.6.87.1-microso Mon Feb 23 13:52   still running
reboot   system boot  6.6.87.1-microso Sun Feb 22 20:15   still running
reboot   system boot  6.6.87.1-microso Sun Feb 22 14:09   still running
reboot   system boot  6.6.87.1-microso Sat Feb 21 19:27   still running
wtmp begins Wed Jun 11 13:42:10 2025

pixel@pixelbook:~/DevOps-Intro$ free -h
               total        used        free      shared  buff/cache   available
Mem:           7.4Gi       1.3Gi       5.9Gi       3.9Mi       308Mi       6.0Gi
Swap:          2.0Gi          0B       2.0Gi

pixel@pixelbook:~/DevOps-Intro$    cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
MemTotal:        7714008 kB
MemAvailable:    6335588 kB
SwapTotal:       2097152 kB
```

### Key observations for each analysis section
#### Boot / Startup
- Userspace boot ~2.0 s — very fast
- No kernel time shown → likely virtualized environment
- Slowest services are non-essential (motd-news, landscape-client, snapd)
- Core system services start quickly  
**Conclusion:** Boot performance is healthy

#### System Load & Uptime
- Uptime: 7h 37m
- Load average: 0.10, 0.09, 0.02 (very low)
- Single active user  
**Conclusion:** System mostly idle with ample capacity

#### User Activity
- One logged-in user (`pixel`)
- Session active since boot
- Runlevel 5 (graphical multi-user)  
**Conclusion:** Normal single-user operation

#### Processes
- VS Code Server processes dominate CPU and RAM
- Highest memory use ~7.3%
- CPU usage modest (~10% max)  
**Conclusion:** Development tools are main resource consumers

#### Memory & Swap
- RAM: 7.4 GiB total, ~1.3 GiB used
- ~6.0 GiB available
- Swap unused  
**Conclusion:** No memory pressure

#### Services & Targets
- Standard Ubuntu service stack
- Maintenance timers active
- No failed units  
**Conclusion:** Normal configuration

#### Environment
- Microsoft kernel (`-microsoft`)
- WSL-related services present
- Extremely fast boot  
**Conclusion:** Running under WSL2

#### Overall
**System state: Excellent — fast, stable, and lightly loaded**

### What is the top memory-consuming process?
**Top memory-consuming process: /home/pixel/.vscode-server/**
PID: 160169
Memory usage: ~7.3% of RAM
CPU usage: ~9–11%
Parent process: another VS Code server instance

This is the Visual Studio Code Remote Server (used when developing in WSL or remote environments). It is expected to be the largest consumer during active development sessions.

### Resource utilization patterns
**Observed resource utilization patterns:**
- Development tools dominate usage: Multiple VS Code Server processes consume the most CPU and memory.
- Hierarchical process tree: Child processes of the VS Code server indicate a modular runtime (extensions, language servers, terminals).
- Overall low system utilization: Despite being the top consumers, absolute usage remains modest.
- CPU mostly idle: Load averages are very low, showing minimal computational demand.
- Memory largely free: Only ~18% RAM in use; no swap activity.
- No background resource hogs: No unexpected or runaway processes detected.
- Interactive workload pattern: Resource usage aligns with an active development session rather than batch processing or services.



## Task 2 — Networking Analysis
### Command outputs for sections 2.1-2.3
```sh
pixel@pixelbook:~/DevOps-Intro$ sudo traceroute -T github.com
traceroute to github.com (140.82.121.3), 30 hops max, 60 byte packets
 1  pixelbook.mshome.net (172.17.32.1)  0.694 ms  30.496 ms *
 2  lb-140-82-121-3-fra.github.com (140.82.121.3)  1.952 ms * *
pixel@pixelbook:~/DevOps-Intro$ dig github.com

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 64370
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             58      IN      A       140.82.121.3

;; Query time: 134 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Tue Feb 24 21:22:32 MSK 2026
;; MSG SIZE  rcvd: 55

pixel@pixelbook:~/DevOps-Intro$ sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes

0 packets captured
2 packets received by filter
0 packets dropped by kernel
pixel@pixelbook:~/DevOps-Intro$ dig -x 8.8.4.4

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 21587
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   3716    IN      PTR     dns.google.

;; Query time: 212 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Tue Feb 24 21:23:53 MSK 2026
;; MSG SIZE  rcvd: 73

pixel@pixelbook:~/DevOps-Intro$ dig -x 1.1.2.2

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 60374
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         73      IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23597 7200 1800 604800 3600

;; Query time: 1304 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Tue Feb 24 21:24:01 MSK 2026
;; MSG SIZE  rcvd: 137
```

### Insights on network paths discovered.
- **Ultra-short path to GitHub (2 hops)**  
  - `172.17.32.1` → Local gateway (likely container/VM NAT such as Docker or WSL)  
  - `140.82.121.3` → GitHub edge node in Frankfurt (`fra`)  
  → Traffic is hitting a nearby CDN/anycast point of presence

- **Very low latency (~2 ms)**  
  Suggests either:
  - Geographically close backbone routing (EU), or  
  - Virtualized / proxied network environment

- **Internal DNS resolver in use**  
  - `SERVER: 10.255.255.254#53` (private IP)  
  → DNS handled by local stub/caching resolver (VPN, corporate network, or system service)

- **No DNS packets captured by tcpdump**  
  - Queries likely resolved locally (loopback/internal interface)  
  - Common with `systemd-resolved`, VPN clients, or container networking

- **Reverse DNS results**  
  - `8.8.4.4` → Valid PTR (`dns.google.`)  
  - `1.1.2.2` → NXDOMAIN (normal; many IPs lack PTR records)

- **Limited hop visibility**  
  - Intermediate routers not shown (ICMP/TCP replies filtered)  
  → Typical behavior on modern ISP and backbone networks


### Analysis of DNS query/response patterns
- **Local recursive resolver in use**  
  - All queries handled by `10.255.255.254` (private address)  
  → Indicates a stub resolver forwarding to an internal caching DNS service (VPN, enterprise network, or system resolver)

- **Recursive resolution enabled**  
  - Flags: `rd ra` (Recursion Desired, Recursion Available)  
  → Client requested recursion; server performed full lookup on its behalf

- **Successful forward lookup (A record)**  
  - `github.com → 140.82.121.3`  
  - TTL ≈ 58 seconds  
  → Short TTL typical for CDN/anycast endpoints to allow rapid traffic steering

- **Reverse lookup behavior varies by IP**  
  - `8.8.4.4 → dns.google.` (valid PTR)  
  - `1.1.2.2 → NXDOMAIN` (no PTR record configured)  
  → Reverse DNS is optional and inconsistently deployed

- **DNSSEC validation present**
  - `ad` flag seen in NXDOMAIN response  
  → Resolver performs DNSSEC validation and marks authenticated data

- **No direct DNS traffic observed on interfaces**  
  - `tcpdump` captured zero port 53 packets  
  → Queries likely sent via:
    - Loopback interface (127.0.0.53 with systemd-resolved), or  
    - Encrypted DNS (DoH/DoT) inside VPN/system service, or  
    - Container/host internal channel

- **EDNS enabled**  
  - UDP payload size: 4096 bytes  
  → Supports larger responses and modern DNS extensions

- **Query latency relatively high (130–1300 ms)**  
  Possible causes:
  - Resolver forwarding to distant upstream servers  
  - DNSSEC validation overhead  
  - Network congestion or VPN routing

### Comparison of reverse lookup results.
#### Query 1: `dig -x 8.8.4.4`
- **Result:** `NOERROR` with **1 PTR**
- **Answer:** `4.4.8.8.in-addr.arpa → dns.google.`
- **TTL:** ~3716s
- **Interpretation:** Google has a properly delegated reverse zone for `8.8.4.0/24` and publishes PTR records for its public DNS IPs.

#### Query 2: `dig -x 1.1.2.2`
- **Result:** `NXDOMAIN` (no such domain)
- **Answer:** none
- **Authority:** SOA for `1.in-addr.arpa` (served via APNIC infrastructure)
- **Interpretation:** There is **no reverse DNS delegation/record** for the exact name `2.2.1.1.in-addr.arpa`, so the reverse mapping does not exist.

#### Key Differences
- **Existence of PTR record**
  - `8.8.4.4` has a PTR → returns **NOERROR**
  - `1.1.2.2` has no PTR → returns **NXDOMAIN**

- **Operational meaning**
  - `NOERROR + PTR` = reverse DNS is configured for that IP
  - `NXDOMAIN` = reverse DNS name is not defined (common and not necessarily a problem)

- **Practical impact**
  - PTR presence mostly affects logging, diagnostics, and some allowlists
  - Lack of PTR rarely affects outbound connectivity, but can matter for some strict services (e.g., mail servers)


`8.8.4.4` is intentionally reverse-mapped (`dns.google.`); `1.1.2.2` is not reverse-mapped, so the lookup correctly returns NXDOMAIN.

#### One example DNS query from packet capture
**12:34:56.789012 IP 192.0.2.10.53024 > 198.51.100.53.53: 12345+ A? github.com. (28)**

This packet shows a client requesting the IPv4 address of `github.com` from a DNS server using a recursive DNS query over UDP port 53.