# Lab 8 — Site Reliability Engineering (SRE)

## Task 1 — Key Metrics for SRE and System Analysis

### 1.1 Monitor System Resources

#### CPU Usage

```
top -l 1 -s 0 | head -30

Processes: 457 total, 2 running, 1 stuck, 454 sleeping, 3318 threads
2026/03/27 18:56:51
Load Avg: 4.81, 2.68, 2.24
CPU usage: 10.87% user, 12.99% sys, 76.13% idle
```

**Top 3 processes by CPU (from top output):**

| Rank | Process | CPU % | Memory |
|------|---------|-------|--------|
| 1 | com.apple.WebKit (PID 85969) | active | 1311M |
| 2 | Google Chrome Helper (PID 82170) | active | 228M |
| 3 | Google Chrome Helper (PID 96731) | active | 205M |

> CPU is mostly idle (76.13%), with user processes consuming ~11% and kernel ~13%.

#### Memory Usage

```
PhysMem: 15G used (2313M wired, 7394M compressor), 85M unused.
VM: 209T vsize, 5702M framework vsize, 22996989(0) swapins, 26597197(0) swapouts.
```

**Top 3 processes by Memory:**

| Rank | Process | Memory |
|------|---------|--------|
| 1 | com.apple.WebKit (PID 85969) | 1311M |
| 2 | Google Chrome Helper (PID 82170) | 228M |
| 3 | Google Chrome Helper (PID 96174) | 209M |

#### I/O Usage

```
iostat -w 1 -c 5

              disk0               disk4               disk5       cpu    load average
    KB/t  tps  MB/s     KB/t  tps  MB/s     KB/t  tps  MB/s  us sy id   1m   5m   15m
   22.80   91  2.03   325.36    0  0.00   110.60    0  0.00   9  5 86  2.80 2.32 2.10
   28.67    6  0.17     0.00    0  0.00     0.00    0  0.00   5  3 91  2.80 2.32 2.10
   19.43   49  0.93     0.00    0  0.00     0.00    0  0.00   4  2 94  2.80 2.32 2.10
   41.00   12  0.48     0.00    0  0.00     0.00    0  0.00   3  2 95  2.66 2.30 2.09
   40.00    5  0.19     0.00    0  0.00     0.00    0  0.00   3  2 95  2.66 2.30 2.09
```

**Top I/O consumer:** `disk0` (main NVMe SSD) — peak 2.03 MB/s, mostly idle afterwards.  
`disk4` and `disk5` show near-zero activity (mounted external/virtual volumes).

---

### 1.2 Disk Space Management

#### Disk Usage (`df -h`)

```
Filesystem        Size    Used   Avail Capacity iused ifree %iused  Mounted on
/dev/disk3s1s1   460Gi    17Gi    56Gi    23%    427k  589M    0%   /
/dev/disk3s6     460Gi    18Gi    56Gi    25%      18  589M    0%   /System/Volumes/VM
/dev/disk3s2     460Gi    15Gi    56Gi    21%    2,0k  589M    0%   /System/Volumes/Preboot
/dev/disk3s5     460Gi   352Gi    56Gi    87%    3,0M  589M    1%   /System/Volumes/Data
/dev/disk4s1     609Mi   403Mi   206Mi    67%     792  4,3G    0%   /Volumes/Codex Installer
/dev/disk6s1     186Mi   142Mi    42Mi    78%       8  428k    0%   /Volumes/VirtualBox
```

> ⚠️ **Notable:** `/System/Volumes/Data` is at **87% capacity** (352Gi / 460Gi) — this warrants attention.

#### Top directories in `/var`

```
sudo du -h /var | sort -rh | head -n 10

0B    /var
```

> On macOS, `/var` is a symlink to `/private/var`. The directory appears empty at the top level due to system permissions and macOS sandboxing. This is expected behavior on macOS — system logs and temporary files are stored under `/private/var`.

#### Top 3 largest files in `/var`

```
sudo find /var -type f -exec du -h {} + 2>/dev/null | sort -rh | head -n 3
```

> No results returned — consistent with the above: `/var` on macOS is a protected symlink with no directly accessible user-space files. The actual data resides in `/private/var` and is managed by the OS.

---

### Analysis

The following patterns are observed in resource utilization:

- **CPU** is healthy: 76% idle, with load averages of 4.81 / 2.68 / 2.24 indicating a temporary spike that is already stabilizing. The main consumers are browser renderer processes (WebKit, Chrome Helper), which is typical for a development workstation.
- **Memory** is heavily utilized: only 85M of 16GB remains unused, with 7.4GB held in the compressor (macOS's compressed memory system). High swap activity (22M swapins / 26M swapouts) suggests the system has experienced memory pressure. The main culprit is Chrome with multiple tabs open.
- **I/O** is minimal: disk0 (NVMe SSD) peaks at ~2 MB/s and quickly drops to under 0.5 MB/s. No I/O bottleneck is present.
- **Disk space** is the most concerning metric: the data volume is at 87% capacity, leaving only ~56Gi free.

---

### Reflection

Based on these findings, the following optimizations would be recommended:

1. **Memory:** Reduce the number of open Chrome tabs or switch to a more memory-efficient browser profile. On Apple Silicon, unified memory is shared between CPU and GPU — running close to capacity degrades overall system performance.
2. **Disk:** The 87% usage on the data volume is approaching critical levels. Clearing caches (`~/Library/Caches`), removing unused applications, and offloading large files to external storage would be advisable.
3. **Swap:** High swap counts indicate historical memory pressure. Adding monitoring for memory usage over time (e.g., via `vm_stat` in a cron job) would help identify peak usage periods.
4. **I/O:** No action needed — disk I/O is well within healthy limits for an NVMe SSD.

---

## Task 2 — Practical Website Monitoring Setup

**Monitored website:** `https://github.com`

### 2.1 API Check — Basic Availability

The API check was configured in Checkly to verify that GitHub's homepage returns an HTTP 200 status code, confirming basic availability.

**Configuration:**
- **Type:** API Check
- **URL:** `https://github.com`
- **Assertion:** Status code equals `200`
- **Frequency:** Every 10 minutes

![alt text](<Снимок экрана 2026-03-27 в 23.16.17.png>)
![alt text](<Снимок экрана 2026-03-27 в 23.29.17.png>)

---

### 2.2 Browser Check — Content & Performance

The browser check uses Playwright to simulate a real user visiting GitHub, verify that the main heading loads, and measure page load time.

**Script used:**
```javascript
const { chromium } = require('playwright');

const browser = await chromium.launch();
const page = await browser.newPage();

await page.goto('https://github.com');

await page.waitForSelector('h1');
const title = await page.title();
console.log('Page title:', title);

const loadTime = await page.evaluate(() => {
  return window.performance.timing.loadEventEnd - window.performance.timing.navigationStart;
});
console.log('Load time:', loadTime, 'ms');

await browser.close();
```

![alt text](<Снимок экрана 2026-03-27 в 23.19.14.png>) 
![alt text](<Снимок экрана 2026-03-27 в 23.21.12.png>)

---

### 2.3 Alert Settings

Alerts were configured to notify via email when any check fails.

**Configuration:**
- **Channel:** Email
- **Trigger:** Check failure (any check returns non-200 or browser assertion fails)
- **Escalation:** Alert after 1 failed run to minimize response time
![alt text](<Снимок экрана 2026-03-27 в 23.23.43.png>)

---

### Analysis

These specific checks and thresholds were chosen for the following reasons:

- **API check** covers the most fundamental SLA metric: is the site reachable at all? An HTTP 200 assertion catches server errors (5xx) and unexpected redirects.
- **Browser check** goes beyond network-level availability — it confirms that JavaScript renders correctly and that the DOM contains expected content. A site can return 200 but still be broken for users.
- **10-minute frequency** is appropriate for a public site like GitHub: it provides timely detection without exhausting free-tier check limits.
- **Email alert on first failure** ensures immediate awareness of incidents without introducing noise from transient errors.

---

### Reflection

This monitoring setup contributes to website reliability in several concrete ways:

- **Reduces Mean Time to Detect (MTTD):** Issues are caught within 10 minutes rather than being discovered by users.
- **Covers both synthetic and real-user simulation:** The combination of API and browser checks mirrors what both infrastructure monitoring and real end-users would experience.
- **Supports SLA tracking:** Checkly's dashboard provides historical uptime data, which can be used to measure and report on availability SLAs.
- **Enables proactive incident response:** With alerting in place, the team can begin investigation and remediation before a significant number of users are impacted.

This aligns with the SRE principle of monitoring user-facing symptoms (is the site usable?) rather than only internal signals (is the server running?).
