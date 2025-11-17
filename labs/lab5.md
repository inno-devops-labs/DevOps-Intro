# Lab 5 — Virtualization & System Analysis

![difficulty](https://img.shields.io/badge/difficulty-intermediate-yellow)
![topic](https://img.shields.io/badge/topic-Virtualization-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Learn virtualization fundamentals by deploying VMs and analyzing system specifications across different platforms.
> **Deliverable:** A PR from `feature/lab5` to the course repo with `labs/submission5.md` containing VM deployment documentation and system analysis. Submit the PR link via Moodle.

---

## Overview

In this lab you will practice:
- Setting up virtualization platforms across different operating systems.
- Deploying and configuring virtual machines with modern Linux distributions.
- Using command-line tools for system information gathering and analysis.
- Documenting virtualization workflows for cross-platform environments.

These skills are essential for DevOps infrastructure management and system administration.

---

## Tasks

### Task 1 — VirtualBox Installation (5 pts)

**Objective:** Install VirtualBox on your host operating system.

#### 1.1: Install VirtualBox

1. **Download and Install:**

   - Download VirtualBox from [https://www.virtualbox.org/](https://www.virtualbox.org/)
   - Install using the GUI installer with default settings
   - Restart if prompted

2. **Verify Installation:**

   - Launch VirtualBox and note the version number

In `labs/submission5.md`, document:
- Host operating system and version (e.g., "Windows 11 Pro 23H2", "macOS Sonoma 14.1", "Ubuntu 22.04 LTS")
- VirtualBox version number
- Any installation issues encountered

---

### Task 2 — Ubuntu VM and System Analysis (5 pts)

**Objective:** Deploy Ubuntu 24.04 LTS in VirtualBox and discover tools to analyze system information.

#### 2.1: Create Ubuntu VM

1. **VM Setup:**

   - Download Ubuntu 24.04 LTS ISO from [https://ubuntu.com/download/desktop](https://ubuntu.com/download/desktop)
   - Create new VM in VirtualBox with:
     - RAM: 4GB minimum (8GB recommended)
     - Storage: 25GB minimum
     - CPU: 2 cores minimum
   - Install Ubuntu using the default installation process

#### 2.2: System Information Discovery

1. **Find Tools to Gather Information:**

   Research and discover command-line tools that can provide:
   - **CPU Details**: Processor model, architecture, cores, frequency
   - **Memory Information**: Total RAM, available memory
   - **Network Configuration**: IP addresses, network interfaces
   - **Storage Information**: Disk usage, filesystem details
   - **Operating System**: Ubuntu version, kernel information
   - **Virtualization Detection**: Confirmation system is running in a VM

   <details>
   <summary>💡 Where to start your research</summary>

   - Check `/proc` filesystem for hardware information
   - Explore standard Linux system commands
   - Look for commands starting with `ls`, `ip`, `df`, `free`, `uname`
   - Search for tools that can detect virtualization
   - Use `man` pages and `--help` flags to understand commands

   </details>

In `labs/submission5.md`, document:
- VM configuration specifications used (RAM, storage, CPU cores)
- For each information type above:
  - Tool name(s) you discovered
  - Command(s) used
  - Complete command output
- Brief reflection on which tools were most useful and why

---

## How to Submit

1. Create a branch for this lab and push it to your fork:

   ```bash
   git switch -c feature/lab5
   # create labs/submission5.md with your findings
   git add labs/submission5.md
   git commit -m "docs: add lab5 submission"
   git push -u origin feature/lab5
   ```

2. Open a PR from your fork's `feature/lab5` branch → **course repository's main branch**.

3. In the PR description, include:

   ```text
   - [x] Task 1 done
   - [x] Task 2 done
   ```

4. **Copy the PR URL** and submit it via **Moodle before the deadline**.

---

## Acceptance Criteria

- ✅ Branch `feature/lab5` exists with commits for each task.
- ✅ File `labs/submission5.md` contains required outputs and analysis for Tasks 1-2.
- ✅ VirtualBox is successfully installed and verified.
- ✅ Ubuntu 24.04 LTS VM is deployed and documented.
- ✅ System analysis shows comprehensive hardware and OS information.
- ✅ PR from `feature/lab5` → **course repo main branch** is open.
- ✅ PR link submitted via Moodle before the deadline.

---

## Rubric (10 pts)

| Criterion                                      | Points |
| ---------------------------------------------- | -----: |
| Task 1 — VirtualBox installation              |   **5** |
| Task 2 — Ubuntu VM + system analysis          |   **5** |
| **Total**                                      |  **10** |

---

## Guidelines

- Use clear Markdown headers to organize sections in `submission5.md`.
- Include complete command outputs with proper formatting.
- Document your tool discovery process and reasoning.

<details>
<summary>📚 Helpful Resources</summary>

- [VirtualBox Documentation](https://www.virtualbox.org/wiki/Documentation)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- [Linux Command Line Basics](https://ubuntu.com/tutorials/command-line-for-beginners)

</details>

<details>
<summary>💡 Installation Tips</summary>

1. Download software only from official websites.
2. Use default installation settings unless you have specific requirements.
3. Ensure your host system has sufficient resources before creating VMs.
4. Enable virtualization in BIOS/UEFI if VM performance is poor.

</details>

<details>
<summary>🔍 Tool Discovery Tips</summary>

1. Start with built-in Linux commands before installing additional packages.
2. Use package managers (apt) to search for system information tools.
3. Test multiple tools and compare their outputs.
4. Document which tools provide the most useful information.

</details>