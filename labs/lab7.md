# Lab 7 — GitOps Fundamentals

![difficulty](https://img.shields.io/badge/difficulty-intermediate-yellow)
![topic](https://img.shields.io/badge/topic-GitOps-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Understand core GitOps principles through simulated reconciliation loops and health monitoring using only Linux command-line tools.  
> **Deliverable:** A PR from `feature/lab7` to the course repo with `labs/submission7.md` containing all task outputs and analysis. Submit the PR link via Moodle.

---

## Overview

In this lab you will practice:
- Managing **declarative configuration** using Git as the source of truth.
- Implementing **automated reconciliation loops** to detect and fix drift.
- Building **self-healing systems** that continuously sync desired state.
- Monitoring **state synchronization health** with checksums and logging.

These simulations mirror how real GitOps tools (ArgoCD, Flux) work, helping you understand the fundamentals before using production tools.

---

## Tasks

### Task 1 — Git State Reconciliation (6 pts)

**Objective:** Simulate how GitOps operators continuously synchronize cluster state with Git as the source of truth.

#### 1.1: Setup Desired State Configuration

1. **Create Desired State (Source of Truth):**

   ```bash
   echo "version: 1.0" > desired-state.txt
   echo "app: myapp" >> desired-state.txt
   echo "replicas: 3" >> desired-state.txt
   ```

2. **Simulate Current Cluster State:**

   ```bash
   cp desired-state.txt current-state.txt
   echo "Initial state synchronized"
   ```

#### 1.2: Create Reconciliation Loop

1. **Create Reconciliation Script:**

   Create a file named `reconcile.sh`:

   ```bash
   #!/bin/bash
   # reconcile.sh - GitOps reconciliation loop
   
   DESIRED=$(cat desired-state.txt)
   CURRENT=$(cat current-state.txt)
   
   if [ "$DESIRED" != "$CURRENT" ]; then
       echo "$(date) - ⚠️  DRIFT DETECTED!"
       echo "Reconciling current state with desired state..."
       cp desired-state.txt current-state.txt
       echo "$(date) - ✅ Reconciliation complete"
   else
       echo "$(date) - ✅ States synchronized"
   fi
   ```

2. **Make Script Executable:**

   ```bash
   chmod +x reconcile.sh
   ```

#### 1.3: Test Manual Drift Detection

1. **Simulate Manual Drift:**

   ```bash
   echo "version: 2.0" > current-state.txt
   echo "app: myapp" >> current-state.txt
   echo "replicas: 5" >> current-state.txt
   ```

2. **Run Reconciliation Manually:**

   ```bash
   ./reconcile.sh
   diff desired-state.txt current-state.txt
   ```

3. **Verify Drift Was Fixed:**

   ```bash
   cat current-state.txt
   ```

#### 1.4: Automated Continuous Reconciliation

1. **Start Continuous Reconciliation Loop:**

   ```bash
   watch -n 5 ./reconcile.sh
   ```

   <details>
   <summary>💡 Understanding watch command</summary>

   `watch -n 5` runs the command every 5 seconds, similar to how GitOps tools continuously sync state.

   Press `Ctrl+C` to stop the watch process.

   </details>

2. **In Another Terminal, Trigger Drift:**

   ```bash
   cd gitops-lab
   echo "replicas: 10" >> current-state.txt
   ```

3. **Observe Auto-Healing:**

   Watch the reconciliation loop automatically detect and fix the drift within 5 seconds.

In `labs/submission7.md`, document:
- Initial desired-state.txt and current-state.txt contents
- Screenshot or output of drift detection and reconciliation
- Output showing synchronized state after reconciliation
- Output from continuous reconciliation loop detecting auto-healing
- Analysis: Explain the GitOps reconciliation loop. How does this prevent configuration drift?
- Reflection: What advantages does declarative configuration have over imperative commands in production?

---

### Task 2 — GitOps Health Monitoring (4 pts)

**Objective:** Implement health checks for configuration synchronization and build proactive monitoring.

#### 2.1: Create Health Check Script

1. **Create Health Check Script:**

   Create a file named `healthcheck.sh`:

   ```bash
   #!/bin/bash
   # healthcheck.sh - Monitor GitOps sync health
   
   DESIRED_MD5=$(md5sum desired-state.txt | awk '{print $1}')
   CURRENT_MD5=$(md5sum current-state.txt | awk '{print $1}')
   
   if [ "$DESIRED_MD5" != "$CURRENT_MD5" ]; then
       echo "$(date) - ❌ CRITICAL: State mismatch detected!" | tee -a health.log
       echo "  Desired MD5: $DESIRED_MD5" | tee -a health.log
       echo "  Current MD5: $CURRENT_MD5" | tee -a health.log
   else
       echo "$(date) - ✅ OK: States synchronized" | tee -a health.log
   fi
   ```

   ```bash
   chmod +x healthcheck.sh
   ```

#### 2.2: Test Health Monitoring

1. **Test Healthy State:**

   ```bash
   ./healthcheck.sh
   cat health.log
   ```

2. **Simulate Configuration Drift:**

   ```bash
   echo "unapproved-change: true" >> current-state.txt
   ```

3. **Run Health Check on Drifted State:**

   ```bash
   ./healthcheck.sh
   cat health.log
   ```

4. **Fix Drift and Verify:**

   ```bash
   ./reconcile.sh
   ./healthcheck.sh
   cat health.log
   ```

#### 2.3: Continuous Health Monitoring

1. **Create Combined Monitoring Script:**

   Create a file named `monitor.sh`:

   ```bash
   #!/bin/bash
   # monitor.sh - Combined reconciliation and health monitoring
   
   echo "Starting GitOps monitoring..."
   for i in {1..10}; do
       echo "\n--- Check #$i ---"
       ./healthcheck.sh
       ./reconcile.sh
       sleep 3
   done
   ```

   ```bash
   chmod +x monitor.sh
   ```

2. **Run Monitoring Loop:**

   ```bash
   ./monitor.sh
   ```

3. **Review Complete Health Log:**

   ```bash
   cat health.log
   ```

In `labs/submission7.md`, document:
- Contents of healthcheck.sh script
- Output showing "OK" status when states match
- Output showing "CRITICAL" status when drift is detected
- Complete health.log file showing multiple checks
- Output from monitor.sh showing continuous monitoring
- Analysis: How do checksums (MD5) help detect configuration changes?
- Comparison: How does this relate to GitOps tools like ArgoCD's "Sync Status"?

---

## How to Submit

1. Complete all tasks and document your work in `labs/submission7.md`

2. Open a PR from your fork's `feature/lab7` branch → **course repository's main branch**.

3. In the PR description, include:

   ```text
   - [x] Task 1 — Git State Reconciliation
   - [x] Task 2 — GitOps Health Monitoring
   ```

4. **Copy the PR URL** and submit it via **Moodle before the deadline**.

---

## Acceptance Criteria

- ✅ Branch `feature/lab7` exists with commits for each task.
- ✅ File `labs/submission7.md` contains required outputs and analysis for Tasks 1-2.
- ✅ Scripts `reconcile.sh`, `healthcheck.sh`, and `monitor.sh` are functional.
- ✅ Health log demonstrates both healthy and drifted states.
- ✅ Analysis sections demonstrate understanding of GitOps principles.
- ✅ PR from `feature/lab7` → **course repo main branch** is open.
- ✅ PR link submitted via Moodle before the deadline.

---

## Rubric (10 pts)

| Criterion                                | Points |
| ---------------------------------------- | -----: |
| Task 1 — Git State Reconciliation         |  **6** |
| Task 2 — GitOps Health Monitoring         |  **4** |
| **Total**                                | **10** |

---

## Guidelines

- Use clear Markdown headers to organize sections in `submission7.md`.
- Include command outputs, script contents, and screenshots where helpful.
- Focus on understanding the reconciliation loop concept, not just running scripts.
- Provide thoughtful analysis connecting simulations to real GitOps tools.
- Document your observations during continuous monitoring.

<details>
<summary>📚 GitOps Concepts</summary>

| Task | GitOps Principle           | Real-World Equivalent                 |
| ---- | -------------------------- | ------------------------------------- |
| 1    | Continuous Reconciliation  | ArgoCD/Flux sync loops                |
| 2    | Health Monitoring          | Kubernetes operator status checks     |

**GitOps Philosophy:**
1. **Git as Single Source of Truth** - All configuration changes go through Git.
2. **Declarative Configuration** - Define the desired state, not the steps to get there.
3. **Automated Reconciliation** - Systems continuously sync to match Git state.
4. **Self-Healing** - Drift is automatically corrected without manual intervention.

</details>

<details>
<summary>📚 Helpful Resources</summary>

- [GitOps Principles](https://opengitops.dev/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Flux CD Documentation](https://fluxcd.io/docs/)

</details>

<details>
<summary>💡 Tips</summary>

1. These simulations mirror how real GitOps operators work - just at human speed instead of computer speed!
2. Understanding these fundamentals prepares you for tools like ArgoCD and Flux CD.
3. Use multiple terminals to see drift detection in real-time.
4. Keep your scripts simple and focus on understanding the concepts.

</details>