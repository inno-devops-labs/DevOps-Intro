# Lab 7 — GitOps Fundamentals

## Task 1 — Git State Reconciliation

### Initial desired-state.txt
```
version: 1.0
app: myapp
replicas: 3
```

### Initial current-state.txt (after cp)
```
version: 1.0
app: myapp
replicas: 3
```

### Drift Detection Output (after manual drift)
```
Fri Mar 20 03:32:44 PM MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 03:32:44 PM MSK 2026 - ✅ Reconciliation complete
```

### After Reconciliation (current-state.txt)
```
version: 1.0
app: myapp
replicas: 3
```

### Auto-healing Demonstration (watch output)
```
Every 5.0s: ./reconcile.sh              lev-VirtualBox: Fri Mar 20 15:34:16 2026

Fri Mar 20 03:34:16 PM MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 03:34:16 PM MSK 2026 - ✅ Reconciliation complete
```

### Analysis
**GitOps reconciliation loop explanation:**

The GitOps reconciliation loop is a continuous process that compares the desired state of a system (stored in Git) with the current state (running in the cluster/environment). In my implementation, this process is executed by the reconcile.sh script, which:

1. Reads desired-state.txt (Git — the source of truth)
2. Reads current-state.txt (the current state of the system)
3. Compares them
4. When differences are detected, automatically copies the desired state to the current state

In real GitOps tools (ArgoCD, Flux), this loop runs constantly: the operator checks every few seconds whether the cluster matches what is described in the Git repository. If not — it applies the changes.

**Advantages of declarative configuration:**

The declarative approach has key advantages over imperative commands:

1. **Automatic drift correction** — the system returns to the desired state without manual intervention. In my example, when someone changed replicas to 10, reconcile.sh immediately reverted it back to 3.

2. **Single source of truth** — all configurations are stored in Git, providing complete change history, code review capabilities, and audit trails.

3. **Idempotence** — no matter how many times you apply the same declarative configuration, the result will be the same.

4. **Simplified fault tolerance** — if a server fails and recovers, the system automatically returns to the desired state.

The imperative approach ("do this, do that") requires constant human oversight and does not protect against accidental or intentional changes.

## Task 2 — GitOps Health Monitoring

### healthcheck.sh Script
```
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

### Health Check Outputs

**Healthy state:**
```
Fri Mar 20 03:32:44 PM MSK 2026 - ✅ OK: States synchronized
```

**Critical state (after drift):**
```
Fri Mar 20 03:32:45 PM MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

### Complete health.log
```
Fri Mar 20 03:32:44 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:32:45 PM MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Fri Mar 20 03:32:45 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:37 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:40 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:43 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:46 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:50 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:53 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:56 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:59 PM MSK 2026 - ✅ OK: States synchronized
```

### monitor.sh Output
```
Starting GitOps monitoring...

--- Check #1 ---
Fri Mar 20 03:34:37 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:37 PM MSK 2026 - ✅ States synchronized

--- Check #2 ---
Fri Mar 20 03:34:40 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:40 PM MSK 2026 - ✅ States synchronized

--- Check #3 ---
Fri Mar 20 03:34:43 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:43 PM MSK 2026 - ✅ States synchronized

--- Check #4 ---
Fri Mar 20 03:34:46 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:47 PM MSK 2026 - ✅ States synchronized

--- Check #5 ---
Fri Mar 20 03:34:50 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:50 PM MSK 2026 - ✅ States synchronized

--- Check #6 ---
Fri Mar 20 03:34:53 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:53 PM MSK 2026 - ✅ States synchronized

--- Check #7 ---
Fri Mar 20 03:34:56 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:56 PM MSK 2026 - ✅ States synchronized

--- Check #8 ---
Fri Mar 20 03:34:59 PM MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 03:34:59 PM MSK 2026 - ✅ States synchronized
```

### Analysis
**How checksums help detect configuration changes:**

MD5 (Message Digest Algorithm 5) is a cryptographic hash function that generates a unique 128-bit signature (fingerprint) for any set of data. In the context of GitOps monitoring:

1. **Fast comparison** — instead of comparing two files line by line (which can be costly with large volumes), healthcheck.sh computes the MD5 of each file and compares only these short strings.

2. **Sensitivity to any changes** — even changing a single character (e.g., replicas: 3 → replicas: 4) completely changes the MD5 hash. In my example:
   - Desired state produced MD5: `a15a1a4f965ecd8f9e23a33a6b543155`
   - Drifting state produced MD5: `48168ff3ab5ffc0214e81c7e2ee356f5`
   - The difference is immediately visible without inspecting the actual content

3. **Monitoring automation** — MD5 allows easy integration of checks into scripts and alerting systems. In production, such checks are used to track unauthorized configuration changes.

4. **Audit and logging** — recording MD5 hashes in health.log makes it possible to track not only when desynchronization occurred, but also exactly which states were different.

**Comparison to ArgoCD "Sync Status":**

ArgoCD's Sync Status is a feature that shows whether a Kubernetes cluster matches the configuration stored in Git. My health monitoring implementation mimics this functionality:

| My Implementation | ArgoCD |
|-------------------|--------|
| healthcheck.sh compares desired-state.txt and current-state.txt | ArgoCD compares Git repository with cluster state |
| health.log records sync status history | ArgoCD UI shows Sync Status and history |
| MD5 checksums detect differences | ArgoCD uses diff algorithms to show changes |
| monitor.sh runs continuous checks | ArgoCD controller runs continuous reconciliation |

Key similarities:
- **Continuous monitoring** — both constantly check for drift
- **Clear status indication** — ✅ OK vs ❌ CRITICAL in my script mirrors ArgoCD's "Synced" vs "OutOfSync" status
- **Audit trail** — health.log provides a history similar to ArgoCD's event log
- **Self-healing** — when drift is detected, both systems automatically restore the desired state

The main difference is that ArgoCD operates at the Kubernetes resource level, while my implementation demonstrates the core concepts using simple text files, making the fundamental GitOps principles visible and understandable.