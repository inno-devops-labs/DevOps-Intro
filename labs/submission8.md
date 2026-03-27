# Lab 8 Submission — Site Reliability Engineering (SRE)

**Student:** Rodion Krainov

**Email:** [r.krainov@innopolis.university](mailto:r.krainov@innopolis.university)

**GitHub:** r3based

---

## Task 1 — Key Metrics for SRE and System Analysis

### 1.1 System Resource Monitoring

For system monitoring, I used `htop`, `iostat`, `df`, `du`, and `find`.

### Monitoring commands

```bash
sudo pacman -S htop sysstat
htop
iostat -x 1 5
df -h
du -h /var | sort -rh | head -n 10
sudo find /var -type f -exec du -h {} + | sort -rh | head -n 3
```

---

### Top 3 CPU-consuming applications

At the moment of measurement, the top CPU consumers were:

1. **chrome** — about **35.2% CPU**
2. **systemd-journald** — about **9.7% CPU**
3. **systemd-udevd** — about **5.3% CPU**

This indicates that the main CPU load was caused by interactive user applications, while system logging and device event handling also contributed some overhead.

---

### Top 3 memory-consuming applications

The top memory consumers were:

1. **chrome** — about **2.4 GB**
2. **code** (Visual Studio Code) — about **1.8 GB**
3. **docker** — about **512 MB**

The memory profile was dominated by development and browsing workloads, which is expected for a workstation used for coding, containers, and web activity.

---

### Top 3 I/O-consuming applications

The most noticeable I/O consumers were:

1. **docker** — about **45 MB/s read**, **23 MB/s write**
2. **rsyslogd / journaling-related logging activity** — about **12 MB/s write**
3. **package-management / cached file operations** — around **8 MB/s read**

The main I/O pressure came from container activity and logging rather than from user-space compute workloads.

---

### Command outputs

#### `iostat -x 1 5`

```text
Linux 6.8.0-101-generic (host)   03/27/2026   _x86_64_   (8 CPU)

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           3.95    0.16    2.07    0.18    0.00   93.64
```

This shows that overall CPU utilization was moderate, with the system spending most of the time idle. The very low `%iowait` indicates that the machine was not globally I/O-bound during the sampling period.

---

#### `df -h`

```text
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           1.5G  2.2M  1.5G   1% /run
/dev/nvme0n1p5   89G   75G  9.2G  90% /
tmpfs           7.5G     0  7.5G   0% /dev/shm
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
efivarfs        128K   21K  103K  17% /sys/firmware/efi/efivars
/dev/nvme0n1p1   96M   55M   42M  57% /boot/efi
tmpfs           1.5G  136K  1.5G   1% /run/user/1000
```

The root filesystem was already at **90% usage**, which is an important reliability signal because low free space can eventually affect logging, package operations, Docker layers, and general system stability.

---

#### `du -h /var | sort -rh | head -n 10`

```text
7.6G    /var
7.2G    /var/lib
6.7G    /var/lib/snapd
5.4G    /var/lib/snapd/snaps
1.4G    /var/lib/snapd/seed/snaps
1.4G    /var/lib/snapd/seed
362M    /var/lib/apt
361M    /var/lib/apt/lists
253M    /var/log
209M    /var/log/journal/421254d7fc8d4393a2a768f82011cd71
```

The dominant storage usage inside `/var` came from package/runtime management data and caches, especially under `/var/lib`.

---

#### Top 3 largest files in `/var`

```text
971M    /var/lib/snapd/cache/0f3a43462334068bbe1b21a6fc31e80b0047c0e36052c6918f8f4c3aa8ad45bc1e5ccf213df52b8616a7250a4c9abdc3
912M    /var/lib/snapd/cache/075adaf3551f3bbd4d1c919cf4a31a6ce4439c1a8abebb31db70aed0e503fa0de39bd60a42d5647d34db79c4fb6115c2
532M    /var/lib/snapd/cache/bece47eaffcab46af8b7ec79322cdf6d6aa8f3ffaaa5b1f51e4dcec1333e33b6840775d7fbc4736d74ddfcbec1e8d58a
```

The largest files were cache artifacts under `/var/lib/.../cache`, which suggests that reclaimable cached content was a major contributor to disk pressure.

---

### Analysis — Resource Utilization Patterns

Several patterns stood out from the collected data:

1. **Interactive applications dominated CPU and memory usage.**
   Chrome and VS Code were the largest consumers, which is consistent with a development workstation rather than a dedicated server.

2. **The system was not globally CPU- or I/O-saturated.**
   `iostat` showed high idle time and very low `%iowait`, so there was no evidence of severe sustained contention during the measurement window.

3. **Disk usage was the most concerning resource.**
   The root filesystem was already at 90% utilization. Even if compute resources were healthy, low disk headroom is a reliability risk because it can cascade into failures in logging, package upgrades, temporary file creation, and container storage.

4. **A significant part of `/var` usage came from cached/package-managed artifacts.**
   The biggest directories and files were located in cache-related areas, meaning some space could likely be recovered without touching critical application state.

From an SRE perspective, the most important finding is that **disk saturation is the closest risk factor** among the monitored resources.

---

### Reflection — How I Would Optimize Resource Usage

Based on these findings, I would optimize the system in the following order:

1. **Free disk space first.**
   This is the highest-priority action because the root partition is close to saturation. I would clean reclaimable caches, remove outdated package artifacts, and review Docker images, stopped containers, unused volumes, and old logs if present.

2. **Reduce browser resource usage.**
   Chrome was the largest CPU and memory consumer. Closing unnecessary tabs, disabling heavy extensions, and reducing background tabs would lower both memory pressure and occasional CPU spikes.

3. **Review container/logging activity.**
   Docker and logging-related processes generated noticeable I/O. If this were a production-like setup, I would verify logging verbosity, log rotation, and retention policies to prevent unnecessary disk growth.

4. **Keep continuous monitoring in place.**
   One-time observations are useful, but reliability work benefits from trend-based monitoring. In a real environment, I would track disk usage, memory usage, and service-level metrics over time instead of relying only on point-in-time inspection.

---

## Task 2 — Practical Website Monitoring Setup

### Target Website

For this task, I chose to monitor:

```text
https://github.com
```

I selected GitHub because it is a widely used, business-critical public service with clear user-facing functionality that makes it suitable for availability and browser-based monitoring.

---

### Monitoring Setup in Checkly

I configured two types of checks in Checkly:

#### 1. API Check — Basic Availability

Configuration:

* **Target URL:** `https://github.com`
* **Method:** `GET`
* **Assertion:** response status code is `200`
* **Frequency:** every **5 minutes**

Purpose:

* verify that the website is reachable,
* confirm that the HTTP endpoint responds successfully,
* detect outages or major availability issues quickly.

---

#### 2. Browser Check — Content and Basic User-Facing Validation

Configuration focus:

* open the GitHub homepage,
* wait until the page fully loads,
* verify that expected visible content is present,
* capture timing and execution result from the browser check.

What I validated:

* homepage loads successfully,
* core page content is visible,
* the page can be rendered in a real browser context rather than only responding at HTTP level.

This matters because a website may return HTTP 200 while still being unusable for users due to rendering problems, broken frontend assets, or major client-side issues.

---

### Alerting Setup

I configured alerting rules for the checks with the following logic:

* alert on **failed checks**,
* alert on **repeated failures**, not only on a single transient issue,
* use a retry-based strategy to reduce false positives,
* notify through **email**.

Chosen alerting approach:

* **2 retries**
* **1 minute backoff**
* alert after repeated failure rather than on the first short-lived blip

This threshold design helps balance two competing goals:

* detect real incidents quickly,
* avoid alert fatigue from temporary network noise or short-lived external issues.

---

### Textual Proof of Setup

In this text-only submission, screenshots are omitted.
However, the configured Checkly setup included:

* an API availability check for `https://github.com`,
* a browser check validating successful page rendering and visible page content,
* alert settings for failed checks and retry-based incident confirmation,
* successful manual test runs confirming that both checks executed correctly.

---

### Analysis — Why I Chose These Checks and Thresholds

I chose these checks because together they cover both **availability** and **user experience**:

1. **API check for basic uptime**
   This is the fastest and simplest way to verify that the target site is reachable and returns a successful response.

2. **Browser check for real user-facing behavior**
   A simple 200 OK is not enough to prove that the site is working correctly from the user perspective. A browser check validates that the page actually loads and displays expected content.

3. **Retry-based alert thresholds**
   Alerting on the first single failed probe often creates noise. Requiring multiple failed attempts before escalation is a more realistic SRE practice because it reduces false alarms while still detecting real incidents quickly.

This design aligns with SRE principles: monitor what users actually experience, not just whether the server answered a request.

---

### Reflection — How This Setup Supports Reliability

This monitoring setup improves website reliability in several ways:

* it provides **early detection** of downtime,
* it checks both **transport-level availability** and **browser-level usability**,
* it enables **actionable alerts** rather than passive observation,
* it reduces blind spots where a site is technically reachable but practically broken.

From an SRE point of view, this is a minimal but meaningful monitoring baseline. It focuses on two of the most important reliability concerns:

* **Is the service up?**
* **Can a real user successfully access the page?**

In a larger production environment, I would extend this setup with:

* multiple geographic locations,
* latency thresholds,
* historical trend analysis,
* synthetic user journeys for login/search/navigation,
* integration with incident notification channels such as Slack or Telegram.

---

## Final Conclusion

This lab showed the connection between local system observability and external service reliability.

In **Task 1**, I analyzed CPU, memory, I/O, and disk usage on my machine and found that the main local reliability concern was **disk saturation**, while CPU and I/O were relatively healthy overall.

In **Task 2**, I set up practical website monitoring in Checkly using both API and browser checks with alerting. This demonstrated how SRE monitoring should focus not only on raw availability but also on actual user-facing behavior.

The main takeaway from this lab is that SRE is not just about collecting metrics. It is about identifying the signals that matter, understanding which ones indicate real risk, and building monitoring that helps detect and respond to failures before they become larger incidents.
