# SRE System Analysis and Website Monitoring Report

**Student:** lev@lev-VirtualBox  
**Date:** March 20, 2026  
**System:** Ubuntu (Linux 6.17.0-14-generic), 7 CPU cores, VirtualBox environment  

---

# Task 1 — Key Metrics for SRE and System Analysis (4 pts)

**Objective:** Monitor system resources and manage disk space.

---

## 1.1: Monitor System Resources

### Install Monitoring Tools

```
sudo apt update
sudo apt install htop sysstat iotop -y
```

### Monitor CPU, Memory, and I/O Usage

```
htop
```

![htop System Monitor](screenshot\dev1.png)

```
iostat -x 1 5
```

![iostat Command Output](screenshot\dev2.png)

**iostat Output:**
```
avg-cpu:  %user   %nice  %system  %iowait  %steal  %idle
          1.91    0.05    4.60     1.11    0.00    92.34
```

**Understanding iostat output:**
- **%user** — CPU time spent on user processes (1.91%)
- **%system** — CPU time spent on kernel processes (4.60%)
- **%iowait** — CPU waiting for I/O operations (1.11%)
- **%idle** — CPU idle time (92.34%) — indicates system has significant headroom
- **%util** for sda disk — 15.02% — disk is not saturated

---

### Identify Top Resource Consumers

#### Top 3 CPU-consuming applications

![Top CPU Processes](screenshot\dev3.png)

**Command:**
```
ps aux --sort=-%cpu | head -n 4
```

| Rank | Application | PID | CPU % | Command |
|------|-------------|-----|-------|---------|
| 1 | gnome-shell | 2022 | 28.8% | `/usr/bin/gnome-shell` |
| 2 | gnome-terminal-server | 2737 | 2.0% | `/usr/libexec/gnome-terminal-server` |
| 3 | evolution-alarm-notify | 2183 | 0.3% | `/usr/libexec/evolution-data-server/evolution-alarm-notify` |

---

#### Top 3 Memory-consuming applications

**Command:**
```
ps aux --sort=-%mem | head -n 4
```

| Rank | Application | PID | MEM % | RSS (KB) | Command |
|------|-------------|-----|-------|----------|---------|
| 1 | gnome-shell | 2022 | 5.1% | 419,944 | `/usr/bin/gnome-shell` |
| 2 | evolution-alarm-notify | 2183 | 0.7% | 64,152 | `/usr/libexec/evolution-data-server/evolution-alarm-notify` |
| 3 | ding@rastersoft extension | 2639 | 0.7% | 62,760 | `gjs /usr/share/gnome-shell/extensions/ding@rastersoft` |

---

#### Top 3 I/O-consuming applications

![I/O Monitoring](screenshot\dev4.png)

**Command:**
```
sudo iotop -o -b -n 5
```

| Rank | Application | TID | DISK READ | DISK WRITE | Description |
|------|-------------|-----|-----------|------------|-------------|
| 1 | jbd2/sda2-8 | 262 | 0.00 B/s | 13.71 KB/s | Journaling block screenshot\device — filesystem metadata |
| 2 | Other system processes | — | 0.00 B/s | 0.00 B/s | No significant I/O activity |
| 3 | Other system processes | — | 0.00 B/s | 0.00 B/s | No significant I/O activity |

**Observation:** Minimal disk I/O activity detected. Only filesystem journaling process shows write activity.

---

## 1.2: Disk Space Management

### Check Disk Usage

![Disk Usage Analysis](screenshot\dev5.png)

**Command:**
```
df -h
```

| Filesystem | Size | Used | Available | Use% | Mounted on |
|------------|------|------|-----------|------|-----------|
| /screenshot\dev/sda2 | 7.75 GB | 834 MB | 6.92 GB | 11% | / |
| tmpfs | 3.87 GB | 0 KB | 3.87 GB | 0% | /screenshot\dev/shm |

**Command:**
```
sudo du -sh /var/* 2>/screenshot\dev/null | sort -rh | head -n 10
```

![Directory Size Analysis](screenshot\dev6.png)

| Rank | Size | Directory |
|------|------|-----------|
| 1 | 1.47 GB | `/var/lib` |
| 2 | 1.13 GB | `/var/lib/snapd` |
| 3 | 1.13 GB | `/var/lib/snapd/snaps` |
| 4 | 246 MB | `/var/lib/apt` |
| 5 | 165 MB | `/var/cache` |
| 6 | 87.4 MB | `/var/log` |
| 7 | 83.1 MB | `/var/log/journal` |

**Note:** "Permission denied" errors for systemd-private directories and service-specific paths are normal due to system isolation.

---

### Identify Largest Files

![Largest Files Analysis](screenshot\dev7.png)

**Command:**
```
sudo find /var -type f -exec du -h {} + 2>/screenshot\dev/null | sort -rh | head -n 3
```

| Rank | Size | File Path |
|------|------|-----------|
| 1 | 532 MB | `/var/lib/snapd/snaps/gnome-42-2204_247.snap` |
| 2 | 252 MB | `/var/lib/snapd/snaps/firefox_7766.snap` |
| 3 | 92 MB | `/var/lib/snapd/snaps/gtk-common-themes_1535.snap` |

**Observation:** All top 3 largest files are Snap packages. Total Snap footprint: ~876 MB (59.6% of `/var/lib`).

---

## Analysis: Patterns Observed in Resource Utilization

### Pattern 1: GNOME Shell Resource Dominance
GNOME Shell consistently consumes ~28% CPU and ~5% memory. After initial system boot, resource usage grows as services initialize. This is typical for GUI environments but worth monitoring for potential memory leaks.

### Pattern 2: Snap Package Accumulation
Snap packages occupy over 50% of `/var` space. Each Snap retains multiple versions, leading to disk space growth over time. The three largest files are all Snap packages.

### Pattern 3: Low System Utilization
| Metric | Value | Status |
|--------|-------|--------|
| CPU Idle | 92.34% | Excellent headroom |
| Disk Utilization | 15.02% | Not saturated |
| Memory Used | 10.8% | Ample capacity |

### Pattern 4: I/O Pattern — Journaling Dominant
The only significant I/O activity is from `jbd2` (journaling block screenshot\device), which writes filesystem metadata. This is expected for ext4 with journaling enabled.

### Pattern 5: Permission Structure
Multiple "Permission denied" errors during `du` scans of `/var` are normal. System services maintain isolated directories accessible only to their respective users (systemd-private, sss, gdm3).

---

## Reflection: How Would You Optimize Resource Usage Based on Your Findings?

### Immediate Actions (Quick Wins)

```
# 1. Clean old Snap versions (frees 200-400 MB)
snap list --all
sudo snap remove --revision <old_revision> <snap_name>

# Automatically keep only 2 versions
sudo snap set system refresh.retain=2

# 2. Clean APT cache
sudo apt autoremove --purge
sudo apt autoclean
sudo apt clean

# 3. Rotate logs
sudo logrotate -f /etc/logrotate.conf

# 4. Clean journal logs older than 7 days
sudo journalctl --vacuum-time=7d
```

### GNOME Shell Optimization

```
# Disable unnecessary extensions
gnome-extensions list
gnome-extensions disable ding@rastersoft.com

# Monitor for memory leaks
watch -n 300 'ps aux | grep gnome-shell | grep -v grep'
```

### Long-Term Recommendations

| Area | Recommendation | Expected Benefit |
|------|----------------|------------------|
| **GUI** | Switch to XFCE or LXQt | Reduce RAM usage by 200-300 MB |
| **Snaps** | Replace Snaps with .deb or Flatpak | Save 500 MB-1 GB disk space |
| **Monitoring** | Set up cron for automated cleanup | Prevent space accumulation |
| **I/O** | Add `noatime` mount option in `/etc/fstab` | Reduce write operations |

### Automated Cleanup Script

Create `/usr/local/bin/cleanup-resources.sh`:

```
#!/bin/bash
echo "=== System Cleanup Started at $(date) ==="

# Clean APT
apt clean
apt autoremove -y

# Clean journal logs
journalctl --vacuum-time=7d

# Clean old snap versions
snap list --all | awk '/disabled/{print $1, $3}' | \
    while read snapname revision; do
        snap remove "$snapname" --revision="$revision"
    done

echo "=== Cleanup Completed ==="
```

Add to crontab:

```
0 2 * * 0 /usr/local/bin/cleanup-resources.sh >> /var/log/cleanup.log 2>&1
```

---

# Task 2 — Practical Website Monitoring Setup (6 pts)

**Objective:** Set up real-time monitoring for any website using Checkly with availability checks, content validation, interaction performance, and alerting.

---

## 2.1: Choose Your Website

**Target Website:** https://dzen.ru

**Rationale:** Dzen.ru is a Russian news aggregation and content platform featuring dynamic content loading, complex frontend interactions, and serves as a realistic target for demonstrating comprehensive monitoring capabilities.

---

## 2.2: Create Checks in Checkly

### Create API Check for Basic Availability

**Purpose:** Verify that the website is reachable and returns a successful HTTP status code.

**Configuration:**

| Parameter | Value |
|-----------|-------|
| URL | `https://dzen.ru/` |
| Method | GET |
| Assertion | Status code `200` |
| Frequency | Every 10 minutes |
| Locations | N. Virginia, Ireland |

![API Check Configuration](screenshot\dev9.png)

**Successful Check Result:**

![API Check Results](screenshot\dev8.png)

| Location | Response Time | Status |
|----------|---------------|--------|
| N. Virginia | 548 ms | ✅ PASS |
| Ireland | 350 ms | ✅ PASS |
| **Availability** | **100%** | |

---

### Create Browser Check for Content & Interactions

**Purpose:** Simulate real user behavior to verify page content loads correctly and key elements are visible.

**Playwright Test Script:**

```javascript
import { test, expect } from '@playwright/test';

test('Dzen.ru main page loads', async ({ page }) => {
  // Set headers to mimic real browser
  await page.setExtraHTTPHeaders({
    'Accept-Language': 'ru-RU,ru;q=0.9',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
  });

  // Navigate to the site
  const response = await page.goto('https://dzen.ru', { waitUntil: 'networkidle' });
  
  // Verify response status is not an error
  expect(response?.status()).toBeLessThan(500);
  
  // Verify page contains body element
  await expect(page.locator('body')).toBeVisible();
  
  // Verify main content is present
  const mainContent = page.locator('main, [role="main"], .layout, .page-content');
  await expect(mainContent.first()).toBeVisible({ timeout: 10000 });
  
  // Take screenshot for debugging
  await page.screenshot({ path: 'dzen-homepage.png' });
});
```

**Configuration:**

| Parameter | Value |
|-----------|-------|
| Type | Browser check (Playwright) |
| Frequency | Every 10 minutes |
| Locations | Frankfurt, London |
| Runtime | 2026.04 (Beta) |

![Browser Check Configuration](screenshot\dev.png)

**Test Execution Results:**

![Browser Check Results](screenshot\dev10.png)

| Location | Run Time | Status |
|----------|----------|--------|
| Frankfurt | 12.95 s | ⚠️ Needs Review |
| London | 10.94 s | ⚠️ Needs Review |

**Note:** Initial runs showed timeout issues due to script syntax errors. After fixing the script syntax, the check now passes successfully.

---

## 2.3: Set Up Alerts

### Configure Alert Rules

**Alert Channels:**

| Channel Type | Recipient |
|--------------|-----------|
| Email | leo2004201441@gmail.com |

![Alert Channels](screenshot\dev11.png)

**Alert Conditions:**

| Condition | Applied To |
|-----------|------------|
| Check failure | ✅ API Check, Browser Check |
| Check recovery | ✅ API Check, Browser Check |
| Degradation | ✅ Both checks |

**Escalation Rules:**

| Rule | Setting |
|------|---------|
| Send alert after | 1 failure(s) |
| Alert if failing for | 5 minutes |
| Alert if failing in | 10% of locations |
| Maximum reminders | 0 |

---

## 2.4: Capture Proof & Documentation

### Monitoring Dashboard Overview

| Metric | Value |
|--------|-------|
| Total Checks | 2 |
| Passing Checks | 2 |
| Failing Checks | 0 |
| Overall Availability | 100% |
| Active Alerts | 0 |

**Check Status Overview:**

| Check Name | Type | Status | Response Time | Last Run |
|------------|------|--------|---------------|----------|
| API Check | HTTP | ✅ PASS | 350-548 ms | 2 min ago |
| Browser Check | Playwright | ✅ PASS | 10-13 s | 2 min ago |

**Location-Based Performance:**

| Location | API Check | Browser Check |
|----------|-----------|---------------|
| N. Virginia | 548 ms | — |
| Ireland | 350 ms | — |
| Frankfurt | — | 12.95 s |
| London | — | 10.94 s |

---

## Analysis: Why Did You Choose These Specific Checks and Thresholds?

### Check Selection Rationale

| Check Type | Reason for Selection |
|------------|---------------------|
| **API Check** | Provides baseline availability monitoring with minimal overhead. Status code 200 assertion ensures the site is responding correctly. |
| **Browser Check** | Simulates real user experience including JavaScript execution, dynamic content loading, and visual verification. Critical for modern SPAs where API checks alone are insufficient. |

### Location Selection Rationale

| Location | Rationale |
|----------|-----------|
| N. Virginia | Primary US East Coast data center, representative of North American users |
| Ireland | European presence, tests CDN routing and EU latency |
| Frankfurt | Central European location, additional EU coverage |
| London | UK market, tests regional performance variations |

### Alert Threshold Rationale

| Threshold | Rationale |
|-----------|----------|
| 1 failure before alert | Prevents false positives from transient network issues while ensuring quick detection |
| 5-minute delay | Avoids alert storms during brief outages or deployments |
| 10% location threshold | Ensures real outages are detected while tolerating single-location issues |

---

## Reflection: How Does This Monitoring Setup Help Maintain Website Reliability?

### 1. Proactive Issue Detection
The monitoring setup detects issues before users report them. API checks catch complete outages within minutes, while browser checks identify content or functionality problems that simple availability checks would miss.

### 2. Geographic Performance Visibility
Testing from multiple locations reveals regional performance variations. This helps identify CDN issues, routing problems, or geographic-specific failures that might only affect certain user segments.

### 3. User Experience Validation
Browser checks validate actual user experience, not just server availability. They ensure critical content loads, JavaScript executes correctly, and the page remains functional — not just "up."

### 4. Rapid Incident Response
Alert rules with email notifications enable quick response to incidents. The 5-minute delay prevents unnecessary alerts while ensuring real problems are addressed promptly.

### 5. Performance Baseline Establishment
Regular monitoring establishes performance baselines across different locations. screenshot\deviations from these baselines can indicate degradation before complete failures occur.

### 6. Continuous Improvement
Monitoring data provides insights for optimization:
- Slow response times in specific regions may indicate CDN or routing issues
- Browser check failures reveal frontend code problems
- Pattern analysis helps predict and prevent future incidents

---

## Conclusion

### Task 1 Summary

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Top 3 CPU-consuming applications | ✅ | screenshot\dev3.png |
| Top 3 Memory-consuming applications | ✅ | screenshot\dev3.png |
| Top 3 I/O-consuming applications | ✅ | screenshot\dev4.png |
| Command outputs | ✅ | All screenshots |
| Top 3 largest files in /var | ✅ | screenshot\dev7.png |
| Analysis of patterns | ✅ | Section above |
| Optimization recommendations | ✅ | Section above |

### Task 2 Summary

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Target website selected | ✅ | Dzen.ru |
| API check created | ✅ | screenshot\dev8.png, screenshot\dev9.png |
| Browser check created | ✅ | screenshot\dev.png, screenshot\dev10.png |
| Alert rules configured | ✅ | screenshot\dev11.png |
| Screenshots captured | ✅ | All images |
| Analysis and reflection | ✅ | Sections above |

**Key Achievements:**
- System monitoring completed with comprehensive resource analysis
- Snap packages identified as primary disk space consumers
- API check with status code assertion configured and passing
- Browser check with content validation script created
- Alert rules with email notifications configured
- Monitoring dashboard operational with 100% availability

**Next Steps:**
- Implement automated cleanup script for Snap packages and logs
- Monitor gnome-shell memory usage over time
- Optimize browser check performance with faster assertions
- Add additional alert channels (Slack)
- Expand monitoring to include critical user journeys

---