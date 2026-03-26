# Lab 8 — Site Reliability Engineering

## Task 1 — Key Metrics for SRE and System Analysis

### 1.1 Install Monitoring Tools

I installed the monitoring tools required for this task:

```bash
sudo apt install htop sysstat -y
```

### 1.2 Monitor CPU, Memory, and I/O Usage

I used `htop` to inspect live CPU and memory usage and `iostat -x 1 5` to observe disk I/O behavior.

#### Command output: `iostat -x 1 5`

```bash
Linux 6.17.0-19-generic (nikita-flmhxx)         26.03.2026      _x86_64_        (18 CPU)

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           4,36    0,01    1,58    0,03    0,00   94,03

Device             tps    kB_read/s    kB_wrtn/s    kB_dscd/s    kB_read    kB_wrtn    kB_dscd
loop0             0,00         0,00         0,00         0,00         17          0          0
loop1             0,01         0,08         0,00         0,00        688          0          0
loop10            0,01         0,08         0,00         0,00        691          0          0
loop11            0,00         0,01         0,00         0,00         63          0          0
loop12            0,07         2,41         0,00         0,00      20281          0          0
loop13            0,01         0,04         0,00         0,00        361          0          0
loop14            0,00         0,00         0,00         0,00         14          0          0
loop2             0,01         0,08         0,00         0,00        680          0          0
loop3             0,01         0,08         0,00         0,00        669          0          0
loop4             0,01         0,08         0,00         0,00        709          0          0
loop5             0,01         0,08         0,00         0,00        680          0          0
loop6             0,01         0,08         0,00         0,00        693          0          0
loop7             0,01         0,04         0,00         0,00        353          0          0
loop8             0,01         0,08         0,00         0,00        668          0          0
loop9             0,01         0,08         0,00         0,00        694          0          0
nvme0n1          26,16       867,23       392,03         0,00    7295502    3297942          0
```

### 1.3 Top Resource Consumers

#### Top 3 CPU-consuming applications

| Rank | Process / Application | CPU % | Notes                                     |
| ---- | --------------------- | ----: | ----------------------------------------- |
| 1    | chrome (PID 15646)    |  10.1 | Browser tab/process consuming highest CPU |
| 2    | chrome (PID 4758)     |   8.2 | Active browser process                    |
| 3    | chrome (PID 15438)    |   7.6 | Background/active tab process             |

#### Top 3 memory-consuming applications

| Rank | Process / Application   | Memory % | Notes                               |
| ---- | ----------------------- | -------: | ----------------------------------- |
| 1    | chrome (PID 4700)       |      2.3 | Highest memory usage, multiple tabs |
| 2    | kwin_wayland (PID 2266) |      1.5 | Window manager                      |
| 3    | plasmashell (PID 2410)  |      1.4 | Desktop environment shell           |

#### Top 3 I/O-consuming applications

| Rank | Process / Application | I/O Activity | Notes                          |
| ---- | --------------------- | -----------: | ------------------------------ |
| 1    | None significant      |      ~0 kB/s | No active disk-heavy processes |
| 2    | None significant      |      ~0 kB/s | System idle in terms of I/O    |
| 3    | None significant      |      ~0 kB/s | No bottlenecks observed        |

#### Command output: `pidstat -d 1 3`

```bash
Linux 6.17.0-19-generic (nikita-flmhxx)         26.03.2026      _x86_64_        (18 CPU)

12:51:48      UID       PID   kB_rd/s   kB_wr/s kB_ccwr/s iodelay  Command

12:51:49      UID       PID   kB_rd/s   kB_wr/s kB_ccwr/s iodelay  Command

12:51:50      UID       PID   kB_rd/s   kB_wr/s kB_ccwr/s iodelay  Command

Average:      UID       PID   kB_rd/s   kB_wr/s kB_ccwr/s iodelay  Command
```

### 1.4 Disk Space Management

#### Disk usage: `df -h`

```bash
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           3,1G  2,3M  3,1G   1% /run
/dev/nvme0n1p5  477G   74G  379G  17% /
tmpfs            16G  733M   15G   5% /dev/shm
efivarfs        268K  216K   48K  83% /sys/firmware/efi/efivars
tmpfs           5,0M  8,0K  5,0M   1% /run/lock
tmpfs           1,0M     0  1,0M   0% /run/credentials/systemd-journald.service
tmpfs           1,0M     0  1,0M   0% /run/credentials/systemd-resolved.service
/dev/nvme0n1p1   96M   51M   46M  53% /boot/efi
tmpfs            16G   59M   16G   1% /tmp
tmpfs           3,1G  160K  3,1G   1% /run/user/1000
```

#### Largest directories under `/var`

```bash
6.5G    /var
5.3G    /var/lib
2.9G    /var/lib/snapd
1.9G    /var/lib/flatpak
1.7G    /var/lib/snapd/cache
1.2G    /var/lib/snapd/seed/snaps
1.2G    /var/lib/snapd/seed
1.2G    /var/lib/flatpak/runtime
635M    /var/cache
596M    /var/lib/flatpak/runtime/org.freedesktop.Platform/x86_64/25.08/18c4d2cd492ef63f2ba38cd06de0149d2542404144a0e0f6ebe0dfe5f7dbb680/files
```

#### Top 3 largest files in `/var`

| Rank | File path                                                                                                             | Size |
| ---- | --------------------------------------------------------------------------------------------------------------------- | ---: |
| 1    | /var/lib/snapd/snaps/gnome-42-2204_247.snap                                                                           | 532M |
| 2    | /var/lib/snapd/cache/bece47eaffcab46af8b7ec79322cdf6d6aa8f3ffaaa5b1f51e4dcec1333e33b6840775d7fbc4736d74ddfcbec1e8d58a | 532M |
| 3    | /var/lib/snapd/snaps/gnome-42-2204_226.snap                                                                           | 517M |

### 1.5 Analysis

From the monitoring results, I observed the following patterns:

* **CPU usage:** The top CPU consumers are all Chrome processes, with usage between 7.6% and 10.1%. This indicates that browser activity (likely multiple tabs or active web applications) is the main source of CPU load.
* **Memory usage:** Chrome also uses the most memory, followed by `kwin_wayland` and `plasmashell`. This shows that both the browser and the graphical desktop environment contribute to memory consumption.
* **I/O usage:** Disk I/O activity is very low. The `%idle` value is consistently above 93%, and `%iowait` is near 0%, which indicates there is no I/O bottleneck. The `pidstat` output also shows no significant read/write activity.
* **Disk usage under `/var`:** The majority of disk space is used by `/var/lib`, especially `snapd` (2.9G) and `flatpak` (1.9G). This indicates that containerized/package-managed applications are the main contributors to disk usage.

Overall, the system appears to be stable and lightly loaded, with no critical bottlenecks. CPU and memory usage are moderate and mainly driven by user applications (browser and desktop environment), while disk and I/O usage are minimal.

### 1.6 Reflection: How I Would Optimize Resource Usage

Based on the findings, I would optimize the system in the following ways:

* Reduce CPU usage by limiting the number of active browser tabs or disabling unnecessary extensions in Chrome.
* Reduce memory usage by closing unused applications and minimizing background processes.
* Clean up disk space by removing unused Snap and Flatpak packages and clearing their caches.
* Implement regular maintenance such as log cleanup and cache removal in `/var` to prevent unnecessary disk growth.

These changes would help improve responsiveness, reduce bottlenecks, and make the system more reliable.

---

## Task 2 — Practical Website Monitoring Setup

### 2.1 Website Chosen for Monitoring

**Website URL:** `https://en.wikipedia.org/wiki/Hahn%E2%80%93Banach_theorem`

### 2.2 API Check Configuration

I created an API check in Checkly to verify that the website is reachable and returns a successful HTTP response.

* **Check type:** API check
* **URL:** `https://en.wikipedia.org/wiki/Hahn%E2%80%93Banach_theorem`
* **Assertion:** Status code equals `200`
* **Frequency:** every 5 min

#### Screenshot: API check configuration

![alt text](image.png)

#### Screenshot: Successful API check result

![alt text](image-1.png)

### 2.3 Browser Check Configuration

I created a browser check to validate that the website loads correctly and that key content or interactions work as expected.

* **Check type:** Browser check
* **Target page:** `https://en.wikipedia.org/wiki/Hahn%E2%80%93Banach_theorem`
* **What it tests:** Wait for an element to become visible (Asserts that the main heading `<h1>` contains the text "Hahn–Banach theorem".)
* **Frequency:** every 10 min

#### Screenshot: Browser check configuration

![alt text](image-3.png)

#### Screenshot: Successful browser check result

![alt text](image-4.png)

### 2.4 Alert Settings
I configured alerts to notify me when the checks fail.

* **Alert condition:** When any check fails 1 time (i.e., a single failure triggers an alert)
* **Reminder:** 1 reminder sent every 10 minutes 
* **Notification method:** Email


#### Screenshot: Alert settings

![alt text](image-6.png)
#### Screenshot Dashboard:

![alt text](image-5.png)

### 2.5 Analysis: Why I Chose These Checks and Thresholds

I chose these checks because they cover both **availability** and **user-facing content**:

* The API check confirms that the server is responding with HTTP 200, ensuring basic uptime.
* The browser check verifies that the page actually renders the expected content – in this case, the article title – which is critical for a user to trust the site.
* The alert threshold (fail on first failure with a 10‑minute reminder) ensures I am notified immediately if a problem occurs, but prevents alert fatigue by not spamming me if the issue is intermittent.

This setup is useful because it catches both server‑side outages and front‑end rendering issues that users would experience.

### 2.6 Reflection: How This Monitoring Setup Helps Website Reliability

This monitoring setup improves reliability by detecting problems early, before users experience them. The API check provides a simple uptime signal, while the browser check verifies actual page behavior from a user perspective. Alerts make sure failures are noticed quickly so they can be investigated and fixed before they affect many users.
