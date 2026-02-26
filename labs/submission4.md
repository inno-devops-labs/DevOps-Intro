# Task 1
## Command outputs

`systemd-analyze`

```
Startup finished in 5.263s (firmware) + 2.806s (loader) + 1.449s (kernel) + 2.887s (initrd) + 10.219s (userspace) = 22.626s 
graphical.target reached after 10.187s in userspace.
```

`systemd-analyze blame`


```
5.419s NetworkManager-wait-online.service
3.046s sys-module-fuse.device
2.984s sys-devices-LNXSYSTM:00-LNXSYBUS:00-INTC6001:00-tpmrm-tpmrm0.device
2.984s dev-tpmrm0.device
2.984s sys-devices-platform-serial8250-serial8250:0-serial8250:0.0-tty-ttyS0.device
2.984s dev-ttyS0.device
2.979s sys-devices-platform-serial8250-serial8250:0-serial8250:0.1-tty-ttyS1.device
2.979s dev-ttyS1.device
2.979s sys-devices-platform-serial8250-serial8250:0-serial8250:0.2-tty-ttyS2.device
2.979s dev-ttyS2.device
2.979s sys-devices-platform-serial8250-serial8250:0-serial8250:0.3-tty-ttyS3.device
2.979s dev-ttyS3.device
2.956s sys-module-configfs.device
2.748s dev-disk-by\x2did-nvme\x2deui.002538bb21ba0b6c\x2dpart3.device
2.748s dev-disk-by\x2did-nvme\x2dSAMSUNG_MZVL21T0HCLR\x2d00BL2_S64NNX0TB06706\x2dpart3.device
2.748s dev-nvme0n1p3.device
...
other services
```

`uptime`
```
 22:00:57 up 17 min,  2 users,  load average: 1.33, 0.91, 0.58
```

`w`
```
USER     TTY        LOGIN@   IDLE   JCPU   PCPU WHAT
kirill   tty2      21:48   17:19   0.13s  0.13s /usr/bin/startplasma-wayland
kirill             21:48   11:44   0.00s  1.04s /usr/lib/systemd/systemd --user
```

`ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6`
```
    PID    PPID CMD                         %MEM %CPU
   3988    2369 /usr/lib64/firefox/firefox   3.7 16.6
   7670    2369 /home/kirill/apps/Telegram/  3.4  1.2
   2662    2643 /usr/bin/kwin_wayland --way  3.0 12.2
   2869    2369 /usr/bin/plasmashell --no-r  2.9  4.7
   3379    2369 /usr/libexec/DiscoverNotifi  2.7  0.2
```

`ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6`
```
    PID    PPID CMD                         %MEM %CPU
   3988    2369 /usr/lib64/firefox/firefox   3.7 16.3
   2662    2643 /usr/bin/kwin_wayland --way  3.0 12.2
   6882    5207 /usr/share/code/code --type  2.2 12.1
   2869    2369 /usr/bin/plasmashell --no-r  2.9  4.7
   5242    5204 /usr/share/code/code --type  0.8  3.4
```

`systemctl list-dependencies`
```
default.target
● ├─accounts-daemon.service
● ├─rtkit-daemon.service
● ├─sddm.service
● ├─switcheroo-control.service
○ ├─systemd-update-utmp-runlevel.service
● ├─tuned-ppd.service
● ├─udisks2.service
● ├─upower.service
● └─multi-user.target
●   ├─abrt-journal-core.service
●   ├─abrt-oops.service
○   ├─abrt-vmcore.service
●   ├─abrt-xorg.service
●   ├─abrtd.service
●   ├─akmods.service
●   ├─atd.service
○   ├─audit-rules.service
●   ├─auditd.service
●   ├─avahi-daemon.service
●   ├─chronyd.service
●   ├─crond.service
●   ├─cups.path
●   ├─dkms.service
●   ├─docker.service
●   ├─firewalld.service
○   ├─flatpak-add-fedora-repos.service
●   ├─irqbalance.service
○   ├─livesys-late.service
○   ├─livesys.service
●   ├─mcelog.service
○   ├─mdmonitor.service
●   ├─ModemManager.service
●   ├─NetworkManager.service
●   ├─nvidia-powerd.service
●   ├─plymouth-quit-wait.service
●   ├─plymouth-quit.service
●   ├─rsyslog.service
●   ├─smartd.service
○   ├─sssd.service
●   ├─systemd-ask-password-wall.path
●   ├─systemd-homed.service
●   ├─systemd-logind.service
●   ├─systemd-oomd.service
○   ├─systemd-update-utmp-runlevel.service
●   ├─systemd-user-sessions.service
●   ├─tuned.service
○   ├─vboxservice.service
○   ├─vmtoolsd.service
●   ├─basic.target
●   │ ├─-.mount
●   │ ├─tmp.mount
●   │ ├─paths.target
●   │ ├─slices.target
●   │ │ ├─-.slice
●   │ │ └─system.slice
●   │ ├─sockets.target
●   │ │ ├─avahi-daemon.socket
●   │ │ ├─cups.socket
●   │ │ ├─dbus.socket
●   │ │ ├─dm-event.socket
●   │ │ ├─iscsid.socket
●   │ │ ├─iscsiuio.socket
●   │ │ ├─pcscd.socket
●   │ │ ├─sshd-unix-local.socket
●   │ │ ├─sssd-kcm.socket
●   │ │ ├─systemd-bootctl.socket
●   │ │ ├─systemd-coredump.socket
●   │ │ ├─systemd-creds.socket
●   │ │ ├─systemd-hostnamed.socket
●   │ │ ├─systemd-initctl.socket
●   │ │ ├─systemd-journald-audit.socket
●   │ │ ├─systemd-journald-dev-log.socket
●   │ │ ├─systemd-journald.socket
○   │ │ ├─systemd-pcrextend.socket
○   │ │ ├─systemd-pcrlock.socket
●   │ │ ├─systemd-sysext.socket
●   │ │ ├─systemd-udevd-control.socket
●   │ │ ├─systemd-udevd-kernel.socket
●   │ │ └─systemd-userdbd.socket
●   │ ├─sysinit.target
●   │ │ ├─dev-hugepages.mount
●   │ │ ├─dev-mqueue.mount
●   │ │ ├─dracut-shutdown.service
○   │ │ ├─fips-crypto-policy-overlay.service
○   │ │ ├─iscsi-onboot.service
...
```

`systemctl list-dependencies multi-user.target`
```
multi-user.target
● ├─abrt-journal-core.service
● ├─abrt-oops.service
○ ├─abrt-vmcore.service
● ├─abrt-xorg.service
● ├─abrtd.service
● ├─akmods.service
● ├─atd.service
○ ├─audit-rules.service
● ├─auditd.service
● ├─avahi-daemon.service
● ├─chronyd.service
● ├─crond.service
● ├─cups.path
● ├─dkms.service
● ├─docker.service
● ├─firewalld.service
○ ├─flatpak-add-fedora-repos.service
● ├─irqbalance.service
○ ├─livesys-late.service
○ ├─livesys.service
● ├─mcelog.service
○ ├─mdmonitor.service
● ├─ModemManager.service
● ├─NetworkManager.service
● ├─nvidia-powerd.service
...
```

`who -a`
```
           system boot  2026-02-26 21:43
kirill   ? seat0        2026-02-26 21:48   ?          2363
kirill   + tty2         2026-02-26 21:48 00:20        2363

```

`last -n 5`
```
kirill   pts/3        :0               Thu Feb 26 21:58   still logged in
kirill   pts/0        :0               Thu Feb 26 21:48   still logged in
kirill   tty2                          Thu Feb 26 21:48   still logged in
reboot   system boot  6.14.9-300.fc42. Thu Feb 26 21:43   still running
kirill   pts/0        :0               Tue Feb 24 21:56 - crash (1+23:47)

wtmp begins Tue Apr 29 22:37:09 2025
```

`free -h`
```
               total        used        free      shared  buff/cache   available
Mem:            15Gi       8.0Gi       2.0Gi       2.0Gi       7.7Gi       7.3Gi
Swap:          8.0Gi          0B       8.0Gi
```

`cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable`
```
MemTotal:       16090668 kB
MemAvailable:    7625560 kB
SwapTotal:       8388604 kB
```

## Key observations for each analysis section

**Boot Performance Analysis**: Total boot time was 22.6s, with userspace taking the longest at 10.2s. The biggest bottleneck is `NetworkManager-wait-online.service` at 5.4s, followed by several device initialization delays (~3s each). Firmware and loader phases together account for 8s, suggesting UEFI overhead.

**Process Forensics**: Firefox is the heaviest process by both CPU (16.3%) and memory (3.7%). `kwin_wayland` and VS Code worker processes are also significant CPU consumers. Most high-CPU processes are user-facing GUI applications rather than background services.

**Service Dependencies**: The `default.target` has a large dependency tree rooted through `multi-user.target`, which includes many active services: Docker, NetworkManager, firewalld, auditd, and Avahi. Several services are inactive (○), such as `sssd`, `vmtoolsd`, and `vboxservice`, indicating optional or legacy services that are installed but not running.

**User Sessions**: A single user (`kirill`) is logged in via `tty2` (Wayland session) and two pseudo-terminals. The system was booted at 21:43 and the session started at 21:48. The previous session ended in a crash on February 24.

**Memory Analysis**: Total RAM is 15Gi with 8Gi used. However, 7.7Gi is occupied by buff/cache, leaving 7.3Gi effectively available. Swap (8Gi) is completely unused, indicating no memory pressure.

## What is the top memory-consuming process

Firefox (`/usr/lib64/firefox/firefox`) is the top memory-consuming process at 3.7% of total RAM (~600MB), followed closely by Telegram (3.4%) and `kwin_wayland` (3.0%).

## Note any resource utilization patterns you observe

- **CPU load is moderate**: The load average (1.33, 0.91, 0.58) is trending downward, suggesting a spike shortly after login that is settling down - typical of a desktop session startup.
- **GUI processes dominate resources**: Firefox, Telegram, KWin, and Plasma are the top consumers of both CPU and memory, which is expected for a KDE Wayland desktop session.
- **Memory is well-managed**: Despite 8Gi used, the kernel has allocated 7.7Gi as buff/cache, which it will release under pressure. Swap is untouched, indicating healthy memory headroom.

# Task 2

## Command outputs

`traceroute github.com`
```
traceroute to github.com (140.82.121.3), 30 hops max, 60 byte packets
 1  _gateway (10.91.48.1)  2.530 ms  2.476 ms  2.459 ms
 2  10.252.6.1 (10.252.6.1)  2.465 ms  2.448 ms  2.432 ms
 3  1.123.18.84.in-addr.arpa (84.18.123.1)  18.407 ms  11.596 ms  11.570 ms
 4  178.176.191.24 (178.176.191.24)  7.146 ms  7.131 ms  7.114 ms
 5  * * *
 6  * * *
 7  * * *
 8  * * *
 9  83.169.204.82 (83.169.204.82)  46.227 ms  44.606 ms 83.169.204.78 (83.169.204.78)  44.548 ms
10  netnod-ix-ge-a-sth-1500.inter.link (194.68.123.180)  42.554 ms netnod-ix-ge-b-sth-1500.inter.link (194.68.128.180)  45.670 ms  45.102 ms
11  * * *
12  * * *
13  * * *
14  * * *
15  r3-fra3-de.as5405.net (94.103.180.54)  63.425 ms  61.775 ms  116.093 ms
16  r1-fra3-de.as5405.net (94.103.180.24)  57.396 ms  59.449 ms  60.926 ms
17  cust-sid436.fra3-de.as5405.net (45.153.82.37)  59.612 ms cust-sid435.r1-fra3-de.as5405.net (45.153.82.39)  57.738 ms cust-sid436.fra3-de.as5405.net (45.153.82.37)  59.066 ms
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

`dig github.com`

```
; <<>> DiG 9.18.36 <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 13794
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             7       IN      A       140.82.121.3

;; Query time: 6 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Thu Feb 26 22:11:37 MSK 2026
;; MSG SIZE  rcvd: 55
```

`sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn`
```
tcpdump: WARNING: any: That device doesn't support promiscuous mode
(Promiscuous mode not supported on the "any" device)
dropped privs to tcpdump
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
22:12:00.111321 lo    In  IP 127.0.0.1.37229 > 127.0.0.53.53: 1041+ [1au] HTTPS? csp.yandex.net. (43)
22:12:00.111923 wlp0s20f3 Out IP 10.91.56.186.42719 > 10.90.137.30.53: 57881+ [1au] HTTPS? csp.yandex.net. (43)
22:12:00.112573 wlp0s20f3 Out IP 10.91.56.186.34489 > 10.90.137.30.53: 63119+ [1au] AAAA? csp.yandex.net. (43)
22:12:00.112625 wlp0s20f3 Out IP 10.91.56.186.54100 > 10.90.137.30.53: 4510+ [1au] A? csp.yandex.net. (43)
22:12:00.118293 wlp0s20f3 In  IP 10.90.137.30.53 > 10.91.56.186.42719: 57881 0/1/1 (94)
5 packets captured
10 packets received by filter
0 packets dropped by kernel
```

`dig -x 8.8.4.4`
```
; <<>> DiG 9.18.36 <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 45144
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   78321   IN      PTR     dns.google.

;; Query time: 27 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Thu Feb 26 22:12:56 MSK 2026
;; MSG SIZE  rcvd: 73
```

`dig -x 1.1.2.2`
```
; <<>> DiG 9.18.36 <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 1374
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         899     IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23597 7200 1800 604800 3600

;; Query time: 764 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Thu Feb 26 22:13:18 MSK 2026
;; MSG SIZE  rcvd: 137
```

## Insights on network paths discovered

The route to `github.com` (140.82.121.3) spans 17 visible hops before reaching GitHub's edge, with the total path likely being longer. Traffic exits the local network through a private gateway (10.91.48.1), passes through an ISP uplink, then routes through European transit providers (Stockholm Netnod IX at hop 10, Frankfurt AS5405 at hops 15–17) before reaching GitHub's infrastructure. The furthest measured latency is ~60ms, consistent with a Russia → Western Europe path.

## Analysis of DNS query/response patterns

All DNS queries are resolved through the local stub resolver at `127.0.0.53` (systemd-resolved), which forwards to the upstream DNS server at `10.90.137.30`. The `dig github.com` query resolved in just 6ms with a TTL of 7 seconds, indicating a nearly-expired cached record. The query returned a single A record (`140.82.121.3`), consistent with GitHub's anycast routing. The packet capture confirms that systemd-resolved batches queries - sending separate `A`, `AAAA`, and `HTTPS` record requests simultaneously for a single hostname lookup.

## Comparison of reverse lookup results

`8.8.4.4` resolved successfully to `dns.google` - a well-maintained PTR record matching its known identity as a Google public DNS server. `1.1.2.2` returned `NXDOMAIN`, meaning no PTR record exists for that IP. The authority section in the response shows that APNIC administers the `1.in-addr.arpa.` zone, confirming the query reached the authoritative server. The contrast illustrates that reverse DNS is optional and not all IPs have PTR records configured, unlike forward DNS which is generally required for public services.

## One example DNS query from packet capture (sanitize IPs if needed)

```
22:12:00.112625 wlp0s20f3 Out IP 10.91.56.186.54100 > 10.90.137.30.53: 4510+ [1au] A? csp.yandex.net. (43)
<client-ip>.42719 > <dns-server>.53: 57881+ [1au] HTTPS? csp.yandex.net. (43)
<dns-server>.53  > <client-ip>.42719: 57881 0/1/1 (94)
```

A client sent an `HTTPS` record query for `csp.yandex.net` to the upstream DNS server. The response returned 0 answers with 1 authority and 1 additional record, meaning no HTTPS record exists for that domain. The query ID `57881` matches between request and response, confirming the correct reply was received.

