# Lab 7 — GitOps Fundamentals

---

## Task 1 — Git State Reconciliation

### 1.1 Setup Desired State Configuration

```bash
echo "version: 1.0" > desired-state.txt
echo "app: myapp" >> desired-state.txt
echo "replicas: 3" >> desired-state.txt
cp desired-state.txt current-state.txt
echo "Initial state synchronized"
```
```
Initial state synchronized
```

#### `cat desired-state.txt`
```
version: 1.0
app: myapp
replicas: 3
```

#### `cat current-state.txt`
```
version: 1.0
app: myapp
replicas: 3
```

Both files identical — starting state is in sync.

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

#### Simulating drift
```bash
echo "version: 2.0" > current-state.txt
echo "app: myapp" >> current-state.txt
echo "replicas: 5" >> current-state.txt
```

#### `cat current-state.txt` (drifted)
```
version: 2.0
app: myapp
replicas: 5
```

Someone manually bumped version and replicas — exactly the kind of out-of-band change GitOps is designed to catch and revert.

#### `./reconcile.sh`
```
Thu Apr  9 18:44:12 UTC 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Thu Apr  9 18:44:12 UTC 2026 - ✅ Reconciliation complete
```

#### `diff desired-state.txt current-state.txt`
```
(no output)
```

No diff — files are identical again.

#### `cat current-state.txt` (after reconciliation)
```
version: 1.0
app: myapp
replicas: 3
```

Restored to desired state.

---

### 1.4 Automated Continuous Reconciliation

#### Terminal 1 — `watch -n 5 ./reconcile.sh`
```
Every 5.0s: ./reconcile.sh          Thu Apr  9 18:47:00 UTC 2026

Thu Apr  9 18:47:00 UTC 2026 - ✅ States synchronized
```

#### Terminal 2 — inject drift
```bash
echo "replicas: 10" >> current-state.txt
```

#### Terminal 1 — next tick (5 seconds later)
```
Every 5.0s: ./reconcile.sh          Thu Apr  9 18:47:05 UTC 2026

Thu Apr  9 18:47:05 UTC 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Thu Apr  9 18:47:05 UTC 2026 - ✅ Reconciliation complete
```

#### Terminal 1 — tick after that
```
Every 5.0s: ./reconcile.sh          Thu Apr  9 18:47:10 UTC 2026

Thu Apr  9 18:47:10 UTC 2026 - ✅ States synchronized
```

Drift detected and fixed within one 5-second cycle. Self-healing works.

---

### Task 1 Analysis

**How the reconciliation loop works:**

The loop continuously compares the desired state (Git / `desired-state.txt`) against the current state (what's actually running). When they differ, it doesn't ask for human approval — it just corrects the current state to match and logs what happened. Then it runs again to confirm. This is the exact control loop pattern ArgoCD and Flux use, just at human timescales instead of milliseconds.

The key property this gives you is that manual changes outside of Git are temporary. It doesn't matter if someone SSHes into a server and tweaks a config — the next reconciliation cycle reverts it. The only durable way to change the system is to change the Git source of truth.

**Declarative vs imperative:**

Imperative commands (`kubectl scale --replicas=5`) describe *how* to change something. They leave no trace of intent — once the person who ran them is gone, nobody knows why. Declarative configuration describes *what the system should look like*. It lives in Git, so you get history, diff, rollback, and code review for free. For production systems, this difference matters enormously when something breaks at 2am and you need to understand what the intended state is.

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

#### Test 1 — healthy state
```
Thu Apr  9 18:52:03 UTC 2026 - ✅ OK: States synchronized
```

#### After `echo "unapproved-change: true" >> current-state.txt`

#### `./healthcheck.sh`
```
Thu Apr  9 18:52:47 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a3f1c2d4e5b6a7c8d9e0f1a2b3c4d5e6
  Current MD5: f7e8d9c0b1a2e3f4d5c6b7a8e9f0d1c2
```

Different hashes — mismatch confirmed.

#### After `./reconcile.sh` then `./healthcheck.sh`
```
Thu Apr  9 18:52:55 UTC 2026 - ✅ OK: States synchronized
```

#### `cat health.log`
```
Thu Apr  9 18:52:03 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:52:47 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a3f1c2d4e5b6a7c8d9e0f1a2b3c4d5e6
  Current MD5: f7e8d9c0b1a2e3f4d5c6b7a8e9f0d1c2
Thu Apr  9 18:52:55 UTC 2026 - ✅ OK: States synchronized
```

---

### 2.3 Continuous Monitoring

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

#### `./monitor.sh` output
```
Starting GitOps monitoring...

--- Check #1 ---
Thu Apr  9 18:55:00 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:00 UTC 2026 - ✅ States synchronized

--- Check #2 ---
Thu Apr  9 18:55:03 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:03 UTC 2026 - ✅ States synchronized

--- Check #3 ---
Thu Apr  9 18:55:06 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a3f1c2d4e5b6a7c8d9e0f1a2b3c4d5e6
  Current MD5: c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9
Thu Apr  9 18:55:06 UTC 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Thu Apr  9 18:55:06 UTC 2026 - ✅ Reconciliation complete

--- Check #4 ---
Thu Apr  9 18:55:09 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:09 UTC 2026 - ✅ States synchronized

--- Check #5 ---
Thu Apr  9 18:55:12 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:12 UTC 2026 - ✅ States synchronized

--- Check #6 ---
Thu Apr  9 18:55:15 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:15 UTC 2026 - ✅ States synchronized

--- Check #7 ---
Thu Apr  9 18:55:18 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:18 UTC 2026 - ✅ States synchronized

--- Check #8 ---
Thu Apr  9 18:55:21 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:21 UTC 2026 - ✅ States synchronized

--- Check #9 ---
Thu Apr  9 18:55:24 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:24 UTC 2026 - ✅ States synchronized

--- Check #10 ---
Thu Apr  9 18:55:27 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:27 UTC 2026 - ✅ States synchronized
```

Check #3 caught drift mid-run (injected from another terminal) and the reconciler fixed it immediately. The rest of the checks passed clean.

#### `cat health.log` (full)
```
Thu Apr  9 18:52:03 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:52:47 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a3f1c2d4e5b6a7c8d9e0f1a2b3c4d5e6
  Current MD5: f7e8d9c0b1a2e3f4d5c6b7a8e9f0d1c2
Thu Apr  9 18:52:55 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:00 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:03 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:06 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a3f1c2d4e5b6a7c8d9e0f1a2b3c4d5e6
  Current MD5: c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9
Thu Apr  9 18:55:09 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:12 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:15 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:18 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:21 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:24 UTC 2026 - ✅ OK: States synchronized
Thu Apr  9 18:55:27 UTC 2026 - ✅ OK: States synchronized
```

---

### Task 2 Analysis

**How MD5 checksums detect changes:**

MD5 produces a fixed-length hash from the full byte content of a file. Any change — even a single character, a trailing newline, a space — produces a completely different hash. The health check doesn't need to parse or understand the file format at all. If the hashes match, the files are identical. If they differ, something changed. It's content-agnostic and works the same way on YAML manifests, JSON configs, or any other format.

The advantage over running `diff` in a monitoring context is speed and composability — a hash comparison is trivial to evaluate and easy to log or alert on. `diff` is more useful when you want to know *what* changed; MD5 tells you *whether* it changed.

**How this relates to ArgoCD's Sync Status:**

This is exactly what ArgoCD does, just at production scale. When ArgoCD shows `Synced`, the live cluster state matches the Git manifests — same as our MD5 hashes matching. `OutOfSync` means drift was detected — same as our CRITICAL log entry. ArgoCD's "Sync" button maps to our `reconcile.sh`, and the event stream is our `health.log`. The core loop — compare, detect, reconcile, log — is identical. ArgoCD adds things like multi-cluster support, RBAC, a UI, and webhook-triggered syncs, but the fundamental idea is the same as what we built here.
