# Lab 8 — Site Reliability Engineering (SRE)

## Task 1 — Key Metrics for SRE and System Analysis

### 1.1: Monitor System Resources

For this task I collected system resource metrics for CPU, memory, and disk I/O. Since my machine is running macOS, I used native monitoring commands instead of `htop`/`iostat` from Ubuntu. The goal was the same: identify the main resource consumers and analyze whether the system has any bottlenecks.

---

### CPU Usage

**Command used:**
```bash
ps -arcwwwxo pid,%cpu,%mem,comm | head
```

**Output:**
```text
  PID  %CPU %MEM COMM
24853  36.1  0.5 v2RayTun
  385  23.2  0.7 WindowServer
 5729  18.8 38.0 com.apple.Virtualization.VirtualMachine
```

#### Top 3 CPU-consuming applications

| Rank | Process | CPU Usage | Description |
|----:|---------|----------:|-------------|
| 1 | `v2RayTun` | 36.1% | VPN/proxy client processing encrypted network traffic |
| 2 | `WindowServer` | 23.2% | macOS display compositor responsible for rendering windows |
| 3 | `com.apple.Virtualization.VirtualMachine` | 18.8% | Virtual machine process consuming CPU for guest OS operations |

**Observation:**  
The highest CPU usage is caused by networking, graphical rendering, and virtualization. This is expected because a VPN client encrypts/decrypts traffic, `WindowServer` is active during desktop usage, and the virtual machine requires host CPU resources.

---

### Memory Usage

**Command used:**
```bash
ps -amcwwwxo pid,%cpu,%mem,comm | head
```

**Output:**
```text
  PID  %CPU %MEM COMM
28492   1.5  3.3 Code Helper (Plugin)
16570   0.1  2.6 AMessenger Helper (Renderer)
24335   4.7  2.5 Telegram
```

#### Top 3 memory-consuming applications

| Rank | Process | Memory Usage | Description |
|----:|---------|-------------:|-------------|
| 1 | `Code Helper (Plugin)` | 3.3% | VS Code extension/plugin host process |
| 2 | `AMessenger Helper (Renderer)` | 2.6% | Renderer process of a messenger application |
| 3 | `Telegram` | 2.5% | Telegram desktop client with cached media and UI state |

**Observation:**  
The largest memory consumers are mostly desktop applications based on multi-process architectures. VS Code and messenger applications usually create separate helper/renderer processes, which increases memory usage.

---

### I/O Usage

**Command used:**
```bash
iostat 1 5
```

**Output:**
```text
disk0       cpu    load average
    KB/t  tps  MB/s  us sy id   1m   5m   15m
   16.75   63  1.02  12  6 82  4.30 4.40 4.61
   26.00    6  0.15  11  5 84  4.30 4.40 4.61
   16.00    7  0.11  11  5 85  4.04 4.35 4.59
   14.51  902 12.77  13  5 82  4.04 4.35 4.59
   15.00  139  2.04  10  3 87  4.04 4.35 4.59
```

#### I/O analysis

| Metric | Observed value |
|--------|----------------|
| Disk throughput | Around `0.11 MB/s` to `12.77 MB/s` |
| Peak transactions per second | `902 tps` |
| CPU idle time | Around `82–87%` |
| Load average | Around `4.0–4.6` |

**Top I/O activity summary:**

Unlike CPU and memory, this `iostat` output shows device-level activity rather than per-process I/O usage. Based on the system activity at the time of measurement, the likely I/O contributors were:

| Rank | Source | Reason |
|----:|--------|--------|
| 1 | Virtual machine process | VM disk image reads/writes can create short I/O bursts |
| 2 | Browser / Chrome framework | Browser cache and background updates may access disk |
| 3 | Messaging / development apps | Telegram, messenger, and VS Code can write cache, logs, and extension data |

**Observation:**  
The system is not I/O bottlenecked. CPU idle time stayed high at `82–87%`, and disk throughput was low to moderate. There was one burst of `902 tps` and `12.77 MB/s`, but it was short and did not cause high CPU wait or system saturation.

---

## 1.2: Disk Space Management

### Disk Usage Overview

**Command used:**
```bash
df -h
```

**Output:**
```text
Filesystem        Size    Used   Avail Capacity  Mounted on
/dev/disk3s1s1   926Gi    17Gi   653Gi     3%    /
/dev/disk3s5     926Gi   234Gi   653Gi    27%    /System/Volumes/Data
```

#### Disk usage summary

| Mount point | Size | Used | Available | Capacity |
|-------------|-----:|-----:|----------:|---------:|
| `/` | 926Gi | 17Gi | 653Gi | 3% |
| `/System/Volumes/Data` | 926Gi | 234Gi | 653Gi | 27% |

**Observation:**  
The disk has enough free space. The main data volume uses only `27%`, leaving approximately `653Gi` available.

---

### Top Directories in `/var`

**Command used:**
```bash
du -h /private/var | sort -rh | head -n 10
```

**Output:**
```text
3.2G    /private/var/folders
2.0G    /private/var/db
1.0G    /private/var/vm
357M    /private/var/tmp
 83M    /private/var/log
 37M    /private/var/protected
```

#### Largest `/var` directories

| Rank | Directory | Size | Purpose |
|----:|-----------|-----:|---------|
| 1 | `/private/var/folders` | 3.2G | User and application caches/temp files |
| 2 | `/private/var/db` | 2.0G | System databases and metadata |
| 3 | `/private/var/vm` | 1.0G | Virtual memory and sleep image files |
| 4 | `/private/var/tmp` | 357M | Temporary files |
| 5 | `/private/var/log` | 83M | System and application logs |

---

### Top 3 Largest Files in `/var`

**Command used:**
```bash
sudo find /private/var -type f -exec du -h {} + | sort -rh | head -n 3
```

**Output:**
```text
1.0G    /private/var/vm/sleepimage
445M    /private/var/folders/.../Google Chrome Framework.framework/Versions/146.0.7680.80/Google Chrome Framework
445M    /private/var/folders/.../Google Chrome Framework.framework/Versions/146.0.7680.76/Google Chrome Framework
```

#### Top 3 largest files

| Rank | File | Size | Description |
|----:|------|-----:|-------------|
| 1 | `/private/var/vm/sleepimage` | 1.0G | Hibernation/sleep image used by macOS |
| 2 | `Google Chrome Framework` version `146.0.7680.80` | 445M | Chrome framework binary |
| 3 | `Google Chrome Framework` version `146.0.7680.76` | 445M | Older Chrome framework binary remaining after update |

---

## Analysis: Resource Utilization Patterns

The collected metrics show that the system is generally healthy and not overloaded.

1. **CPU usage is concentrated in a few processes**
   - `v2RayTun` uses the most CPU because VPN/proxy software performs encryption, decryption, and traffic routing.
   - `WindowServer` has noticeable CPU usage due to graphical rendering.
   - The virtual machine process also consumes CPU, which is expected when a guest OS is running.

2. **Memory usage is mostly caused by desktop applications**
   - VS Code helper processes and messenger clients consume memory separately.
   - Electron-based applications often use multiple renderer/helper processes, so their total memory usage can be higher than it looks from a single process.

3. **Disk I/O is moderate**
   - Disk throughput is mostly low, with one short burst.
   - CPU idle time remains high, so the system is not waiting heavily on disk operations.
   - There is no clear sign of I/O saturation.

4. **Disk space is not a critical issue**
   - The data volume is only `27%` used.
   - `/private/var/folders` and `/private/var/db` are the largest directories in `/var`.
   - Duplicate Chrome framework files and the sleep image are the biggest individual files found.

---

## Reflection: Resource Optimization Recommendations

Based on the findings, I would optimize the system in the following ways:

1. **Monitor or reduce VPN CPU usage**
   - `v2RayTun` is the highest CPU consumer.
   - If high CPU usage is constant, I would check VPN configuration, change protocol/settings, update the client, or use a lighter alternative.

2. **Close unused Electron-based applications**
   - VS Code, messengers, and Telegram consume memory through multiple processes.
   - Closing unused windows or disabling unnecessary VS Code extensions would reduce RAM usage.

3. **Review running virtual machines**
   - The virtual machine consumes both CPU and a large amount of memory.
   - If it is not needed, pausing or shutting it down would free significant resources.

4. **Clean temporary and cache files carefully**
   - `/private/var/folders` contains cache and temporary data.
   - I would not delete system directories manually without checking, but rebooting or clearing application caches can reduce usage.

5. **Remove outdated Chrome framework files**
   - Two Chrome framework versions were found.
   - Removing the older version through browser update cleanup or reinstalling Chrome can reclaim around `445M`.

6. **Consider disabling hibernation only if appropriate**
   - `/private/var/vm/sleepimage` uses `1.0G`.
   - If hibernation is not needed, it can be disabled, but this should be done carefully because it changes sleep behavior.

---

# Task 2 — Practical Website Monitoring Setup

## 2.1: Website Chosen

**Website URL:**
```text
https://innopolis.university
```

**Reason for choosing this website:**  
I chose the Innopolis University website because it is relevant to the course and contains important information for students, applicants, and staff. Monitoring this website is useful because downtime or slow response time can affect access to university announcements, admission information, and educational resources.

---

## 2.2: Checkly Monitoring Configuration

For website monitoring I used Checkly and configured two types of checks:

1. **API Check** for basic availability
2. **Browser Check** for user-facing page validation and performance

---

### API Check — Basic Availability

**Configuration:**

| Setting | Value |
|--------|-------|
| Check type | API Check |
| URL | `https://innopolis.university` |
| Method | `GET` |
| Assertion | HTTP status code equals `200` |
| Frequency | Every 5 minutes |
| Locations | EU West, US East |

**Purpose:**  
The API check verifies that the website is reachable and returns a successful HTTP response. This is the fastest way to detect complete downtime, server errors, or DNS/connectivity issues.

---

### Browser Check — Content and Interaction Validation

**Configuration:**

| Setting | Value |
|--------|-------|
| Check type | Browser Check |
| Tool | Playwright |
| Target URL | `https://innopolis.university` |
| Main performance expectation | Page loads within 5 seconds |
| Content validation | University name/logo is visible |
| Interaction validation | Navigation menu can be opened/clicked |
| Rendering validation | Main content section appears correctly |

**Example Playwright check logic:**
```javascript
const { test, expect } = require('@playwright/test');

test('Innopolis University homepage is available and usable', async ({ page }) => {
  const response = await page.goto('https://innopolis.university', {
    waitUntil: 'domcontentloaded',
    timeout: 5000
  });

  expect(response.status()).toBe(200);

  await expect(page.locator('body')).toContainText(/Innopolis|University/i);

  const nav = page.locator('nav').first();
  await expect(nav).toBeVisible();

  await page.locator('a').first().click();
});
```

**Purpose:**  
The browser check validates the website from a real user perspective. A site can return status code `200` but still be broken visually or functionally. This check confirms that the homepage loads, content is visible, and basic navigation works.

---

## 2.3: Alert Configuration

### Alert rules

| Alert Rule | Threshold | Notification Channel |
|-----------|-----------|----------------------|
| Failed availability check | 2 consecutive failures | Email |
| High response time / slow page load | More than `5000 ms` | Email |
| SSL certificate expiry | Less than 14 days remaining | Email |

### Why these thresholds were chosen

1. **2 consecutive failures**
   - A single failed check may be caused by temporary network problems.
   - Waiting for 2 consecutive failures reduces false positives and alert fatigue.

2. **5 second latency threshold**
   - A page that takes more than 5 seconds to load provides poor user experience.
   - This threshold helps detect performance degradation before users start reporting issues.

3. **14-day SSL certificate warning**
   - SSL certificate expiration can make the website inaccessible or untrusted by browsers.
   - A 14-day warning gives enough time to renew or fix certificate problems.

---

## 2.4: Screenshots

The following screenshots were added to the repository as proof of Checkly configuration and successful execution.

### Browser Check Configuration

![Browser Check Configuration](screenshots/check.png)

### Successful Check Result and Dashboard Overview

![Successful Check Result and Dashboard](screenshots/dashboard.png)

### Alert Settings

![Alert Settings](screenshots/alerts.png)

---

## Analysis: Why These Checks and Thresholds?

I selected both API and browser checks because they cover different reliability levels.

1. **API check covers availability**
   - It quickly verifies whether the site responds with HTTP `200`.
   - This is useful for detecting downtime, server errors, DNS failures, or routing problems.

2. **Browser check covers real user experience**
   - It verifies that the page actually renders useful content.
   - It catches problems that a simple HTTP check may miss, for example blank pages, broken JavaScript, missing main content, or broken navigation.

3. **Latency threshold covers performance**
   - Availability alone is not enough.
   - A slow website can still technically be “up”, but from the user’s point of view it is unreliable.
   - The 5 second threshold provides a practical boundary for acceptable homepage loading time.

4. **SSL alert prevents avoidable outages**
   - Expired certificates can cause browser warnings and block users from accessing the website.
   - Monitoring SSL expiry is a simple but important reliability practice.

---

## Reflection: How This Monitoring Setup Helps Maintain Reliability

This Checkly setup improves website reliability by detecting problems before users need to report them.

It also maps well to the main SRE monitoring ideas:

| SRE Signal | How it is monitored |
|-----------|---------------------|
| Latency | Browser check and response time threshold |
| Traffic | Checkly dashboard shows check executions and response patterns |
| Errors | API check detects non-200 responses and failed browser tests |
| Saturation | Slow response time may indicate overloaded backend or infrastructure |

The configured alerts reduce **Mean Time To Detect (MTTD)**. Since checks run every 5 minutes and alerts trigger after 2 consecutive failures, serious availability problems should be detected in about 10 minutes. This makes it possible to react faster, reduce downtime, and improve the overall reliability of the monitored website.
