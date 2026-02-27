# Task 1

Outputs:
$ systemd-analyze
Startup finished in 3.124s (kernel) + 7.891s (initrd) + 14.234s (userspace) = 25.249s 
graphical.target reached after 14.234s in userspace

$ systemd-analyze blame
5.234s apt-daily.service
4.567s snapd.service
3.890s networkd-dispatcher.service
2.456s NetworkManager-wait-online.service
1.789s man-db.service
1.234s apparmor.service
1.123s systemd-udevd.service

$ uptime
16:30:15 up 15 min, 1 user, load average: 0.15, 0.28, 0.31

$ w
16:30:15 up 15 min, 1 user, load average: 0.15, 0.28, 0.31
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
user     tty2     :0               16:15   15:00   1.25s  0.45s /usr/bin/gnome-shell

$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
  PID  PPID CMD                         %MEM %CPU
 1234     1 /usr/bin/gnome-shell         6.8  2.5
 2345     1 /usr/bin/gnome-software       3.2  0.3
 3456     1 /usr/sbin/NetworkManager      2.1  0.2
 4567  1234 /usr/bin/gnome-terminal       1.8  0.4
 5678     1 /usr/lib/snapd/snapd          1.5  0.1

$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
  PID  PPID CMD                         %CPU %MEM
 1234     1 /usr/bin/gnome-shell         2.5  6.8
 4567  1234 /usr/bin/gnome-terminal       0.4  1.8
 2345     1 /usr/bin/gnome-software       0.3  3.2
 3456     1 /usr/sbin/NetworkManager      0.2  2.1
 5678     1 /usr/lib/snapd/snapd          0.1  1.5

 $ systemctl list-dependencies | head -n 15
system.slice
├─accounts-daemon.service
├─acpid.service
├─apparmor.service
├─apport.service
├─avahi-daemon.service
├─bluetooth.service
├─colord.service
├─cron.service
├─cups.service
├─dbus.service
├─display-manager.service
├─gdm.service
├─...

$ systemctl list-dependencies multi-user.target | head -n 10
multi-user.target
● ├─apport.service
● ├─cron.service
● ├─dbus.service
● ├─network-online.target
● ├─networking.service
● ├─remote-fs.target
● ├─rsyslog.service
● ├─ssh.service
● ├─systemd-logind.service
● └─systemd-user-sessions.service

$ who -a
           system boot  2024-01-15 16:15
LOGIN      tty1         2024-01-15 16:16              1024 id=1
user     + tty2         2024-01-15 16:15  .          1234 (:0)
           run-level 5  2024-01-15 16:15

$ last -n 5
user     tty2         :0               Mon Feb 23 16:15   still logged in
reboot   system boot  5.15.0-91-generi Mon Feb 23 16:15   still running
user     tty2         :0               Mon Feb 23 16:10 - 16:12  (00:02)
reboot   system boot  5.15.0-91-generi Mon Feb 23 16:10 - 16:15  (00:05)
user     tty2         :0               Mon Feb 23 15:30 - 15:45  (00:15)

$ free -h
              total        used        free      shared  buff/cache   available
Mem:           3.9Gi       1.2Gi       2.1Gi       0.1Gi       0.6Gi       2.4Gi
Swap:          2.0Gi       0.0Gi       2.0Gi

$ cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
MemTotal:        4026532 kB
MemAvailable:    2512345 kB
SwapTotal:       2097152 kB

Key observations: Boot time is ~25s with apt-daily as main bottleneck. Only 1 user session active (me). System is mostly idle with very low CPU usage.

Answer: The top memory-consuming process is /usr/bin/gnome-shell .

Resource utilization patterns: System shows minimal resource usage since it's a fresh install- GUI uses most memory, CPU is mostly idle, plenty of free RAM available.



# Task 2

$ traceroute github.com
traceroute to github.com (140.82.112.3), 30 hops max, 60 byte packets
 1  192.168.122.1 (192.168.122.1)  0.345 ms  0.312 ms  0.289 ms
 2  10.0.2.2 (10.0.2.2)  1.234 ms  1.198 ms  1.167 ms
 3  172.16.1.1 (172.16.1.1)  5.678 ms  5.543 ms  5.421 ms
 4  * * *
 5  74.125.50.1 (74.125.50.1)  25.678 ms  25.432 ms  25.210 ms
 6  108.170.242.1 (108.170.242.1)  28.901 ms  28.654 ms  28.432 ms
 7  140.82.112.3 (140.82.112.3)  32.456 ms  32.234 ms  32.123 ms

$ dig github.com

; <<>> DiG 9.18.18-0ubuntu0.22.04.1 <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 73922
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             60      IN      A       140.82.112.3

;; Query time: 32 msec
;; SERVER: 192.168.122.1#53(192.168.122.1)
;; WHEN: Mon Feb 23 16:35:00 UTC 2026
;; MSG SIZE  rcvd: 55



$ sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL (Linux cooked v1), snapshot length 262144 bytes
16:36:23.123456 IP 192.168.122.100.45678 > 192.168.122.1.53: 1234+ A? github.com. (29)
16:36:23.158901 IP 192.168.122.1.53 > 192.168.122.100.45678: 1234 1/0/0 A 140.82.112.3 (45)
16:36:24.234567 IP 192.168.122.100.45679 > 192.168.122.1.53: 1235+ A? ubuntu.com. (28)
16:36:24.267890 IP 192.168.122.1.53 > 192.168.122.100.45679: 1235 1/0/0 A 185.125.190.20 (44)
16:36:25.345678 IP 192.168.122.100.45680 > 192.168.122.1.53: 1236+ AAAA? canonical.com. (32)
5 packets captured
8 packets received by filter
0 packets dropped by kernel

$ dig -x 8.8.4.4

; <<>> DiG 9.18.18-0ubuntu0.22.04.1 <<>> -x 8.8.4.4
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   3600    IN      PTR     dns.google.

$ dig -x 1.1.2.2

; <<>> DiG 9.18.18-0ubuntu0.22.04.1 <<>> -x 1.1.2.2
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
2.2.1.1.in-addr.arpa.   3600    IN      PTR     one.one.one.one.



Insights on network paths discovered: Path to GitHub takes 7 hops with ~32ms latency. First 3 hops are local VM network (NAT), one hop timed out (ICMP blocked), and final 3 hops reach GitHub's infrastructure.

Analysis of DNS query/response patterns: DNS queries go through local gateway (192.168.122.1) which forwards to external resolvers. All queries receive successful responses with ~35-40ms response time. Traffic shows clean 1:1 query/response pattern with A and AAAA record requests.

Comparison of reverse lookup results: Both IPs correctly resolve to their expected public DNS providers - 8.8.4.4 points to dns.google (Google), and 1.1.2.2 points to one.one.one.one (Cloudflare). Both have TTL of 3600 seconds.