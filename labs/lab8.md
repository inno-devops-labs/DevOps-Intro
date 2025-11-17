# Lab 8 — Site Reliability Engineering (SRE)

![difficulty](https://img.shields.io/badge/difficulty-intermediate-yellow)
![topic](https://img.shields.io/badge/topic-SRE-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Explore Site Reliability Engineering principles through system monitoring, performance analysis, and practical website monitoring setup.  
> **Deliverable:** A PR from `feature/lab8` to the course repo with `labs/submission8.md` containing monitoring outputs, analysis, and Checkly setup documentation. Submit the PR link via Moodle.

---

## Overview

In this lab you will practice:
- Monitoring system resources (CPU, memory, I/O) and identifying resource bottlenecks.
- Managing disk space and identifying large files.
- Setting up real-time website monitoring with availability, content validation, and performance checks.
- Configuring alerting for proactive issue detection.

These skills are essential for ensuring system reliability and maintaining SLAs in production environments.

---

## Tasks

### Task 1 — Key Metrics for SRE and System Analysis (4 pts)

**Objective:** Monitor system resources and manage disk space.

#### 1.1: Monitor System Resources

1. **Install Monitoring Tools (if needed):**

   ```bash
   sudo apt install htop sysstat -y
   ```

2. **Monitor CPU, Memory, and I/O Usage:**

   ```bash
   htop
   iostat -x 1 5
   ```

   <details>
   <summary>🔍 Understanding iostat output</summary>

   - `%user`: CPU time in user space
   - `%system`: CPU time in kernel space
   - `%iowait`: CPU waiting for I/O operations
   - `%idle`: CPU idle time

   </details>

3. **Identify Top Resource Consumers:**

   Find the top 3 most consuming applications for:
   - **CPU usage**
   - **Memory usage**
   - **I/O usage**

#### 1.2: Disk Space Management

1. **Check Disk Usage:**

   ```bash
   df -h
   du -h /var | sort -rh | head -n 10
   ```

2. **Identify Largest Files:**

   ```bash
   sudo find /var -type f -exec du -h {} + | sort -rh | head -n 3
   ```

In `labs/submission8.md`, document:
- Top 3 most consuming applications for CPU, memory, and I/O usage
- Command outputs showing resource consumption
- Top 3 largest files in the `/var` directory
- Analysis: What patterns do you observe in resource utilization?
- Reflection: How would you optimize resource usage based on your findings?

---

### Task 2 — Practical Website Monitoring Setup (6 pts)

**Objective:** Set up real-time monitoring for any website using Checkly with availability checks, content validation, interaction performance, and alerting.

#### 2.1: Choose Your Website

1. **Select Target Website:**

   Pick ANY public website you want to monitor (e.g., your favorite store, news site, or portfolio)

#### 2.2: Create Checks in Checkly

1. **Sign Up:**

   - Create a free account at [Checkly](https://checklyhq.com/)

2. **Create API Check for Basic Availability:**

   <details>
   <summary>💡 What to configure</summary>

   - **URL:** Your chosen website
   - **Assertion:** Status code is 200
   - **Frequency:** Choose appropriate check interval

   </details>

3. **Create Browser Check for Content & Interactions:**

   <details>
   <summary>💡 What to test</summary>

   Examples of what you can check:
   - Is a specific text/element visible on the page?
   - Does a button click work?
   - How long does page load take?
   - Can you fill out a form?

   Choose checks that make sense for your selected website.

   </details>

#### 2.3: Set Up Alerts

1. **Configure Alert Rules:**

   Design alert rules of YOUR choice:
   - What to alert on? (e.g., failed checks, slow latency, downtime)
   - How to be notified? (email, Telegram, Slack, etc.)
   - Set thresholds that make sense for your site

#### 2.4: Capture Proof & Documentation

1. **Run Checks Manually:**

   - Verify all checks work correctly
   - Observe the monitoring dashboard

2. **Take Screenshots:**

   Capture screenshots showing:
   - Your browser check configuration
   - A successful check result
   - Your alert settings
   - Dashboard overview

In `labs/submission8.md`, document:
- Website URL you chose to monitor
- Screenshots of browser check configuration
- Screenshots of successful check results
- Screenshots of alert settings
- Analysis: Why did you choose these specific checks and thresholds?
- Reflection: How does this monitoring setup help maintain website reliability?

---

## How to Submit

1. Create a branch for this lab and push it to your fork:

   ```bash
   git switch -c feature/lab8
   # create labs/submission8.md with your findings
   git add labs/submission8.md
   git commit -m "docs: add lab8 submission"
   git push -u origin feature/lab8
   ```

2. Open a PR from your fork's `feature/lab8` branch → **course repository's main branch**.

3. In the PR description, include:

   ```text
   - [x] Task 1 — Key Metrics for SRE and System Analysis
   - [x] Task 2 — Practical Website Monitoring Setup
   ```

4. **Copy the PR URL** and submit it via **Moodle before the deadline**.

---

## Acceptance Criteria

- ✅ Branch `feature/lab8` exists with commits for each task.
- ✅ File `labs/submission8.md` contains required outputs and analysis for Tasks 1-2.
- ✅ System monitoring outputs show CPU, memory, and I/O analysis.
- ✅ Checkly monitoring is configured with screenshots as proof.
- ✅ PR from `feature/lab8` → **course repo main branch** is open.
- ✅ PR link submitted via Moodle before the deadline.

---

## Rubric (10 pts)

| Criterion                                       | Points |
| ----------------------------------------------- | -----: |
| Task 1 — Key Metrics for SRE and System Analysis |  **4** |
| Task 2 — Practical Website Monitoring Setup     |  **6** |
| **Total**                                       | **10** |

---

## Guidelines

- Use proper Markdown formatting and structure for the documentation files.
- Organize the files within the lab folder using appropriate naming conventions.
- Include clear screenshots with annotations if helpful.
- Provide thoughtful analysis of your monitoring setup decisions.

<details>
<summary>📚 Helpful Resources</summary>

- [Checkly Documentation](https://www.checklyhq.com/docs/)
- [SRE Book - Google](https://sre.google/sre-book/table-of-contents/)
- [Monitoring Best Practices](https://sre.google/sre-book/monitoring-distributed-systems/)

</details>

<details>
<summary>💡 SRE Tips</summary>

1. Focus on metrics that matter - availability, latency, and error rates.
2. Set realistic alert thresholds to avoid alert fatigue.
3. Monitor user-facing functionality, not just server health.
4. Document your reasoning for chosen monitoring strategies.

</details>

<details>
<summary>🔍 Monitoring Best Practices</summary>

1. **The Four Golden Signals:**
   - Latency: How long does it take?
   - Traffic: How much demand?
   - Errors: How many failures?
   - Saturation: How full is the system?

2. **Alert Design:**
   - Alert on symptoms, not causes
   - Make alerts actionable
   - Avoid alert fatigue with proper thresholds

</details>