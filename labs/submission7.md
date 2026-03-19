# Submission 7 - GitOps Fundamentals

## Task 1 - Git State Reconciliation

### 1.1 Initial desired and current state

`desired-state.txt`:

```text
version: 1.0
app: myapp
replicas: 3
```

`current-state.txt` (after initial copy):

```text
version: 1.0
app: myapp
replicas: 3
```

### 1.2 Manual drift detection and reconciliation

Commands executed:

```bash
echo "version: 2.0" > current-state.txt
echo "app: myapp" >> current-state.txt
echo "replicas: 5" >> current-state.txt
./reconcile.sh
diff desired-state.txt current-state.txt
cat current-state.txt
```

Output:

```text
Thu Mar 19 08:47:46 PM MSK 2026 - DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 19 08:47:46 PM MSK 2026 - Reconciliation complete

(diff output is empty)

version: 1.0
app: myapp
replicas: 3
```

### 1.3 Continuous reconciliation (auto-healing)

Continuous loop command:

```bash
watch -n 2 ./reconcile.sh
```

Drift was injected from another terminal:

```bash
echo "replicas: 99" >> current-state.txt
```

Output observed in `watch`:

```text
Every 2.0s: ./reconcile.sh

Thu Mar 19 08:56:17 PM MSK 2026 - DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 19 08:56:17 PM MSK 2026 - Reconciliation complete
```

### Analysis

The reconciliation loop compares desired and current state continuously.  
When drift appears, it automatically restores the current state to match the desired configuration.  
This prevents long-lived configuration drift because unauthorized manual changes are corrected quickly.

### Reflection

Declarative configuration is better than imperative commands in production because:

- the target state is explicit and versioned in Git;
- rollback is easier (revert commit and resync);
- automation can continuously enforce the same known-good state;
- changes are auditable and reproducible.

## Task 2 - GitOps Health Monitoring

### 2.1 `healthcheck.sh` content

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

### 2.2 Health check results

Output with healthy state:

```text
Thu Mar 19 08:50:01 PM MSK 2026 - OK: States synchronized
```

Output after drift:

```text
Thu Mar 19 08:50:01 PM MSK 2026 - CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

Output after reconcile:

```text
Thu Mar 19 08:50:01 PM MSK 2026 - OK: States synchronized
```

### 2.3 `monitor.sh` output

```text
Starting GitOps monitoring...

--- Check #1 ---
Thu Mar 19 08:50:12 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:12 PM MSK 2026 - States synchronized

--- Check #2 ---
Thu Mar 19 08:50:15 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:15 PM MSK 2026 - States synchronized

--- Check #3 ---
Thu Mar 19 08:50:18 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:18 PM MSK 2026 - States synchronized

--- Check #4 ---
Thu Mar 19 08:50:21 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:21 PM MSK 2026 - States synchronized

--- Check #5 ---
Thu Mar 19 08:50:24 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:24 PM MSK 2026 - States synchronized

--- Check #6 ---
Thu Mar 19 08:50:27 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:27 PM MSK 2026 - States synchronized

--- Check #7 ---
Thu Mar 19 08:50:30 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:30 PM MSK 2026 - States synchronized

--- Check #8 ---
Thu Mar 19 08:50:33 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:33 PM MSK 2026 - States synchronized

--- Check #9 ---
Thu Mar 19 08:50:36 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:36 PM MSK 2026 - States synchronized

--- Check #10 ---
Thu Mar 19 08:50:40 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:40 PM MSK 2026 - States synchronized
```

### 2.4 Complete `health.log`

```text
Thu Mar 19 08:50:01 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:01 PM MSK 2026 - CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Thu Mar 19 08:50:01 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:12 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:15 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:18 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:21 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:24 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:27 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:30 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:33 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:36 PM MSK 2026 - OK: States synchronized
Thu Mar 19 08:50:40 PM MSK 2026 - OK: States synchronized
```

### Analysis

MD5 checksums are content fingerprints.  
Any configuration change changes the checksum, so drift is detected quickly and reliably.

### Comparison with ArgoCD Sync Status

This lab simulation maps to GitOps tools like ArgoCD:

- `OK` is similar to `Synced`;
- `CRITICAL` mismatch is similar to `OutOfSync`;
- `reconcile.sh` acts like automated sync to desired Git state.

ArgoCD is richer (resource-level status and health), but the core idea is the same: continuously compare desired vs actual and converge automatically.
