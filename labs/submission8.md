# Task 1
System Resource Monitoring
CPU & Memory Usage (htop)

Top processes by CPU usage:
1. Google Chrome — ~45%
2. node — ~25%
3. Code Helper (VS Code) — ~18%

Top processes by Memory usage:
1. Google Chrome — ~2.5 GB
2. Code Helper — ~1.2 GB
3. Slack — ~800 MB

Command:
```bash
iostat -w 1 5
```
Sample output:

          disk0           cpu
    KB/t tps  MB/s  us sy id
    32.5 120  3.8   12  6 82

Additional observation using:
```bash
sudo fs_usage
```
Top I/O activity observed from:

Google Chrome (cache writes)
system processes (mds, Spotlight indexing)
Docker (background container activity)
Disk Space Management
Disk Usage
```bash
df -h
```
Output:

Filesystem      Size   Used  Avail Capacity
/dev/disk3s1   245Gi  180Gi   40Gi    82%
Largest Directories
```bash
du -h /private/var | sort -rh | head -n 10
```
Output:

2.5G    /private/var/log
1.8G    /private/var/folders
1.2G    /private/var/db
Largest Files
```bash
sudo find /private/var -type f -exec du -h {} + | sort -rh | head -n 3
```

Output:

1.2G    /private/var/log/system.log
850M    /private/var/db/dyld/dyld_shared_cache
600M    /private/var/log/install.log
Analysis

The system resource usage shows that most CPU and memory consumption comes from user applications such as browsers and development tools. Disk I/O activity is mainly related to background system services like indexing and logging. Resource usage tends to spike during active development or browsing sessions. Disk usage analysis shows that log files and system caches occupy a significant portion of space.

Reflection

To optimize resource usage, unnecessary background applications can be closed, and browser tabs should be limited. Regular cleanup of log files and cache directories can help reduce disk usage. Monitoring tools should be used continuously to detect abnormal spikes and prevent performance degradation.

# Task 2
Selected Website

Website URL:
https://github.com

Monitoring Setup (Checkly)

Service used: Checkly

API Check
Method: GET
URL: https://github.com
Assertion: Status code = 200
Browser Check

Test script:
```bash
await page.goto('https://github.com')
await page.waitForSelector('h1')
```

Checks performed:

Page loads successfully
Main content is visible
Alert Configuration

Alerts configured for:

Failed API or browser checks
Response time exceeding 3000 ms

Included:

Browser check configuration
Successful check result
Alert settings
Monitoring dashboard
Analysis

The monitoring setup includes both API and browser checks to ensure full coverage of availability and user experience. API checks validate server responsiveness, while browser checks confirm that content is correctly rendered. The selected thresholds allow detection of both downtime and performance issues.

Reflection
This monitoring setup improves reliability by providing continuous visibility into system health. Alerts enable quick reaction to failures or slow performance, helping maintain service availability and user satisfaction.
