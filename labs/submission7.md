## Task 1 — Git State Reconciliation

### Initial desired-state.txt
```text
version: 1.0
app: myapp
replicas: 3
```

### Initial current-state.txt
```text
version: 1.0
app: myapp
replicas: 3
```

### reconcile.sh
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

### Output: manual drift detection and reconciliation
```text
Thu Mar 19 23:33:50 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 19 23:33:50 MSK 2026 - ✅ Reconciliation complete
```
### Output: synchronized state after reconciliation
```text
version: 1.0
app: myapp
replicas: 3
```

### Output: diff check after reconciliation
```text
No differences: states are synchronized
```
### Output: continuous reconciliation / auto-healing
```text
Thu Mar 19 23:36:34 MSK 2026 - ✅ States synchronized
Thu Mar 19 23:36:39 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 19 23:36:39 MSK 2026 - ✅ Reconciliation complete
Thu Mar 19 23:36:44 MSK 2026 - ✅ States synchronized
Thu Mar 19 23:36:49 MSK 2026 - ✅ States synchronized
```

### Output: state after auto-healing
```text
version: 1.0
app: myapp
replicas: 3
```

### Analysis

The reconciliation loop compares the desired state stored in Git with the current live state. If the two files are different, the script detects configuration drift and restores the current state by copying the desired state back into `current-state.txt`.

This prevents configuration drift because unauthorized or accidental changes do not remain in the system. During every reconciliation cycle, the system checks for differences and automatically returns to the approved declarative configuration.

### Reflection

Declarative configuration is better than imperative commands in production because the target state is explicitly defined, version-controlled, and easy to review. It improves reproducibility, simplifies rollback, reduces manual errors, and allows automated tools to keep systems continuously synchronized with the source of truth.

### Observation

On macOS, the watch utility was not available by default, so continuous reconciliation was demonstrated using a shell loop that executed ./reconcile.sh every 5 seconds. This provided the same GitOps-style periodic reconciliation behavior and successfully demonstrated auto-healing after drift was introduced

## Task 2 — GitOps Health Monitoring

### healthcheck.sh
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

### Output: healthy state
```text
Thu Mar 19 23:56:54 MSK 2026 - ✅ OK: States synchronized
```

### Output: drift detected
```text
Thu Mar 19 23:57:02 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 39856f67e618e2ff0c34f2b1c1a88126
```

### Output: drift fixed and verified
```text
Thu Mar 19 23:57:13 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 19 23:57:13 MSK 2026 - ✅ Reconciliation complete
Thu Mar 19 23:57:13 MSK 2026 - ✅ OK: States synchronized
```

### monitor.sh
```bash
#!/bin/bash
# monitor.sh - Combined reconciliation and health monitoring

echo "Starting GitOps monitoring..."
for i in {1..10}; do
    echo
    echo "--- Check #$i ---"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 3
done
```

### Output: continuous monitoring
```text
Starting GitOps monitoring...

--- Check #1 ---
Thu Mar 19 23:57:32 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 42a1cb7c03eb0eb34d419702ddb82c2e
Thu Mar 19 23:57:32 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 19 23:57:32 MSK 2026 - ✅ Reconciliation complete

--- Check #2 ---
Thu Mar 19 23:57:35 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:35 MSK 2026 - ✅ States synchronized

--- Check #3 ---
Thu Mar 19 23:57:38 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:38 MSK 2026 - ✅ States synchronized

--- Check #4 ---
Thu Mar 19 23:57:41 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:41 MSK 2026 - ✅ States synchronized

--- Check #5 ---
Thu Mar 19 23:57:44 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:44 MSK 2026 - ✅ States synchronized

--- Check #6 ---
Thu Mar 19 23:57:47 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:47 MSK 2026 - ✅ States synchronized

--- Check #7 ---
Thu Mar 19 23:57:50 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:50 MSK 2026 - ✅ States synchronized

--- Check #8 ---
Thu Mar 19 23:57:53 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:53 MSK 2026 - ✅ States synchronized
```

### Complete health.log
```text
Thu Mar 19 23:56:54 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:02 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 39856f67e618e2ff0c34f2b1c1a88126
Thu Mar 19 23:57:13 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:32 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 42a1cb7c03eb0eb34d419702ddb82c2e
Thu Mar 19 23:57:35 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:38 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:41 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:44 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:47 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:50 MSK 2026 - ✅ OK: States synchronized
Thu Mar 19 23:57:53 MSK 2026 - ✅ OK: States synchronized
```

### Analysis
MD5 checksums help detect configuration changes because they convert the full file contents into short unique fingerprints. If even one line in the configuration changes, the checksum also changes, so the script can immediately detect that the desired and current states are no longer synchronized.

This makes health monitoring simple and reliable for a GitOps-style workflow. Instead of comparing files line by line every time, the script compares two hashes and reports either a healthy synchronized state or a critical mismatch.

### Comparison
This is similar to GitOps tools such as ArgoCD and its Sync Status. In both cases, the system compares the desired state stored in Git with the actual running state and reports whether they match.

The difference is that this lab uses simple text files and MD5 checksums, while ArgoCD compares Kubernetes manifests with live cluster resources. The core idea is the same: detect drift, report sync status, and support automatic reconciliation.
```