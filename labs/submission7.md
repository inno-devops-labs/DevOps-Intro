# Lab 7 — GitOps Simulation

## Task 1 — Git State Reconciliation

### Initial desired state

`desired-state.txt`

```text
version: 1.0
app: myapp
replicas: 3
```

### Initial current state

`current-state.txt`

```text
version: 1.0
app: myapp
replicas: 3
```

### Reconciliation script

`reconcile.sh`

```bash
#!/bin/bash

if cmp -s desired-state.txt current-state.txt; then
    echo "States are synchronized."
else
    echo "Drift detected."
    cp desired-state.txt current-state.txt
    echo "Reconciliation completed."
fi
```

### Manual drift simulation

Modified `current-state.txt`:

```text
version: 2.0
app: myapp
replicas: 10
```

Difference before reconciliation:

```text
1c1
< version: 1.0
---
> version: 2.0
3c3
< replicas: 3
---
> replicas: 10
```

Reconciliation output:

```text
Drift detected.
Reconciliation completed.
```

State after reconciliation:

```text
version: 1.0
app: myapp
replicas: 3
```

### Continuous reconciliation loop

A watch-based loop was started with:

```bash
watch -n 5 ./reconcile.sh
```

Then `current-state.txt` was modified again:

```text
version: 1.0
app: myapp
replicas: 3
replicas: 10
```

The reconciliation loop automatically restored the correct state. Final synchronized state:

```text
version: 1.0
app: myapp
replicas: 3
```

### Analysis

The reconciliation loop continuously compares the current state with the desired state and restores the system when drift is detected. This simulates the core GitOps idea: Git (or the desired-state file in this lab) acts as the single source of truth.

By automatically correcting changes, reconciliation reduces configuration drift and keeps the system consistent over time.

### Reflection

Declarative configuration is preferable to imperative commands in production because it defines **what the final state should be**, rather than **how to reach it**. This makes systems easier to audit, version, reproduce, and automatically recover when unexpected changes occur.

---

## Task 2 — GitOps Health Monitoring

### Health check script

`healthcheck.sh`

```bash
#!/bin/bash

DESIRED_MD5=$(md5sum desired-state.txt | awk '{print $1}')
CURRENT_MD5=$(md5sum current-state.txt | awk '{print $1}')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ "$DESIRED_MD5" = "$CURRENT_MD5" ]; then
    echo "OK: state is synchronized"
    echo "$TIMESTAMP OK desired=$DESIRED_MD5 current=$CURRENT_MD5" >> health.log
else
    echo "CRITICAL: drift detected"
    echo "$TIMESTAMP CRITICAL desired=$DESIRED_MD5 current=$CURRENT_MD5" >> health.log
fi
```

### Healthy state check

Output of `./healthcheck.sh` when both files matched:

```text
OK: state is synchronized
```

Initial log entry:

```text
2026-03-27 05:58:54 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
```

### Drifted state check

Drift was introduced with:

```bash
echo "unapproved-change: true" >> current-state.txt
```

Modified state:

```text
version: 1.0
app: myapp
replicas: 3
unapproved-change: true
```

Health check output:

```text
CRITICAL: drift detected
```

Log after drift:

```text
2026-03-27 05:58:54 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
2026-03-27 06:01:41 CRITICAL desired=a15a1a4f965ecd8f9e23a33a6b543155 current=48168ff3ab5ffc0214e81c7e2ee356f5
```

### Recovery after drift

Reconciliation and health check:

```text
Drift detected.
Reconciliation completed.
OK: state is synchronized
```

Log after recovery:

```text
2026-03-27 05:58:54 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
2026-03-27 06:01:41 CRITICAL desired=a15a1a4f965ecd8f9e23a33a6b543155 current=48168ff3ab5ffc0214e81c7e2ee356f5
2026-03-27 06:03:17 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
```

### Monitor loop script

`monitor.sh`

```bash
#!/bin/bash

for i in {1..10}; do
    echo "Iteration $i"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 3
done
```

### Monitor loop execution

Before running the monitor, drift was introduced again:

```text
version: 1.0
app: myapp
replicas: 3
replicas: 99
```

Output of `./monitor.sh`:

```text
Iteration 1
CRITICAL: drift detected
Drift detected.
Reconciliation completed.
Iteration 2
OK: state is synchronized
States are synchronized.
Iteration 3
OK: state is synchronized
States are synchronized.
Iteration 4
OK: state is synchronized
States are synchronized.
Iteration 5
OK: state is synchronized
States are synchronized.
Iteration 6
OK: state is synchronized
States are synchronized.
Iteration 7
OK: state is synchronized
States are synchronized.
Iteration 8
OK: state is synchronized
States are synchronized.
Iteration 9
OK: state is synchronized
States are synchronized.
Iteration 10
OK: state is synchronized
States are synchronized.
```

Final `health.log`:

```text
2026-03-27 05:58:54 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
2026-03-27 06:01:41 CRITICAL desired=a15a1a4f965ecd8f9e23a33a6b543155 current=48168ff3ab5ffc0214e81c7e2ee356f5
2026-03-27 06:03:17 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
2026-03-27 06:05:08 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
2026-03-27 06:05:58 CRITICAL desired=a15a1a4f965ecd8f9e23a33a6b543155 current=93d541ce03f5304eec60b2363acf80c9
2026-03-27 06:06:01 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
2026-03-27 06:06:04 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
2026-03-27 06:06:08 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
2026-03-27 06:06:11 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
2026-03-27 06:06:14 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
2026-03-27 06:06:17 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
2026-03-27 06:06:20 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
2026-03-27 06:06:23 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
2026-03-27 06:06:27 OK desired=a15a1a4f965ecd8f9e23a33a6b543155 current=a15a1a4f965ecd8f9e23a33a6b543155
```

Final synchronized state:

```text
version: 1.0
app: myapp
replicas: 3
```

### Analysis

Checksums provide a simple and reliable way to detect whether two configuration files are identical. If the MD5 hashes differ, the system can immediately identify that drift has occurred.

This is conceptually similar to the Sync Status in tools such as ArgoCD and Flux: the desired state is compared with the observed state, and a mismatch is reported as unhealthy or out of sync.
