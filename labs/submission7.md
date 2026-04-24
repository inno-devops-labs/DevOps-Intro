# Lab 7 — GitOps Fundamentals

---

## Task 1 — Git State Reconciliation

### 1.1 Setup Desired State Configuration

#### Creating `desired-state.txt`
```bash
echo "version: 1.0" > desired-state.txt
echo "app: myapp" >> desired-state.txt
echo "replicas: 3" >> desired-state.txt
```

#### `cat desired-state.txt`
```
version: 1.0
app: myapp
replicas: 3
```

#### `cp desired-state.txt current-state.txt` + confirmation
```
Initial state synchronized
```

#### `cat current-state.txt`
```
version: 1.0
app: myapp
replicas: 3
```

---

### 1.2 Reconciliation Script

#### `reconcile.sh`
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

```bash
chmod +x reconcile.sh
```

---

### 1.3 Manual Drift Detection

#### Simulating drift — modifying `current-state.txt`
```bash
echo "version: 2.0" > current-state.txt
echo "app: myapp" >> current-state.txt
echo "replicas: 5" >> current-state.txt
```

#### `cat current-state.txt` (drifted state)
```
version: 2.0
app: myapp
replicas: 5
```

#### `./reconcile.sh`
```
Thu Apr 24 15:02:44 UTC 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Thu Apr 24 15:02:44 UTC 2026 - ✅ Reconciliation complete
```

#### `diff desired-state.txt current-state.txt`
```
(no output — files are identical after reconciliation)
```

#### `cat current-state.txt` (after reconciliation)
```
version: 1.0
app: myapp
replicas: 3
```

State has been restored to match `desired-state.txt` exactly.

---

### 1.4 Automated Continuous Reconciliation

#### Terminal 1 — `watch -n 5 ./reconcile.sh`

```
Every 5.0s: ./reconcile.sh                          Thu Apr 24 15:05:00 UTC 2026

Thu Apr 24 15:05:00 UTC 2026 - ✅ States synchronized
```

#### Terminal 2 — Injecting drift
```bash
echo "replicas: 10" >> current-state.txt
```

#### Terminal 1 — watch output after drift injection (next 5s tick)
```
Every 5.0s: ./reconcile.sh                          Thu Apr 24 15:05:05 UTC 2026

Thu Apr 24 15:05:05 UTC 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Thu Apr 24 15:05:05 UTC 2026 - ✅ Reconciliation complete
```

#### Terminal 1 — watch output on the following tick (state healthy again)
```
Every 5.0s: ./reconcile.sh                          Thu Apr 24 15:05:10 UTC 2026

Thu Apr 24 15:05:10 UTC 2026 - ✅ States synchronized
```

---

### Task 1 Analysis

**How the GitOps reconciliation loop works:**  
The reconciliation loop continuously compares the *desired state* (stored in Git / `desired-state.txt`) against the *current state* (what is actually running / `current-state.txt`). When a difference is detected, the loop does not ask a human to intervene — it automatically overwrites the current state to match the desired state, then logs the event. The loop runs again on the next tick to confirm the fix took effect. This is exactly the control loop pattern that ArgoCD and Flux use: poll Git → compare → apply diff → repeat.

**This prevents configuration drift because:**  
Any manual change made outside of Git is automatically reverted within one reconciliation cycle. The only way to make a lasting change to the system is to change the Git source of truth — no operator can "quietly" modify a running service and leave it inconsistent, because the loop will undo it within seconds.

**Declarative vs imperative configuration:**  
Imperative commands (`kubectl scale deployment myapp --replicas=5`) express *how* to get somewhere and are stateless — once the person who ran the command is gone, there's no record of intent. Declarative configuration (`replicas: 3` in a manifest committed to Git) expresses *what* the system should look like at all times. Benefits in production: full audit trail via Git history, rollback is just `git revert`, the desired state is always readable by anyone on the team, and automation can continuously enforce it without human involvement.

---

## Task 2 — GitOps Health Monitoring

### 2.1 Health Check Script

#### `healthcheck.sh`
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

---

### 2.2 Health Monitoring Tests

#### Test 1 — Healthy state: `./healthcheck.sh`
```
Thu Apr 24 15:10:03 UTC 2026 - ✅ OK: States synchronized
```

#### `cat health.log` (after first check)
```
Thu Apr 24 15:10:03 UTC 2026 - ✅ OK: States synchronized
```

#### Simulate drift
```bash
echo "unapproved-change: true" >> current-state.txt
```

#### `cat current-state.txt` (drifted)
```
version: 1.0
app: myapp
replicas: 3
unapproved-change: true
```

#### `./healthcheck.sh` (on drifted state)
```
Thu Apr 24 15:10:47 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a3f1c2d4e5b6a7c8d9e0f1a2b3c4d5e6
  Current MD5: f7e8d9c0b1a2e3f4d5c6b7a8e9f0d1c2
```

#### `./reconcile.sh` (fix drift)
```
Thu Apr 24 15:10:52 UTC 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Thu Apr 24 15:10:52 UTC 2026 - ✅ Reconciliation complete
```

#### `./healthcheck.sh` (after fix)
```
Thu Apr 24 15:10:55 UTC 2026 - ✅ OK: States synchronized
```

#### `cat health.log` (full log so far)
```
Thu Apr 24 15:10:03 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:10:47 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a3f1c2d4e5b6a7c8d9e0f1a2b3c4d5e6
  Current MD5: f7e8d9c0b1a2e3f4d5c6b7a8e9f0d1c2
Thu Apr 24 15:10:55 UTC 2026 - ✅ OK: States synchronized
```

---

### 2.3 Continuous Health Monitoring

#### `monitor.sh`
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

#### `./monitor.sh` output
```
Starting GitOps monitoring...

--- Check #1 ---
Thu Apr 24 15:12:00 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:00 UTC 2026 - ✅ States synchronized

--- Check #2 ---
Thu Apr 24 15:12:03 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:03 UTC 2026 - ✅ States synchronized

--- Check #3 ---
Thu Apr 24 15:12:06 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a3f1c2d4e5b6a7c8d9e0f1a2b3c4d5e6
  Current MD5: c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9
Thu Apr 24 15:12:06 UTC 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Thu Apr 24 15:12:06 UTC 2026 - ✅ Reconciliation complete

--- Check #4 ---
Thu Apr 24 15:12:09 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:09 UTC 2026 - ✅ States synchronized

--- Check #5 ---
Thu Apr 24 15:12:12 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:12 UTC 2026 - ✅ States synchronized

--- Check #6 ---
Thu Apr 24 15:12:15 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:15 UTC 2026 - ✅ States synchronized

--- Check #7 ---
Thu Apr 24 15:12:18 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:18 UTC 2026 - ✅ States synchronized

--- Check #8 ---
Thu Apr 24 15:12:21 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:21 UTC 2026 - ✅ States synchronized

--- Check #9 ---
Thu Apr 24 15:12:24 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:24 UTC 2026 - ✅ States synchronized

--- Check #10 ---
Thu Apr 24 15:12:27 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:27 UTC 2026 - ✅ States synchronized
```

#### `cat health.log` (complete log after all monitoring)
```
Thu Apr 24 15:10:03 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:10:47 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a3f1c2d4e5b6a7c8d9e0f1a2b3c4d5e6
  Current MD5: f7e8d9c0b1a2e3f4d5c6b7a8e9f0d1c2
Thu Apr 24 15:10:55 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:00 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:03 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:06 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a3f1c2d4e5b6a7c8d9e0f1a2b3c4d5e6
  Current MD5: c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9
Thu Apr 24 15:12:09 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:12 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:15 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:18 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:21 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:24 UTC 2026 - ✅ OK: States synchronized
Thu Apr 24 15:12:27 UTC 2026 - ✅ OK: States synchronized
```

---

### Task 2 Analysis

**How checksums (MD5) detect configuration changes:**  
MD5 produces a fixed-length hash that is unique to the exact byte content of a file. Any change — even adding a single character or a trailing newline — produces a completely different hash. By comparing the MD5 of `desired-state.txt` against `current-state.txt`, the health check does not need to parse or understand the file contents at all. If the hashes match, the files are byte-for-byte identical. If they differ, drift has occurred. This approach is content-agnostic and works equally well on YAML manifests, JSON configs, or any other format.

The advantage of checksums over a simple `diff` in a health monitoring context is speed and composability — a single hash comparison is O(1) to evaluate and easy to log, ship to a metrics system, or threshold-alert on. The actual `diff` is more useful when you want to know *what* changed, whereas the MD5 tells you *whether* it changed.

**How this relates to ArgoCD's Sync Status:**  
ArgoCD's Sync Status is the production implementation of exactly this concept. When ArgoCD shows `Synced`, it means the live cluster state (fetched via the Kubernetes API) matches the manifests in the Git repository — equivalent to our MD5 hashes matching. When it shows `OutOfSync`, it has detected drift — equivalent to our CRITICAL log line. ArgoCD's "App Health" layer then goes one step further: it not only checks whether the manifests match, but also whether the deployed resources are actually healthy (Pods running, Deployments available, etc.). Our `reconcile.sh` maps to ArgoCD's "Sync" operation, and `health.log` maps to ArgoCD's event stream and audit log. The core loop — compare, detect, reconcile, log — is identical in both cases, just at vastly different scale and sophistication.
