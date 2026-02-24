# Lab4

## Task 1


### All comand outputs for sections 1.1-1.5.
<details>
<summary> systemd-analyze</summary>

```sh
Startup finished in 5.589s (firmware) + 4.044s (loader) + 5.420s (kernel) + 2.845s (userspace) = 17.899s 
graphical.target reached after 2.202s in userspace.
```

</details>
<details>
<summary> systemd-analyze blame</summary>

```sh
1.292s asusd.service
 492ms NetworkManager.service
 402ms dev-nvme1n1p2.device
 356ms upower.service
 316ms libvirtd.service
 292ms user@1000.service
 274ms systemd-udev-trigger.service
 257ms systemd-modules-load.service
 162ms systemd-tmpfiles-clean.service
 133ms systemd-journal-flush.service
  94ms systemd-journald.service
  76ms power-profiles-daemon.service
  73ms systemd-tmpfiles-setup-dev-early.service
  73ms systemd-tmpfiles-setup.service
  62ms systemd-resolved.service
  56ms systemd-udevd.service
  47ms systemd-hostnamed.service
  42ms polkit.service
  41ms systemd-timesyncd.service
  37ms systemd-userdbd.service
  35ms systemd-tmpfiles-setup-dev.service
  33ms systemd-fsck@dev-disk-by\x2duuid-73A2\x2d3E91.service
  33ms bluetooth.service
  32ms boot-efi.mount
  32ms systemd-vconsole-setup.service
  30ms systemd-logind.service
  28ms rtkit-daemon.service
  27ms swayosd-libinput-backend.service
  26ms user-runtime-dir@1000.service
  24ms systemd-binfmt.service
  23ms dbus-broker.service
  22ms supergfxd.service
  22ms systemd-remount-fs.service
  21ms systemd-backlight@leds:asus::kbd_backlight.service
  19ms systemd-userdb-load-credentials.service
  19ms switcheroo-control.service
  18ms systemd-update-utmp.service
  18ms wpa_supplicant.service
  17ms systemd-backlight@backlight:amdgpu_bl1.service
  17ms systemd-sysctl.service
  14ms systemd-rfkill.service
  11ms systemd-machined.service
  10ms systemd-random-seed.service
  10ms dev-hugepages.mount
   9ms dev-mqueue.mount
   9ms sys-kernel-debug.mount
   9ms sshd.service
   8ms sys-kernel-tracing.mount
   8ms systemd-udev-load-credentials.service
   7ms tmp.mount
   7ms sys-kernel-config.mount
   7ms kmod-static-nodes.service
   6ms sys-fs-fuse-connections.mount
   5ms systemd-user-sessions.service
   4ms proc-sys-fs-binfmt_misc.mount
   1ms polkit-agent-helper.socket
 715us systemd-bootctl.socket
 618us systemd-mute-console.socket
 600us systemd-coredump.socket
 600us sshd-unix-local.socket
 571us systemd-ask-password.socket
 529us systemd-factory-reset.socket
 506us systemd-sysext.socket
 414us systemd-repart.socket
 400us systemd-creds.socket
 162us dirmngr@etc-pacman.d-gnupg.socket
  38us systemd-journald-dev-log.socket
  37us gpg-agent-extra@etc-pacman.d-gnupg.socket
  37us systemd-machined.socket
  36us dbus.socket
  35us gpg-agent-browser@etc-pacman.d-gnupg.socket
  32us systemd-journald.socket
  32us gpg-agent@etc-pacman.d-gnupg.socket
  32us systemd-importd.socket
  32us keyboxd@etc-pacman.d-gnupg.socket
  32us gpg-agent-ssh@etc-pacman.d-gnupg.socket
  25us libvirtd.socket
  25us systemd-resolved-monitor.socket
  23us systemd-userdbd.socket
  22us dm-event.socket
  20us systemd-udevd-control.socket
  20us virtlockd.socket
  19us systemd-udevd-varlink.socket
  16us systemd-hostnamed.socket
  15us systemd-logind-varlink.socket
  15us libvirtd-ro.socket
  15us libvirtd-admin.socket
  15us systemd-resolved-varlink.socket
  14us virtlogd.socket
  14us virtlogd-admin.socket
  14us virtlockd-admin.socket
  11us systemd-rfkill.socket
   9us systemd-udevd-kernel.socket
```
</details>
<details>
<summary> uptime</summary> 

```sh
 15:45:41 up  1:04,  1 user,  load average: 0.68, 0.80, 0.78
```
</details>
<details>
<summary> w</summary>

```sh
 15:46:54 up  1:05,  1 user,  load average: 0.89, 0.81, 0.79
USER     TTY       LOGIN@   IDLE   JCPU   PCPU  WHAT
platon   tty1      14:42    1:04m  0.06s   ?    systemctl --user --wait start niri.service
```
</details>

<details>
<summary> ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6</summary>

```sh
    PID    PPID CMD                         %MEM %CPU
   5802    1192 AyuGram                      3.1  3.6
   4230    1192 /usr/lib/firefox/firefox     3.1  7.1
  18284    1790 /proc/self/exe --type=utili  1.8  2.5
   6932    4336 /usr/lib/firefox/firefox -c  1.6  2.2
   4764    4336 /usr/lib/firefox/firefox -c  1.4  0.2
```

</details>
<details>
<summary> ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6</summary>

```sh
    PID    PPID CMD                         %MEM %CPU
   1332    1192 /usr/bin/niri --session      0.8  8.1
   4230    1192 /usr/lib/firefox/firefox     3.1  7.0
   2328    1796 /opt/visual-studio-code/cod  1.3  4.6
   5802    1192 AyuGram                      3.1  3.5
  18284    1790 /proc/self/exe --type=utili  1.6  2.6
```

</details>

<details>
<summary> systemctl list-dependencies</summary>

```sh
default.target
● ├─greetd.service
● ├─power-profiles-daemon.service
● ├─swayosd-libinput-backend.service
● ├─switcheroo-control.service
● └─multi-user.target
●   ├─dbus-broker.service
○   ├─libvirtd.service
●   ├─NetworkManager.service
●   ├─sshd.service
●   ├─systemd-ask-password-wall.path
●   ├─systemd-logind.service
●   ├─systemd-user-sessions.service
○   ├─vboxservice.service
●   ├─basic.target
●   │ ├─-.mount
●   │ ├─tmp.mount
●   │ ├─paths.target
●   │ ├─slices.target
●   │ │ ├─-.slice
●   │ │ └─system.slice
●   │ ├─sockets.target
●   │ │ ├─dbus.socket
●   │ │ ├─dirmngr@etc-pacman.d-gnupg.socket
●   │ │ ├─dm-event.socket
●   │ │ ├─gpg-agent-browser@etc-pacman.d-gnupg.socket
●   │ │ ├─gpg-agent-extra@etc-pacman.d-gnupg.socket
●   │ │ ├─gpg-agent-ssh@etc-pacman.d-gnupg.socket
●   │ │ ├─gpg-agent@etc-pacman.d-gnupg.socket
●   │ │ ├─keyboxd@etc-pacman.d-gnupg.socket
●   │ │ ├─libvirtd-admin.socket
●   │ │ ├─libvirtd-ro.socket
●   │ │ ├─libvirtd.socket
●   │ │ ├─polkit-agent-helper.socket
●   │ │ ├─sshd-unix-local.socket
●   │ │ ├─systemd-ask-password.socket
●   │ │ ├─systemd-bootctl.socket
●   │ │ ├─systemd-coredump.socket
●   │ │ ├─systemd-creds.socket
●   │ │ ├─systemd-factory-reset.socket
●   │ │ ├─systemd-hostnamed.socket
●   │ │ ├─systemd-importd.socket
●   │ │ ├─systemd-journald-dev-log.socket
●   │ │ ├─systemd-journald.socket
●   │ │ ├─systemd-logind-varlink.socket
●   │ │ ├─systemd-machined.socket
●   │ │ ├─systemd-mute-console.socket
○   │ │ ├─systemd-pcrextend.socket
○   │ │ ├─systemd-pcrlock.socket
●   │ │ ├─systemd-repart.socket
●   │ │ ├─systemd-sysext.socket
●   │ │ ├─systemd-udevd-control.socket
●   │ │ ├─systemd-udevd-kernel.socket
●   │ │ ├─systemd-udevd-varlink.socket
●   │ │ ├─systemd-userdbd.socket
●   │ │ ├─virtlockd-admin.socket
●   │ │ ├─virtlockd.socket
●   │ │ ├─virtlogd-admin.socket
●   │ │ └─virtlogd.socket
●   │ ├─sysinit.target
●   │ │ ├─dev-hugepages.mount
●   │ │ ├─dev-mqueue.mount
○   │ │ ├─haveged.service
●   │ │ ├─kmod-static-nodes.service
○   │ │ ├─ldconfig.service
●   │ │ ├─proc-sys-fs-binfmt_misc.automount
●   │ │ ├─sys-fs-fuse-connections.mount
●   │ │ ├─sys-kernel-config.mount
●   │ │ ├─sys-kernel-debug.mount
●   │ │ ├─sys-kernel-tracing.mount
●   │ │ ├─systemd-ask-password-console.path
●   │ │ ├─systemd-binfmt.service
○   │ │ ├─systemd-boot-random-seed.service
○   │ │ ├─systemd-firstboot.service
○   │ │ ├─systemd-hibernate-clear.service
○   │ │ ├─systemd-hwdb-update.service
○   │ │ ├─systemd-journal-catalog-update.service
●   │ │ ├─systemd-journal-flush.service
●   │ │ ├─systemd-journald.service
○   │ │ ├─systemd-machine-id-commit.service
●   │ │ ├─systemd-modules-load.service
○   │ │ ├─systemd-pcrmachine.service
○   │ │ ├─systemd-pcrnvdone.service
○   │ │ ├─systemd-pcrphase-sysinit.service
○   │ │ ├─systemd-pcrphase.service
○   │ │ ├─systemd-pcrproduct.service
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
●   │ │ ├─imports.target
●   │ │ ├─integritysetup.target
●   │ │ ├─local-fs.target
●   │ │ │ ├─-.mount
●   │ │ │ ├─boot-efi.mount
○   │ │ │ ├─systemd-fsck-root.service
●   │ │ │ ├─systemd-remount-fs.service
●   │ │ │ └─tmp.mount
●   │ │ ├─swap.target
●   │ │ └─veritysetup.target
●   │ └─timers.target
●   │   ├─archlinux-keyring-wkd-sync.timer
●   │   ├─man-db.timer
●   │   ├─shadow.timer
●   │   └─systemd-tmpfiles-clean.timer
●   ├─getty.target
○   │ ├─getty@tty1.service
●   │ └─supergfxd.service
●   └─remote-fs.target
○     └─var-lib-machines.mount
```
</details>

<details>
<summary> systemctl list-dependencies multi-user.target</summary>

```sh
multi-user.target
● ├─dbus-broker.service
○ ├─libvirtd.service
● ├─NetworkManager.service
● ├─sshd.service
● ├─systemd-ask-password-wall.path
● ├─systemd-logind.service
● ├─systemd-user-sessions.service
○ ├─vboxservice.service
● ├─basic.target
● │ ├─-.mount
● │ ├─tmp.mount
● │ ├─paths.target
● │ ├─slices.target
● │ │ ├─-.slice
● │ │ └─system.slice
● │ ├─sockets.target
● │ │ ├─dbus.socket
● │ │ ├─dirmngr@etc-pacman.d-gnupg.socket
● │ │ ├─dm-event.socket
● │ │ ├─gpg-agent-browser@etc-pacman.d-gnupg.socket
● │ │ ├─gpg-agent-extra@etc-pacman.d-gnupg.socket
● │ │ ├─gpg-agent-ssh@etc-pacman.d-gnupg.socket
● │ │ ├─gpg-agent@etc-pacman.d-gnupg.socket
● │ │ ├─keyboxd@etc-pacman.d-gnupg.socket
● │ │ ├─libvirtd-admin.socket
● │ │ ├─libvirtd-ro.socket
● │ │ ├─libvirtd.socket
● │ │ ├─polkit-agent-helper.socket
● │ │ ├─sshd-unix-local.socket
● │ │ ├─systemd-ask-password.socket
● │ │ ├─systemd-bootctl.socket
● │ │ ├─systemd-coredump.socket
● │ │ ├─systemd-creds.socket
● │ │ ├─systemd-factory-reset.socket
● │ │ ├─systemd-hostnamed.socket
● │ │ ├─systemd-importd.socket
● │ │ ├─systemd-journald-dev-log.socket
● │ │ ├─systemd-journald.socket
● │ │ ├─systemd-logind-varlink.socket
● │ │ ├─systemd-machined.socket
● │ │ ├─systemd-mute-console.socket
○ │ │ ├─systemd-pcrextend.socket
○ │ │ ├─systemd-pcrlock.socket
● │ │ ├─systemd-repart.socket
● │ │ ├─systemd-sysext.socket
● │ │ ├─systemd-udevd-control.socket
● │ │ ├─systemd-udevd-kernel.socket
● │ │ ├─systemd-udevd-varlink.socket
● │ │ ├─systemd-userdbd.socket
● │ │ ├─virtlockd-admin.socket
● │ │ ├─virtlockd.socket
● │ │ ├─virtlogd-admin.socket
● │ │ └─virtlogd.socket
● │ ├─sysinit.target
● │ │ ├─dev-hugepages.mount
● │ │ ├─dev-mqueue.mount
○ │ │ ├─haveged.service
● │ │ ├─kmod-static-nodes.service
○ │ │ ├─ldconfig.service
● │ │ ├─proc-sys-fs-binfmt_misc.automount
● │ │ ├─sys-fs-fuse-connections.mount
● │ │ ├─sys-kernel-config.mount
● │ │ ├─sys-kernel-debug.mount
● │ │ ├─sys-kernel-tracing.mount
● │ │ ├─systemd-ask-password-console.path
● │ │ ├─systemd-binfmt.service
○ │ │ ├─systemd-boot-random-seed.service
○ │ │ ├─systemd-firstboot.service
○ │ │ ├─systemd-hibernate-clear.service
○ │ │ ├─systemd-hwdb-update.service
○ │ │ ├─systemd-journal-catalog-update.service
● │ │ ├─systemd-journal-flush.service
● │ │ ├─systemd-journald.service
○ │ │ ├─systemd-machine-id-commit.service
● │ │ ├─systemd-modules-load.service
○ │ │ ├─systemd-pcrmachine.service
○ │ │ ├─systemd-pcrnvdone.service
○ │ │ ├─systemd-pcrphase-sysinit.service
○ │ │ ├─systemd-pcrphase.service
○ │ │ ├─systemd-pcrproduct.service
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
● │ │ ├─imports.target
● │ │ ├─integritysetup.target
● │ │ ├─local-fs.target
● │ │ │ ├─-.mount
● │ │ │ ├─boot-efi.mount
○ │ │ │ ├─systemd-fsck-root.service
● │ │ │ ├─systemd-remount-fs.service
● │ │ │ └─tmp.mount
● │ │ ├─swap.target
● │ │ └─veritysetup.target
● │ └─timers.target
● │   ├─archlinux-keyring-wkd-sync.timer
● │   ├─man-db.timer
● │   ├─shadow.timer
● │   └─systemd-tmpfiles-clean.timer
● ├─getty.target
○ │ ├─getty@tty1.service
● │ └─supergfxd.service
● └─remote-fs.target
○   └─var-lib-machines.mount
```

</details>

<details>
<summary> who -a</summary>

```sh
           system boot  2026-02-24 14:41
```

</details>

<details>
<summary> last -n 5</summary>

```sh
reboot   system boot  6.18.7-arch1-1.* Tue Feb 24 14:41   still running
reboot   system boot  6.18.7-arch1-1.* Tue Feb 24 06:58 - 12:33  (05:35)
reboot   system boot  6.18.7-arch1-1.* Mon Feb 23 16:41 - 21:03  (04:22)
reboot   system boot  6.18.7-arch1-1.* Mon Feb 23 06:48 - 12:23  (05:35)
reboot   system boot  6.18.7-arch1-1.* Sun Feb 22 07:47 - 21:47  (13:59)

wtmp begins Sun Dec 29 14:27:05 2024
```
</details>

<details>

<summary> free -h</summary>

```sh
               total        used        free      shared  buff/cache   available
Mem:            30Gi       5.7Gi        20Gi       144Mi       4.2Gi        24Gi
Swap:             0B          0B          0B
```

</details>

<details>
<summary> cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable</summary>

```sh
MemTotal:       32075832 kB
MemAvailable:   26027020 kB
SwapTotal:             0 kB
```

</details>


**Summary of findings:**

- The system boot time is approximately 17.899 seconds, with the userspace taking 2.845 seconds to reach the graphical target
- The most resource-intensive processes are AyuGram and Firefox, consuming around 3.1% of memory each, with Firefox also consuming 7.1% of CPU
- The system has a load average of around 0.68 to 0.89, indicating moderate system activity
- The system has no swap space configured, and the available memory is around 24GiB, which is sufficient for the current workload

**What is the top memory-consuming process?**

The top memory-consuming process is AyuGram, which is using approximately 3.1% of the system's memory


## Task 2

### All command outputs for sections 2.1-2.3.

<details>
<summary> traceroute github.com</summary>

```sh
traceroute to github.com (140.82.121.3), 30 hops max, 60 byte packets
 1  * * *
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

</details>

<details>
<summary> dig github.com</summary>

```sh

; <<>> DiG 9.20.19 <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 29963
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;github.com.			IN	A

;; ANSWER SECTION:
github.com.		54	IN	A	140.82.121.3

;; Query time: 65 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Tue Feb 24 20:09:34 MSK 2026
;; MSG SIZE  rcvd: 55

```
</details>

<details>
<summary> sudo timeout 10 tcpdump -c 5 -i lo 'port 53' -nn</summary>

```sh
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on lo, link-type EN10MB (Ethernet), snapshot length 262144 bytes
20:06:39.717705 IP 127.0.0.1.52004 > 127.0.0.53.53: 17180+ [1au] A? google.com. (51)
20:06:39.718044 IP 127.0.0.53.53 > 127.0.0.1.52004: 17180 1/0/1 A 142.250.181.238 (55)

2 packets captured
4 packets received by filter
0 packets dropped by kernel
```

</details>

<details>
<summary> dig -x 8.8.4.4 </summary>

```bash

; <<>> DiG 9.20.19 <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 46158
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.		IN	PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.	7191	IN	PTR	dns.google.

;; Query time: 1 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Tue Feb 24 20:10:46 MSK 2026
;; MSG SIZE  rcvd: 73
```

</details>

<details>
<summary> dig -x 1.1.2.2</summary>

```sh

; <<>> DiG 9.20.19 <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 13100
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.		IN	PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.		3600	IN	SOA	ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23597 7200 1800 604800 3600

;; Query time: 151 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Tue Feb 24 20:11:21 MSK 2026
;; MSG SIZE  rcvd: 137
```

</details>

### Insights on network paths discovered

Traceroute to github.com (140.82.121.3) showed all 30 hops returning `* * *`. This indicates that routers along the path are either blocking ICMP packets or filtering UDP traceroute traffic. However, DNS successfully resolves github.com, confirming network connectivity exists.

### Analysis of DNS query/response patterns

From `dig github.com` output:

- A record query for github.com returned IP address 140.82.121.3
- TTL of 54 seconds indicates a cached response
- DNS server is the local systemd-resolved resolver (127.0.0.53)
- Query time of 65 ms is normal for an external DNS query
- Flags `qr rd ra` mean: query response, recursion desired, recursion available

### Comparison of reverse lookup results

| IP Address | PTR Record | Status |
|------------|------------|--------|
| 8.8.4.4 | dns.google. | NOERROR — successfully resolved |
| 1.1.2.2 | — | NXDOMAIN — record does not exist |

8.8.4.4 is Google's public DNS server with a configured reverse PTR record. 1.1.2.2 this IP has no PTR record in the APNIC zone.

### One example DNS query from packet capture

DNS query captured from tcpdump:

```sh
127.0.0.1.52004 > 127.0.0.53.53: 17180+ [1au] A? google.com. (51)
127.0.0.53.53 > 127.0.0.1.52004: 17180 1/0/1 A 142.250.181.238 (55)
```

- Local client sent an A record query for `google.com` to systemd-resolved
- Resolver returned IP 142.250.181.238 (Google server)
- Flag `[1au]` indicates EDNS0 usage with one additional record
- Transaction ID: 17180
