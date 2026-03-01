# Lab 4 — OS & Networking Submission

## Task 1 — Operating System Analysis

### 1.1 Boot Performance Analysis

**`systemd-analyze` output:**
```
Startup finished in 5.359s (firmware) + 12.164s (loader) + 2.674s (kernel) + 8.118s (userspace) = 28.317s
graphical.target reached after 8.108s in userspace
```

**`systemd-analyze blame` output:**
```
6.404s NetworkManager-wait-online.service
6.148s plymouth-quit-wait.service
2.801s gpu-manager.service
1.975s nvidia-cdi-refresh.service
1.792s snapd.seeded.service
1.728s snapd.service
 723ms docker.service
 382ms fwupd.service
 314ms systemd-resolved.service
 283ms systemd-oomd.service
 279ms systemd-timesyncd.service
 253ms dev-nvme0n1p4.device
 189ms networkd-dispatcher.service
 148ms secureboot-db.service
 146ms systemd-udev-trigger.service
 144ms containerd.service
 133ms ModemManager.service
 126ms udisks2.service
 117ms bolt.service
 111ms upower.service
  ...
```

**`uptime` output:**
```
18:31:39 up 19 min,  1 user,  load average: 0.31, 0.31, 0.23
```

**`w` output:**
```
 18:31:41 up 19 min,  1 user,  load average: 0.31, 0.31, 0.23
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
yoba     :1       :1               18:15   ?xdm?   7:33   0.00s /usr/libexec/gd
```

**Observations:**
- Total boot time was 28.317s, split across firmware (5.36s), bootloader (12.16s), kernel (2.67s), and userspace (8.12s). The bootloader stage is the longest — likely due to GRUB timeout or UEFI initialization.
- The top boot-time offenders were `NetworkManager-wait-online.service` (6.4s) and `plymouth-quit-wait.service` (6.1s). Both are common culprits on desktop systems with NVIDIA GPUs.
- System load averages (0.31, 0.31, 0.23) indicate the machine is largely idle — all values are well below 1.0, which is healthy for a single-user workstation.
- Only one user (`yoba`) is currently logged in via a graphical session (:1).

---

### 1.2 Process Forensics

**Top memory-consuming processes (`--sort=-%mem`):**
```
    PID    PPID CMD                         %MEM %CPU
   7007    2843 /snap/telegram-desktop/6899  3.7  2.0
   4783    2843 /opt/google/chrome/chrome    3.2  4.5
   6362    4803 /opt/google/chrome/chrome -  2.9  2.4
   2843    2595 /usr/bin/gnome-shell         2.4  4.1
   5664    4803 /opt/google/chrome/chrome -  2.2  6.4
```

**Top CPU-consuming processes (`--sort=-%cpu`):**
```
    PID    PPID CMD                         %MEM %CPU
   4827    4800 /opt/google/chrome/chrome -  2.0  8.9
   5664    4803 /opt/google/chrome/chrome -  2.2  6.5
   4783    2843 /opt/google/chrome/chrome    3.2  4.5
   5109     811 /opt/happ/bin/tun/sing-box   0.3  4.3
   2843    2595 /usr/bin/gnome-shell         2.4  4.1
```

**Observations:**
- The top memory-consuming process is **Telegram Desktop** at 3.7% RAM (~600 MB on a 16 GiB system). Chrome and its renderer processes collectively account for the largest overall footprint across multiple PIDs.
- Chrome dominates CPU usage as well, with one renderer process peaking at 8.9% CPU. This is typical of an active browser with JavaScript-heavy tabs.
- `gnome-shell` appears in both lists (2.4% MEM, 4.1% CPU), which is expected as it manages the entire graphical desktop environment.
- A background tunnel process (`sing-box`) uses minimal memory (0.3%) but is consistently active at 4.3% CPU, likely handling VPN/proxy traffic.

---

### 1.3 Service Dependencies

**`systemctl list-dependencies` output (default.target, truncated):**
```
default.target
● ├─accounts-daemon.service
● ├─apport.service
● ├─gdm.service
● ├─power-profiles-daemon.service
● ├─switcheroo-control.service
○ ├─systemd-update-utmp-runlevel.service
● ├─udisks2.service
● └─multi-user.target
  ├─AmneziaVPN.service
  ├─containerd.service
  ├─docker.service
  ├─NetworkManager.service
  ├─snapd.service
  ├─systemd-resolved.service
  ├─basic.target
  │ ├─sockets.target
  │ ├─sysinit.target
  │ └─timers.target
  ├─getty.target
  └─remote-fs.target
```

**`systemctl list-dependencies multi-user.target` output (truncated):**
```
multi-user.target
● ├─AmneziaVPN.service
● ├─containerd.service
● ├─docker.service
● ├─cron.service
● ├─NetworkManager.service
● ├─rsyslog.service
● ├─snapd.service
● ├─systemd-resolved.service
● ├─ufw.service
● ├─wpa_supplicant.service
● ├─basic.target
● │ ├─sockets.target
● │ ├─sysinit.target
● │ └─timers.target
● ├─getty.target
● └─remote-fs.target
```

**Observations:**
- `default.target` on this system is `graphical.target`, which depends on `multi-user.target` as its foundation. This layered design means all CLI services are guaranteed to be up before the GUI starts.
- `multi-user.target` pulls in a large set of services including Docker, Snap, NetworkManager, logging (rsyslog), firewall (ufw), and wireless (wpa_supplicant) — the full stack needed for a functional multi-user environment.
- Several third-party services are registered at this level: `AmneziaVPN.service`, `happd.service`, and `containerd.service`, indicating active use of containerization and VPN tooling.
- Services marked with ○ (e.g., `anacron.service`, `dmesg.service`) are defined but currently inactive/disabled — they won't block boot.

---

### 1.4 User Sessions

**`who -a` output:**
```
           system boot  2026-03-01 18:12
           run-level 5  2026-03-01 18:12
yoba     ? :1           2026-03-01 18:15   ?          2681 (:1)
```

**`last -n 5` output:**
```
yoba     :1           :1               Sun Mar  1 18:15   still logged in
reboot   system boot  6.8.0-101-generi Sun Mar  1 18:12   still running
yoba     :1           :1               Sat Feb 28 23:34 - down   (18:36)
reboot   system boot  6.8.0-101-generi Sat Feb 28 23:34 - 18:10  (18:36)
yoba     :1           :1               Sat Feb 28 16:38 - down   (06:46)
wtmp begins Thu Jan 15 22:05:14 2026
```

**Observations:**
- The system booted on 2026-03-01 at 18:12 into run-level 5 (graphical multi-user mode) and has been up for ~19 minutes at the time of capture.
- Only one user (`yoba`) is currently active via a graphical display session (:1), with PID 2681 managing the session.
- Login history shows consistent usage by a single user with no suspicious remote logins. All sessions originate from the local display (:1), confirming this is a personal workstation with no remote SSH access in recent history.
- The `wtmp` log begins January 15, 2026, providing about 6 weeks of login history.

---

### 1.5 Memory Analysis

**`free -h` output:**
```
               total        used        free      shared  buff/cache   available
Mem:            15Gi       6.3Gi       4.4Gi       261Mi       4.7Gi       8.5Gi
Swap:          2.0Gi          0B       2.0Gi
```

**`/proc/meminfo` filtered output:**
```
MemTotal:       16160968 kB
MemAvailable:    8915036 kB
SwapTotal:       2097148 kB
```

**Observations:**
- Total RAM is ~15.4 GiB (16,160,968 kB). Currently 6.3 GiB is in use, with 8.5 GiB still available — the system is under moderate memory load (~39% utilization), which is healthy.
- The 4.7 GiB in `buff/cache` is kernel-managed page cache. Linux reclaims this automatically when applications need more memory, so the true "available" figure of 8.5 GiB is the relevant one for capacity planning.
- Swap usage is exactly 0 bytes despite having a 2 GiB swap file configured, indicating the system has sufficient physical RAM and has not needed to fall back to disk paging. This is good for performance.

**Answer — Top memory-consuming process:** `Telegram Desktop` (`/snap/telegram-desktop/6899`) at **3.7% MEM** (~600 MB)

---

## Task 2 — Networking Analysis

### 2.1 Network Path Tracing

**`traceroute github.com` output:**
```
Command 'traceroute' not found, but can be installed with:
sudo apt install inetutils-traceroute
sudo apt install traceroute
```

> Note: `traceroute` was not installed on this system. The tool is available via `sudo apt install traceroute` but was not installed during this lab session. DNS resolution for `github.com` was confirmed functional via `dig` (see below).

**`dig github.com` output:**
```
; <<>> DiG 9.18.39-0ubuntu0.22.04.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 38443
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494

;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             32      IN      A       140.82.121.4

;; Query time: 78 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Sun Mar 01 19:09:52 MSK 2026
;; MSG SIZE  rcvd: 55
```

**Observations:**
- `github.com` resolved to `140.82.121.4` — a known GitHub IP within their `140.82.121.0/24` range.
- Resolution was handled by the local stub resolver at `127.0.0.53` (systemd-resolved), which forwarded the query upstream. Total query time was 78ms, indicating the answer was not cached and required a full upstream resolution cycle.
- The TTL of 32 seconds is very short, which is typical for GitHub — they use low TTLs to allow rapid failover between their anycast edge addresses.
- The `qr rd ra` flags confirm: the response is authoritative (`qr`), recursion was requested (`rd`), and the resolver supports recursion (`ra`).

---

### 2.2 Packet Capture

**`tcpdump` DNS capture output:**
```
tcpdump: data link type LINUX_SLL2
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes

19:10:17.760186 lo    In  IP 127.0.0.1.47440 > 127.0.0.53.53: 48683+ [1au] AAAA? fi.sota.ac. (39)
19:10:17.760192 lo    In  IP 127.0.0.1.50658 > 127.0.0.53.53: 28165+ [1au] A? fi.sota.ac. (39)
19:10:17.760334 tun0  Out IP 172.18.0.1.44589 > 172.18.0.2.53: 20465+ [1au] AAAA? fi.sota.ac. (39)
19:10:17.760507 lo    In  IP 127.0.0.53.53 > 127.0.0.1.50658: 28165 24/0/1 A 217.217.247.XXX, ... (423)
19:10:17.762765 tun0  In  IP 172.18.0.2.53 > 172.18.0.1.44589: 20465 0/1/1 (124)

5 packets captured
10 packets received by filter
0 packets dropped by kernel
```

**Example DNS query from capture:**
```
19:10:17.760192 lo  In  IP 127.0.0.1.50658 > 127.0.0.53.53: 28165+ [1au] A? fi.sota.ac. (39)
```

**Observations:**
- DNS queries flow from the application (port 50658) to the local systemd-resolved stub at `127.0.0.53:53`, which then forwards them onward. This two-stage pattern is the standard Ubuntu DNS resolution architecture.
- Both `A` (IPv4) and `AAAA` (IPv6) queries were issued in parallel for `fi.sota.ac.` — this is the Happy Eyeballs / dual-stack behavior of modern resolvers.
- Traffic on `tun0` (a VPN tunnel interface) shows DNS queries are also being routed through the VPN's internal resolver (`172.18.0.2:53`), suggesting a split-DNS or VPN-with-DNS-leak-protection configuration is active.
- The `A` record response returned 24 addresses for `fi.sota.ac.`, indicating a heavily load-balanced or anycast service. All IPs were in the `217.217.247.0/24` range (last octets sanitized per security guidelines).
- No packets were dropped by the kernel, and capture completed cleanly within the 10-second timeout window.

---

### 2.3 Reverse DNS Lookups

**`dig -x 8.8.4.4` output:**
```
; <<>> DiG 9.18.39-0ubuntu0.22.04.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 50531
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494

;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   6364    IN      PTR     dns.google.

;; Query time: 31 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Sun Mar 01 19:10:28 MSK 2026
;; MSG SIZE  rcvd: 73
```

**`dig -x 1.1.2.2` output:**
```
; <<>> DiG 9.18.39-0ubuntu0.22.04.2-Ubuntu <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 1651
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494

;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         1493    IN      SOA     ns.apnic.net. ...

;; Query time: 642 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Sun Mar 01 19:10:29 MSK 2026
;; MSG SIZE  rcvd: 137
```

**Observations:**
- **8.8.4.4** successfully resolved to `dns.google.` with a TTL of 6364 seconds (~1.77 hours). This confirms that Google maintains proper PTR records for their public DNS infrastructure, which is important for trust and anti-spam compliance. Query completed in 31ms.
- **1.1.2.2** returned `NXDOMAIN` — no PTR record exists for this address. The authority section shows APNIC (`ns.apnic.net`) is the responsible zone administrator for the `1.0.0.0/8` block, but the specific address `1.1.2.2` has no reverse mapping configured. This is different from Cloudflare's `1.1.1.1`, which does have a PTR record (`one.one.one.one`). Query took 642ms due to the need to reach APNIC's authoritative nameservers.
- The contrast between these two lookups illustrates that PTR record maintenance is optional but a best practice — well-managed infrastructure (like Google's) maintains them; other addresses in the same subnet may not.
