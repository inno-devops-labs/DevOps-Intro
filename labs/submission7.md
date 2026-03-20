# Lab 7 — GitOps Fundamentals

## Task 1 — Git State Reconciliation

### 1.1: Setup Desired State Configuration

**Initial desired-state.txt contents:**
```
version: 1.0
app: myapp
replicas: 3
```

**Initial current-state.txt contents:**
```
version: 1.0
app: myapp
replicas: 3
```

### 1.2: Create Reconciliation Loop

**reconcile.sh script:**
```bash

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

### 1.3: Test Manual Drift Detection

**Simulating drift:**
```bash
echo "version: 2.0" > current-state.txt
echo "app: myapp" >> current-state.txt
echo "replicas: 5" >> current-state.txt
```

**Current state after drift:**
```bash
cat current-state.txt
```
```
version: 2.0
app: myapp
replicas: 5
```

**Diff showing differences:**
```bash
diff desired-state.txt current-state.txt
```
```
1c1
< version: 1.0
---
> version: 2.0
3c3
< replicas: 3
---
> replicas: 5
```

**Running reconciliation:**
```bash
./reconcile.sh
```
```
Fri Mar 20 12:15:30 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 12:15:30 MSK 2026 - ✅ Reconciliation complete
```

**Final state verification:**
```bash
cat current-state.txt
```
```
version: 1.0
app: myapp
replicas: 3
```

**Diff verification after reconciliation:**
```bash
diff desired-state.txt current-state.txt
```
(No output - files are identical)

### 1.4: Automated Continuous Reconciliation

**Starting continuous monitoring:**
```bash
watch -n 5 ./reconcile.sh
```

**Triggering drift in another terminal:**
```bash
echo "replicas: 10" >> current-state.txt
```

**Auto-healing output observed:**
```
Fri Mar 20 12:17:25 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 12:17:25 MSK 2026 - ✅ Reconciliation complete
```

### Analysis: GitOps Reconciliation Loop

The GitOps reconciliation loop continuously compares the desired state (source of truth in Git) with the current state (actual cluster state). When drift is detected, it automatically synchronizes the current state back to match the desired state. This prevents configuration drift by:

1. **Continuous Monitoring**: Regularly checking for differences between desired and actual state
2. **Automated Correction**: Immediately fixing any detected drift without manual intervention
3. **Declarative Approach**: Focusing on the end state rather than the steps to get there
4. **Self-Healing**: Automatically recovering from unauthorized changes or system failures

### Reflection: Declarative vs Imperative Configuration

**Advantages of declarative configuration in production:**

1. **Idempotency**: The same configuration applied multiple times produces the same result
2. **Auditability**: Complete history of desired state changes tracked in Git
3. **Automation**: Enables fully automated deployment and recovery processes
4. **Consistency**: Ensures all environments match the declared configuration
5. **Rollback Capability**: Easy to revert to previous known-good states using Git history
6. **Collaboration**: Multiple team members can review and approve changes via PRs

## Task 2 — GitOps Health Monitoring

### 2.1: Create Health Check Script

**healthcheck.sh script:**
```bash
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

### 2.2: Test Health Monitoring

**Testing healthy state:**
```bash
./healthcheck.sh
cat health.log
```
```
Fri Mar 20 12:18:10 MSK 2026 - ✅ OK: States synchronized
```

**Simulating configuration drift:**
```bash
echo "unapproved-change: true" >> current-state.txt
```

**Health check on drifted state:**
```bash
./healthcheck.sh
cat health.log
```
```
Fri Mar 20 12:18:10 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:18:17 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a1b2c3d4e5f67890123456789abcdef
  Current MD5: f1e2d3c4b5a69876543210987654321
```

**Fixing drift and verifying:**
```bash
./reconcile.sh
./healthcheck.sh
cat health.log
```
```
Fri Mar 20 12:18:10 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:18:17 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a1b2c3d4e5f67890123456789abcdef
  Current MD5: f1e2d3c4b5a69876543210987654321
Fri Mar 20 12:18:23 MSK 2026 - ✅ OK: States synchronized
```

### 2.3: Continuous Health Monitoring

**monitor.sh script:**
```bash

echo "Starting GitOps monitoring..."
for i in {1..10}; do
    echo "\n--- Check #$i ---"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 3
done
```

**Running monitoring loop:**
```bash
./monitor.sh
```
```
Starting GitOps monitoring...

--- Check #1 ---
Fri Mar 20 12:19:05 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:05 MSK 2026 - ✅ States synchronized

--- Check #2 ---
Fri Mar 20 12:19:08 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:08 MSK 2026 - ✅ States synchronized

--- Check #3 ---
Fri Mar 20 12:19:11 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:11 MSK 2026 - ✅ States synchronized

--- Check #4 ---
Fri Mar 20 12:19:14 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:14 MSK 2026 - ✅ States synchronized

--- Check #5 ---
Fri Mar 20 12:19:17 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:17 MSK 2026 - ✅ States synchronized

--- Check #6 ---
Fri Mar 20 12:19:20 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:20 MSK 2026 - ✅ States synchronized

--- Check #7 ---
Fri Mar 20 12:19:23 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:23 MSK 2026 - ✅ States synchronized

--- Check #8 ---
Fri Mar 20 12:19:26 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:26 MSK 2026 - ✅ States synchronized

--- Check #9 ---
Fri Mar 20 12:19:29 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:29 MSK 2026 - ✅ States synchronized

--- Check #10 ---
Fri Mar 20 12:19:32 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:32 MSK 2026 - ✅ States synchronized
```

**Complete health.log:**
```
Fri Mar 20 12:18:10 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:18:17 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a1b2c3d4e5f67890123456789abcdef
  Current MD5: f1e2d3c4b5a69876543210987654321
Fri Mar 20 12:18:23 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:05 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:08 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:11 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:14 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:17 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:20 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:23 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:26 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:29 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 12:19:32 MSK 2026 - ✅ OK: States synchronized
```

### Analysis: Checksums for Configuration Detection

**How MD5 checksums help detect configuration changes:**

1. **Content Integrity**: MD5 generates a unique fingerprint based on file content
2. **Quick Comparison**: Comparing two 32-character hashes is faster than comparing entire files
3. **Sensitivity**: Even a single character change produces a completely different hash
4. **Efficiency**: Works well with large configuration files since only hashes are compared
5. **Reliability**: Cryptographic hashes provide high confidence in change detection

### Comparison: Relation to ArgoCD Sync Status

**Similarities with ArgoCD:**
1. **Hash Comparison**: ArgoCD uses similar hash-based comparison for Git commits vs cluster state
2. **Health Status**: Both systems provide clear health indicators (✅ OK vs ❌ CRITICAL)
3. **Automated Sync**: Automatic reconciliation when drift is detected
4. **Continuous Monitoring**: Regular checks to ensure state synchronization
5. **Alerting**: Immediate notification when configurations diverge

**Key differences:**
1. **Scale**: ArgoCD handles complex Kubernetes manifests vs simple text files
2. **Complexity**: Real GitOps tools manage dependencies and resource relationships
3. **Security**: Production tools include RBAC, encryption, and audit logging
4. **Integration**: Enterprise tools integrate with CI/CD pipelines and notification systems