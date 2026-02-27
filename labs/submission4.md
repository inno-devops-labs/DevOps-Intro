# Lab 4 — OS & Networking (macOS)

> Note: The original lab uses Linux/systemd tools. Since this was completed on macOS, equivalent tools were used:
>
> * `systemd-analyze` → `uptime`, `sysctl kern.boottime`
> * `systemctl` → `launchctl`
> * `free` and `/proc/meminfo` → `sysctl`, `vm_stat`, `top`

---

## Task 1 — Operating System Analysis

### 1.1 Boot Performance Analysis

**Command:** `uptime`

```text
23:24  up 16 days, 50 mins, 2 users, load averages: 3.27 5.24 6.07
```

**Command:** `sysctl -n kern.boottime`

```text
{ sec = 1770838459, usec = 678680 } Wed Feb 11 22:34:19 2026
```

**Command:** `log show --style compact --last 10m --predicate 'eventMessage CONTAINS "Previous shutdown cause"'`

```text
Timestamp               Ty Process[PID:TID]
```

**Observations:**

* The system has been running for over 16 days without reboot.
* Boot timestamp confirms last reboot on Feb 11, 2026.
* No recent shutdown cause entries were found in logs (likely due to clean uptime and log retention).

---

### 1.2 Process Forensics

**Top processes by CPU:**

```text
PID   PPID COMMAND          %MEM  %CPU
48612   525 /Library/Applica  0.7  28.2
46109     1 /System/Library/  0.8  26.6
402       1 /System/Library/  1.0  22.8
46110     1 /System/Library/  0.8  11.1
34824     1 /Applications/V2  0.5   8.5
```

**Top processes by memory:**

```text
PID   PPID COMMAND          %MEM  %CPU
47317     1 /System/Library/  3.3   8.1
1424      1 /System/Volumes/  1.7   3.0
402       1 /System/Library/  0.9  20.7
47293     1 /System/Library/  0.8   0.0
1284      1 /Applications/V2  0.8   3.8
```

**Top memory-consuming process:**
WebKit system process (browser rendering component, sanitized).

**Observations:**

* CPU usage is distributed across multiple system services and applications.
* The highest memory usage comes from a WebKit-related process, which is typical for macOS browsers.
* No single process dominates system resources, indicating balanced load.

---

### 1.3 Service Dependencies (launchd equivalent)

**Command:** `launchctl list | head -n 30`

```text
PID	Status	Label
-	0	com.apple.SafariHistoryServiceAgent
47299	-9	com.apple.progressd
-	0	com.apple.enhancedloggingd
46388	-9	com.apple.cloudphotod
-	-9	com.apple.MENotificationService
612	0	com.apple.Finder
23878	-9	com.apple.homed
33542	-9	com.apple.dataaccess.dataaccessd
-	0	com.apple.quicklook
-	0	com.apple.parentalcontrols.check
797	0	com.apple.mediaremoteagent
645	0	com.apple.FontWorker
27792	-9	com.apple.bird
-	0	com.apple.amp.mediasharingd
-	-9	com.apple.knowledgeconstructiond
33150	-9	com.apple.inputanalyticsd
-	0	com.apple.familycontrols.useragent
-	0	com.apple.AssetCache.agent
46319	0	com.apple.GameController.gamecontrolleragentd
-	0	com.apple.universalaccessAuthWarn
-	0	com.apple.UserPictureSyncAgent
694	0	com.apple.nsurlsessiond
42366	-9	com.apple.devicecheckd
-	0	com.apple.syncservices.uihandler
33270	-9	com.apple.iconservices.iconservicesagent
-	-9	com.apple.diagnosticextensionsd
-	-9	com.apple.intelligenceplatformd
27438	-9	com.apple.SafariBookmarksSyncAgent
-	0	com.apple.cmio.LaunchCMIOUserExtensionsAgent
```

**Command:** `launchctl print system | head -n 80`

```text
system = {
	type = system
	handle = 0
	active count = 986
	service count = 423
	active service count = 159
	maximum allowed shutdown time = 71 s
	...
}
```

**Observations:**

* macOS uses `launchd` instead of `systemd` for service management.
* Over 400 registered services exist, with ~150 active at runtime.
* Many Apple background services (iCloud, media, analytics) are visible.
* Some services show negative exit status, which is normal for inactive or on-demand daemons.

---

### 1.4 User Sessions

**Command:** `who -a`

```text
system boot  Feb 11 22:34 
vozamhcak    console      Feb 11 22:34 
vozamhcak    ttys000      Feb 20 21:58 
vozamhcak    ttys001      Feb 15 13:06
```

**Command:** `last -n 5`

```text
vozamhcak  ttys000  Fri Feb 20 21:58   still logged in
vozamhcak  ttys000  Tue Feb 17 23:32 - 23:32
vozamhcak  ttys001  Sun Feb 15 13:06 - 13:06
vozamhcak  ttys000  Sun Feb 15 10:35 - 10:35
vozamhcak  ttys000  Fri Feb 13 16:06 - 16:06
```

**Observations:**

* Single user environment with multiple terminal sessions.
* Long-running console session aligns with system uptime.
* No suspicious login activity detected.

---

### 1.5 Memory Analysis

**Total RAM:**

```text
sysctl -n hw.memsize
8589934592
```

**Swap usage:**

```text
vm.swapusage: total = 1024.00M  used = 407.50M  free = 616.50M  (encrypted)
```

**vm_stat snapshot (abridged):**

```text
Pages free: 4144
Pages active: 85455
Pages inactive: 84543
Pages wired down: 99066
Pages stored in compressor: 593356
Swapouts: 37088
```

**top memory summary:**

```text
PhysMem: 7525M used (1496M wired, 3353M compressor), 91M unused.
```

**Observations:**

* System has 8 GB RAM total.
* Majority of memory is actively used, with heavy reliance on compression.
* Swap usage (~400 MB) indicates moderate memory pressure but not critical.
* macOS memory compression is actively reducing swap overhead.

---

## Summary (Task 1)

* System shows long stable uptime (16+ days).
* Resource usage is balanced without runaway processes.
* Top memory consumer is a WebKit rendering process.
* Memory pressure is moderate but managed via compression.
* macOS service model differs from Linux but provides similar observability via `launchctl`.




---

## Task 2 — Networking Analysis

### 2.1 Network Path Tracing

**Command:** `traceroute github.com`

```text
traceroute to github.com (140.82.121.x), 64 hops max, 40 byte packets
1  * * *
2  * * *
3  * * *
```

**Observation:**
Traceroute did not return visible hops. This is common on modern networks where ICMP or UDP traceroute probes are blocked by routers, firewalls, or NAT layers (especially on macOS and VPN environments).

---

**Command:** `dig github.com`

```text
;; ANSWER SECTION:
github.com.        1    IN    A    198.18.0.xxx
```

**Observations:**

* DNS resolution succeeded with status NOERROR.
* Response was returned almost instantly (~1 ms).
* DNS server used: 1.1.1.1 (Cloudflare).
* The returned IP appears to be NAT or filtered environment (non-public range).

---

### 2.2 Packet Capture (DNS)

**Command:** `sudo tcpdump -c 5 -i any 'port 53' -nn`

```text
0 packets captured
```

**Observations:**

* No packets were captured during the short window.
* This is expected in cases where:

  * DNS caching is active
  * macOS network privacy features are enabled
  * DNS-over-HTTPS or system resolver abstraction is used
* Modern macOS versions often hide DNS traffic from raw tcpdump unless running longer captures.

**Example DNS query (from manual trigger):**

```text
dig google.com → A record returned successfully
```

---

### 2.3 Reverse DNS Lookups

**Command:** `dig -x 8.8.4.4`

```text
8.8.4.4 → dns.google
```

**Command:** `dig -x 1.1.2.2`

```text
Status: NXDOMAIN
```

**Comparison:**

* 8.8.4.4 has a valid PTR record resolving to dns.google.
* 1.1.2.2 does not have a reverse DNS entry (NXDOMAIN).
* This demonstrates that reverse DNS is optional and depends on provider configuration.

---

## Summary (Task 2)

* DNS resolution is fast and reliable via Cloudflare resolver.
* Traceroute visibility is limited, likely due to firewall or NAT filtering.
* Packet capture did not reveal DNS traffic, likely due to OS-level DNS abstraction or caching.
* Reverse DNS results demonstrate both valid PTR resolution and NXDOMAIN scenarios.

