Страница 1
# Lab 4 — Operating Systems & Networking
## Task 1 — Operating System Analysis
### 1.1 Boot Performance Analysis
**Command outputs:**
```bash$ systemd-analyze
 
output:Startup finished in 4.728s (kernel) + 13.193s (userspace) = 17.921s graphical.target reached after 13.138s in userspace. 
$ systemd-analyze blame
output:
 
43.518s man-db.service23.900s fwupd-refresh.service7.828s logrotate.service7.138s snapd.seeded.service6.912s snapd.service5.010s vboxadd.service4.312s NetworkManager.service4.057s apt-daily.service4.005s systemd-udev-settle.service3.913s fstrim.service3.319s dev-sda1.device3.231s blueman-mechanism.service3.086s apport.service3.015s accounts-daemon.service2.952s gpu-manager.service2.350s dev-loop10.device2.334s dev-loop9.device2.328s dev-loop8.device2.258s avahi-daemon.service2.200s apt-daily-upgrade.service2.095s systemd-tmpfiles-clean.service2.072s polkit.service1.917s grub-common.service1.882s rsyslog.service1.852s udisks2.service 
$ uptimeoutput:
12:09:10 up 1 day,  3:50,  1 user,  load average: 0.32, 1.04, 1.66
$ woutput:
 12:09:36 up 1 day,  3:51,  1 user,  load average: 0.38, 0.99, 1.62USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHATuser     tty2     -                18Mar26 16days 12:43   0.02s /usr/lib/x86_64-linux-gnu/sddm/sddm-helper --soc
 
The system booted in [your boot time] total, with userspace taking [your userspace time]. The slowest service was [slowest service name] at [time] seconds. Current load average is [load averages] — this indicates [low/normal/high] system stress (load < 1.0 = low, > 1.0 per CPU core = high). There are [number] users currently logged in: [usernames]. [Any observations about idle times or remote IPs].
 
The system booted in 17.9 seconds total, with kernel taking 4.7s and userspace 13.2s — this is fast and healthy. However, man-db.service (manual page database) took 43.5 seconds to run, but note this likely ran after boot completion as a one-time background task. fwupd-refresh.service (firmware updater) took 23.9s, also post-boot. Current load average shows decreasing trend (1.66 → 1.04 → 0.32 over 15/5/1 min), meaning the system was previously busy but is now calming down. Only 1 user is logged in via SDDM display manager (GUI login from March 18 — 16 days idle, which is unusual).
 
Top 5 memory-consuming processes: PID  PPID CMD                         %MEM %CPU23665  1317 /snap/firefox/7967/usr/lib/ 23.8 12.428609 23788 /snap/firefox/7967/usr/lib/ 12.0  6.71239   1221 /usr/lib/xorg/Xorg          11.0  0.728736 23788 /snap/firefox/7967/usr/lib/  9.0  1.328468 23788 /snap/firefox/7967/usr/lib/  9.0  1.0
Top 5 CPU-consuming processes: PID  PPID CMD                         %MEM %CPU23665  1317 /snap/firefox/7967/usr/lib/ 23.8 12.428609 23788 /snap/firefox/7967/usr/lib/ 12.0  6.7190      2 [jbd2/sda1-8]                0.0  5.728736 23788 /snap/firefox/7967/usr/lib/  9.0  1.328468 23788 /snap/firefox/7967/usr/lib/  8.8  1.0
Top memory-consuming process: Firefox (PID 23665) using 23.8% of system RAM. Multiple Firefox processes dominate both memory and CPU usage — there are at least 4 separate Firefox instances running (PIDs 23665, 28609, 28736, 28468).
1.3 Service Dependencies
 
$ systemctl list-dependenciesdefault.target● ├─accounts-daemon.service● ├─sddm.service● ├─switcheroo-control.service○ ├─systemd-update-utmp-runlevel.service● ├─udisks2.service● └─multi-user.target
$ systemctl list-dependencies multi-user.targetmulti-user.target○   ├─anacron.service●   ├─apport.service●   ├─avahi-daemon.service○   ├─blueman-mechanism.service●   ├─console-setup.service●   ├─cron.service●   ├─cups-browsed.service●   ├─cups.path●   ├─cups.service●   ├─dbus.service○   ├─dmesg.service○   ├─e2scrub_reap.service○   ├─grub-common.service○   ├─grub-initrd-fallback.service●   ├─kerneloops.service●   ├─lm-sensors.service●   ├─ModemManager.service○   ├─networkd-dispatcher.service 
Analysis: The system uses default.target (aliased to graphical.target) with SDDM as the display manager. Key dependencies include accounts-daemon, udisks2 (storage), and multi-user.target. Services marked with ● are static/active, while ○ indicates indirect/optional dependencies. Notable services: cups (printing), avahi-daemon (network discovery), ModemManager (mobile broadband), apport (crash reporting), and cron (scheduled tasks).
 
$ who -a           system boot  2026-03-18 08:19           run-level 5  2026-03-18 08:21LOGIN      tty2         2026-03-18 08:30              1234 id=tty2user     + tty2         2026-03-18 08:30  old         5678 (:0)
$ last -n 5user     tty2         :0               Wed Mar 18 16:18   gone - no logoutreboot   system boot  6.14.0-27-generi Wed Mar 18 16:18   still runninguser     tty1         :1               Sat Mar 14 23:22 - crash (3+16:55)user     tty2         :0               Wed Mar 11 14:02 - crash (7+02:15)reboot   system boot  6.14.0-27-generi Wed Mar 11 14:01   still running
wtmp begins Tue Sep  2 22:32:25 2025
 
Currently 1 user (user) logged in via tty2 (local GUI) using SDDM.The last -n 5 output shows:
·	March 18, 2026 — user logged in at 16:18, marked "gone - no logout" (session never properly ended)
·	Two reboot entries — March 18 and March 11, both "still running"
·	Previous crashes — user sessions on March 14 and March 11 ended with "crash" status
·	 
·	 
Pattern: The system shows a browser-dominant memory profile. Firefox alone accounts for approximately 53.6% of total RAM (23.8% + 12.0% + 9.0% + 8.8%) across its four processes.
 
### 2.1 Network Path Tracing
**Command outputs:**
$ traceroute github.comtraceroute to github.com (140.82.121.3), 64 hops max 1   10.0.2.2  0.003ms  0.002ms  0.003ms  2   *  *  *  3   *  *  *  4   *  *  *  5   *  *  *  6   *  *  *  7   *  *  *  8   *  *  *  9   *  *  * 10   *  *  * 11   *  *  * 12   *  *  * 13   *  *  * 14   *  *  *
$ dig github.com; <<>> DiG 9.18.30 <<>> github.com;; ANSWER SECTION:github.com.             42      IN      A       140.82.121.4
DNS query analysis:
·	GitHub.com IP address: 140.82.121.4
·	TTL: 42 seconds (very low — indicates dynamic DNS/load balancing)
·	CNAME records: None — direct A record
·	DNS server: 127.0.0.53 (systemd-resolved stub resolver)
·	Query time: 40 milliseconds
·	Status: NOERROR — successful resolution
 
 
sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn tcpdump: data link type LINUX_SLL2 listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes 12:36:59.086175 lo    In  IP 127.0.0.1.33237 > 127.0.0.53.53: 59229+ [1au] A? api.github.com. (43) 12:36:59.086396 enp0s3 Out IP 10.0.2.15.44044 > 1.1.1.1.53: 30506+ [1au] A? api.github.com. (43) 12:36:59.088368 lo    In  IP 127.0.0.1.33237 > 127.0.0.53.53: 47707+ [1au] AAAA? api.github.com. (43) 12:36:59.088468 enp0s3 Out IP 10.0.2.15.41904 > 1.1.1.1.53: 44597+ [1au] AAAA? api.github.com. (43) 12:36:59.088983 lo    In  IP 127.0.0.1.46056 > 127.0.0.53.53: 48334+ [1au] HTTPS? api.github.com. (43) 5 packets captured 22 packets received by filter 0 packets dropped by kernel
 
Key observations:
·	DNS server used: 1.1.1.1 (Cloudflare's public DNS)
·	Local resolver: 127.0.0.53 (systemd-resolved) — caches DNS results
·	Query types: A (IPv4), AAAA (IPv6), HTTPS (modern DNS type for HTTP/3)
·	Domain queried: api.github.com (background check, not user-initiated)
·	Transport: UDP only (no TCP fallback needed)
·	EDNS enabled: [1au] flag = EDNS0 with 65494 byte UDP buffer
 
 
$ dig -x 8.8.4.4;; ANSWER SECTION:4.4.8.8.in-addr.arpa.   6159    IN      PTR     dns.google.
$ dig -x 1.1.2.2;; STATUS: NXDOMAIN;; AUTHORITY SECTION:1.in-addr.arpa.         3309    IN      SOA     ns.apnic.net.
Analysis:
8.8.4.4 (Google):
·	Has a valid PTR record pointing to dns.google.
·	Confirms this is one of Google's public DNS resolvers
·	TTL: 6159 seconds (~1.7 hours)
1.1.2.2 (APNIC):
·	No PTR record exists (NXDOMAIN)
·	Authority shows APNIC manages the 1.in-addr.arpa zone
·	This IP is not configured for reverse DNS — common for non-mail servers
Why the difference?
·	PTR records are optional. Google configures them for public DNS transparency
·	1.1.2.2 is part of APNIC's research range, not a public service
 
One example DNS query from packet capture (sanitized):
IP 10.0.2.XXX.44044 > 1.1.1.XXX.53: 30506+ [1au] A? api.github.com. (43)
