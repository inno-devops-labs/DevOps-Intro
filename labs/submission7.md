# Lab 7

WSL Ubuntu. Work dir: `labs/lab7`.

## Task 1

Initial `desired-state.txt` and `current-state.txt`:

```
version: 1.0
app: myapp
replicas: 3
```

Manual drift and reconciliation:

```
version: 2.0
app: myapp
replicas: 5

Thu Mar 19 18:41:36 MSK 2026 - DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 19 18:41:36 MSK 2026 - Reconciliation complete
```

`diff desired-state.txt current-state.txt`: no output.

State after reconciliation:

```
version: 1.0
app: myapp
replicas: 3
```

`watch -n 5 ./reconcile.sh`:

```
Thu Mar 19 18:44:28 MSK 2026 - States synchronized
Thu Mar 19 18:44:33 MSK 2026 - DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 19 18:44:33 MSK 2026 - Reconciliation complete
Thu Mar 19 18:44:38 MSK 2026 - States synchronized
```

The script compares desired and current state and restores the current file from the desired file when they differ. This prevents drift because manual changes are overwritten by the declared state.

Declarative configuration is easier to review, repeat, and roll back. Imperative changes are harder to track and lead to drift.

## Task 2

`healthcheck.sh`:

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

Healthy state:

```
Thu Mar 19 18:43:09 MSK 2026 - OK: States synchronized
```

Drift detected:

```
Thu Mar 19 18:43:09 MSK 2026 - CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

`monitor.sh` output:

```
Starting GitOps monitoring...

--- Check #1 ---
Thu Mar 19 18:43:27 MSK 2026 - CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Thu Mar 19 18:43:27 MSK 2026 - DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 19 18:43:27 MSK 2026 - Reconciliation complete

--- Check #2 ---
Thu Mar 19 18:43:30 MSK 2026 - OK: States synchronized
Thu Mar 19 18:43:30 MSK 2026 - States synchronized
```

Complete `health.log`:

```
Thu Mar 19 18:43:27 MSK 2026 - CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Thu Mar 19 18:43:30 MSK 2026 - OK: States synchronized
Thu Mar 19 18:43:33 MSK 2026 - OK: States synchronized
Thu Mar 19 18:43:36 MSK 2026 - OK: States synchronized
Thu Mar 19 18:43:39 MSK 2026 - OK: States synchronized
Thu Mar 19 18:43:42 MSK 2026 - OK: States synchronized
Thu Mar 19 18:43:45 MSK 2026 - OK: States synchronized
Thu Mar 19 18:43:48 MSK 2026 - OK: States synchronized
Thu Mar 19 18:43:51 MSK 2026 - OK: States synchronized
Thu Mar 19 18:43:54 MSK 2026 - OK: States synchronized
```

MD5 changes when file contents change, so mismatches are easy to detect. It is a simple way to check sync health.

This is a simplified version of ArgoCD Sync Status. Here the result is based on file hashes, while ArgoCD compares live cluster resources with manifests in Git.
