# Lab 7 Submission — GitOps Fundamentals

---

## Task 1 — Git State Reconciliation

### 1.1 Setup Desired State Configuration

**Created desired-state.txt:**

```bash
echo "version: 1.0" > desired-state.txt
echo "app: myapp" >> desired-state.txt
echo "replicas: 3" >> desired-state.txt
```

**Contents of desired-state.txt:**
```
version: 1.0
app: myapp
replicas: 3
```

**Simulated initial cluster state:**

```bash
cp desired-state.txt current-state.txt
echo "Initial state synchronized"
```

**Output:**
```
Initial state synchronized
```

---

### 1.2 Reconciliation Script

**Contents of reconcile.sh:**

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

---

### 1.3 Manual Drift Detection

**Simulated drift by modifying current-state.txt:**

```bash
echo "version: 2.0" > current-state.txt
echo "app: myapp" >> current-state.txt
echo "replicas: 5" >> current-state.txt
```

**Ran reconciliation:**

```
$ ./reconcile.sh
вторник, 17 марта 2026 г. 15:25:33 (MSK) - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
вторник, 17 марта 2026 г. 15:25:33 (MSK) - ✅ Reconciliation complete
```

**Verified no diff after reconciliation:**

```
$ diff desired-state.txt current-state.txt
(no output — files are identical)
```

**Verified current-state.txt restored to desired state:**

```
$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3
```

---

### 1.4 Automated Continuous Reconciliation

**Started continuous loop in terminal 1:**

```bash
watch -n 5 ./reconcile.sh
```

**Triggered drift from terminal 2:**

```bash
echo "replicas: 10" >> current-state.txt
```

**Watch output showing auto-healing:**

```
Every 5,0s: ./reconcile.sh   MacBook-Air--Jeanne.local: вторник, 17 марта 2026 г. 15:30:14

вторник, 17 марта 2026 г. 15:30:14 (MSK) - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
вторник, 17 марта 2026 г. 15:30:14 (MSK) - ✅ Reconciliation complete
```

Within 5 seconds the reconciliation loop automatically detected the unauthorized change to `replicas: 10` and restored the desired state without any manual intervention.

---

### Analysis

**How does the GitOps reconciliation loop prevent configuration drift?**

The reconciliation loop continuously compares the actual state of the system against the desired state stored in Git. Whenever a discrepancy is detected — whether caused by a manual change, a failed deployment, or an external process — the loop automatically overwrites the current state with the desired state and logs the event. This creates a self-healing system: no matter what happens to the running environment, it is always pulled back to the version declared in Git. The key principle is that Git is the single source of truth — any change that did not go through Git is treated as unauthorized drift and corrected.

**Advantages of declarative configuration over imperative commands:**

| | Declarative | Imperative |
|---|---|---|
| **Approach** | Define *what* the state should be | Define *how* to get there step by step |
| **Reproducibility** | Always produces the same result | Depends on current state and execution order |
| **Auditability** | Full history in Git | Hard to track what was run and when |
| **Self-healing** | Easy to automate | Requires manual intervention |
| **Rollback** | `git revert` restores previous state instantly | Must manually undo each command |

In production, declarative configuration eliminates entire categories of human error. Teams can review changes in PRs before they are applied, roll back to any previous state trivially, and trust that the running system always matches what is in the repository.

---

## Task 2 — GitOps Health Monitoring

### 2.1 Health Check Script

**Contents of healthcheck.sh:**

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

---

### 2.2 Health Monitoring Tests

**Test 1 — Healthy state:**

```
$ ./healthcheck.sh
вторник, 17 марта 2026 г. 15:31:40 (MSK) - ✅ OK: States synchronized
```

**Test 2 — Simulated drift:**

```
$ echo "unapproved-change: true" >> current-state.txt
$ ./healthcheck.sh
вторник, 17 марта 2026 г. 15:31:53 (MSK) - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

**Test 3 — After reconciliation:**

```
$ ./reconcile.sh
вторник, 17 марта 2026 г. 15:32:03 (MSK) - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
вторник, 17 марта 2026 г. 15:32:03 (MSK) - ✅ Reconciliation complete

$ ./healthcheck.sh
вторник, 17 марта 2026 г. 15:32:08 (MSK) - ✅ OK: States synchronized
```

---

### 2.3 Continuous Monitoring

**Contents of monitor.sh:**

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

**Output of ./monitor.sh:**

```
Starting GitOps monitoring...

--- Check #1 ---
вторник, 17 марта 2026 г. 15:32:20 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:20 (MSK) - ✅ States synchronized

--- Check #2 ---
вторник, 17 марта 2026 г. 15:32:23 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:23 (MSK) - ✅ States synchronized

--- Check #3 ---
вторник, 17 марта 2026 г. 15:32:26 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:27 (MSK) - ✅ States synchronized

--- Check #4 ---
вторник, 17 марта 2026 г. 15:32:30 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:30 (MSK) - ✅ States synchronized

--- Check #5 ---
вторник, 17 марта 2026 г. 15:32:33 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:33 (MSK) - ✅ States synchronized

--- Check #6 ---
вторник, 17 марта 2026 г. 15:32:36 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:36 (MSK) - ✅ States synchronized

--- Check #7 ---
вторник, 17 марта 2026 г. 15:32:39 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:39 (MSK) - ✅ States synchronized

--- Check #8 ---
вторник, 17 марта 2026 г. 15:32:42 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:42 (MSK) - ✅ States synchronized

--- Check #9 ---
вторник, 17 марта 2026 г. 15:32:45 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:45 (MSK) - ✅ States synchronized

--- Check #10 ---
вторник, 17 марта 2026 г. 15:32:48 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:48 (MSK) - ✅ States synchronized
```

**Complete health.log:**

```
вторник, 17 марта 2026 г. 15:31:40 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:31:53 (MSK) - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
вторник, 17 марта 2026 г. 15:32:08 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:20 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:23 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:26 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:30 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:33 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:36 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:39 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:42 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:45 (MSK) - ✅ OK: States synchronized
вторник, 17 марта 2026 г. 15:32:48 (MSK) - ✅ OK: States synchronized
```

---

### Analysis

**How do checksums (MD5) help detect configuration changes?**

MD5 produces a fixed-length hash fingerprint of a file's entire contents. Even a single character change — like appending `unapproved-change: true` — produces a completely different hash. This makes it an efficient and reliable way to detect any modification without reading or comparing the full file content line by line. The health check compares the MD5 of `desired-state.txt` against `current-state.txt`: if they match, the system is in sync; if they differ, drift has occurred. This approach scales well because the comparison is always constant-time regardless of file size.

**How does this relate to ArgoCD's Sync Status?**

The simulation directly mirrors ArgoCD's core sync mechanism. ArgoCD continuously compares the live state of Kubernetes resources against the manifests stored in Git, and reports one of three statuses: `Synced` (equivalent to our ✅ OK), `OutOfSync` (equivalent to our ❌ CRITICAL), or `Unknown`. When drift is detected, ArgoCD can either alert the team or automatically apply the Git state back to the cluster — exactly what our `reconcile.sh` does. The key difference is scale: ArgoCD manages hundreds of Kubernetes resources across multiple clusters, uses cryptographic hashing of resource manifests, and integrates with Git webhooks for near-instant detection rather than polling every few seconds.
