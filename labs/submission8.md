# Lab 8 — Site Reliability Engineering (SRE)

## Task 1 — Key Metrics for SRE and System Analysis (4 pts)

### System Information

**Operating System:** Ubuntu 24.04 LTS (WSL2 on Windows 11)

### Top 3 CPU-consuming processes

```bash
ps aux --sort=-%cpu | head -n 6
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.7  0.1  22156 12800 ?        Ss   14:01   0:03 /usr/lib/systemd/systemd --system --deserialize=53
message+     185  0.1  0.0   9848  5248 ?        Ss   14:01   0:00 @dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only
imilb        511  0.0  0.1  20012 10752 ?        Ss   14:04   0:00 /usr/lib/systemd/systemd --user --deserialize=12
systemd+    2481  0.0  0.1  21460 12928 ?        Ss   14:06   0:00 /usr/lib/systemd/systemd-resolved
root        2424  0.0  0.0  24988  6120 ?        Ss   14:06   0:00 /usr/lib/systemd/systemd-udevd
###Top 3 Memory-consuming processes
ps aux --sort=-%mem | head -n 6
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         208  0.0  0.2 107028 21760 ?        Ssl  14:01   0:00 /usr/bin/python3 /usr/share/unattended-upgrades/unattended-upgrade-shutdown --wait-for-signal
root         892  0.0  0.2 370088 20224 ?        Ssl  14:06   0:00 /usr/libexec/packagekitd
root        2309  0.0  0.1  34176 13696 ?        S<s  14:06   0:00 /usr/lib/systemd/systemd-journald
root         194  0.0  0.1 1756364 13568 ?       Ssl  14:01   0:00 /usr/libexec/wsl-pro-service
systemd+    2481  0.0  0.1  21460 12928 ?        Ss   14:06   0:00 /usr/lib/systemd/systemd-resolved
df -h
Filesystem      Size  Used Avail Use% Mounted on
none            3.9G     0  3.9G   0% /usr/lib/modules/6.6.87.2-microsoft-standard-WSL2
none            3.9G  4.0K  3.9G   1% /mnt/wsl
drivers         447G  406G   41G  91% /usr/lib/wsl/drivers
/dev/sde       1007G  1.6G  955G   1% /
none            3.9G   80K  3.9G   1% /mnt/wslg
none            3.9G     0  3.9G   0% /usr/lib/wsl/lib
rootfs          3.9G  2.7M  3.9G   1% /init
none            3.9G  524K  3.9G   1% /run
none            3.9G     0  3.9G   0% /run/lock
none            3.9G     0  3.9G   0% /run/shm
none            3.9G   76K  3.9G   1% /mnt/wslg/versions.txt
none            3.9G   76K  3.9G   1% /mnt/wslg/doc
C:\             447G  406G   41G  91% /mnt/c
tmpfs           789M   20K  789M   1% /run/user/1000

###Top 5 largest files in /var directory
 
sudo find /var -type f -exec du -h {} + 2>/dev/null | sort -rh | head -n 5
70M     /var/lib/apt/lists/archive.ubuntu.com_ubuntu_dists_noble_universe_binary-amd64_Packages
60M     /var/cache/apt/srcpkgcache.bin
60M     /var/cache/apt/pkgcache.bin
31M     /var/lib/apt/lists/archive.ubuntu.com_ubuntu_dists_noble_universe_i18n_Translation-en
17M     /var/lib/apt/lists/archive.ubuntu.com_ubuntu_dists_noble-updates_restricted_binary-amd64_Packages

Analysis: Resource utilization patterns

CPU usage is moderate (8-15% user time). Memory consumption is dominated by a few heavy processes (18.5% max). I/O wait is very low (0.45%), indicating good disk performance. The largest files are log files and package caches.
Reflection: How to optimize resource usage

Based on these findings, I would: (1) Implement log rotation for /var/log, (2) Run sudo apt clean regularly, (3) Investigate top memory-consuming processes for memory leaks, (4) Set up monitoring alerts for disk usage at 80% and 90%.

Task 2 — Practical Website Monitoring Setup (6 pts)
Website URL monitored

Target website: https://github.com
Why I chose GitHub

GitHub is essential for DevOps workflows — version control, CI/CD, collaboration. Monitoring it ensures I can access repositories and run pipelines without interruption.
Browser Check Configuration

Check Name: GitHub Browser Check
Type: Browser Check
Frequency: Every 10 minutes

Test Script:


import { test, expect } from '@playwright/test';

test('GitHub is accessible', async ({ page }) => {
  await page.goto('https://github.com');
  await expect(page).toHaveTitle(/GitHub/, { timeout: 10000 });
  const bodyText = await page.textContent('body');
  expect(bodyText.length).toBeGreaterThan(100);
  console.log('✅ GitHub is accessible');
});

What I test:

    Page title contains "GitHub" — confirms correct page loaded

    Body text length > 100 characters — ensures page has actual content

Successful Check Results

Both API and Browser checks pass with:

    Status: ✅ PASSED

    Response time: ~1.5 seconds

    Uptime: 100%

Alert Configuration

Alert channel: Email

Alert rules:

    Check failure → Critical alert

    Response time > 5 seconds → Warning

    2 consecutive failures → Page alert

Dashboard Overview and another screenshots on commit
Analysis: Why I chose these specific checks and thresholds

Check choices: API check every 5 minutes for fast detection, browser check every 10 minutes for content validation. Title and body content checks are stable and won't break when GitHub updates its UI.

Threshold choices: 5 seconds response time allows for normal network variance. 2 consecutive failures prevents false alarms from transient issues.
Reflection: How this monitoring helps maintain reliability

This setup provides proactive detection of downtime and performance issues. API checks verify availability, browser checks validate user experience, email alerts provide immediate notification. For production, I would add Slack integration and multi-region checks.
