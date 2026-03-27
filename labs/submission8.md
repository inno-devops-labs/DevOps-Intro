# Lab 8 — Site Reliability Engineering (SRE)

## Task 1 — Key Metrics for SRE and System Analysis

### System resource monitoring

I ran the required commands on my local machine (macOS) and checked CPU, memory, disk, and I/O activity.

#### Top 3 CPU-consuming applications

1. `com.apple.WebKit.WebContent` — `99.1%`
2. `WindowServer` — `16.3%`
3. `mapssyncd` — `6.8%`

```bash
ps -axo pid,ppid,%cpu,%mem,command | sort -nrk3 | head -n 10
````

```text
 1687     1  99.1  7.6 /System/Library/Frameworks/WebKit.framework/.../com.apple.WebKit.WebContent
  401     1  16.3  0.9 /System/Library/PrivateFrameworks/SkyLight.framework/Resources/WindowServer -daemon
 3099     1   6.8  0.1 /System/Library/PrivateFrameworks/MapsSync.framework/mapssyncd
```

#### Top 3 memory-consuming applications

1. `com.apple.WebKit.WebContent` — `7.7%`
2. `AppleSpell` — `2.4%`
3. `com.apple.WebKit.WebContent` — `2.3%`

```bash
ps -axo pid,ppid,%mem,%cpu,command | sort -nrk3 | head -n 10
```

```text
 1687     1  7.7   5.7 /System/Library/Frameworks/WebKit.framework/.../com.apple.WebKit.WebContent
 1316     1  2.4   0.0 /System/Library/Services/AppleSpell.service/Contents/MacOS/AppleSpell
 1761     1  2.3   6.5 /System/Library/Frameworks/WebKit.framework/.../com.apple.WebKit.WebContent
```

#### I/O usage

```bash
iostat -w 1 -c 5
```

```text
              disk0       cpu    load average
    KB/t  tps  MB/s  us sy id   1m   5m   15m
   21.85 1180 25.18  21  9 71  2.20 9.68 8.37
    4.89   99  0.47   7  3 90  2.20 9.68 8.37
    4.98   65  0.31   7  3 89  2.26 9.57 8.34
    4.95  143  0.69   9  4 86  2.26 9.57 8.34
   23.70  282  6.52   8  4 88  2.26 9.57 8.34
```

From the `iostat` output, the system had short bursts of disk activity, but overall it did not look heavily I/O-bound.

---

### Disk space management

#### Disk usage

```bash
df -h
```

```text
Filesystem        Size    Used   Avail Capacity Mounted on
/dev/disk3s1s1   228Gi    12Gi    75Gi    14%   /
/dev/disk3s5     228Gi   132Gi    75Gi    64%   /System/Volumes/Data
```

#### Largest directories in `/var`

```bash
du -sh /private/var/* 2>/dev/null | sort -hr | head -n 10
```

```text
2.2G	/private/var/db
2.0G	/private/var/vm
1.4G	/private/var/folders
93M	/private/var/log
```

#### Top 3 largest files in `/var`

```bash
find /private/var -type f -exec du -h {} + 2>/dev/null | sort -hr | head -n 3
```

```text
2.0G	/private/var/vm/sleepimage
158M	/private/var/db/uuidtext/dsc/0B32AEB647383BEFA00A0F484C0F1230
153M	/private/var/db/uuidtext/dsc/674DB25A34B23C568BD47D78005B2F2E
```

### Analysis

The main load came from browser-related processes, especially `WebKit.WebContent`. One browser process used almost all CPU at the time of measurement, and several WebKit processes also appeared in memory-heavy processes. Disk usage looked normal overall, and the biggest space in `/private/var` was used by system files like `sleepimage` and system databases.

### Reflection

The easiest optimization would be to close heavy browser tabs and stop background applications that are not needed. I would also review long-running services like the Java/Kafka process because they take memory even when idle. For disk usage, I would mainly monitor logs, caches, and temporary files instead of deleting system files directly.

---

## Task 2 — Practical Website Monitoring Setup

For website monitoring, I used **[https://example.com](https://example.com)** as the target website.

I created an **API check** to verify that the site returns status code `200`. I also created a **browser check** to confirm that the page loads correctly and that the main text on the page is visible. In addition, I configured an alert rule to notify me in case of failed checks or slow response time.

### Why these checks

I chose these checks because they cover both basic availability and visible page content. A website may still respond with HTTP 200 even if something important on the page is broken, so browser checks are useful in addition to API checks.

### Reflection

This setup helps detect downtime and simple user-facing issues early. It is a basic but practical example of SRE monitoring because it focuses on availability, response behavior, and alerting.