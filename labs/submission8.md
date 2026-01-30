# Lab 8 — Site Reliability Engineering (SRE)

## Task 1 — Key Metrics for SRE and System Analysis

### 1.1 Monitoring System Resources

#### 1. CPU and Memory Monitoring (htop)

**Command:** `htop`

**Screenshot:**

![htop cpu screenshot](https://github.com/user-attachments/assets/d31317ac-2010-4899-bca0-d47d62c886e2)

**Top 3 CPU-consuming processes:**
1. `/usr/bin/gnome-shell` — 10.2%  
2. `/usr/lib/xorg/Xorg` — 5.1%
3. `jetbrains-toolbox` — 5.1%

![htop memory screenshot](https://github.com/user-attachments/assets/be7451dd-6ef2-4b08-80a8-42bd53098341)

**Top 3 memory-consuming processes:**
1. `firefox/...` — 3.7%  
2. `firefox/...` — 3.7%  
3. `firefox/...` — 3.7%

**Analysis:**

CPU load is moderate, mostly coming from the graphical environment (gnome-shell, Xorg) and background apps like JetBrains Toolbox.
Memory usage is dominated by several Firefox processes, each handling separate browser components such as tabs or rendering.
All active processes operate within normal limits, and the system remains stable and responsive.

#### 2. Disk I/O Monitoring (iostat -x 1 5)

**Command:** `iostat -x 1 5`

**Excerpt from output:**

```bash
avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           2.58    0.03    1.25    0.03    0.00   96.12

Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
nvme0n1         19.70    982.49     1.58   7.42    0.22    49.88   14.90    566.25    15.52  51.02    1.15    38.02    3.84 104273.12     0.00   0.00    0.29 27142.48    1.17    0.27    0.02   0.48

```

**Top 3 devices by I/O utilization:**
1. `nvme0n1` — %util ≈ 0.48  
2. `loop10` — %util ≈ 0.01  
3. `loop6` — %util ≈ 0.01

**Analysis:**
Disk I/O load is minimal; the main storage device `nvme0n1` shows less than 1 % utilization.
Most loop devices are mounted snap packages with negligible activity.
No I/O bottlenecks were detected.

### 1.2 Disk Space Management

#### 1. Disk Usage Overview

**Command:** `df -h`

**Output:**

```
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           3.1G  2.6M  3.1G   1% /run
/dev/nvme0n1p7  288G   28G  246G  10% /
tmpfs            16G  6.1M   16G   1% /dev/shm
tmpfs           5.0M   16K  5.0M   1% /run/lock
efivarfs        128K   59K   65K  48% /sys/firmware/efi/efivars
/dev/nvme0n1p1  256M   41M  216M  16% /boot/efi
tmpfs           3.1G  168K  3.1G   1% /run/user/1000
```

**Interpretation:**
Root partition (`/`) is only 10 % used; available space is more than sufficient.
No immediate storage issues.

#### 2. Largest Directories in /var

**Command:** `du -h /var | sort -rh | head -n 10`

**Output:**

```bash
3.7G	/var
2.8G	/var/lib
2.5G	/var/lib/snapd
1.3G	/var/lib/snapd/snaps
1.2G	/var/lib/snapd/seed/snaps
1.2G	/var/lib/snapd/seed
621M	/var/cache
573M	/var/cache/apt
460M	/var/cache/apt/archives
301M	/var/log
```

**Analysis:**
Most disk usage comes from snap packages stored in `/var/lib/snapd`.
Caches (`/var/cache/apt`) and logs (`/var/log`) occupy moderate space and can be cleaned safely.

3. **Largest Files in /var**

**Command:** `sudo find /var -type f -exec du -h {} + | sort -rh | head -n 3`

**Output:**

```bash
517M	/var/lib/snapd/snaps/gnome-42-2204_226.snap
517M	/var/lib/snapd/seed/snaps/gnome-42-2204_202.snap
517M	/var/lib/snapd/cache/c3c38b9039608c596b7174b23d37e6cd1bbd7b13dae28ec1a17a31df34bb5598a7f9f69c4171304c7abac9a73e9d2357
```

**Interpretation:**
The three largest files are snap images, each ≈ 517 MB. These belong to GNOME snap packages.

### Findings & Reflection

**Observed patterns:**

- CPU and memory usage are low — the system is mostly idle.
- Disk I/O activity is negligible, confirming that the system has no performance bottlenecks.
- The /var/lib/snapd directory dominates disk usage due to stored snap packages.

**Optimization recommendations:**

1. Remove old or unused snap package revisions:
```bash
sudo snap list --all | grep disabled
sudo snap remove <package> --revision=<revision_number>
```
2. Clean package cache and old logs:
```bash
sudo apt clean
sudo journalctl --vacuum-size=100M
```
3. Continue periodic monitoring with htop and iostat to detect anomalies early.


## Task 2 — Practical Website Monitoring Setup

### 2.1 Target Website

Website: https://innopolis.university/

### 2.2 API Check – Basic Availability

- **Method:** GET
- **Assertion:** Status code equals 200
- **Interval:** Every 2 minutes
- **Locations:** Frankfurt 🇩🇪

**Result:** ✅ Status 200, response time ~80 ms

![API Check result](https://github.com/user-attachments/assets/727cc68e-6a48-403c-8db4-d8c0e01f9f39)

![API timing](https://github.com/user-attachments/assets/2b0145ce-d460-4d9e-8d70-cf7bbf3e1c08)

![API Check Scheduling](https://github.com/user-attachments/assets/4672f286-f051-4d4a-9392-da214cb8b858)

### 2.3 Browser Check — Content & Interactions

**Goal**

Verify the “Информирование о приеме на обучение 2025” link in the Russian version of the Innopolis University site, ensuring that it correctly opens the admissions page in a new tab.

**Playwright (Checkly) script**

```js
const { expect, test } = require('@playwright/test')

test.setTimeout(210000)
test.use({ actionTimeout: 10000 })

test('Check Innopolis University apply link', async ({ page, context }) => {
  // 1. Visit homepage
  const response = await page.goto('https://innopolis.university/')
  expect(response.status(), 'Homepage should respond with a valid status code').toBeLessThan(400)

  // 2. Verify page title
  await expect(page).toHaveTitle(/Университет Иннополис/i)

  // 3. Locate the “Информирование о приеме...” link
  const applyLink = page.locator('text=Информирование о приеме на обучение 2025').first()
  await expect(applyLink).toBeVisible({ timeout: 10000 })

  // 4. Click the link and wait for new tab
  const newPagePromise = context.waitForEvent('page', { timeout: 20000 })
  await applyLink.click()
  const newPage = await newPagePromise

  // 5. Wait for the new tab to load
  await newPage.waitForLoadState('domcontentloaded')

  // 6. Verify that new page has expected URL
  await expect(newPage).toHaveURL(/apply/i)

  // 7. Screenshot the result
  await newPage.screenshot({ path: 'innopolis_apply_page.png', fullPage: true })
})
```

**What this check validates**

- The target text (“Информирование о приеме на обучение 2025”) exists and is visible.
- Clicking it successfully opens the admissions page in a new browser tab.
- The new page loads fully and contains /apply in the URL.
- The test records a full-page screenshot upon success.

**Browser Check Results**

- **Availability:** 100%
- **Median load (P50):** 10.85 s
- **P95:** 11.78 s
- **Errors:** 0
- **Location:** Frankfurt 🇩🇪

![Browser Check](https://github.com/user-attachments/assets/36b55467-5bb0-46ff-a9d7-067734f5f213)

**Analysis**

The browser check simulates a real user path. It verifies that navigation works correctly and that content loads within acceptable latency limits.

#### Screenshot — Dashboard

![Dashboard](https://github.com/user-attachments/assets/09b013bb-a47e-49e7-825a-a338653e7a7b)


### 2.4 Alerts — Configuration and Reasoning

Notification Channel — Email

**Rules**

- Trigger alert if a check is failing for more than 5 minutes
- Send 2 reminders, with 10-minute interval
- SSL expiration warning at 30 days

**Subscribers**
- Browser Check — IU
- https://innopolis.university/

**Screenshots**

![Email alert configuration](https://github.com/user-attachments/assets/9e24a131-d802-4955-9083-10ce0845b209)

![Global alert rules](https://github.com/user-attachments/assets/a348fbf2-8976-4d25-88f0-961c80cdb3d8)

**Rationale**
- A 5-minute window avoids false positives caused by minor network delays.
- Two reminders ensure persistent visibility for real downtime.
- SSL expiry notifications prevent loss of trust and service interruptions.

### Analysis & Reflection

**Why these checks were chosen**

- API check monitors uptime and latency.
- Browser check validates interactive functionality and navigation, ensuring that the user journey remains intact.
- Alerts notify early without creating alert fatigue.

**How this improves reliability**

- Multi-region monitoring detects outages globally.
- Real browser runs catch front-end and content issues invisible to ping/API checks.
- Timely alerts allow proactive fixes and SLA compliance.
- Historical metrics (P50/P95) help detect gradual degradation before full failure.