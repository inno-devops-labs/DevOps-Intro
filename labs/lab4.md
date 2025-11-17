# Lab 4 — Operating Systems & Networking

![difficulty](https://img.shields.io/badge/difficulty-beginner-success)
![topic](https://img.shields.io/badge/topic-OS%20%26%20Networking-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Analyze operating system fundamentals and conduct network diagnostics to develop core DevOps infrastructure skills.  
> **Deliverable:** A PR from `feature/lab4` to the course repo with `labs/submission4.md` containing command outputs, analysis, and observations. Submit the PR link via Moodle.

---

## Overview

In this lab you will practice:
- Analyzing OS components: boot performance, resource usage, services, sessions, and memory management.
- Performing network diagnostics: path tracing, DNS inspection, packet capture, and reverse lookups.
- Documenting system analysis findings with proper security considerations.

---

## Tasks

### Task 1 — Operating System Analysis (6 pts)

**Objective:** Analyze key OS components including boot performance, resource usage, services, sessions, and memory management.

#### 1.1: Boot Performance Analysis

1. **Analyze System Boot Time:**

   ```sh
   systemd-analyze
   systemd-analyze blame
   ```

2. **Check System Load:**

   ```sh
   uptime
   w
   ```

#### 1.2: Process Forensics

1. **Identify Resource-Intensive Processes:**

   ```sh
   ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
   ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
   ```

#### 1.3: Service Dependencies

1. **Map Service Relationships:**

   ```sh
   systemctl list-dependencies
   systemctl list-dependencies multi-user.target
   ```

#### 1.4: User Sessions

1. **Audit Login Activity:**

   ```sh
   who -a
   last -n 5
   ```

#### 1.5: Memory Analysis

1. **Inspect Memory Allocation:**

   ```sh
   free -h
   cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
   ```

In `labs/submission4.md`, document:
- All command outputs for sections 1.1-1.5.
- Key observations for each analysis section.
- Answer: "What is the top memory-consuming process?"
- Note any resource utilization patterns you observe.

---

### Task 2 — Networking Analysis (4 pts)

**Objective:** Perform network diagnostics including path tracing, DNS inspection, packet capture, and reverse lookups.

#### 2.1: Network Path Tracing

1. **Traceroute Execution:**

   ```sh
   traceroute github.com
   ```

2. **DNS Resolution Check:**

   ```sh
   dig github.com
   ```

#### 2.2: Packet Capture

1. **Capture DNS Traffic:**

   ```sh
   sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
   ```

   <details>
   <summary>🔍 Understanding tcpdump flags</summary>

   - `-c 5`: Capture 5 packets
   - `-i any`: Listen on all interfaces
   - `port 53`: Filter for DNS traffic
   - `-nn`: Don't resolve hostnames/ports (faster)

   </details>

#### 2.3: Reverse DNS

1. **Perform PTR Lookups:**

   ```sh
   dig -x 8.8.4.4
   dig -x 1.1.2.2
   ```

In `labs/submission4.md`, document:
- All command outputs for sections 2.1-2.3.
- Insights on network paths discovered.
- Analysis of DNS query/response patterns.
- Comparison of reverse lookup results.
- One example DNS query from packet capture (sanitize IPs if needed).

---

## How to Submit

1. Create a branch for this lab and push it to your fork:

   ```bash
   git switch -c feature/lab4
   # create labs/submission4.md with your findings
   git add labs/submission4.md
   git commit -m "docs: add lab4 submission"
   git push -u origin feature/lab4
   ```

2. Open a PR from your fork's `feature/lab4` branch → **course repository's main branch**.

3. In the PR description, include:

   ```text
   - [x] Task 1 done
   - [x] Task 2 done
   ```

4. **Copy the PR URL** and submit it via **Moodle before the deadline**.

---

## Acceptance Criteria

- ✅ Branch `feature/lab4` exists with commits for each task.
- ✅ File `labs/submission4.md` contains required outputs and analysis for Tasks 1-2.
- ✅ All sensitive information (IPs, process names) is properly sanitized in documentation.
- ✅ PR from `feature/lab4` → **course repo main branch** is open.
- ✅ PR link submitted via Moodle before the deadline.

---

## Rubric (10 pts)

| Criterion                                    | Points |
| -------------------------------------------- | -----: |
| Task 1 — Operating system analysis           |   **6** |
| Task 2 — Networking analysis                 |   **4** |
| **Total**                                    |  **10** |

---

## Guidelines

- Use clear Markdown headers to organize sections in `submission4.md`.
- Include both command outputs and written analysis for each task.
- For packet capture, document at least one DNS query example.
- Sanitize sensitive information: replace last octet of IPs with XXX, avoid sensitive process names.

<details>
<summary>🔒 Security Best Practices</summary>

1. Sanitize IPs in packet capture outputs (replace last octet with XXX).
2. Avoid including sensitive process names in documentation.
3. Do not expose internal network topology details publicly.

</details>

<details>
<summary>📚 Helpful Resources</summary>

- [systemd-analyze man page](https://www.freedesktop.org/software/systemd/man/systemd-analyze.html)
- [tcpdump tutorial](https://danielmiessler.com/study/tcpdump/)
- [dig command examples](https://linux.die.net/man/1/dig)

</details>