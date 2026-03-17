# Task 1

## Initial desired-state.txt and current-state.txt contents

desired-state.txt

```
version: 1.0
app: myapp
replicas: 3
```

same contents in current-state.txt initially


## Output of drift detection and reconciliation
`./reconcile.sh`

```
Wed Mar 18 00:15:47 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed Mar 18 00:15:47 MSK 2026 - ✅ Reconciliation complete
```

After drift fix:
`cat current-state.txt`

```
version: 1.0
app: myapp
replicas: 3
```

## Output showing synchronized state after reconciliation

synchronized state:
`cat current-state.txt`

```
version: 1.0
app: myapp
replicas: 3
```

## Output from continuous reconciliation loop detecting auto-healing

```
Every 5.0s: ./reconcile.sh                                     fedora: Wed Mar 18 00:18:35 2026

Wed Mar 18 00:18:35 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed Mar 18 00:18:35 MSK 2026 - ✅ Reconciliation complete
```

```
Every 5.0s: ./reconcile.sh                                     fedora: Wed Mar 18 00:18:55 2026

Wed Mar 18 00:18:55 MSK 2026 - ✅ States synchronized
```

## Analysis: Explain the GitOps reconciliation loop. How does this prevent configuration drift?

A controller reads the desired state from a single source of GT and continuously compares it to the live current state. On each loop it detects differences (drift) and applies the minimal changes needed to converge the live state to desired state.

## Reflection: What advantages does declarative configuration have over imperative commands in production?

Applying the same manifest yields the same result

Easier automation, CI/CD integration, and safe rollbacks

Reduces human error and improves consistency across environments

# Task 2


## Contents of healthcheck.sh script

```
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



## Output showing "OK" status when states match

`Wed Mar 18 00:23:35 MSK 2026 - ✅ OK: States synchronized`

## Output showing "CRITICAL" status when drift is detected

```
Wed Mar 18 00:24:23 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

## Complete health.log file showing multiple checks

```
Wed Mar 18 00:23:35 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 00:24:23 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Wed Mar 18 00:25:06 MSK 2026 - ✅ OK: States synchronized
```

## Output from monitor.sh showing continuous monitoring
`monitor.sh` contents

```
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

Output:

```
Starting GitOps monitoring...
\n--- Check #1 ---
Wed Mar 18 00:25:58 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 00:25:58 MSK 2026 - ✅ States synchronized
\n--- Check #2 ---
Wed Mar 18 00:26:01 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 00:26:01 MSK 2026 - ✅ States synchronized
\n--- Check #3 ---
Wed Mar 18 00:26:04 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 00:26:04 MSK 2026 - ✅ States synchronized
\n--- Check #4 ---
Wed Mar 18 00:26:07 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 00:26:07 MSK 2026 - ✅ States synchronized
```

## Analysis: How do checksums (MD5) help detect configuration changes?

Comparing checksums is a cheap and simple to compute. It helps to quickly detect any differences in any files, so if checksums are not equal then there is some change


## Comparison: How does this relate to GitOps tools like ArgoCD's "Sync Status"?

Basic idea is the same: compare hash representations. AgroCD provides richer functionality such as structured diffs and automated reconciliation and UI/permission controls. When GitOps tools is simpler approach 