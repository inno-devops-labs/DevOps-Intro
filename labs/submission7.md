# Lab 7 — GitOps Fundamentals

## Task 1 — Git State Reconciliation

### 1.1 Initial State

**desired-state.txt**
```

version: 1.0
app: myapp
replicas: 3

```

**current-state.txt**
```

version: 1.0
app: myapp
replicas: 3

```

---

### 1.3 Drift Detection and Reconciliation

**Simulated drift:**
```

version: 2.0
app: myapp
replicas: 5

```

**Reconciliation output:**
```

Fri Mar 20 18:30:58 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 18:30:58 MSK 2026 - ✅ Reconciliation complete

```

**Diff after reconciliation:**
```

(no output — files are identical)

```

**Final current-state.txt:**
```

version: 1.0
app: myapp
replicas: 3

```

---

### 1.4 Continuous Reconciliation (Auto-Healing)

**Drift introduced:**
```

replicas: 10

````

**Observed behavior:**
- The reconciliation loop detected drift automatically
- State was restored without manual intervention
- Demonstrates self-healing behavior

---

### Analysis

The GitOps reconciliation loop continuously compares the **desired state** (stored in Git) with the **current state** (running system).

If a difference is detected:
1. Drift is identified
2. System automatically applies the desired configuration
3. State becomes consistent again

This prevents configuration drift by ensuring:
- Manual changes are overridden
- System always converges to declared state
- No human intervention is required

---

### Reflection

Declarative configuration defines *what the system should look like*, not *how to achieve it*.

Advantages over imperative approach:
- Idempotency (safe to reapply multiple times)
- Easier debugging (state is explicit)
- Version control via Git
- Enables automation and rollback

---

## Task 2 — GitOps Health Monitoring

### 2.1 healthcheck.sh

```bash
#!/bin/bash
# healthcheck.sh - Monitor GitOps sync health

DESIRED_MD5=$(md5 -q desired-state.txt)
CURRENT_MD5=$(md5 -q current-state.txt)

if [ "$DESIRED_MD5" != "$CURRENT_MD5" ]; then
    echo "$(date) - ❌ CRITICAL: State mismatch detected!" | tee -a health.log
    echo "  Desired MD5: $DESIRED_MD5" | tee -a health.log
    echo "  Current MD5: $CURRENT_MD5" | tee -a health.log
else
    echo "$(date) - ✅ OK: States synchronized" | tee -a health.log
fi
````

---

### 2.2 Health Monitoring Results

**Mismatch detected:**

```
Fri Mar 20 18:32:33 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 86c1e4f2cba0e303f72049ccbb3141bf
```

**After additional drift:**

```
Fri Mar 20 18:32:38 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 7a7e95e8ec1e6e1833160b5f21f09692
```

**After reconciliation:**

```
Fri Mar 20 18:32:43 MSK 2026 - ✅ OK: States synchronized
```

---

### 2.3 Continuous Monitoring (monitor.sh)

**Output excerpt:**

```
--- Check #1 ---
❌ CRITICAL: State mismatch detected
⚠️ DRIFT DETECTED → reconciliation triggered

--- Check #2+ ---
✅ OK: States synchronized
```

**Observation:**

* First iteration detects drift
* System automatically fixes it
* All subsequent checks remain healthy

---

### Complete health.log

```
Fri Mar 20 18:32:33 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 86c1e4f2cba0e303f72049ccbb3141bf
Fri Mar 20 18:32:38 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 7a7e95e8ec1e6e1833160b5f21f09692
Fri Mar 20 18:32:43 MSK 2026 - ✅ OK: States synchronized
```

---

### Analysis

MD5 checksums provide a fast way to detect changes in configuration files.

Instead of comparing line-by-line:

* Each file is reduced to a hash
* Any change results in a different hash
* Enables efficient monitoring at scale

---

### Comparison with ArgoCD

This implementation mirrors GitOps tools like ArgoCD:

| This Lab          | ArgoCD Equivalent    |
| ----------------- | -------------------- |
| desired-state.txt | Git repository       |
| current-state.txt | Kubernetes cluster   |
| reconcile.sh      | Sync loop            |
| healthcheck.sh    | Sync status / health |
| MD5 comparison    | Diffing manifests    |

ArgoCD continuously:

* Detects drift
* Shows "OutOfSync" status
* Automatically or manually syncs state

---

## Conclusion

This lab demonstrates core GitOps principles:

* Git as single source of truth
* Continuous reconciliation
* Automated self-healing
* Health monitoring via checksums

The system ensures consistency, reliability, and automation — key properties of modern infrastructure management.
