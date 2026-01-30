# Lab 4 — Operating Systems & Networking

## Task 1 — Operating System Analysis

### Task 1.1 — Boot Performance Analysis

**1. Analyze System Boot Time**

```bash
anna@annaThinkBook ~> systemd-analyze
Startup finished in 4.286s (firmware) + 13.350s (loader) + 1.496s (kernel) + 9.942s (userspace) = 29.076s 
graphical.target reached after 9.915s in userspace.
```

Observation:

The total boot time is ~29 seconds. The slowest stages are firmware and loader (~18 seconds combined). The kernel loads quickly (~1.5s), and the graphical interface becomes ready in ~10s.

```bash
anna@annaThinkBook ~> systemd-analyze blame
4min 37.161s snapd.service
     38.785s dev-loop13.device
     36.317s dev-loop18.device
     30.169s dev-loop3.device
     17.868s fstrim.service
      6.138s dev-loop17.device
      5.871s NetworkManager-wait-online.service
      2.566s plymouth-quit-wait.service
      1.805s man-db.service
      1.297s snapd.seeded.service
       890ms systemd-backlight@backlight:amdgpu_bl1.service
       858ms NetworkManager.service
       781ms docker.service
       779ms boot-efi.mount
       730ms fwupd.service
       261ms dev-nvme0n1p5.device
       220ms upower.service
       204ms apport.service
       167ms snapd.apparmor.service
       154ms user@1000.service
       149ms systemd-udev-trigger.service
       144ms udisks2.service
       131ms containerd.service
       127ms dev-loop6.device
       123ms dev-loop1.device
       115ms secureboot-db.service
       114ms dev-loop7.device
       110ms dev-loop5.device
       107ms dev-loop4.device
       106ms gnome-remote-desktop.service
       100ms power-profiles-daemon.service
        98ms polkit.service
        94ms accounts-daemon.service
        93ms gpu-manager.service
        90ms dev-loop2.device
        87ms systemd-journal-flush.service
        83ms dev-loop0.device
        75ms rsyslog.service
        69ms gdm.service
        65ms plymouth-start.service
        64ms update-notifier-download.service
        64ms systemd-fsck@dev-disk-by\x2duuid-78F2\x2dE94E.service
        63ms systemd-journald.service
        60ms systemd-resolved.service
        57ms ModemManager.service
        55ms apparmor.service
        53ms setvtrgb.service
        52ms systemd-tmpfiles-setup.service
        50ms dev-loop10.device
        49ms dev-loop8.device
        49ms dev-loop11.device
        48ms dev-loop9.device
        46ms dev-loop16.device
        46ms dev-loop15.device
        46ms dev-loop14.device
        46ms dev-loop12.device
        45ms avahi-daemon.service
        45ms systemd-udevd.service
        44ms bluetooth.service
        41ms grub-common.service
        39ms dbus.service
        35ms systemd-sysctl.service
        33ms bolt.service
        32ms systemd-logind.service
        32ms systemd-oomd.service
        31ms keyboard-setup.service
        31ms systemd-random-seed.service
        30ms systemd-timesyncd.service
        29ms fwupd-refresh.service
        28ms colord.service
        27ms systemd-tmpfiles-clean.service
        27ms switcheroo-control.service
        25ms systemd-remount-fs.service
        24ms snap-bare-5.mount
        24ms cups.service
        23ms snap-code-196.mount
        23ms snap-core20-2599.mount
        22ms systemd-modules-load.service
        22ms e2scrub_reap.service
        21ms snap-core22-1981.mount
        21ms grub-initrd-fallback.service
        20ms snap-core24-988.mount
        20ms thermald.service
        20ms snap-firefox-5751.mount
        19ms docker.socket
        19ms snap-firefox-6316.mount
        18ms snap-firmware\x2dupdater-167.mount
        17ms snap-gnome\x2d42\x2d2204-202.mount
        17ms rtkit-daemon.service
        17ms snap-gtk\x2dcommon\x2dthemes-1535.mount
        16ms dev-loop19.device
        16ms snap-snap\x2dstore-1248.mount
        16ms systemd-binfmt.service
        15ms plymouth-read-write.service
        15ms snap-snap\x2dstore-1270.mount
        15ms iio-sensor-proxy.service
        15ms dev-loop25.device
        14ms dev-loop22.device
        14ms dev-hugepages.mount
        13ms dev-loop24.device
        13ms kerneloops.service
        13ms wpa_supplicant.service
        13ms dev-mqueue.mount
        12ms snap-snapd-24505.mount
        12ms sys-kernel-debug.mount
        12ms systemd-tmpfiles-setup-dev-early.service
        11ms snap-snapd\x2ddesktop\x2dintegration-253.mount
        11ms sys-kernel-tracing.mount
        11ms sysstat.service
        10ms flatpak-system-helper.service
        10ms snap-telegram\x2ddesktop-6691.mount
         9ms alsa-restore.service
         9ms snap-chromium-3251.mount
         8ms kmod-static-nodes.service
         8ms snap-gnome\x2d46\x2d2404-125.mount
         8ms snap-gnome\x2d42\x2d2204-226.mount
         8ms systemd-backlight@leds:platform::kbd_backlight.service
         8ms snap-mesa\x2d2404-912.mount
         8ms modprobe@configfs.service
         7ms proc-sys-fs-binfmt_misc.mount
         7ms swap.img.swap
         7ms snap-cups-1100.mount
         7ms systemd-rfkill.service
         7ms dev-loop20.device
         7ms snap-telegram\x2ddesktop-6798.mount
         7ms modprobe@drm.service
         7ms snap-core24-1151.mount
         7ms systemd-tmpfiles-setup-dev.service
         6ms snap-core22-2133.mount
         6ms snap-snapd\x2ddesktop\x2dintegration-315.mount
         6ms snap-core20-2669.mount
         6ms systemd-update-utmp.service
         6ms snap-snapd-25202.mount
         6ms modprobe@fuse.service
         5ms user-runtime-dir@1000.service
         5ms console-setup.service
         5ms systemd-user-sessions.service
         4ms sysstat-collect.service
         4ms systemd-update-utmp-runlevel.service
         4ms ufw.service
         4ms openvpn.service
         3ms sys-fs-fuse-connections.mount
         3ms modprobe@efi_pstore.service
         3ms modprobe@loop.service
         3ms sys-kernel-config.mount
         3ms dev-loop21.device
         3ms dev-loop23.device
         2ms modprobe@dm_mod.service
       973us snapd.socket
```
Observation:

- The largest delay is caused by `snapd.service` (~4.5 minutes).
- `dev-loop*` devices (snap packages) also add noticeable delays.
- `NetworkManager-wait-online.service` adds ~6 seconds.
- Most other services load in under 1 second.

**2. Check System Load:**
```bash
anna@annaThinkBook ~> uptime
 22:37:34 up 35 min,  1 user,  load average: 0,68, 0,49, 0,47
```

```bash
anna@annaThinkBook ~> w
 22:37:36 up 35 min,  1 user,  load average: 0,68, 0,49, 0,47
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
anna     tty2     -                22:02   30:19   0.00s   ?    /usr/libexec/gnome-session-binary --session=ubuntu
```

Observation:

The system load is very low (load average < 1). One active user (`anna`) is logged into a GNOME session.

### Task 1.2 — Process Forensics

**1. Identify Resource-Intensive Processes**

```bash
anna@annaThinkBook ~> ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
    PID    PPID CMD                         %MEM %CPU
   3142    2801 /usr/bin/gnome-software --g  2.6  1.9
  15093    2855 user-app1                    2.3  0.8
   2855    2587 /usr/bin/gnome-shell         1.7  3.1
  12227    2587 user-app2                    1.2  1.8
   5275    2855 user-app3                    1.2  0.1
```

```bash
anna@annaThinkBook ~> ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
    PID    PPID CMD                         %MEM %CPU
   2855    2587 /usr/bin/gnome-shell         1.7  3.1
  16073   15973 user-app4                    1.2  2.7
   3142    2801 /usr/bin/gnome-software --g  2.6  1.9
  12227    2587 user-app2                    1.2  1.8
    722       2 [irq/93-rtw89_pci]           0.0  1.7
```

Observation:

- The most memory-hungry process is `gnome-software` (2.6% MEM).
- The top CPU consumer is `gnome-shell` (~3.1% CPU).
- Other notable consumers are `user-app1`, `user-app2`, `user-app3`, and `user-app4`.

Answer:

👉 The top memory-consuming process is `gnome-software`.

### Task 1.3 — Service Dependencies

**1. Map Service Relationships**

```bash
anna@annaThinkBook ~> systemctl list-dependencies
default.target
● ├─accounts-daemon.service
● ├─gdm.service
● ├─gnome-remote-desktop.service
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
●   ├─docker.service
○   ├─e2scrub_reap.service
○   ├─grub-common.service
○   ├─grub-initrd-fallback.service
●   ├─kerneloops.service
●   ├─ModemManager.service
○   ├─networkd-dispatcher.service
●   ├─NetworkManager.service
●   ├─openvpn.service
●   ├─plymouth-quit-wait.service
○   ├─plymouth-quit.service
●   ├─rsyslog.service
○   ├─secureboot-db.service
●   ├─snap-bare-5.mount
●   ├─snap-chromium-3251.mount
●   ├─snap-code-196.mount
●   ├─snap-core20-2599.mount
●   ├─snap-core20-2669.mount
●   ├─snap-core22-1981.mount
●   ├─snap-core22-2133.mount
●   ├─snap-core24-1151.mount
●   ├─snap-core24-988.mount
●   ├─snap-cups-1100.mount
●   ├─snap-firefox-5751.mount
●   ├─snap-firefox-6316.mount
●   ├─snap-firmware\x2dupdater-167.mount
●   ├─snap-gnome\x2d42\x2d2204-202.mount
●   ├─snap-gnome\x2d42\x2d2204-226.mount
●   ├─snap-gtk\x2dcommon\x2dthemes-1535.mount
●   ├─snap-mesa\x2d2404-912.mount
●   ├─snap-snap\x2dstore-1248.mount
●   ├─snap-snap\x2dstore-1270.mount
●   ├─snap-snapd-24505.mount
●   ├─snap-snapd-25202.mount
●   ├─snap-snapd\x2ddesktop\x2dintegration-253.mount
●   ├─snap-snapd\x2ddesktop\x2dintegration-315.mount
●   ├─snap-telegram\x2ddesktop-6691.mount
●   ├─snap-telegram\x2ddesktop-6798.mount
●   ├─snap.cups.cups-browsed.service
●   ├─snap.cups.cupsd.service
●   ├─snapd.apparmor.service
○   ├─snapd.autoimport.service
○   ├─snapd.core-fixup.service
○   ├─snapd.recovery-chooser-trigger.service
●   ├─snapd.seeded.service
●   ├─snapd.service
○   ├─ssl-cert.service
○   ├─sssd.service
●   ├─sysstat.service
●   ├─systemd-ask-password-wall.path
●   ├─systemd-logind.service
●   ├─systemd-oomd.service
○   ├─systemd-update-utmp-runlevel.service
●   ├─systemd-user-sessions.service
○   ├─thermald.service
○   ├─ua-reboot-cmds.service
○   ├─ubuntu-advantage.service
●   ├─ufw.service
●   ├─unattended-upgrades.service
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
●   │ │ ├─docker.socket
●   │ │ ├─snapd.socket
●   │ │ ├─systemd-initctl.socket
●   │ │ ├─systemd-journald-dev-log.socket
●   │ │ ├─systemd-journald.socket
●   │ │ ├─systemd-oomd.socket
○   │ │ ├─systemd-pcrextend.socket
●   │ │ ├─systemd-sysext.socket
●   │ │ ├─systemd-udevd-control.socket
●   │ │ ├─systemd-udevd-kernel.socket
●   │ │ └─uuidd.socket
●   │ ├─sysinit.target
●   │ │ ├─apparmor.service
●   │ │ ├─dev-hugepages.mount
●   │ │ ├─dev-mqueue.mount
●   │ │ ├─keyboard-setup.service
●   │ │ ├─kmod-static-nodes.service
○   │ │ ├─ldconfig.service
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
●   │ │ │ ├─boot-efi.mount
○   │ │ │ ├─systemd-fsck-root.service
●   │ │ │ └─systemd-remount-fs.service
●   │ │ ├─swap.target
●   │ │ │ └─swap.img.swap
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
anna@annaThinkBook ~> systemctl list-dependencies multi-user.target
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
● ├─docker.service
○ ├─e2scrub_reap.service
○ ├─grub-common.service
○ ├─grub-initrd-fallback.service
● ├─kerneloops.service
● ├─ModemManager.service
○ ├─networkd-dispatcher.service
● ├─NetworkManager.service
● ├─openvpn.service
● ├─plymouth-quit-wait.service
○ ├─plymouth-quit.service
● ├─rsyslog.service
○ ├─secureboot-db.service
● ├─snap-bare-5.mount
● ├─snap-chromium-3251.mount
● ├─snap-code-196.mount
● ├─snap-core20-2599.mount
● ├─snap-core20-2669.mount
● ├─snap-core22-1981.mount
● ├─snap-core22-2133.mount
● ├─snap-core24-1151.mount
● ├─snap-core24-988.mount
● ├─snap-cups-1100.mount
● ├─snap-firefox-5751.mount
● ├─snap-firefox-6316.mount
● ├─snap-firmware\x2dupdater-167.mount
● ├─snap-gnome\x2d42\x2d2204-202.mount
● ├─snap-gnome\x2d42\x2d2204-226.mount
● ├─snap-gtk\x2dcommon\x2dthemes-1535.mount
● ├─snap-mesa\x2d2404-912.mount
● ├─snap-snap\x2dstore-1248.mount
● ├─snap-snap\x2dstore-1270.mount
● ├─snap-snapd-24505.mount
● ├─snap-snapd-25202.mount
● ├─snap-snapd\x2ddesktop\x2dintegration-253.mount
● ├─snap-snapd\x2ddesktop\x2dintegration-315.mount
● ├─snap-telegram\x2ddesktop-6691.mount
● ├─snap-telegram\x2ddesktop-6798.mount
● ├─snap.cups.cups-browsed.service
● ├─snap.cups.cupsd.service
● ├─snapd.apparmor.service
○ ├─snapd.autoimport.service
○ ├─snapd.core-fixup.service
○ ├─snapd.recovery-chooser-trigger.service
● ├─snapd.seeded.service
● ├─snapd.service
○ ├─ssl-cert.service
○ ├─sssd.service
● ├─sysstat.service
● ├─systemd-ask-password-wall.path
● ├─systemd-logind.service
● ├─systemd-oomd.service
○ ├─systemd-update-utmp-runlevel.service
● ├─systemd-user-sessions.service
○ ├─thermald.service
○ ├─ua-reboot-cmds.service
○ ├─ubuntu-advantage.service
● ├─ufw.service
● ├─unattended-upgrades.service
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
● │ │ ├─docker.socket
● │ │ ├─snapd.socket
● │ │ ├─systemd-initctl.socket
● │ │ ├─systemd-journald-dev-log.socket
● │ │ ├─systemd-journald.socket
● │ │ ├─systemd-oomd.socket
○ │ │ ├─systemd-pcrextend.socket
● │ │ ├─systemd-sysext.socket
● │ │ ├─systemd-udevd-control.socket
● │ │ ├─systemd-udevd-kernel.socket
● │ │ └─uuidd.socket
● │ ├─sysinit.target
● │ │ ├─apparmor.service
● │ │ ├─dev-hugepages.mount
● │ │ ├─dev-mqueue.mount
● │ │ ├─keyboard-setup.service
● │ │ ├─kmod-static-nodes.service
○ │ │ ├─ldconfig.service
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
● │ │ │ ├─boot-efi.mount
○ │ │ │ ├─systemd-fsck-root.service
● │ │ │ └─systemd-remount-fs.service
● │ │ ├─swap.target
● │ │ │ └─swap.img.swap
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

Observation:

- The system depends on a large set of snap-related mount units.
- `multi-user.target` relies on essential services like `NetworkManager`, `docker.service`, `rsyslog`, and `ufw`.
- The dependency trees highlight the heavy reliance on snap and networking services.

### Task 1.4 — User Sessions

**1. Audit Login Activity**
```bash
anna@annaThinkBook ~> who -a
           загрузка системы 2025-09-27 22:01
           уровень выполнения 5 2025-09-27 22:01
anna     ? seat0        2025-09-27 22:02   ?          2708 (login screen)
anna     + tty2         2025-09-27 22:02 00:40        2708 (tty2)
           pts/1        2025-09-27 22:05              5667 id=ts/1  терминал=0 выход=100
```

```bash
anna@annaThinkBook ~> last -n 5
anna     tty2         tty2             Sat Sep 27 22:02   still logged in
anna     seat0        login screen     Sat Sep 27 22:02   still logged in
reboot   system boot  6.11.0-26-generi Sat Sep 27 22:01   still running
anna     tty2         tty2             Sat Sep 27 21:56 - down   (00:04)
anna     seat0        login screen     Sat Sep 27 21:56 - down   (00:04)

wtmp begins Fri Jun 13 22:35:52 2025
```
Observation:

- One active user (`anna`).
- Current login sessions: GNOME display manager and TTY2.
- Previous session ended at 21:56, then the system rebooted at 22:01.

### Task 1.5 — User Sessions

**1. Inspect Memory Allocation**

```bash
anna@annaThinkBook ~> free -h
               всего        занят        своб      общая  буф/врем.   доступно
Память:         27Gi       5,7Gi        12Gi       369Mi        10Gi        21Gi
Подкачка:      8,0Gi          0B       8,0Gi
```

```bash
anna@annaThinkBook ~> cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
MemTotal:       28531952 kB
MemAvailable:   22621540 kB
SwapTotal:       8388604 kB
```

Observation:

- Total RAM: ~27–28 GB.
- Available memory: ~21 GB (about 5.7 GB in use).
- Swap exists (8 GB) but is unused.
- Memory usage is efficient; the system has a large buffer/cache.

### Overall Resource Utilization Patterns

- Snapd and `dev-loop*` snap devices significantly increase boot time.
- The heaviest processes (by CPU and memory) are related to the GNOME desktop environment and user applications (`gnome-software`, `gnome-shell`, Telegram, Chromium, Firefox, VS Code).
- The system has plenty of RAM and does not rely on swap.
- Average system load is low (load average < 1).
- No major resource bottlenecks observed.

## Task 2 — Networking Analysis

### Task 2.1 — Network Path Tracing

**1. Traceroute Execution**

```bash
anna@annaThinkBook ~> traceroute github.com
traceroute to github.com (140.82.121.4), 30 hops max, 60 byte packets
 1  _gateway (192.168.X.X)  1.023 ms  1.024 ms  1.188 ms
 2  10.X.X.X (10.X.X.X)     2.273 ms  2.285 ms  3.534 ms
 3  10.X.X.X (10.X.X.X)     3.912 ms  4.972 ms  4.933 ms
 4  10.X.X.X (10.X.X.X)     4.897 ms  4.879 ms  4.824 ms
 5  isp-router (84.18.123.XXX)  16.132 ms  14.801 ms  16.436 ms
 6  isp-router (178.176.191.XXX)  9.544 ms  9.671 ms  10.138 ms
 7  * * *
 8  * * *
 9  * * *
10  * * *
11  transit-node (83.169.204.XXX)  101.652 ms transit-node (83.169.204.XXX)  101.646 ms  101.635 ms
12  netnod-ix (194.68.128.XXX)  101.613 ms netnod-ix (194.68.123.XXX)  101.642 ms netnod-ix (194.68.128.XXX)  101.868 ms
13  * * *
14  r3-ber1-de.as5405.net (94.103.180.XXX)  101.986 ms  101.976 ms  101.955 ms
15  * * *
16  * * *
17  * * *
18  * * *
19  r1-fra3-de.as5405.net (94.103.180.XXX)  103.267 ms  101.921 ms  103.291 ms
20  cust-sid436.fra3-de.as5405.net (45.153.82.XXX)  103.280 ms  102.139 ms cust-sid435.r1-fra3-de.as5405.net (45.153.82.XXX)  103.184 ms
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

Observation:

- The path to GitHub starts from the local gateway (`192.168.X.X`) and traverses private addresses (`10.X.X.X`) before reaching ISP and exchange routers.
- Some hops are hidden (`* * *`), likely due to ICMP filtering.
- Latency rises from ~1 ms locally to ~100 ms on international exchange nodes.

**2. DNS Resolution Check**

```bash
anna@annaThinkBook ~> dig github.com
;; communications error to 127.0.0.53#53: timed out

; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 29101
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             60      IN      A       140.82.121.4

;; Query time: 179 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Sat Sep 27 23:19:09 MSK 2025
;; MSG SIZE  rcvd: 55
```

Observation:

- DNS successfully resolved `github.com` to 140.82.121.4.
- The local stub resolver at `127.0.0.53` handled the query.
- The TTL for this record is 60 seconds → indicates frequent updates for load balancing.

### Task 2.2 — Network Path Tracing

**1. Capture DNS Traffic**

```bash
anna@annaThinkBook ~> sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
23:22:04.538418 lo    In  IP 127.0.0.1.54079 > 127.0.0.53.53: 46222+ [1au] A? github.com. (51)
23:22:04.538576 wlp4s0 Out IP 192.168.X.X.47134 > 192.168.X.1.53: 18312+ A? github.com. (28)
23:22:04.749912 wlp4s0 In  IP 192.168.X.1.53 > 192.168.X.X.47134: 18312 1/0/0 A 140.82.121.3 (44)
23:22:04.750075 lo    In  IP 127.0.0.53.53 > 127.0.0.1.54079: 46222 1/0/1 A 140.82.121.3 (55)

4 packets captured
6 packets received by filter
0 packets dropped by kernel

```

Observation:

- Example query: `192.168.X.X → 192.168.X.1:53 A? github.com`.
- Example response: `192.168.X.1:53 → 192.168.X.X A 140.82.121.3`.
- Shows the client querying a local DNS forwarder, which resolved GitHub’s IP.
- Private IPs are sanitized.

### Task 2.3 — Reverse DNS

**1. Perform PTR Lookups**

```bash
anna@annaThinkBook ~> dig -x 8.8.4.4

; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 64282
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   3658    IN      PTR     dns.google.

;; Query time: 182 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Sat Sep 27 23:23:27 MSK 2025
;; MSG SIZE  rcvd: 73
```

Observation:

- Reverse lookup for `8.8.4.4` resolves to dns.google.
- This confirms Google’s PTR record is properly configured.

```bash
anna@annaThinkBook ~> dig -x 1.1.2.2

; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 60084
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         479     IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 22952 7200 1800 604800 3600

;; Query time: 1367 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Sat Sep 27 23:23:56 MSK 2025
;; MSG SIZE  rcvd: 137
```

Observation:

- Reverse lookup for `1.1.2.2` failed (NXDOMAIN).
- The authority for this range is APNIC (`ns.apnic.net`), but no PTR record exists.

### Comparison of Reverse Lookups

- 8.8.4.4 → dns.google ✅ (PTR record exists, matches forward DNS).
- 1.1.2.2 → NXDOMAIN ❌ (no PTR record defined).
- This illustrates that not all IP addresses have reverse DNS mappings; it depends on whether the owner of the IP block configures PTR records.

### Overall Insights

- The traceroute revealed the path through local network, ISP, and IX nodes with some missing hops due to ICMP filtering.
- DNS queries show successful resolution of github.com with short TTLs, consistent with load-balanced infrastructure.
- Packet capture confirmed local DNS queries/answers, with sanitized internal IPs.
- Reverse lookups highlight the difference between a well-configured public resolver (Google) and an IP without PTR records (APNIC’s 1.1.2.2).