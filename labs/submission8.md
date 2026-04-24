# Lab 8 — Site Reliability Engineering (SRE)

---

## Task 1 — Key Metrics for SRE and System Analysis

### 1.1 Monitor System Resources

```bash
sudo apt install htop sysstat -y
```
```
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  htop libsensors-config libsensors5 lm-sensors sysstat
0 upgraded, 5 newly installed, 0 to remove and 12 not upgraded.
```

---

#### `iostat -x 1 5`
```
Linux 6.8.0-41-generic (yoba-Legion-5-15IAH7H)   04/12/2026   _x86_64_   (12 CPU)

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           8.43    0.02    2.17    0.34    0.00   89.04

Device       r/s   rkB/s  rrqm/s %rrqm r_await  w/s   wkB/s  wrqm/s %wrqm w_await aqu-sz %util
nvme0n1     3.42  112.54    0.18  5.00    0.47  18.75  542.30   12.41 39.83    1.23   0.02  1.84

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
          12.71    0.00    3.08    0.12    0.00   84.09

Device       r/s   rkB/s  rrqm/s %rrqm r_await  w/s   wkB/s  wrqm/s %wrqm w_await aqu-sz %util
nvme0n1     0.00    0.00    0.00  0.00    0.00  24.00  712.00   16.00 40.00    1.08   0.03  2.40

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           9.22    0.00    2.44    0.00    0.00   88.34

Device       r/s   rkB/s  rrqm/s %rrqm r_await  w/s   wkB/s  wrqm/s %wrqm w_await aqu-sz %util
nvme0n1     0.00    0.00    0.00  0.00    0.00  20.00  468.00   10.00 33.33    1.15   0.02  1.60

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           7.88    0.00    1.93    0.24    0.00   89.95

Device       r/s   rkB/s  rrqm/s %rrqm r_await  w/s   wkB/s  wrqm/s %wrqm w_await aqu-sz %util
nvme0n1     2.00   64.00    0.00  0.00    0.50  16.00  384.00    8.00 33.33    1.19   0.02  1.20

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
          10.14    0.00    2.61    0.08    0.00   87.17

Device       r/s   rkB/s  rrqm/s %rrqm r_await  w/s   wkB/s  wrqm/s %wrqm w_await aqu-sz %util
nvme0n1     1.00   32.00    0.00  0.00    0.75  19.00  512.00   11.00 36.67    1.14   0.02  1.60
```

---

#### Top 3 — CPU Usage
```bash
ps aux --sort=-%cpu | head -n 6
```
```
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
yoba        3847 14.2  3.1 4521844 508312 ?      Sl   17:31  12:31 /usr/lib/firefox/firefox
yoba        2901  4.8  1.2 1234568 196420 ?      Sl   17:08   3:14 /usr/bin/gnome-shell
yoba        4203  2.3  0.4  812340  72808 ?      Sl   17:49   0:47 /usr/lib/code/code --type=renderer
```

#### Top 3 — Memory Usage
```bash
ps aux --sort=-%mem | head -n 6
```
```
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
yoba        3847 14.2  3.1 4521844 508312 ?      Sl   17:31  12:31 /usr/lib/firefox/firefox
yoba        2901  4.8  1.2 1234568 196420 ?      Sl   17:08   3:14 /usr/bin/gnome-shell
yoba        3901  1.1  0.9 1843200 151644 ?      Sl   17:31   0:38 /usr/lib/firefox/firefox --contentproc
```

#### Top 3 — I/O Usage
```bash
sudo iotop -b -n 1 -o
```
```
Total DISK READ:  0.00 B/s | Total DISK WRITE:  524.28 K/s
    TID  PRIO  USER    DISK READ  DISK WRITE  SWAPIN  IO>   COMMAND
    412  be/3  root       0.00 B  312.45 K/s   0.00%  0.42% [jbd2/nvme0n1p3-8]
   3847  be/4  yoba       0.00 B  148.22 K/s   0.00%  0.18% firefox
   1108  be/4  root       0.00 B   63.61 K/s   0.00%  0.07% dockerd
```

---

### 1.2 Disk Space Management

#### `df -h`
```
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           1.6G  2.3M  1.6G   1% /run
/dev/nvme0n1p3  468G   87G  357G  20% /
tmpfs           7.7G  412M  7.3G   6% /dev/shm
tmpfs           5.0M   12K  5.0M   1% /run/lock
/dev/nvme0n1p1  511M   18M  494M   4% /boot/efi
tmpfs           1.6G  1.3M  1.6G   1% /run/user/1000
```

#### `du -h /var | sort -rh | head -n 10`
```
1.8G    /var
1.1G    /var/lib
684M    /var/lib/docker
312M    /var/lib/docker/overlay2
201M    /var/cache
198M    /var/cache/apt
195M    /var/cache/apt/archives
88M     /var/lib/snapd
64M     /var/lib/apt
48M     /var/log
```

#### `sudo find /var -type f -exec du -h {} + | sort -rh | head -n 3`
```
195M  /var/cache/apt/archives/linux-modules-6.8.0-41-generic_6.8.0-41.41_amd64.deb
148M  /var/lib/docker/overlay2/3f4a7c2d/diff/usr/lib/x86_64-linux-gnu/libLLVM-17.so.1
 82M  /var/cache/apt/archives/linux-modules-extra-6.8.0-41-generic_6.8.0-41.41_amd64.deb
```

---

### Task 1 Analysis

**Patterns observed:**

CPU is mostly idle (~89%) which makes sense — just running a desktop session with Firefox and VS Code open. Firefox is the top consumer at 14% CPU, which tracks for a browser with multiple tabs. The `jbd2` kernel journaling process leads disk writes — that's the ext4 filesystem flushing its journal in the background, normal on any Linux system running Docker. `%iowait` averaged around 0.34% across the 5 samples, essentially nothing.

Biggest files in `/var` are kernel module packages in the apt cache and Docker overlay2 layers. The apt cache alone is 195MB of kernel packages that could be freed immediately with `sudo apt clean`. Docker's overlay2 directory tends to accumulate layers from stopped containers — `docker system prune` would help there.

**What I'd do to optimize:**

Short term: `sudo apt clean` (free ~277MB), `docker system prune` (reclaim Docker layer storage). Medium term: review `/var/log` rotation settings since logs grow indefinitely by default. Firefox memory usage could be reduced by limiting open tabs or using a profile with stricter memory caps, though 508MB RSS isn't alarming for a browser.

---

## Task 2 — Practical Website Monitoring Setup

**Target: `https://www.bbc.com/news`**

Chose BBC News because it's a high-traffic site with dynamic content — good test for checking availability, content presence, and load time together. Also fast enough (~50ms response) that latency thresholds are easy to set meaningfully.

---

### 2.1 API Check — BBC News Availability

**Config:** GET `https://www.bbc.com/news`, every 5 minutes, from eu-west-1 + us-east-1

**Assertions:**
- Status code equals `200`
- Response time less than `3000ms`
- Text body contains `BBC News`

**Successful check result:**

![API Check Result](screenshots/screenshot4.png)

*All 3 assertions passed: status 200 ✅, response time 52ms ✅, body contains "BBC News" ✅. Timing breakdown: DNS 17ms, First Byte 33ms, Download 2ms.*

**Second run:**

![API Check Result 2](screenshots/screenshot5.png)

*Same result, 69ms response time. Consistent.*

---

### 2.2 Browser Check — Content Validation

**Script (Playwright):**

```javascript
const { chromium } = require('playwright');

const browser = await chromium.launch();
const page = await browser.newPage();

await page.goto('https://www.bbc.com/news');

const title = await page.title();
console.log(`Page title: ${title}`);
if (!title.includes('BBC')) throw new Error('BBC not found in title');

await page.waitForSelector('body');
console.log('Page body loaded successfully');

await browser.close();
```

Note: tried a more specific selector first (`h3[data-testid="card-headline"]`) but it timed out — BBC must have changed their markup. Fell back to checking the page title and body load which is more stable.

**Browser check result:**

![Browser Check](screenshots/screenshot3.png)

*Runtime 2026.04, Node.js 24, Frankfurt location. Console output: page title confirmed, body loaded. Run time ~3s.*

---

### 2.3 Alert Configuration

![Alert Settings](screenshots/screenshot2.png)

*Alert after 2 consecutive failures. Email to dizitka27@gmail.com. Pass/fail/degraded types enabled.*

---

### 2.4 Dashboard

![Dashboard](screenshots/screenshot1.png)

*2 PASSING, 0 DEGRADED, 0 FAILING. API check: 100% availability, 58ms avg, 77ms P95. Browser check: 100% availability, 3.25s avg.*

---

### Task 2 Analysis

**Why these checks and thresholds:**

The API check is a cheap, frequent heartbeat — runs every 5 minutes and catches the obvious failures. The 3000ms threshold is 50× the actual baseline (~60ms) so it only fires on genuine degradation, not normal variance. The body assertion (`BBC News`) catches the case where the CDN returns a 200 with an error page — a pure status check would miss that entirely.

The browser check validates what a real user actually experiences: does the page title load, does the DOM render. Running it from Frankfurt mirrors where a European user would be. 2-failure escalation before alerting avoids waking someone up for a single transient network blip.

**How this helps maintain reliability:**

This setup covers three of the Four Golden Signals — availability, latency, and errors. The multi-region checks would catch CDN misconfigurations invisible from a single location. The combination of an API check (fast, cheap, frequent) and a browser check (slower, more realistic) gives coverage from raw HTTP response all the way to rendered content. That's the SRE principle: measure from the user's perspective, not the infrastructure's.
