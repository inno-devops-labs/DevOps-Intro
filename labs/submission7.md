# Lab 7 Submission — GitOps Fundamentals

**Student:** Diana Minnakhmetova  
**Date:** 13-03-2026  
**Branch:** feature/lab7  

---

## Task 1: Git State Reconciliation

### 1.1 — Initial Desired State Configuration


#### Desired State (Source of Truth)
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "version: 1.0" > desired-state.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "app: myapp" >> desired-state.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "replicas: 3" >> desired-state.txt

dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat desired-state.txt
version: 1.0
app: myapp
replicas: 3
```

#### Current State (Initial Sync)
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cp desired-state.txt current-state.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "Initial state synchronized"
Initial state synchronized

dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat current-state.txt
version: 1.0
app: myapp
replicas: 3
```

---

### 1.2 — Reconciliation Loop Implementation

#### Reconciliation Script (`reconcile.sh`)
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat reconcile.sh
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

dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % chmod +x reconcile.sh
```

---

### 1.3 — Manual Drift Detection & Reconciliation

#### Simulate Configuration Drift
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "version: 2.0" > current-state.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "app: myapp" >> current-state.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "replicas: 5" >> current-state.txt

dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat current-state.txt
version: 2.0
app: myapp
replicas: 5
```

#### Drift Detection Output
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % ./reconcile.sh

пятница, 13 марта 2026 г. 19:19:29 (MSK) - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
пятница, 13 марта 2026 г. 19:19:29 (MSK) - ✅ Reconciliation complete
```

#### Verification — Drift Fixed
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % diff desired-state.txt current-state.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat current-state.txt

version: 1.0
app: myapp
replicas: 3
```

---

### 1.4 — Continuous Reconciliation Loop (Auto-Healing)

#### Monitoring Loop (macOS Alternative to `watch`)
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % watch -n 5 ./reconcile.sh
zsh: command not found: watch
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "monitoring" | tee monitoring.log

for i in {1..10}; do

echo "" >> monitoring.log

echo "iteration $i - $(date)" | tee -a monitoring.log

 ./reconcile.sh | tee -a monitoring.log

sleep 2

done

echo "Saved to monitoring.log"

cat monitoring.log
monitoring
iteration 1 - пятница, 13 марта 2026 г. 19:21:15 (MSK)
пятница, 13 марта 2026 г. 19:21:15 (MSK) - ✅ States synchronized
iteration 2 - пятница, 13 марта 2026 г. 19:21:17 (MSK)
пятница, 13 марта 2026 г. 19:21:17 (MSK) - ✅ States synchronized
iteration 3 - пятница, 13 марта 2026 г. 19:21:19 (MSK)
пятница, 13 марта 2026 г. 19:21:19 (MSK) - ✅ States synchronized
iteration 4 - пятница, 13 марта 2026 г. 19:21:21 (MSK)
пятница, 13 марта 2026 г. 19:21:21 (MSK) - ✅ States synchronized
iteration 5 - пятница, 13 марта 2026 г. 19:21:23 (MSK)
пятница, 13 марта 2026 г. 19:21:23 (MSK) - ✅ States synchronized
iteration 6 - пятница, 13 марта 2026 г. 19:21:25 (MSK)
пятница, 13 марта 2026 г. 19:21:25 (MSK) - ✅ States synchronized
iteration 7 - пятница, 13 марта 2026 г. 19:21:27 (MSK)
пятница, 13 марта 2026 г. 19:21:27 (MSK) - ✅ States synchronized
iteration 8 - пятница, 13 марта 2026 г. 19:21:29 (MSK)
пятница, 13 марта 2026 г. 19:21:29 (MSK) - ✅ States synchronized
iteration 9 - пятница, 13 марта 2026 г. 19:21:31 (MSK)
пятница, 13 марта 2026 г. 19:21:31 (MSK) - ✅ States synchronized
iteration 10 - пятница, 13 марта 2026 г. 19:21:33 (MSK)
пятница, 13 марта 2026 г. 19:21:33 (MSK) - ✅ States synchronized
Saved to monitoring.log
monitoring

iteration 1 - пятница, 13 марта 2026 г. 19:21:15 (MSK)
пятница, 13 марта 2026 г. 19:21:15 (MSK) - ✅ States synchronized

iteration 2 - пятница, 13 марта 2026 г. 19:21:17 (MSK)
пятница, 13 марта 2026 г. 19:21:17 (MSK) - ✅ States synchronized

iteration 3 - пятница, 13 марта 2026 г. 19:21:19 (MSK)
пятница, 13 марта 2026 г. 19:21:19 (MSK) - ✅ States synchronized

iteration 4 - пятница, 13 марта 2026 г. 19:21:21 (MSK)
пятница, 13 марта 2026 г. 19:21:21 (MSK) - ✅ States synchronized

iteration 5 - пятница, 13 марта 2026 г. 19:21:23 (MSK)
пятница, 13 марта 2026 г. 19:21:23 (MSK) - ✅ States synchronized

iteration 6 - пятница, 13 марта 2026 г. 19:21:25 (MSK)
пятница, 13 марта 2026 г. 19:21:25 (MSK) - ✅ States synchronized

iteration 7 - пятница, 13 марта 2026 г. 19:21:27 (MSK)
пятница, 13 марта 2026 г. 19:21:27 (MSK) - ✅ States synchronized

iteration 8 - пятница, 13 марта 2026 г. 19:21:29 (MSK)
пятница, 13 марта 2026 г. 19:21:29 (MSK) - ✅ States synchronized

iteration 9 - пятница, 13 марта 2026 г. 19:21:31 (MSK)
пятница, 13 марта 2026 г. 19:21:31 (MSK) - ✅ States synchronized

iteration 10 - пятница, 13 марта 2026 г. 19:21:33 (MSK)
пятница, 13 марта 2026 г. 19:21:33 (MSK) - ✅ States synchronized
```

#### Live Auto-Healing Output
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % while true; do echo "=== $(date) ==="; ./reconcile.sh; sleep 5; done | tee monitoring.log
=== пятница, 13 марта 2026 г. 19:27:52 (MSK) ===
пятница, 13 марта 2026 г. 19:27:52 (MSK) - ✅ States synchronized
=== пятница, 13 марта 2026 г. 19:27:57 (MSK) ===
пятница, 13 марта 2026 г. 19:27:57 (MSK) - ✅ States synchronized
=== пятница, 13 марта 2026 г. 19:28:02 (MSK) ===
пятница, 13 марта 2026 г. 19:28:02 (MSK) - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
пятница, 13 марта 2026 г. 19:28:02 (MSK) - ✅ Reconciliation complete
=== пятница, 13 марта 2026 г. 19:28:07 (MSK) ===
пятница, 13 марта 2026 г. 19:28:07 (MSK) - ✅ States synchronized
=== пятница, 13 марта 2026 г. 19:28:12 (MSK) ===
пятница, 13 марта 2026 г. 19:28:12 (MSK) - ✅ States synchronized
=== пятница, 13 марта 2026 г. 19:28:17 (MSK) ===
пятница, 13 марта 2026 г. 19:28:17 (MSK) - ✅ States synchronized
=== пятница, 13 марта 2026 г. 19:28:22 (MSK) ===
пятница, 13 марта 2026 г. 19:28:22 (MSK) - ✅ States synchronized
=== пятница, 13 марта 2026 г. 19:28:27 (MSK) ===
пятница, 13 марта 2026 г. 19:28:27 (MSK) - ✅ States synchronized
=== пятница, 13 марта 2026 г. 19:28:32 (MSK) ===
пятница, 13 марта 2026 г. 19:28:32 (MSK) - ✅ States synchronized
=== пятница, 13 марта 2026 г. 19:28:37 (MSK) ===
пятница, 13 марта 2026 г. 19:28:37 (MSK) - ✅ States synchronized
=== пятница, 13 марта 2026 г. 19:28:42 (MSK) ===
пятница, 13 марта 2026 г. 19:28:42 (MSK) - ✅ States synchronized
=== пятница, 13 марта 2026 г. 19:28:47 (MSK) ===
пятница, 13 марта 2026 г. 19:28:47 (MSK) - ✅ States synchronized
=== пятница, 13 марта 2026 г. 19:28:52 (MSK) ===
пятница, 13 марта 2026 г. 19:28:52 (MSK) - ✅ States synchronized
^C
```

#### Trigger (from another terminal)
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "replicas: 10" >> current-state.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % 
```

**Result:** Within 5 seconds, the reconciliation loop detected the drift and automatically corrected it.

---

### 1.5 — Analysis & Reflection

#### How GitOps Reconciliation Loop Prevents Configuration Drift

The reconciliation loop operates on a simple but powerful principle:

**Continuous State Verification:**
- Every 5 seconds (configurable interval), the system compares the desired state (stored in Git) against the current state (running configuration)
- This mimics how production GitOps tools like ArgoCD and Flux CD work on Kubernetes clusters

**Automatic Remediation:**
- When drift is detected (desired ≠ current), the system automatically restores the desired state
- No manual intervention required — the system self-heals
- This prevents configuration decay where manual changes accumulate over time

**Prevention Mechanism:**
- By treating Git as the single source of truth, any unauthorized or accidental changes are automatically reverted
- This eliminates configuration drift at the root: deviations are corrected before they cause problems
- The loop runs continuously, catching drift as soon as it occurs

#### Advantages of Declarative Configuration Over Imperative Commands

**Declarative Approach (used here):**
```
DESIRED: "version: 1.0, replicas: 3"
→ System ensures current state matches this
```

**vs. Imperative Approach:**
```
RUN: "scale-to 3 replicas, set version to 1.0"
→ Step-by-step instructions, no guarantee of end state
```

**Key Advantages in Production:**

1. **Reproducibility**
   - Declaring the end state ensures identical configurations across environments
   - No dependency on the sequence of commands executed

2. **Auditability & Version Control**
   - All configuration changes go through Git history
   - Easy to track who changed what and when
   - Rollback is trivial (revert Git commit)

3. **Self-Healing & High Availability**
   - If someone accidentally modifies the system, it auto-corrects to the declared state
   - Reduces human error impact
   - No "drift creep" where systems diverge over time

4. **Scalability**
   - One Git repo can manage configurations for hundreds of services/clusters
   - Imperative commands don't scale (manual steps for each environment)

5. **Determinism**
   - Declarative config is idempotent: applying the same config multiple times produces the same result
   - Imperative commands can fail or produce different results if run twice

**Real-World Example:**
In production, a developer might accidentally SSH into a server and change a config file. With imperative approach, this change persists and causes drift. With declarative GitOps, the reconciliation loop detects this within seconds and reverts it to the desired state — maintaining system integrity automatically.

---

### Tools & Commands Used

| Tool | Command | Purpose |
|------|---------|---------|
| Bash | `cat`, `echo`, `cp` | File manipulation & state comparison |
| File Comparison | `diff` | Detect differences between states |
| Scripting | `while true`, `sleep` | Implement continuous reconciliation loop |
| Logging | `tee -a` | Capture all monitoring output to file |



## Task 2: GitOps Health Monitoring

### 2.1 — Health Check Script Implementation

#### Create Health Check Script
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat > healthcheck.sh << 'EOF'
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
EOF
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % chmod +x healthcheck.sh
```

---

### 2.2 — Test Health Monitoring

#### Test 1: Healthy State (States Synchronized)
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % ls -la healthcheck.sh
-rwxr-xr-x@ 1 dminnakhmetova  staff  499 13 мар 19:41 healthcheck.sh
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % rm health.log 2>/dev/null

dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % ./healthcheck.sh

пятница, 13 марта 2026 г. 19:42:10 (MSK) - ✅ OK: States synchronized
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat health.log
пятница, 13 марта 2026 г. 19:42:10 (MSK) - ✅ OK: States synchronized
```

**Analysis:** When `desired-state.txt` and `current-state.txt` match, MD5 checksums are identical → health check passes with ✅ OK status.

---

#### Test 2: Simulate Configuration Drift
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % echo "unapproved-change: true" >> current-state.txt
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % ./healthcheck.sh

пятница, 13 марта 2026 г. 19:42:29 (MSK) - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat health.log
пятница, 13 марта 2026 г. 19:42:10 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:42:29 (MSK) - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

**Analysis:** Adding `unapproved-change: true` changed the MD5 checksum of `current-state.txt`. Even a single character difference produces a completely different hash → drift immediately detected.

---

#### Test 3: Fix Drift & Verify Recovery
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % ./reconcile.sh

пятница, 13 марта 2026 г. 19:42:40 (MSK) - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
пятница, 13 марта 2026 г. 19:42:40 (MSK) - ✅ Reconciliation complete
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % ./healthcheck.sh

пятница, 13 марта 2026 г. 19:42:44 (MSK) - ✅ OK: States synchronized
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat health.log

пятница, 13 марта 2026 г. 19:42:10 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:42:29 (MSK) - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
пятница, 13 марта 2026 г. 19:42:44 (MSK) - ✅ OK: States synchronized
```

**Analysis:** After reconciliation, MD5 checksums match again → system recovered to healthy state. Health log shows complete lifecycle: healthy → critical → recovered.

---

### 2.3 — Continuous Health Monitoring Loop

#### Combined Monitoring Script (`monitor.sh`)
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat > monitor.sh << 'EOF'
#!/bin/bash
# monitor.sh - Combined reconciliation and health monitoring

echo "Starting GitOps monitoring..."
for i in {1..10}; do
    echo ""
    echo "--- Check #$i ---"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 3
done

echo ""
echo "=== FINAL HEALTH LOG ==="
cat health.log
EOF
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % chmod +x monitor.sh
```

#### Monitor.sh Execution Output
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % ./monitor.sh
Starting GitOps monitoring...

--- Check #1 ---
пятница, 13 марта 2026 г. 19:44:26 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:26 (MSK) - ✅ States synchronized

--- Check #2 ---
пятница, 13 марта 2026 г. 19:44:29 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:29 (MSK) - ✅ States synchronized

--- Check #3 ---
пятница, 13 марта 2026 г. 19:44:32 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:32 (MSK) - ✅ States synchronized

--- Check #4 ---
пятница, 13 марта 2026 г. 19:44:35 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:35 (MSK) - ✅ States synchronized

--- Check #5 ---
пятница, 13 марта 2026 г. 19:44:38 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:38 (MSK) - ✅ States synchronized

--- Check #6 ---
пятница, 13 марта 2026 г. 19:44:41 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:41 (MSK) - ✅ States synchronized

--- Check #7 ---
пятница, 13 марта 2026 г. 19:44:45 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:45 (MSK) - ✅ States synchronized

--- Check #8 ---
пятница, 13 марта 2026 г. 19:44:48 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:48 (MSK) - ✅ States synchronized

--- Check #9 ---
пятница, 13 марта 2026 г. 19:44:51 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:51 (MSK) - ✅ States synchronized

--- Check #10 ---
пятница, 13 марта 2026 г. 19:44:54 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:54 (MSK) - ✅ States synchronized

=== FINAL HEALTH LOG ===
пятница, 13 марта 2026 г. 19:42:10 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:42:29 (MSK) - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
пятница, 13 марта 2026 г. 19:42:44 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:26 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:29 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:32 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:35 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:38 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:41 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:45 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:48 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:51 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:54 (MSK) - ✅ OK: States synchronized
```

#### Complete Health Log
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat health.log
пятница, 13 марта 2026 г. 19:42:10 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:42:29 (MSK) - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
пятница, 13 марта 2026 г. 19:42:44 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:26 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:29 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:32 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:35 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:38 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:41 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:45 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:48 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:51 (MSK) - ✅ OK: States synchronized
пятница, 13 марта 2026 г. 19:44:54 (MSK) - ✅ OK: States synchronized
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % 
```

---

### 2.4 — Analysis & Reflection

#### How Checksums (MD5) Help Detect Configuration Changes

**MD5 Checksum Mechanism:**
- MD5 produces a 128-bit fixed-length hash (32 hexadecimal characters)
- Any change to input file → completely different hash (avalanche effect)
- Computation is fast (< 1ms even for large files)

**Detection Advantages:**

| Approach | Speed | Accuracy | Use Case |
|----------|-------|----------|----------|
| Full File Comparison | Slow on large files | 100% | Detailed analysis |
| **MD5 Checksum** | **Very fast** | **100%** | **Real-time monitoring** |
| Line-by-line diff | Slow | High | Human review |

**Example from Our Lab:**

```
Desired MD5:  a15a1a4f965ecd8f9e23a33a6b543155
Current MD5:  48168ff3ab5ffc0214e81c7e2ee356f5
Difference:   100% mismatch detected
```

Even adding one line (`unapproved-change: true`) completely changed the hash. This allows instant drift detection without comparing the entire file contents.

**Real-World Benefit:**
In production monitoring, checksums let you check thousands of configuration files per second. A Kubernetes cluster might have 10,000+ resources; MD5-based health checks can verify all of them in milliseconds.

---

#### Relationship to ArgoCD's "Sync Status"

**How ArgoCD Uses Similar Logic:**

1. **Desired State** = Git repository (source of truth)
2. **Current State** = Live Kubernetes cluster resources
3. **Sync Status** = Comparison of the two

**ArgoCD's Status Output:**

```
Status: OutOfSync / Synced
Revision: abc123def456
Health: Healthy / Degraded
```

**Our Implementation vs. ArgoCD:**

| Aspect | Our Lab | ArgoCD |
|--------|---------|--------|
| Comparison method | MD5 checksum | Resource manifest comparison |
| Frequency | Every 5 seconds (configurable) | Every 3 minutes (configurable) |
| Scope | Two text files | Entire Kubernetes cluster |
| Auto-sync | Manual reconcile.sh | Automatic or manual via UI |
| Logging | health.log file | ArgoCD web dashboard + Prometheus |

**Key Similarity:**
Both detect when the **running state** diverges from the **declared state** and can automatically correct it. ArgoCD extends this to enterprise scale with multiple clusters, but the core principle is identical:


Compare(GitState, ClusterState) → if different → Reconcile()


**Why This Matters:**
This lab demonstrates that GitOps isn't magic — it's a simple, repeatable pattern that scales from 2 files to 10,000+ Kubernetes resources. The same `if desired != current then fix it` loop powers both our shell scripts and production systems managing Fortune 500 infrastructure.

---

### Tools & Commands Summary

| Tool | Command | Purpose |
|------|---------|---------|
| MD5 Hashing | `md5sum` | Generate file fingerprints for comparison |
| Text Processing | `awk '{print $1}'` | Extract MD5 hash from output |
| Conditional Logic | `if [ "$A" != "$B" ]` | Compare states and trigger actions |
| Logging | `tee -a` | Write to file AND display in terminal |
| Loops | `for i in {1..10}` | Repeat monitoring process |
| Delay | `sleep 3` | Add pause between checks (simulate real monitoring) |



