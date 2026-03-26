# Task 1 — Key Metrics for SRE and System Analysis

## Top 3 most consuming applications

### CPU
1. htop (~0.3%)
2. /sbin/init (~0.0%)
3. plan9 (~0.0%)

### Memory
1. python3 (unattended-upgrade-shutdown) (~0.3%)
2. packagekitd (~0.3%)
3. packagekitd (~0.3%)

### I/O
1. No active I/O-consuming processes detected
2. No significant disk write/read activity observed
3. System remained idle during monitoring

## Command outputs

### iostat -x 1 5
Linux 6.6.87.2-microsoft-standard-WSL2 (DESKTOP-BNQ0OR3)        03/27/26        _x86_64_        (12 CPU)

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           0.14    0.03    0.16    0.03    0.00   99.64

Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
sda              0.92     60.30     0.35  27.92    0.29    65.89    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.02
sdb              0.11      3.72     0.06  35.00    0.38    35.24    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
sdc              0.08      1.81     0.00   0.00    0.42    22.73    0.00      0.00     0.00   0.00    1.50     2.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    1.00    0.00   0.00
sdd              0.20      2.66     0.04  16.05    2.08    13.06    0.05      0.30     0.03  38.83    3.00     5.84    0.00      3.69     0.00   0.00    0.00  1514.67    0.02    0.83    0.00   0.01
sde             12.67    643.07     4.11  24.48    0.31    50.76 

### df -h
Filesystem      Size  Used Avail Use% Mounted on
none            3.9G     0  3.9G   0% /usr/lib/modules/6.6.87.2-microsoft-standard-WSL2
none            3.9G  4.0K  3.9G   1% /mnt/wsl
drivers         954G  680G  274G  72% /usr/lib/wsl/drivers
/dev/sde       1007G  2.1G  954G   1% /
none            3.9G   80K  3.9G   1% /mnt/wslg
none            3.9G     0  3.9G   0% /usr/lib/wsl/lib
rootfs          3.9G  2.7M  3.9G   1% /init
none            3.9G  544K  3.9G   1% /run
none            3.9G     0  3.9G   0% /run/lock
none            3.9G     0  3.9G   0% /run/shm
none            3.9G   76K  3.9G   1% /mnt/wslg/versions.txt
none            3.9G   76K  3.9G   1% /mnt/wslg/doc
C:\             954G  680G  274G  72% /mnt/c
tmpfs           787M   20K  787M   1% /run/user/1000
tmpfs           787M   20K  787M   1% /run/user/0

### du -h /var | sort -rh | head -n 10
630M    /var
266M    /var/lib
234M    /var/lib/apt/lists
234M    /var/lib/apt
190M    /var/cache
175M    /var/log
173M    /var/log/journal/1063c4c06b5d490d9f8bee9761c825d5
173M    /var/log/journal
172M    /var/cache/apt
53M     /var/cache/apt/archives

### Top 3 largest files in /var
70M     /var/lib/apt/lists/archive.ubuntu.com_ubuntu_dists_noble_universe_binary-amd64_Packages
60M     /var/cache/apt/srcpkgcache.bin
60M     /var/cache/apt/pkgcache.bin

## Analysis

- CPU usage is extremely low, with the system spending about 99.6% of the time idle.
- I/O wait is near zero, which indicates there is no noticeable disk bottleneck.
- Disk utilization is very low; even the busiest device (`sde`) stays below 1% utilization.
- Root filesystem (`/dev/sde`) is almost empty (~1% used), so there is no disk space issue.
- Most storage usage comes from the Windows-mounted drive (`/mnt/c`), which is outside the Linux filesystem.
- Most of the disk usage in `/var` comes from package lists (`/var/lib/apt/lists`) and logs (`/var/log/journal`).
- System logs and package cache are the primary contributors to disk usage.
- The largest files are related to package management (APT lists and cache).
- This indicates that package metadata and cache consume most of the space in `/var`.
- `iotop` did not show any active I/O-heavy processes during observation.

## Reflection

- System is underutilized; no optimization required.
- Could disable unnecessary background services (e.g., unattended upgrades) to reduce overhead.
- Monitoring should be continuous in production to detect spikes.
- For real systems, consider alerting on CPU, memory, and I/O thresholds.

# Task 2 — Practical Website Monitoring Setup

## Website URL
https://example.com

## Browser Check

A browser check was configured using Playwright to monitor https://example.com.

The check performs:
- Navigation to the website
- Verification that the page loads successfully
- Screenshot capture for validation

## Alerts

Alerting was configured to detect failed checks.

- Alert condition: check failure
- Retry strategy: enabled (2 retries)
- Notification method: default global settings

## Analysis

The monitoring setup includes both API and browser checks to ensure full coverage of website reliability.

The API check verifies that the website is available and responds with a correct HTTP status code. This ensures basic uptime monitoring.

The browser check simulates a real user visiting the site, which allows detection of frontend issues, rendering problems, or broken interactions.

The selected thresholds and checks are simple but effective for a static website like example.com, where availability and basic content validation are sufficient.

## Reflection

This monitoring setup improves reliability by combining availability checks and real user simulation.

API checks quickly detect downtime, while browser checks ensure that the website functions correctly from a user perspective.

Alerts enable fast response to failures, reducing downtime and improving system reliability.

In a real production system, additional checks such as performance thresholds, multi-step user flows, and integration with alerting tools would further enhance monitoring capabilities.