# Operating System Analysis

## 1. Operating System Analysis
### 1. All command outputs for sections 1.1-1.5.
#### 1.1. Boot Performance Analysis
**1.1.1 Analyze System Boot Time:**
```bash
systemd-analyze
systemd-analyze blame
```
**Output**:
```bash
Startup finished in 5.206s (firmware) + 6.401s (loader) + 2.387s (kernel) + 16.681s (userspace) = 30.676s 
graphical.target reached after 16.651s in userspace
```

```bash
18.703s apt-daily-upgrade.service
13.211s plymouth-quit-wait.service
10.332s gpu-manager.service
 7.053s NetworkManager-wait-online.service
 2.228s vboxdrv.service
 1.688s snapd.seeded.service
 1.571s snapd.service
 1.345s dev-loop11.device
 1.341s dev-loop8.device
 1.340s dev-loop9.device
 1.311s dev-loop13.device
 1.310s dev-loop12.device
 1.308s dev-loop10.device
 1.227s systemd-resolved.service
 1.100s dev-loop5.device
 1.098s dev-loop6.device
 1.096s dev-loop7.device
 1.087s dev-loop1.device
 1.084s dev-loop0.device
 1.083s dev-loop3.device
 1.082s dev-loop2.device
 1.082s dev-loop4.device
  980ms accounts-daemon.service
  925ms power-profiles-daemon.service
  914ms switcheroo-control.service
  912ms e2scrub_reap.service
  792ms dev-sdb2.device
  786ms systemd-oomd.service
  775ms containerd.service
  759ms systemd-timesyncd.service
  657ms systemd-logind.service
  625ms udisks2.service
  523ms apport.service
  519ms NetworkManager.service
  510ms ModemManager.service
  473ms qemu-kvm.service
  465ms grub-common.service
  460ms avahi-daemon.service
  442ms networkd-dispatcher.service
  430ms grub-initrd-fallback.service
  419ms polkit.service
  401ms rsyslog.service
  386ms snapd.apparmor.service
  327ms systemd-binfmt.service
  317ms apparmor.service
  221ms user@1000.service
  215ms systemd-udev-trigger.service
  209ms proc-sys-fs-binfmt_misc.mount
  205ms dpkg-db-backup.service
  166ms update-notifier-download.service
  140ms systemd-journal-flush.service
  138ms keyboard-setup.service
  137ms logrotate.service
  131ms alsa-restore.service
  128ms systemd-udevd.service
  112ms upower.service
  107ms plymouth-start.service
  107ms thermald.service
  102ms systemd-update-utmp.service
   97ms systemd-journald.service
   96ms run-qemu.mount
   95ms systemd-tmpfiles-setup.service
   94ms packagekit.service
   83ms systemd-backlight@backlight:intel_backlight.service
   80ms boot-efi.mount
   79ms bluetooth.service
   76ms gdm.service
   67ms openvpn.service
   66ms wpa_supplicant.service
   66ms systemd-user-sessions.service
   58ms systemd-modules-load.service
   56ms snap-bare-5.mount
   53ms snap-core22-2139.mount
   51ms systemd-rfkill.service
   50ms snap-core22-2163.mount
   46ms snap-firefox-7423.mount
   43ms snap-firefox-7477.mount
   43ms systemd-fsck@dev-disk-by\x2duuid-D1F7\x2d8820.service
   41ms snap-gnome\x2d42\x2d2204-176.mount
   39ms snap-gnome\x2d42\x2d2204-226.mount
   36ms systemd-sysusers.service
   36ms systemd-tmpfiles-clean.service
   36ms snap-gtk\x2dcommon\x2dthemes-1535.mount
   33ms snap-snap\x2dstore-1113.mount
   33ms colord.service
   33ms kerneloops.service
   32ms snap-snap\x2dstore-1216.mount
   29ms snap-snapd-25202.mount
   28ms dev-hugepages.mount
   27ms systemd-remount-fs.service
   27ms dev-mqueue.mount
   27ms snap-snapd-25577.mount
   27ms systemd-tmpfiles-setup-dev.service
   26ms sys-kernel-debug.mount
   25ms systemd-sysctl.service
   24ms sys-kernel-tracing.mount
   24ms snap-snapd\x2ddesktop\x2dintegration-178.mount
   24ms systemd-random-seed.service
   22ms snap-snapd\x2ddesktop\x2dintegration-315.mount
   22ms plymouth-read-write.service
   21ms swapfile.swap
   19ms console-setup.service
   19ms kmod-static-nodes.service
   18ms modprobe@configfs.service
   17ms modprobe@drm.service
   17ms cups.service
   16ms modprobe@efi_pstore.service
   16ms modprobe@fuse.service
   14ms vboxautostart-service.service
   14ms vboxballoonctrl-service.service
   13ms user-runtime-dir@1000.service
   11ms systemd-update-utmp-runlevel.service
   10ms snapd.socket
    9ms ufw.service
    9ms sys-fs-fuse-connections.mount
    8ms setvtrgb.service
    7ms sys-kernel-config.mount
    7ms vboxweb-service.service
    7ms rtkit-daemon.service
    5ms motd-news.service
```

**1.1.2 Check System Load**
```bash
uptime
w
```

**Output**
```bash
06:19:40 up  2:52,  1 user,  load average: 1,83, 1,07, 0,92
```

```bash
 06:19:43 up  2:52,  1 user,  load average: 1,83, 1,07, 0,92
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
<user>   tty2     tty2             03:29   189days  0.04s  0.04s /usr/libexec/gnome-session-binary --session=ubuntu
```

**Observations:**
- Total boot time: 30.7 seconds
- Major contributors to slow boot:
    - `apt-daily-upgrade.service` (18.7s)
    - `plymouth-quit-wait.service` (13.2s)
    - `gpu-manager.service` (10.3s)
- System load is 1.83.

#### 1.2 Process Forensics
**1.2.1. Identify Resource-Intensive Processes**
```bash
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
```
**Output**
```bash
    PID    PPID CMD                         %MEM %CPU
  11057    3627 /snap/firefox/7477/usr/lib/  7.0 16.9
   3440    2173 /snap/firefox/7477/usr/lib/  5.9 21.8
  12042    3627 /snap/firefox/7477/usr/lib/  4.4  2.6
   5396    3627 /snap/firefox/7477/usr/lib/  3.4  4.2
   4371    4250 /usr/share/code/code --type  3.3 12.7
```

```bash
    PID    PPID CMD                         %MEM %CPU
   3440    2173 /snap/firefox/7477/usr/lib/  5.9 21.8
  11057    3627 /snap/firefox/7477/usr/lib/  7.0 16.9
   4371    4250 /usr/share/code/code --type  3.3 12.7
   2173    1997 /usr/bin/gnome-shell         2.7 10.9
    713       1 avahi-daemon: running [<hostname>]  0.0  7.8
```

**Observations:**
- Firefox is the top consumer of both memory and CPU. Other processes that use notable resources are vscode and gnome shell.

#### 1.3 Service Dependencies
**1.3.1 Map Service Relationships**
```bash
systemctl list-dependencies
systemctl list-dependencies multi-user.target
```

**Output**
```bash
default.target
● ├─accounts-daemon.service
● ├─apport.service
● ├─gdm.service
● ├─power-profiles-daemon.service
● ├─switcheroo-control.service
○ ├─systemd-update-utmp-runlevel.service
● ├─udisks2.service
● └─multi-user.target
○   ├─anacron.service
●   ├─apport.service
●   ├─avahi-daemon.service
●   ├─console-setup.service
●   ├─containerd.service
●   ├─cron.service
●   ├─cups-browsed.service
●   ├─cups.path
●   ├─cups.service
●   ├─dbus.service
○   ├─dmesg.service
○   ├─e2scrub_reap.service
○   ├─grub-common.service
○   ├─grub-initrd-fallback.service
●   ├─irqbalance.service
●   ├─kerneloops.service
●   ├─ModemManager.service
●   ├─networkd-dispatcher.service
●   ├─NetworkManager.service
●   ├─openvpn.service
●   ├─plymouth-quit-wait.service
○   ├─plymouth-quit.service
●   ├─qemu-kvm.service
●   ├─rsyslog.service
●   ├─run-qemu.mount
○   ├─secureboot-db.service
●   ├─snap-bare-5.mount
●   ├─snap-core22-2139.mount
●   ├─snap-core22-2163.mount
●   ├─snap-firefox-7423.mount
●   ├─snap-firefox-7477.mount
●   ├─snap-gnome\x2d42\x2d2204-176.mount
●   ├─snap-gnome\x2d42\x2d2204-226.mount
●   ├─snap-gtk\x2dcommon\x2dthemes-1535.mount
●   ├─snap-snap\x2dstore-1113.mount
●   ├─snap-snap\x2dstore-1216.mount
●   ├─snap-snapd-25202.mount
●   ├─snap-snapd-25577.mount
●   ├─snap-snapd\x2ddesktop\x2dintegration-178.mount
●   ├─snap-snapd\x2ddesktop\x2dintegration-315.mount
●   ├─snapd.apparmor.service
○   ├─snapd.autoimport.service
○   ├─snapd.core-fixup.service
○   ├─snapd.recovery-chooser-trigger.service
●   ├─snapd.seeded.service
●   ├─snapd.service
●   ├─systemd-ask-password-wall.path
●   ├─systemd-logind.service
●   ├─systemd-oomd.service
●   ├─systemd-resolved.service
○   ├─systemd-update-utmp-runlevel.service
●   ├─systemd-user-sessions.service
●   ├─thermald.service
○   ├─ua-reboot-cmds.service
○   ├─ubuntu-advantage.service
●   ├─ufw.service
●   ├─unattended-upgrades.service
●   ├─vboxautostart-service.service
●   ├─vboxballoonctrl-service.service
●   ├─vboxdrv.service
●   ├─vboxweb-service.service
●   ├─whoopsie.path
●   ├─wpa_supplicant.service
●   ├─basic.target
●   │ ├─-.mount
○   │ ├─tmp.mount
●   │ ├─paths.target
●   │ │ ├─acpid.path
○   │ │ └─apport-autoreport.path
●   │ ├─slices.target
●   │ │ ├─-.slice
●   │ │ └─system.slice
●   │ ├─sockets.target
●   │ │ ├─acpid.socket
○   │ │ ├─apport-forward.socket
●   │ │ ├─avahi-daemon.socket
●   │ │ ├─cups.socket
●   │ │ ├─dbus.socket
●   │ │ ├─snapd.socket
●   │ │ ├─systemd-initctl.socket
●   │ │ ├─systemd-journald-audit.socket
●   │ │ ├─systemd-journald-dev-log.socket
●   │ │ ├─systemd-journald.socket
●   │ │ ├─systemd-udevd-control.socket
●   │ │ ├─systemd-udevd-kernel.socket
●   │ │ └─uuidd.socket
●   │ ├─sysinit.target
●   │ │ ├─apparmor.service
●   │ │ ├─dev-hugepages.mount
●   │ │ ├─dev-mqueue.mount
●   │ │ ├─keyboard-setup.service
●   │ │ ├─kmod-static-nodes.service
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
○   │ │ ├─systemd-boot-system-token.service
●   │ │ ├─systemd-journal-flush.service
●   │ │ ├─systemd-journald.service
○   │ │ ├─systemd-machine-id-commit.service
●   │ │ ├─systemd-modules-load.service
○   │ │ ├─systemd-pstore.service
●   │ │ ├─systemd-random-seed.service
●   │ │ ├─systemd-sysctl.service
●   │ │ ├─systemd-sysusers.service
●   │ │ ├─systemd-timesyncd.service
●   │ │ ├─systemd-tmpfiles-setup-dev.service
●   │ │ ├─systemd-tmpfiles-setup.service
●   │ │ ├─systemd-udev-trigger.service
●   │ │ ├─systemd-udevd.service
●   │ │ ├─systemd-update-utmp.service
●   │ │ ├─cryptsetup.target
●   │ │ ├─local-fs.target
●   │ │ │ ├─-.mount
●   │ │ │ ├─boot-efi.mount
○   │ │ │ ├─systemd-fsck-root.service
●   │ │ │ └─systemd-remount-fs.service
●   │ │ ├─swap.target
●   │ │ │ └─swapfile.swap
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
○   │   ├─ua-timer.timer
●   │   ├─update-notifier-download.timer
●   │   └─update-notifier-motd.timer
●   ├─getty.target
○   │ ├─getty-static.service
○   │ └─getty@tty1.service
●   └─remote-fs.target
```

```bash
multi-user.target
○ ├─anacron.service
● ├─apport.service
● ├─avahi-daemon.service
● ├─console-setup.service
● ├─containerd.service
● ├─cron.service
● ├─cups-browsed.service
● ├─cups.path
● ├─cups.service
● ├─dbus.service
○ ├─dmesg.service
○ ├─e2scrub_reap.service
○ ├─grub-common.service
○ ├─grub-initrd-fallback.service
● ├─irqbalance.service
● ├─kerneloops.service
● ├─ModemManager.service
● ├─networkd-dispatcher.service
● ├─NetworkManager.service
● ├─openvpn.service
● ├─plymouth-quit-wait.service
○ ├─plymouth-quit.service
● ├─qemu-kvm.service
● ├─rsyslog.service
● ├─run-qemu.mount
○ ├─secureboot-db.service
● ├─snap-bare-5.mount
● ├─snap-core22-2139.mount
● ├─snap-core22-2163.mount
● ├─snap-firefox-7423.mount
● ├─snap-firefox-7477.mount
● ├─snap-gnome\x2d42\x2d2204-176.mount
● ├─snap-gnome\x2d42\x2d2204-226.mount
● ├─snap-gtk\x2dcommon\x2dthemes-1535.mount
● ├─snap-snap\x2dstore-1113.mount
● ├─snap-snap\x2dstore-1216.mount
● ├─snap-snapd-25202.mount
● ├─snap-snapd-25577.mount
● ├─snap-snapd\x2ddesktop\x2dintegration-178.mount
● ├─snap-snapd\x2ddesktop\x2dintegration-315.mount
● ├─snapd.apparmor.service
○ ├─snapd.autoimport.service
○ ├─snapd.core-fixup.service
○ ├─snapd.recovery-chooser-trigger.service
● ├─snapd.seeded.service
● ├─snapd.service
● ├─systemd-ask-password-wall.path
● ├─systemd-logind.service
● ├─systemd-oomd.service
● ├─systemd-resolved.service
○ ├─systemd-update-utmp-runlevel.service
● ├─systemd-user-sessions.service
● ├─thermald.service
○ ├─ua-reboot-cmds.service
○ ├─ubuntu-advantage.service
● ├─ufw.service
● ├─unattended-upgrades.service
● ├─vboxautostart-service.service
● ├─vboxballoonctrl-service.service
● ├─vboxdrv.service
● ├─vboxweb-service.service
● ├─whoopsie.path
● ├─wpa_supplicant.service
● ├─basic.target
● │ ├─-.mount
○ │ ├─tmp.mount
● │ ├─paths.target
● │ │ ├─acpid.path
○ │ │ └─apport-autoreport.path
● │ ├─slices.target
● │ │ ├─-.slice
● │ │ └─system.slice
● │ ├─sockets.target
● │ │ ├─acpid.socket
○ │ │ ├─apport-forward.socket
● │ │ ├─avahi-daemon.socket
● │ │ ├─cups.socket
● │ │ ├─dbus.socket
● │ │ ├─snapd.socket
● │ │ ├─systemd-initctl.socket
● │ │ ├─systemd-journald-audit.socket
● │ │ ├─systemd-journald-dev-log.socket
● │ │ ├─systemd-journald.socket
● │ │ ├─systemd-udevd-control.socket
● │ │ ├─systemd-udevd-kernel.socket
● │ │ └─uuidd.socket
● │ ├─sysinit.target
● │ │ ├─apparmor.service
● │ │ ├─dev-hugepages.mount
● │ │ ├─dev-mqueue.mount
● │ │ ├─keyboard-setup.service
● │ │ ├─kmod-static-nodes.service
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
○ │ │ ├─systemd-boot-system-token.service
● │ │ ├─systemd-journal-flush.service
● │ │ ├─systemd-journald.service
○ │ │ ├─systemd-machine-id-commit.service
● │ │ ├─systemd-modules-load.service
○ │ │ ├─systemd-pstore.service
● │ │ ├─systemd-random-seed.service
● │ │ ├─systemd-sysctl.service
● │ │ ├─systemd-sysusers.service
● │ │ ├─systemd-timesyncd.service
● │ │ ├─systemd-tmpfiles-setup-dev.service
● │ │ ├─systemd-tmpfiles-setup.service
● │ │ ├─systemd-udev-trigger.service
● │ │ ├─systemd-udevd.service
● │ │ ├─systemd-update-utmp.service
● │ │ ├─cryptsetup.target
● │ │ ├─local-fs.target
● │ │ │ ├─-.mount
● │ │ │ ├─boot-efi.mount
○ │ │ │ ├─systemd-fsck-root.service
● │ │ │ └─systemd-remount-fs.service
● │ │ ├─swap.target
● │ │ │ └─swapfile.swap
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
○ │   ├─ua-timer.timer
● │   ├─update-notifier-download.timer
● │   └─update-notifier-motd.timer
● ├─getty.target
○ │ ├─getty-static.service
○ │ └─getty@tty1.service
● └─remote-fs.target
```

#### 1.4 User Sessions
**1.4.1 Audit Login Activity:**
```bash
who -a
last -n 5
```

**Output**
```bash
           system boot  2025-06-04 17:17
           run-level 5  2025-12-10 22:11
<user>   + tty2         2025-12-11 03:29  old         2059 (tty2)
```

```bash
<user>   tty2         tty2             Thu Dec 11 03:29   still logged in
reboot   system boot  6.8.0-87-generic Wed Jun  4 17:17   still running
<user>   tty2         tty2             Wed Dec 10 10:28 - down   (11:42)
reboot   system boot  6.8.0-87-generic Wed Jun  4 17:17 - 22:11 (189+04:53)
<user>   tty2         tty2             Tue Dec  9 02:17 - down   (04:14)

wtmp begins Wed Nov 22 00:06:37 2023
```

**Observations:**
- The system has been running since June 4, which is a very long uptime.

#### 1.5 Memory Analysis
**1.5.1 Inspect Memory Allocation:**
```bash
free -h
cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
```

**Output**
```bash
               total        used        free      shared  buff/cache   available
Mem:            11Gi       4,5Gi       3,3Gi       737Mi       3,7Gi       7,0Gi
Swap:          2,0Gi          0B       2,0Gi
```

```bash
MemTotal:       12135156 kB
MemAvailable:    7349348 kB
SwapTotal:       2097148 kB
```

**Observations**
- Swap is unused, indicating RAM is sufficient for current workload.
- High available memory (7.3GB) suggests the system is not under memory pressure.