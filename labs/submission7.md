# GitOps Fundamentals



## Task 1 — Git State Reconciliation

### Create Desired State (Source of Truth):

```bash
echo "version: 1.0" > desired-state.txt
echo "app: myapp" >> desired-state.txt
echo "replicas: 3" >> desired-state.txt
cat desired-state.txt
```

```bash
version: 1.0
app: myapp
replicas: 3
```

### Simulate Current Cluster State:

```bash
cp desired-state.txt current-state.txt
echo "Initial state synchronized"
```

```bash
Initial state synchronized
```

### Create a file named `reconcile.sh`:

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

### Simulate Manual Drift:

```bash
echo "version: 2.0" > current-state.txt
echo "app: myapp" >> current-state.txt
echo "replicas: 5" >> current-state.txt
cat current-state.txt
```

```bash
version: 2.0
app: myapp
replicas: 5
```

### Run Reconciliation Manually:

```bash
./reconcile.sh
diff desired-state.txt current-state.txt
```

```bash
Mon Mar  9 12:45:35 +03 2026 - ✅ States synchronized
```

### Verify Drift Was Fixed:

```bash
cat current-state.txt
```

```bash
version: 1.0
app: myapp
replicas: 3
```

### Start Continuous Reconciliation Loop:

```bash
watch -n 5 ./reconcile.sh
```

```bash
Every 5.0s: ./reconcile.sh in 0.026s (0)
Mon Mar  9 12:49:04 +03 2026 - ✅ States synchronized
Mon Mar  9 12:51:24 +03 2026 - ✅ Reconciliation complete
```

**Analysis:** GitOps uses a reconciliation loop, a mechanism in which a controller constantly compares the desired state of the system described in the Git repository with the actual state of the infrastructure.

**Advantages:** 

- Reproducibility
- Version control
- Automation
- Preventing configuration drift
- Transparency and audit



## Task 2 — GitOps Health Monitoring

### Create a file named `healthcheck.sh`:

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

### Test Healthy State:

```bash
./healthcheck.sh
cat health.log
```

```bash
Mon Mar  9 12:59:33 +03 2026 - ✅ OK: States synchronized

Mon Mar  9 12:59:33 +03 2026 - ✅ OK: States synchronized
```

### Test Healthy State:

```bash
echo "unapproved-change: true" >> current-state.txt
cat current-state.txt
```

```bash
version: 1.0
app: myapp
replicas: 3
unapproved-change: true
```

### Run Health Check on Drifted State:

```bash
./healthcheck.sh
cat health.log
```

```bash
Mon Mar  9 13:01:00 +03 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5

Mon Mar  9 12:59:33 +03 2026 - ✅ OK: States synchronized
Mon Mar  9 13:01:00 +03 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

### Fix Drift and Verify:

```bash
./reconcile.sh
./healthcheck.sh
cat health.log
```

```bash
Mon Mar  9 13:01:53 +03 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Mon Mar  9 13:01:54 +03 2026 - ✅ Reconciliation complete

Mon Mar  9 13:02:16 +03 2026 - ✅ OK: States synchronized

Mon Mar  9 12:59:33 +03 2026 - ✅ OK: States synchronized
Mon Mar  9 13:01:00 +03 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Mon Mar  9 13:02:16 +03 2026 - ✅ OK: States synchronized
```

### Create a file named `monitor.sh`:

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

### Run Monitoring Loop:

```bash
./monitor.sh
```

```bash
Starting GitOps monitoring...
\n--- Check #1 ---
Mon Mar  9 13:03:45 +03 2026 - ✅ OK: States synchronized
Mon Mar  9 13:03:45 +03 2026 - ✅ States synchronized
\n--- Check #2 ---
Mon Mar  9 13:03:48 +03 2026 - ✅ OK: States synchronized
Mon Mar  9 13:03:48 +03 2026 - ✅ States synchronized
\n--- Check #3 ---
Mon Mar  9 13:03:51 +03 2026 - ✅ OK: States synchronized
Mon Mar  9 13:03:51 +03 2026 - ✅ States synchronized
...
```

### Review Complete Health Log:

```bash
cat health.log
```

```bash
Mon Mar  9 12:59:33 +03 2026 - ✅ OK: States synchronized
Mon Mar  9 13:01:00 +03 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Mon Mar  9 13:02:16 +03 2026 - ✅ OK: States synchronized
Mon Mar  9 13:03:45 +03 2026 - ✅ OK: States synchronized
Mon Mar  9 13:03:48 +03 2026 - ✅ OK: States synchronized
Mon Mar  9 13:03:51 +03 2026 - ✅ OK: States synchronized
...
```

**Analysis:** Checksums create a unique hash for the file contents. If even one byte of the configuration changes, the MD5 value will also change. Therefore, you can quickly compare the hashes of the current and expected configuration and determine if changes have occurred.

**Comparison:** GitOps tools like ArgoCD use a similar principle. They compare the state of resources in Git with the state in the cluster. If there are differences, ArgoCD shows the OutOfSync status. When the states match, the status becomes Synced. This is similar to the checksum comparison — both mechanisms detect changes between two configuration versions.
