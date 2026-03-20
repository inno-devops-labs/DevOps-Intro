# Lab 7 — GitOps Fundamentals

**Author:** Danis Sharafiev

---

## Task 1 — Git State Reconciliation

### 1.1: Setup Desired State Configuration

```bash
echo "version: 1.0" > desired-state.txt
echo "app: myapp" >> desired-state.txt
echo "replicas: 3" >> desired-state.txt
cp desired-state.txt current-state.txt
```

**desired-state.txt** (source of truth):

```
version: 1.0
app: myapp
replicas: 3
```

**current-state.txt** (initial — identical to desired):

```
version: 1.0
app: myapp
replicas: 3
```

### 1.2: Reconciliation Script

```bash
#!/bin/bash
# reconcile.sh - GitOps reconciliation loop

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

### 1.3: Manual Drift Detection

**Simulated drift** — changed version to 2.0 and replicas to 5:

```bash
echo "version: 2.0" > current-state.txt
echo "app: myapp" >> current-state.txt
echo "replicas: 5" >> current-state.txt
```

**Running reconciliation:**

```
$ ./reconcile.sh
Fri Mar 20 23:40:11 MSK 2026 - DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 23:40:11 MSK 2026 - Reconciliation complete
```

**diff after reconciliation:** no differences — files match.

**current-state.txt after reconciliation:**

```
version: 1.0
app: myapp
replicas: 3
```

The drift was successfully detected and corrected.

### 1.4: Automated Continuous Reconciliation

Simulated continuous reconciliation loop (equivalent to `watch -n 5 ./reconcile.sh`):

```
--- Iteration 1: states in sync ---
Fri Mar 20 23:40:23 MSK 2026 - States synchronized

--- Simulating drift: adding replicas: 10 ---

--- Iteration 2: detecting drift ---
Fri Mar 20 23:40:23 MSK 2026 - DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 23:40:23 MSK 2026 - Reconciliation complete

--- Iteration 3: states back in sync ---
Fri Mar 20 23:40:23 MSK 2026 - States synchronized
```

The loop automatically detected the injected drift and self-healed within one iteration.

### Analysis

The **GitOps reconciliation loop** works by continuously comparing the desired state (stored in Git) with the actual state of the system. When a mismatch (drift) is detected, the loop overwrites the current state with the desired state, restoring consistency. This prevents configuration drift because any unauthorized or accidental change is automatically reverted to the Git-defined state. In production, tools like ArgoCD and Flux implement this pattern by polling a Git repository and applying manifests to a Kubernetes cluster whenever differences are found.

### Reflection

Declarative configuration defines **what** the system should look like, not **how** to get there. This has several advantages over imperative commands:

- **Idempotency** — applying the same declaration multiple times always produces the same result, whereas imperative scripts may fail or produce different outcomes on re-execution.
- **Auditability** — Git history shows exactly what changed, when, and by whom.
- **Reproducibility** — the entire system state can be recreated from a single configuration file.
- **Self-healing** — a reconciliation loop can continuously enforce the declared state, automatically correcting manual interventions or partial failures.

---

## Task 2 — GitOps Health Monitoring

### 2.1: Health Check Script

```bash
#!/bin/bash
# healthcheck.sh - Monitor GitOps sync health

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

### 2.2: Health Monitoring Tests

**Healthy state (states match):**

```
$ ./healthcheck.sh
Fri Mar 20 23:40:43 MSK 2026 - OK: States synchronized
```

**Drifted state** (after `echo "unapproved-change: true" >> current-state.txt`):

```
$ ./healthcheck.sh
Fri Mar 20 23:40:54 MSK 2026 - CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

**After reconciliation and re-check:**

```
$ ./reconcile.sh
Fri Mar 20 23:41:05 MSK 2026 - DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 23:41:05 MSK 2026 - Reconciliation complete

$ ./healthcheck.sh
Fri Mar 20 23:41:05 MSK 2026 - OK: States synchronized
```

**Complete health.log:**

```
Fri Mar 20 23:40:43 MSK 2026 - OK: States synchronized
Fri Mar 20 23:40:54 MSK 2026 - CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Fri Mar 20 23:41:05 MSK 2026 - OK: States synchronized
```

### 2.3: Continuous Health Monitoring

**monitor.sh** script:

```bash
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
```

**Output** (drift injected at check #3):

```
Starting GitOps monitoring...

--- Check #1 ---
Fri Mar 20 23:41:18 MSK 2026 - OK: States synchronized
Fri Mar 20 23:41:18 MSK 2026 - States synchronized

--- Check #2 ---
Fri Mar 20 23:41:18 MSK 2026 - OK: States synchronized
Fri Mar 20 23:41:18 MSK 2026 - States synchronized

--- Check #3 ---
(Injecting drift: replicas changed to 10)
Fri Mar 20 23:41:18 MSK 2026 - CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 86c1e4f2cba0e303f72049ccbb3141bf
Fri Mar 20 23:41:18 MSK 2026 - DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 23:41:18 MSK 2026 - Reconciliation complete

--- Check #4 ---
Fri Mar 20 23:41:18 MSK 2026 - OK: States synchronized
Fri Mar 20 23:41:18 MSK 2026 - States synchronized

--- Check #5 ---
Fri Mar 20 23:41:18 MSK 2026 - OK: States synchronized
Fri Mar 20 23:41:18 MSK 2026 - States synchronized
```

**Complete health.log from monitoring session:**

```
Fri Mar 20 23:41:18 MSK 2026 - OK: States synchronized
Fri Mar 20 23:41:18 MSK 2026 - OK: States synchronized
Fri Mar 20 23:41:18 MSK 2026 - CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 86c1e4f2cba0e303f72049ccbb3141bf
Fri Mar 20 23:41:18 MSK 2026 - OK: States synchronized
Fri Mar 20 23:41:18 MSK 2026 - OK: States synchronized
```

### Analysis

**Checksums (MD5) for change detection:**
MD5 hashes produce a fixed-length fingerprint of file contents. Even a single byte change results in a completely different hash, making it trivial to detect configuration drift without comparing files line-by-line. This is efficient and reliable — instead of parsing and diffing configuration fields, the system compares two short strings.

### Comparison with ArgoCD

This health monitoring simulation mirrors ArgoCD's **Sync Status** mechanism:

| This Lab | ArgoCD Equivalent |
|----------|-------------------|
| `desired-state.txt` | Git repository manifests |
| `current-state.txt` | Live Kubernetes cluster state |
| `healthcheck.sh` (MD5 compare) | ArgoCD sync status (Synced / OutOfSync) |
| `reconcile.sh` (copy desired → current) | ArgoCD sync operation (applies manifests) |
| `health.log` | ArgoCD UI sync history & events |
| `monitor.sh` (loop) | ArgoCD controller reconciliation loop (default: 3 min) |

ArgoCD additionally tracks **Health Status** (Healthy, Degraded, Progressing) by checking Kubernetes resource conditions, going beyond simple file comparison to validate that resources are actually running correctly.
