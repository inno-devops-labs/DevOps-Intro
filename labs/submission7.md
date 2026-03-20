# 1

1.1

desired-state:
```
version: 1.0
app: myapp
replicas: 3
```

current-state:
```
version: 2.0
app: myapp
replicas: 5
```

1.2
```
./reconcile.sh
diff desired-state.txt current-state.txt
Fri 20 Mar 2026 18:33:17 MSK - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri 20 Mar 2026 18:33:17 MSK - ✅ Reconciliation complete
```

1.3
```
cat current-state.txt
version: 1.0
app: myapp
replicas: 3
```

1.4
```
Fri 20 Mar 2026 18:38:16 MSK - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri 20 Mar 2026 18:38:16 MSK - ✅ Reconciliation complete
```

1.5
The GitOps reconciliation loop continuously compares the desired state stored in Git (the source of truth) against the actual live cluster state, automatically correcting any discrepancies by reapplying the desired configuration, thereby preventing configuration drift by ensuring that any manual changes or unauthorized modifications are immediately overwritten to match the declared intent.

1.6
Declarative configuration provides advantages over imperative commands in production by specifying the desired end state, enabling version control, automated reconciliation, idempotent application, and consistent environments across the fleet, whereas imperative commands require manual step-by-step execution that is error-prone, unrepeatable, and difficult to audit or rollback.

# 2

2.1
```
cat healthcheck.sh
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

2.2
```
cat health.log
Fri 20 Mar 2026 18:42:29 MSK - ✅ OK: States synchronized
```

2.3
```
cat health.log
Fri 20 Mar 2026 18:42:45 MSK - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

2.4
```
cat health.log
Fri 20 Mar 2026 18:42:29 MSK - ✅ OK: States synchronized
Fri 20 Mar 2026 18:42:45 MSK - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Fri 20 Mar 2026 18:42:49 MSK - ✅ OK: States synchronized
Fri 20 Mar 2026 18:43:28 MSK - ✅ OK: States synchronized
Fri 20 Mar 2026 18:43:31 MSK - ✅ OK: States synchronized
Fri 20 Mar 2026 18:43:34 MSK - ✅ OK: States synchronized
```

2.5
```
./monitor.sh
Starting GitOps monitoring...
\n--- Check #1 ---
Fri 20 Mar 2026 18:43:28 MSK - ✅ OK: States synchronized
Fri 20 Mar 2026 18:43:28 MSK - ✅ States synchronized
\n--- Check #2 ---
Fri 20 Mar 2026 18:43:31 MSK - ✅ OK: States synchronized
Fri 20 Mar 2026 18:43:31 MSK - ✅ States synchronized
\n--- Check #3 ---
Fri 20 Mar 2026 18:43:34 MSK - ✅ OK: States synchronized
Fri 20 Mar 2026 18:43:34 MSK - ✅ States synchronized
```

2.6
Checksums (MD5) help detect configuration changes by generating a unique, fixed-size hash of the file contents, allowing the health check script to quickly and reliably compare the desired state and current state for any discrepancy—even a single character change—without needing to perform a line-by-line diff, enabling immediate drift detection.

2.7
This MD5-based health check directly mirrors how GitOps tools like ArgoCD use hash comparisons to determine "Sync Status" - green when desired and live state checksums match, and red or "OutOfSync" when they diverge.