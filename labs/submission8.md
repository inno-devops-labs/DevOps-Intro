# Lab 8 Submission — Site Reliability Engineering (SRE)

**Student:** Diana Minnakhmetova  
**Date:** 22-03-2026

---

## Task 1 — Key Metrics for SRE and System Analysis (4 pts)

[X] Top 3 most consuming applications for CPU, memory, and I/O usage

[X] Command outputs showing resource consumption

[X] Top 3 largest files in the /var directory

[X] Analysis: What patterns do you observe in resource utilization?

[X] Reflection: How would you optimize resource usage based on your findings? 


### 1.1: Monitor System Resources

#### System Information
- **OS:** macOS (Apple Silicon)
- **Machine:** MacBook Air
- **Date:** 2026-03-22
- **Tools:** Activity Monitor, Terminal Commands

---

### Top 3 CPU Consumers

**Observed Processes (by % CPU usage):**

1. **deleted** — 79.5% ЦП (9:51:08 uptime)
2. **contactsd** — 38.0% ЦП (32:32:39 uptime)
3. **WindowServer** — 31.0% ЦП (18:17:26,13 uptime)

![CPU Monitoring](https://github.com/user-attachments/assets/7435efa5-a319-4b77-8c56-3ab4a38f34d2)

---

### Top 3 Memory Consumers

**Observed Processes (by Memory usage):**

1. **exchangesyncd** — 1.52 ГБ
2. **WindowServer** — 1.22 ГБ
3. **Google Chrome Helper** — 1.05 ГБ

![Memory Monitoring](https://github.com/user-attachments/assets/cd512258-eeb2-4ed5-873e-e39e5b2ba407)

---

### Disk Space Management

#### 1.2.1: Overall Disk Usage

```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % df -h
Filesystem                                                  Size    Used   Avail Capacity iused ifree %iused  Mounted on
/dev/disk3s1s1                                             228Gi    17Gi    10Gi    63%    426k  107M    0%   /
devfs                                                      215Ki   215Ki     0Bi   100%     742     0  100%   /dev
/dev/disk3s6                                               228Gi   7,0Gi    10Gi    41%       7  107M    0%   /System/Volumes/VM
/dev/disk3s2                                               228Gi    15Gi    10Gi    60%    2,0k  107M    0%   /System/Volumes/Preboot
/dev/disk3s4                                               228Gi   742Mi    10Gi     7%     334  107M    0%   /System/Volumes/Update
/dev/disk1s2                                               500Mi   6,0Mi   483Mi     2%       1  4,9M    0%   /System/Volumes/xarts
/dev/disk1s1                                               500Mi   5,6Mi   483Mi     2%      34  4,9M    0%   /System/Volumes/iSCPreboot
/dev/disk1s3                                               500Mi   1,1Mi   483Mi     1%      69  4,9M    0%   /System/Volumes/Hardware
/dev/disk3s5                                               228Gi   177Gi    10Gi    95%    2,1M  107M    2%   /System/Volumes/Data
map auto_home                                                0Bi     0Bi     0Bi   100%       0     0     -   /System/Volumes/Data/home
/dev/disk2s1                                               5,0Gi   2,0Gi   3,0Gi    41%      67   31M    0%   /System/Volumes/Update/SFR/mnt1
/Users/dminnakhmetova/Downloads/Visual Studio Code 3.app   228Gi   170Gi    31Gi    85%    2,0M  323M    1%   /private/var/folders/lw/v70xk9rs1ls81fvjkhjryscw0000gn/T/AppTranslocation/9650474D-1B38-4C06-9704-4F42F7F76634
/dev/disk3s1                                               228Gi    17Gi    10Gi    63%    455k  107M    0%   /System/Volumes/Update/mnt1
```

**Key Finding:** `/System/Volumes/Data` uses **177Gi from 228Gi** (95% capacity!).

---

#### 1.2.2: Largest Directories in Home

```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % du -h ~ 2>/dev/null | sort -rh | head -n 10
 94G    /Users/dminnakhmetova
 69G    /Users/dminnakhmetova/Library
 49G    /Users/dminnakhmetova/Library/Containers
 43G    /Users/dminnakhmetova/Library/Containers/com.docker.docker/Data/vms/0/data
 43G    /Users/dminnakhmetova/Library/Containers/com.docker.docker/Data/vms/0
 43G    /Users/dminnakhmetova/Library/Containers/com.docker.docker/Data/vms
 43G    /Users/dminnakhmetova/Library/Containers/com.docker.docker/Data
 43G    /Users/dminnakhmetova/Library/Containers/com.docker.docker
 13G    /Users/dminnakhmetova/Downloads
 12G    /Users/dminnakhmetova/Library/Application Support
```

---

#### 1.2.3: Top 3 Largest Files

```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % find ~ -type f -exec du -h {} + 2>/dev/null | sort -rh | head -n 3
 43G    /Users/dminnakhmetova/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw
1,8G    /Users/dminnakhmetova/Library/Containers/com.apple.photolibraryd/Data/tmp/PHAssetCreationRequestPlaceholderSupport-D23B5D3F-E207-453F-81A9-FF6CB2BF2971/BF051A8E-621B-4A73-8E74-CE1583E83571.mov
1,5G    /Users/dminnakhmetova/Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram/appstore/account-8151880982903072430/postbox/db/db_sqlite
```

---

## Analysis: Resource Utilization Patterns

### Key Observations:

1. **CPU Usage Pattern:**
   - **`deleted` process** dominates with 79.5% — background process or system clearing
   - **`contactsd`** (38%) — contacts synchronization, ok for macOS
   - **`WindowServer`** (31%) — grafical serever

2. **Memory Usage Pattern:**
   - **exchangesyncd** (1.52GB) — sync Exchange/iCloud
   - **WindowServer** (1.22GB) — graphic interface
   - **Chrome Helper** (1.05GB) — browser
   - **Total Used:** ~6.98GB from 8GB (87%)

3. **Disk Space Crisis:**
   - **Docker** takes **43GB** (Docker.raw file)
   - **Library/Containers** = **49GB** — apps and their data
   - **Downloads** = **13GB** — just files
   - **Available Space:** only **10GB**  :( (assignments make me sad)

---

## Optimization Recommendations

### Immediate Actions:

1. **Clean Docker Storage:**
   ```bash
   docker system prune -a --volumes
   ```
   Может освободить 10-20GB.

2. **Empty Downloads & Trash:**
   ```bash
   rm -rf ~/Downloads/*
   rm -rf ~/.Trash/*
   ```

3. **Clean Photo Library Temp:**
   ```bash
   rm -rf ~/Library/Containers/com.apple.photolibraryd/Data/tmp/*
   ```

### Long-term Optimization:

- **Memory:** Chrome takes a lot of RAM, maybe take another browser
- **CPU:** turn off background processes which are not needed
- **Disk:** move archives to the external drive

---

## Reflection

**How would you optimize resource usage based on your findings?**

Docker is my biggest consumer. Costs:
- Regularly clean Docker images (`docker image prune`)
- Limit CPU/RAM for Docker VM in preferences
- Use Colima (lightweight Docker) instead of Docker Desktop for macOS

Exchange/iCloud sync can be configured for a shorter interval so that it does not constantly consume the CPU.

Chrome helper - I will transfer it to Safari for background tabs, I will leave Chrome only for dev tools.

---

# Task 2 — Practical Website Monitoring Setup

### 2.1: Target Website

**URL:** `https://skillgrade.pw`

**Why this website?**
SkillGrade is a real production platform for product manager certification. Monitoring it ensures that users can always access the service and that key functionality remains available. It is an excellent SRE monitoring target because real users depend on its availability.

---

### 2.2: API Check — Basic Availability

**Configuration:**
- **Check Name:** `API Check #1`
- **URL:** `https://skillgrade.pw`
- **Method:** GET
- **Assertion:** Status code equals 200
- **Locations:** Frankfurt 🇩🇪, London 🇬🇧
- **Frequency:** Every 10 minutes

**Results:**
- Availability: **100%**
- P50 Response Time: **242 ms**
- P95 Response Time: **245 ms**
- Failed checks: **0**

![API Check Result](https://github.com/user-attachments/assets/37426c6d-2496-467a-a5e2-87fef979750a)

---

### 2.3: Browser Check — Content & Interactions

**Configuration:**
- **Check Name:** `SG browser check`
- **URL:** `https://skillgrade.pw`
- **Check Type:** Browser Check (Playwright)
- **Frequency:** Every 10 minutes

**What is tested:**
1. Page title contains "SkillGrade"
2. Main content area (`main` / `body`) is visible
3. Page contains more than 3 links (content loaded)
4. Page body text length > 50 characters (not blank page)

**Script:**
```javascript
import { test, expect } from '@playwright/test';

test('SkillGrade homepage loads correctly', async ({ page }) => {
  await page.goto('https://skillgrade.pw', { 
    waitUntil: 'domcontentloaded',
    timeout: 30000 
  });

  await expect(page).toHaveTitle(/SkillGrade/i);
  await expect(page.locator('main, body').first()).toBeVisible();

  const linkCount = await page.locator('a').count();
  expect(linkCount).toBeGreaterThan(3);

  const bodyText = await page.locator('body').innerText();
  expect(bodyText.length).toBeGreaterThan(50);

  console.log(`SkillGrade loaded ✅ Found ${linkCount} links`);
});
```

**Results:**
- All test steps passed ✅
- Total runtime: **4.7 seconds**
- Locations: Frankfurt 🇩🇪

> Note: Browser check availability shows 50% in the 24h view due 
> to earlier debugging runs during initial configuration. 
> The final version of the check passes consistently.

![browser check](https://github.com/user-attachments/assets/810da387-0fdd-44f3-b6db-f40252d390fd)

---

### 2.4: Alert Settings

**Alert Channel:** Email  
**Email:** diana@ivor.pw

**Notification triggers:**
| Event | Enabled |
|-------|---------|
| Check fails | ✅ |
| Check recovers | ✅ |
| Check degrades | ❌ |
| SSL certificate expires in 30 days | ✅ |

**Subscribed checks:**
- API Check #1 ✅
- SG browser check ✅

![alert channel](https://github.com/user-attachments/assets/085395c0-ec89-4e95-8682-84e3590cca97)

---

### 2.5: Dashboard Overview

**Dashboard:** DevOps — Lab 8  
**Status:** ✅ All checks passing

| Check | Availability | P95 |
|-------|-------------|-----|
| API Check #1 | 100% | 1.32 s |
| SG browser check | 50%* | 12.53 s |

*50% due to debugging runs during setup, final check passes consistently.

![dashboard](https://github.com/user-attachments/assets/865ce6ca-ebe3-4e76-a16f-c286c29f420c)

---

### Analysis: Why These Checks and Thresholds?

**API Check** covers the most fundamental reliability signal — 
is the server responding? A status 200 assertion ensures the 
site is not returning errors. 10-minute frequency balances 
monitoring coverage with free plan limits.

**Browser Check** goes beyond server health — it validates that 
real users can actually see content. This catches frontend 
failures (broken JS, empty pages) that API checks miss entirely.

**SSL Alert (30 days)** prevents certificate expiry surprises — 
a common cause of unexpected downtime that is easy to forget.

These checks map directly to the **Four Golden Signals:**
| Signal | Covered by |
|--------|-----------|
| Latency | P50/P95 response times in API Check |
| Errors | Status code 200 assertion |
| Availability | 100% uptime tracking |
| User functionality | Browser check content validation |

---

### Reflection: How Does This Monitoring Help?

Without monitoring, downtime is discovered only when users 
complain — which means the problem already exists for minutes 
or hours. This setup provides:

- **Proactive detection** — checks run automatically every 10 min
- **Two-layer coverage** — API (server) + Browser (user experience)
- **Instant alerting** — email on first failure, recovery confirmed
- **Global perspective** — checks from Frankfurt and London 
  catch regional issues

This is exactly the SRE principle of "monitoring user-facing 
symptoms, not just internal causes" — we check what the user 
sees, not just whether the server is running.
```
