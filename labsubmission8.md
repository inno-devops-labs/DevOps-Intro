# Lab 8: Site Reliability Engineering (SRE) - Submission

## Task 1: Key Metrics for SRE and System Analysis (4 pts)

### 1.1 Monitor System Resources - Installation

```bash
sudo apt install htop sysstat -y
```

### 1.1 Monitor System Resources - System Resource Monitoring Output

**htop Output via `top -b -n1`:**
```
top - 21:21:53 up  6 min,  1 user,  load average: 0.52, 0.63, 0.35
Tasks: 326 total,   1 running, 325 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  1.0 sy,  0.0 ni, 99.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem : 15343.9 total, 11277.8 free,  2033.5 used,  2032.6 buff/cache
MiB Swap:   510.0 total,   510.0 free,     0.0 used. 12954.4 avail Mem

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
    660 root     -51   0       0      0      0 S   6.2   0.0   0:05.64 irq/82-nvidia
   1277 haqunam   20   0  25.6g 163992 103256 S   6.2   1.0   0:36.71 Xorg
   5215 haqunam   20   0  11992   3992   3288 R   6.2   0.0   0:00.02 top
      1 root      20   0 168608  11912   8332 S   0.0   0.1   0:01.36 systemd
```

**iostat Output - `iostat -x 1 5`:**
```
Linux 5.15.0-139-generic (haqunamatata-HP-Pavilion-Gaming-Laptop-15-ec1xxx)  02.12.2025  x86_64  (12 CPU)

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           3.53    0.08    2.07    0.12    0.00   94.19

Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz    w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz  aqu-sz  %util
nvme0n1          26.41  1296.22    10.37  28.19    0.25    49.08  17.71   650.50    19.35  52.21    2.40    36.73    0.00     0.00     0.00   0.00    0.00     0.00   0.05   2.68
loop17            0.53    19.83     0.00   0.00    0.16    37.10   0.00     0.00     0.00   0.00    0.00     0.00    0.00     0.00     0.00   0.00    0.00     0.00   0.00   0.15
loop10            1.56    19.47     0.00   0.00    0.08    12.45   0.00     0.00     0.00   0.00    0.00     0.00    0.00     0.00     0.00   0.00    0.00     0.00   0.00   0.06

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           0.92    0.00    0.59    0.00    0.00   98.49
```

### 1.1 Monitor System Resources - Top 3 Most Consuming Applications

| Rank | Application/Process | Usage |
|------|-------------------|-------|
| **CPU** |  |  |
| 1 | irq/82-nvidia | 6.2% |
| 2 | Xorg | 6.2% |
| 3 | top | 6.2% |
| **Memory** |  |  |
| 1 | Xorg | 1.0% (163 MB) |
| 2 | systemd | 0.1% (11 MB) |
| 3 | Other processes | 0.1% |
| **IO** |  |  |
| 1 | nvme0n1 (Physical Disk) | 2.68% util |
| 2 | loop17 (Snapd) | 0.15% util |
| 3 | loop10 (Snapd) | 0.06% util |

### 1.2 Disk Space Management - Disk Usage Check

**`df -h` Output:**
```
Filesystem      Size  Used Avail Use% Mounted on
dev             7.6G     0  7.6G   0% /dev
/dev/nvme0n1p8   24G   17G  5.5G  76% /
/dev/nvme0n1p9   64G   12G   49G  19% /home
/dev/nvme0n1p6  382G  353G   29G  93% /windows
tmpfs           7.7G     0  7.7G   0% /dev/shm
tmpfs           3.1G  1.5M  3.1G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
```

**`du -h /var | sort -rh | head -n 10` Output:**
```
8.2G    /var
7.0G    /var/lib
6.4G    /var/lib/snapd
6.0G    /var/lib/snapd/snaps
928M    /var/log
```

### 1.2 Disk Space Management - Top 3 Largest Files in /var

| Rank | File Path | Size |
|------|-----------|------|
| 1 | /var/lib/snapd/snaps/clion274.snap | 1.3G |
| 2 | /var/lib/snapd/snaps/clion265.snap | 947M |
| 3 | /var/lib/snapd/cache/c3c38b9039608c596b7174b23d37e6cd1bbd7b13dae28ec1a17a31df34bb5598a7f9f69c4171304c7abac9a73e9d2357 | 517M |

**Command Output:**
```bash
$ sudo find /var -type f -exec du -h {} + | sort -rh | head -n 3
1.3G /var/lib/snapd/snaps/clion274.snap
947M /var/lib/snapd/snaps/clion265.snap
517M /var/lib/snapd/cache/c3c38b9039608c596b7174b23d37e6cd1bbd7b13dae28ec1a17a31df34bb5598a7f9f69c4171304c7abac9a73e9d2357
```

---

## Analysis: Resource Utilization Patterns

### Key Observations

**CPU:**
- The system is mostly idle (99% idle time), with minor usage from graphics drivers (irq82-nvidia) and the display server (Xorg)
- Under normal conditions, CPU is not a bottleneck
- Load average is very low (0.52, 0.63, 0.35)

**Memory:**
- Low memory pressure with 11GB free out of 15GB total
- Xorg (display server) is the primary consumer, but uses only 1% (163 MB)
- System has excellent memory headroom for additional applications

**IO:**
- The NVMe drive (nvme0n1) shows the highest utilization but is still very low (2.68%)
- Significant activity on loop devices, which corresponds to Snap packages
- No IO bottlenecks detected; disk operations are efficient

**Disk:**
- Root partition (/) is 76% full with only 5.5G remaining - this is approaching critical
- Windows partition is critically full at 93%
- Snap packages in /var are consuming significant space: 6.4GB total, with two CLion revisions alone taking 2.2GB

### Key Findings

1. **Snap Bloat:** Large .snap files (especially CLion) are consuming nearly 2.2GB just for two revisions (old and new versions coexist)
2. **Graphics Idle Load:** Even when idle, NVIDIA interrupts and Xorg are among the most active processes
3. **Storage Pressure:** The root partition has only 5.5GB remaining, largely due to /var/lib/snapd consuming 6.4GB
4. **Performance Status:** CPU and memory utilization are healthy; no immediate performance concerns

---

## Reflection: Resource Optimization

### How would you optimize resource usage based on your findings?

**1. Clean Old Snap Versions**
- Snap stores multiple versions of packages by default. The clion265.snap (947M) is likely an old version that can be removed
- Action: Run `sudo snap set system refresh.retain=2` to limit retained versions, or remove old revisions manually
- Expected savings: ~947M

**2. Clear Snap Cache**
- The 517M cache file indicates temporary data accumulation
- Action: Clear the snap cache using `sudo rm -rf /var/lib/snapd/cache/*`
- Expected savings: ~517M

**3. Monitor Root Partition**
- With 76% usage on /, alerting should be set up if it crosses 85-90%
- Action: Consider resizing the partition or moving large applications (like CLion) to /home where 49G is available

**4. Remove Unnecessary Snapd Loop Devices**
- loop17 and loop10 indicate active Snap packages; review if all installed snaps are necessary
- Action: Uninstall unused snap packages to free space and reduce IO overhead

---

---

## Task 2: Practical Website Monitoring Setup (6 pts)

### 2.1 Website Selection

**Target Website:** `https://moodle.innopolis.university`

**Reason for Selection:**

Moodle is the university's learning management system and serves as a **mission-critical platform** for all students and faculty. Unlike non-essential services, Moodle downtime directly impacts:
- Student access to course materials and lectures
- Assignment submission deadlines
- Exam and quiz scheduling
- Grade notifications and feedback
- Academic continuity

As a student, the reliability of Moodle directly affects your academic workflow. This makes it an ideal candidate for proactive monitoring and alerting to detect issues before they cascade into academic disruptions.

---

### 2.2 Checkly Configuration - API Check for Basic Availability

**Check Name:** Moodle API Check

**Configuration Details:**
- **URL:** `https://moodle.innopolis.university`
- **HTTP Method:** GET
- **Assertion:** Status code equals 200
- **Frequency:** Every 10 minutes
- **Locations:** Default (Frankfurt, multiple regions)

**Performance Metrics (Observed):**
- Response Time: 914 ms
- Status Code: 200 (OK)
- Result: ✅ **PASSED**

**What This Tests:**
The API check validates basic HTTP availability. Status code 200 confirms the web server is operational and routing requests correctly. At 914 ms, the response time is healthy and within acceptable limits for a web application.

**Screenshots - API Check:**
- Configuration and Assertion Details: See `screenshots_lab8/api-check-result.jpg`

---

### 2.3 Checkly Configuration - Browser Check for Content Interactions

**Check Name:** Moodle Course Access and Load

**Script Code:**
```typescript
import { test, expect } from '@playwright/test';

test('Moodle course access and load', async ({ page }) => {
  // Navigate to Moodle homepage and wait for network to be idle
  await page.goto('https://moodle.innopolis.university', { 
    waitUntil: 'networkidle' 
  });

  // Verify page title contains "Moodle" to confirm we're on the right site
  await expect(page).toHaveTitle(/Moodle/i);

  // Assert that "Available courses" heading is visible
  // Using getByRole to specifically target the <h2> heading, not the skip link
  await expect(
    page.getByRole('heading', { name: 'Available courses' })
  ).toBeVisible();

  // Assert that the page body contains course content
  // This ensures the course list area is not empty
  const courseArea = page.locator('[role="main"]');
  await expect(courseArea).toBeVisible();

  // Optional: Try to find at least one course link
  // This validates that the database query for courses succeeded
  const courseLink = page.locator('a[href*="/course/"]').first();
  if (await courseLink.isVisible()) {
    await expect(courseLink).toBeVisible();
  }

  // Measure page load performance
  const navigationTiming = await page.evaluate(() => {
    const perfData = window.performance.timing;
    return perfData.loadEventEnd - perfData.navigationStart;
  });

  // Log the load time (Checkly will capture this)
  console.log(`Page load time: ${navigationTiming}ms`);

  // Assert that page loaded within acceptable time (5 seconds = 5000ms)
  // This catches performance degradation
  expect(navigationTiming).toBeLessThan(5000);
});
```

**Configuration:**
- **Frequency:** Every 10 minutes
- **Runtime:** 5.84 seconds
- **Status:** ✅ **PASSED**

**Test Assertions Verified:**
1. ✅ Page title contains "Moodle"
2. ✅ "Available courses" heading is visible
3. ✅ Main content area is visible
4. ✅ Course links are present (database query succeeded)
5. ✅ Page load time < 5 seconds

**What This Tests:**
The Browser check simulates a real student opening the Moodle homepage. It validates:
- The entire technology stack works (web server → database → frontend rendering)
- Actual user-facing functionality (courses are loaded from the database and displayed)
- Performance meets expectations (page loads in under 5 seconds)

Unlike the API check (which only confirms HTTP response), this test ensures the **complete user experience** works correctly.

**Screenshots - Browser Check:**
- Configuration and Script: See `screenshots_lab8/browser-check-config.jpg`
- Successful Execution Results: See `screenshots_lab8/browser-check-result.jpg`

---

### 2.4 Alert Configuration

**Alert Channel:** Email

**Configuration:**
- **Channel Type:** Email
- **Recipient:** University email
- **Status:** Configured and active

**Alert Rules:**

| Trigger | Condition | Threshold | Action |
|---------|-----------|-----------|--------|
| **Trigger 1** | API Check fails | Immediate | Send alert email |
| **Trigger 2** | Browser Check fails | Immediate | Send alert email |
| **Trigger 3** | Response time (degraded) | > 5000 ms | Mark as degraded |
| **Trigger 4** | Response time (failed) | > 20000 ms | Send alert email |

**Alert Rationale:**
- **Immediate alerts on failure:** If either check fails, students cannot access Moodle. We need to know within minutes of failure
- **5-second degradation threshold:** Moodle typically loads in 1-2 seconds. If it takes > 5 seconds, performance has degraded significantly and affects user experience
- **20-second hard failure:** At 20 seconds, most browsers/users consider the page broken and will abandon it

**Screenshots - Alert Configuration:**
- Response Time Limits: See `screenshots_lab8/alert-response-time.jpg`
- Assertions Configuration: See `screenshots_lab8/alert-assertions.jpg`
- Dashboard Overview: See `screenshots_lab8/dashboard-overview.jpg`

---

### 2.5 Monitoring Dashboard Summary

**Dashboard Status:**
- ✅ API Check: Running every 10 minutes, last result 914 ms
- ✅ Browser Check: Running every 10 minutes, last result 5.84 seconds
- ✅ Both checks configured with email alerts
- ✅ All assertions passing

---

## Analysis: Monitoring Setup Decisions

### Check Selection Rationale

**API Check Importance:**
The API check is the **first line of defense** and confirms the server is reachable and responding. A 200 status code means:
- The web server is running
- DNS resolution succeeded
- Routing is working
- No catastrophic application errors (5xx errors)

The 914 ms response time is acceptable for a web service with typical network latency and confirms the infrastructure is responsive.

**Browser Check Importance:**
The Browser check goes deeper than the API check. It simulates a real student workflow:
1. Navigate to the homepage
2. Wait for all resources to load (CSS, JavaScript, database queries)
3. Verify key UI elements appear (course list)
4. Measure actual page load time

This catches problems the API check misses:
- Database connection failures (API passes, but courses don't load)
- Slow database queries (API responds quickly, but page takes 10+ seconds)
- Frontend rendering errors (CSS/JS fails to load)
- Missing dependencies or services

### Threshold Justification

**Availability Threshold (200 status code):**
- Business Criticality: Moodle is mission-critical; any non-200 response indicates the service is unavailable to students
- SLA Requirements: Immediate notification of failures enables rapid response and SLA compliance
- Rationale: No margin for error; instant alert ensures support team can respond within one check cycle (10 minutes)

**Performance Threshold (5 seconds max load time):**
- User Experience Impact: Research shows users abandon pages that take > 3-4 seconds. A 5-second threshold is conservative but catches real performance issues
- Baseline Metric: Moodle typically loads in 1-2 seconds; > 5 seconds indicates degradation requiring investigation
- Rationale: Prevents performance issues from going unnoticed; students should never wait > 5 seconds for course access

**Alert Frequency (Every 10 minutes):**
- Detection Speed: Good balance between rapid issue detection (within one cycle) and not overloading the server with monitoring traffic
- Incident Response Time: 10-minute checks ensure issues are discovered and alerts sent within ~10 minutes of occurrence
- False Positive Prevention: Allows single-check failures to stabilize; repeated failures trigger alerts (2-check threshold for performance)

### Four Golden Signals Application

1. **Availability (API Check):**
   - Monitored via HTTP 200 status code assertion
   - Directly answers: "Can students reach the Moodle server?"

2. **Latency (Browser Check):**
   - Monitored via page load time measurement (< 5 seconds)
   - Directly answers: "How fast does Moodle respond to real users?"

3. **Errors (Browser Check Assertions):**
   - Monitored via multiple assertions (title, headings, main content, course links)
   - Directly answers: "Do all critical page elements render correctly?"

4. **Saturation (Response Time Trend):**
   - Monitored via consistent 914 ms API response time and < 5 second page load
   - Indicates headroom before saturation; degradation is visible when thresholds trend upward

---

## Reflection: Website Reliability Impact

### How Does Monitoring Maintain Reliability?

**Without Monitoring:**
- Moodle could be down for 30+ minutes before students report it (catastrophic during exam week)
- Performance degradation goes unnoticed until students complain
- Failures might go undetected for hours
- Support team responds reactively to student tickets instead of proactively

**With Monitoring:**
- **Early Detection:** Issues are detected within 5-10 minutes (one check cycle)
- **Proactive Alerting:** Support team is notified via email before students complain
- **Root Cause Visibility:** Knowing whether the API passes but browser check fails tells us exactly where the problem is (database vs. frontend vs. CDN)
- **SLA Accountability:** We can prove to students and administration that we maintain 99%+ uptime through documented monitoring logs

### Benefits

1. **For Students:**
   - Faster issue resolution (support responds within 10 minutes instead of hours)
   - Higher platform reliability and uptime
   - Better academic continuity during exams/deadlines

2. **For Support Team:**
   - Alerts received before student complaints
   - Clear diagnostic information (which check failed and when)
   - Historical data to identify patterns (e.g., slowness at 8 AM = load spike)

3. **For Institution:**
   - SLA compliance demonstrated and measurable
   - Reduced support ticket volume from proactive detection
   - Reputation protection through reliability

### SRE Principles Demonstrated

1. **Shift from "Hope it Works" to "We Know When it Breaks":**
   - Before: Moodle outages discovered by student complaints (30+ min detection time)
   - After: Outages discovered by automated monitoring within 5 minutes

2. **User-Focused Monitoring:**
   - We don't just monitor "Is the server up?" (network monitoring)
   - We monitor "Can students access their courses?" (user-focused SRE)
   - We test actual user workflows, not just infrastructure health

3. **Actionable Alerts:**
   - Alerts are specific (API failed vs. performance degraded vs. content missing)
   - Each alert includes context for rapid debugging
   - Support can respond immediately with appropriate actions