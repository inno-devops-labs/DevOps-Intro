# Lab 7 — GitOps Fundamentals

## Task 1 — Git State Reconciliation

### Initial `desired-state.txt` and `current-state.txt` contents

`desired-state.txt`
```
version: 1.0
app: myapp
replicas: 3
```

`current-state.txt`
```
version: 1.0
app: myapp
replicas: 3
```

### Output of drift detection and reconciliation

```bash
belyak_anya@zephyrus:~/F25-DevOps-Intro/labs/lab7$ ./reconcile.sh
Sat Oct 18 06:53:50 PM MSK 2025 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sat Oct 18 06:53:50 PM MSK 2025 - ✅ Reconciliation complete
belyak_anya@zephyrus:~/F25-DevOps-Intro/labs/lab7$ diff desired-state.txt current-state.txt
belyak_anya@zephyrus:~/F25-DevOps-Intro/labs/lab7$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3
```

### Output showing synchronized state after reconciliation

```bash
Every 5.0s: ./reconcile.sh                    zephyrus: Sat Oct 18 19:01:02 2025

Sat Oct 18 07:01:02 PM MSK 2025 - ✅ States synchronized
```



### Output from continuous reconciliation loop detecting auto-healing

```bash
Every 5.0s: ./reconcile.sh                    zephyrus: Sat Oct 18 19:01:12 2025

Sat Oct 18 07:01:12 PM MSK 2025 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sat Oct 18 07:01:12 PM MSK 2025 - ✅ Reconciliation complete

```

### Analysis: Explain the GitOps reconciliation loop. How does this prevent configuration drift?

The reconciliation loop continuously compares the *desired state* (stored in `desired-state.txt`) with the *current state* (`current-state.txt`).
When drift occurs — meaning someone manually changes the running configuration — the script detects the difference and automatically restores the desired configuration by copying it over.

This mechanism is the core of GitOps: the system constantly aligns the live environment with the version-controlled source of truth in Git.
As a result, configuration drift cannot persist for long — any unauthorized or accidental change is automatically corrected, keeping the system consistent and predictable.

### Reflection: What advantages does declarative configuration have over imperative commands in production?

A declarative configuration defines **what** the final state should be, rather than **how** to reach it.
In GitOps, all changes are versioned, reviewed, and auditable in Git, enabling reproducibility and easy rollback.
The system ensures the runtime environment always matches the declared configuration automatically.

In contrast, imperative commands require humans to execute steps manually, often leaving no trace of what was done and increasing the risk of drift or errors.
Declarative configuration makes infrastructure self-healing, maintainable, and safer for production environments.

## Task 2 — GitOps Health Monitoring


### Contents of `healthcheck.sh` script

`healthcheck.sh`:

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

### Output showing "OK" status when states match

```bash
belyak_anya@zephyrus:~/F25-DevOps-Intro/labs/lab7$ ./healthcheck.sh
Sat Oct 18 07:45:19 PM MSK 2025 - ✅ OK: States synchronized
belyak_anya@zephyrus:~/F25-DevOps-Intro/labs/lab7$ cat health.log
Sat Oct 18 07:45:19 PM MSK 2025 - ✅ OK: States synchronized
```

### Output showing "CRITICAL" status when drift is detected

```bash
belyak_anya@zephyrus:~/F25-DevOps-Intro/labs/lab7$ echo "unapproved-change: true" >> current-state.txt
belyak_anya@zephyrus:~/F25-DevOps-Intro/labs/lab7$ ./healthcheck.sh
Sat Oct 18 07:45:54 PM MSK 2025 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

### Complete `health.log` file showing multiple checks

```bash
belyak_anya@zephyrus:~/F25-DevOps-Intro/labs/lab7$ cat health.log
Sat Oct 18 07:45:19 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:45:54 PM MSK 2025 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Sat Oct 18 07:46:12 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:03 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:06 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:09 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:12 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:15 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:18 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:21 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:24 PM MSK 2025 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 86c1e4f2cba0e303f72049ccbb3141bf
Sat Oct 18 07:47:27 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:30 PM MSK 2025 - ✅ OK: States synchronized
```

### Output from `monitor.sh` showing continuous monitoring

```bash
belyak_anya@zephyrus:~/F25-DevOps-Intro/labs/lab7$ ./monitor.sh
Starting GitOps monitoring...
\n--- Check #1 ---
Sat Oct 18 07:47:03 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:03 PM MSK 2025 - ✅ States synchronized
\n--- Check #2 ---
Sat Oct 18 07:47:06 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:06 PM MSK 2025 - ✅ States synchronized
\n--- Check #3 ---
Sat Oct 18 07:47:09 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:09 PM MSK 2025 - ✅ States synchronized
\n--- Check #4 ---
Sat Oct 18 07:47:12 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:12 PM MSK 2025 - ✅ States synchronized
\n--- Check #5 ---
Sat Oct 18 07:47:15 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:15 PM MSK 2025 - ✅ States synchronized
\n--- Check #6 ---
Sat Oct 18 07:47:18 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:18 PM MSK 2025 - ✅ States synchronized
\n--- Check #7 ---
Sat Oct 18 07:47:21 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:21 PM MSK 2025 - ✅ States synchronized
\n--- Check #8 ---
Sat Oct 18 07:47:24 PM MSK 2025 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 86c1e4f2cba0e303f72049ccbb3141bf
Sat Oct 18 07:47:24 PM MSK 2025 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sat Oct 18 07:47:24 PM MSK 2025 - ✅ Reconciliation complete
\n--- Check #9 ---
Sat Oct 18 07:47:27 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:27 PM MSK 2025 - ✅ States synchronized
\n--- Check #10 ---
Sat Oct 18 07:47:30 PM MSK 2025 - ✅ OK: States synchronized
Sat Oct 18 07:47:30 PM MSK 2025 - ✅ States synchronized
```

### Analysis: How do checksums (MD5) help detect configuration changes?

MD5 checksums allow instant detection of any modification in configuration files.
Even a single character change produces a completely different hash value.
By comparing the MD5 of the desired state and the current state, the script can quickly determine whether drift has occurred without manually checking file contents.
This makes the health check lightweight, reliable, and automation-friendly.

### Comparison: How does this relate to GitOps tools like ArgoCD's "Sync Status"?

ArgoCD uses a similar concept called **Sync Status** to monitor whether the live cluster configuration matches the desired state stored in Git:

- **Synced** — The live state and the desired state are identical (same as “✅ OK” in this lab).
- **OutOfSync** — A difference is detected between Git and the live cluster (same as “❌ CRITICAL”).

Our healthcheck and monitor scripts reproduce this behavior in a simplified shell-based simulation, continuously verifying and restoring configuration consistency.