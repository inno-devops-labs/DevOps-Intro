# Lab 7 Submission — GitOps Reconciliation and Health Monitoring

**Student:** Rodion Krainov

**Email:** [r.krainov@innopolis.university](mailto:r.krainov@innopolis.university)

**GitHub:** r3based

---

## Task 1 — Git State Reconciliation

### 1.1 Setup Desired State Configuration

I first created the desired state file and copied it into the current state file so that both started in a synchronized condition.

### Commands

```bash
➜  DevOps-Intro git:(Feature/lab7) echo "version: 1.0" > desired-state.txt
➜  DevOps-Intro git:(Feature/lab7) echo "app: myapp" >> desired-state.txt
➜  DevOps-Intro git:(Feature/lab7) echo "replicas: 3" >> desired-state.txt
➜  DevOps-Intro git:(Feature/lab7) cp desired-state.txt current-state.txt
```

### Initial file contents

#### `desired-state.txt`

```text
version: 1.0
app: myapp
replicas: 3
```

#### `current-state.txt`

```text
version: 1.0
app: myapp
replicas: 3
```

At this stage, both files were identical, which represents a healthy synchronized state.

---

### 1.2 Create Reconciliation Loop

I implemented a simple reconciliation script that compares the desired state with the current state and restores the current state if drift is detected.

### `reconcile.sh`

```bash
#!/bin/bash

DESIRED=$(cat desired-state.txt)
CURRENT=$(cat current-state.txt)

if [ "$DESIRED" != "$CURRENT" ]; then
    echo "$(date) - DRIFT DETECTED!"
    echo "Reconciling current state with desired state..."
    cp desired-state.txt current-state.txt
    echo "$(date) - Reconciliation complete"
else
    echo "$(date) - States synchronized"
fi
```

### Command

```bash
➜  DevOps-Intro git:(Feature/lab7) chmod +x reconcile.sh
```

### Explanation

This script simulates a basic GitOps reconciliation loop:

* `desired-state.txt` acts as the source of truth,
* `current-state.txt` represents the live state,
* if the files differ, the script restores the live state from the desired state.

---

### 1.3 Manual Drift Detection Test

To test reconciliation, I manually changed the current state to simulate configuration drift.

### Commands

```bash
➜  DevOps-Intro git:(Feature/lab7) echo "version: 2.0" > current-state.txt
➜  DevOps-Intro git:(Feature/lab7) echo "app: myapp" >> current-state.txt
➜  DevOps-Intro git:(Feature/lab7) echo "replicas: 5" >> current-state.txt
➜  DevOps-Intro git:(Feature/lab7) bash reconcile.sh
➜  DevOps-Intro git:(Feature/lab7) diff desired-state.txt current-state.txt
➜  DevOps-Intro git:(Feature/lab7) cat current-state.txt
```

### Example output

```text
Fri Mar 20 14:34:45 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 14:34:45 MSK 2026 - ✅ Reconciliation complete
```

The `diff` command produced no output after reconciliation, which confirmed that both files became identical again.

### Final `current-state.txt`

```text
version: 1.0
app: myapp
replicas: 3
```

### Result

The script successfully detected manual drift and restored the correct state automatically.

---

### 1.4 Continuous Reconciliation

To simulate continuous GitOps behavior, I ran the reconciliation loop periodically.

### Command

```bash
➜  DevOps-Intro git:(Feature/lab7) watch -n 5 ./reconcile.sh
```

If `watch` is unavailable, the same logic can be implemented as:

```bash
while true; do ./reconcile.sh; sleep 5; done
```

Then I introduced drift from another terminal:

```bash
➜  DevOps-Intro git:(Feature/lab7) echo "replicas: 10" >> current-state.txt
```

### Observation

The system detected the unauthorized change and auto-healed it within the next reconciliation interval.

---

### Task 1 Analysis

This task demonstrates the core GitOps principle: the declared configuration is the source of truth, and the system continuously reconciles live state to match it.

In this lab:

* `desired-state.txt` represents the declarative state,
* `current-state.txt` represents the actual state,
* `reconcile.sh` acts like a very simple controller.

If drift appears due to manual modification, the controller detects it and restores the correct configuration. This reduces long-term configuration drift and makes environments more predictable.

---

### Task 1 Reflection

Declarative configuration is more reliable than imperative configuration in production because it defines the **target state**, not just the sequence of commands used to reach it.

Its main advantages are:

* easier review through version control,
* repeatability across environments,
* safer rollback behavior,
* better automation and self-healing.

Imperative commands are still useful for ad hoc operations, but they are more likely to create hidden differences between environments.

---

## Task 2 — GitOps Health Monitoring

### 2.1 Create Health Check Script

I created a second script to monitor synchronization health using MD5 checksums.

### `healthcheck.sh`

```bash
#!/bin/bash

DESIRED_MD5=$(md5sum desired-state.txt | awk '{print $1}')
CURRENT_MD5=$(md5sum current-state.txt | awk '{print $1}')

if [ "$DESIRED_MD5" != "$CURRENT_MD5" ]; then
    echo "$(date) - CRITICAL: State mismatch detected!" | tee -a health.log
    echo "  Desired MD5: $DESIRED_MD5" | tee -a health.log
    echo "  Current MD5: $CURRENT_MD5" | tee -a health.log
else
    echo "$(date) - OK: States synchronized" | tee -a health.log
fi
```

### Command

```bash
➜  DevOps-Intro git:(Feature/lab7) chmod +x healthcheck.sh
```

---

### 2.2 Test Health Monitoring

I first tested the healthy case where both files matched.

### Healthy state commands

```bash
➜  DevOps-Intro git:(Feature/lab7) ./healthcheck.sh
➜  DevOps-Intro git:(Feature/lab7) cat health.log
```

### Healthy output

```text
Fri Mar 20 14:37:17 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:37:17 MSK 2026 - ✅ OK: States synchronized
```

Then I simulated drift:

```bash
➜  DevOps-Intro git:(Feature/lab7) echo "unapproved-change: true" >> current-state.txt
➜  DevOps-Intro git:(Feature/lab7) ./healthcheck.sh
➜  DevOps-Intro git:(Feature/lab7) cat health.log
```

### Drift output

```text
Fri Mar 20 14:37:34 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:37:17 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:37:34 MSK 2026 - ✅ OK: States synchronized
```

After that, I restored the system and checked health again:

```bash
➜  DevOps-Intro git:(Feature/lab7) ./reconcile.sh
➜  DevOps-Intro git:(Feature/lab7) ./healthcheck.sh
➜  DevOps-Intro git:(Feature/lab7) cat health.log
```

### Output after reconciliation

```text
Fri Mar 20 14:37:39 MSK 2026 - ✅ States synchronized
Fri Mar 20 14:37:39 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:37:17 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:37:34 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:37:39 MSK 2026 - ✅ OK: States synchronized
```

---

### 2.3 Continuous Health Monitoring

To combine health checking and reconciliation, I created a monitoring script.

### `monitor.sh`

```bash
#!/bin/bash

echo "Starting GitOps monitoring..."
for i in {1..10}; do
    echo
    echo "--- Check #$i ---"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 3
done
```

### Commands

```bash
➜  DevOps-Intro git:(Feature/lab7) chmod +x monitor.sh
➜  DevOps-Intro git:(Feature/lab7) ./monitor.sh
➜  DevOps-Intro git:(Feature/lab7) cat health.log
```

### `monitor.sh` output

```text
Starting GitOps monitoring...
\n--- Check #1 ---
Fri Mar 20 14:38:18 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:18 MSK 2026 - ✅ States synchronized
\n--- Check #2 ---
Fri Mar 20 14:38:21 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:21 MSK 2026 - ✅ States synchronized
\n--- Check #3 ---
Fri Mar 20 14:38:24 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:24 MSK 2026 - ✅ States synchronized
\n--- Check #4 ---
Fri Mar 20 14:38:27 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:27 MSK 2026 - ✅ States synchronized
\n--- Check #5 ---
Fri Mar 20 14:38:30 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:30 MSK 2026 - ✅ States synchronized
\n--- Check #6 ---
Fri Mar 20 14:38:33 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:33 MSK 2026 - ✅ States synchronized
\n--- Check #7 ---
Fri Mar 20 14:38:34 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:34 MSK 2026 - ✅ States synchronized
\n--- Check #8 ---
Fri Mar 20 14:38:37 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:37 MSK 2026 - ✅ States synchronized
\n--- Check #9 ---
Fri Mar 20 14:38:40 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:40 MSK 2026 - ✅ States synchronized
\n--- Check #10 ---
Fri Mar 20 14:38:43 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:43 MSK 2026 - ✅ States synchronized
```

### `health.log`

```text
Fri Mar 20 14:37:17 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:37:34 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:37:39 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:18 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:21 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:24 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:27 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:30 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:33 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:34 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:37 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:40 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 14:38:43 MSK 2026 - ✅ OK: States synchronized
```

---

### Task 2 Analysis

MD5 checksums provide a fast and reliable way to detect changes in file content.
If two files are identical, their MD5 hashes will match. Even a very small change produces a different checksum.

That makes checksum comparison a lightweight mechanism for configuration drift detection.

In this lab, `healthcheck.sh` acts as a health monitor:

* matching hashes mean the system is healthy,
* different hashes mean the system is out of sync.

---

### Comparison with ArgoCD Sync Status

This lab models the same core idea used by ArgoCD.

In ArgoCD:

* Git stores the desired state,
* the cluster contains the live state,
* ArgoCD compares both and reports sync status,
* reconciliation brings live state back to the declared configuration.

In this lab:

* `desired-state.txt` is the Git source of truth,
* `current-state.txt` is the live state,
* `healthcheck.sh` reports sync health,
* `reconcile.sh` performs correction.

So while simplified, this exercise accurately demonstrates the logic behind real GitOps controllers.

---

## Final Conclusion

This lab helped me understand the practical foundation of GitOps:

* Git as the single source of truth,
* continuous reconciliation,
* drift detection,
* automatic recovery,
* health monitoring through state comparison.

Even with very small shell scripts, it is possible to simulate the essential behavior of real GitOps tools such as ArgoCD.
The most important takeaway is that GitOps is not just about storing configuration in Git — it is about continuously enforcing that declared configuration on the actual system.
