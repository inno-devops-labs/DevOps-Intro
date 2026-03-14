# Lab 7 Submission
## Task 1: Git State Reconciliation
#### Initial desired-state.txt and current-state.txt contents:
```
arinapetuhova@MacBook-Air-Arina ~ % echo "version: 1.0" > desired-state.txt
echo "app: myapp" >> desired-state.txt
echo "replicas: 3" >> desired-state.txt
arinapetuhova@MacBook-Air-Arina ~ % cp desired-state.txt current-state.txt
arinapetuhova@MacBook-Air-Arina ~ % echo "version: 2.0" > current-state.txt
arinapetuhova@MacBook-Air-Arina ~ % echo "app: myapp" >> current-state.txt
arinapetuhova@MacBook-Air-Arina ~ % echo "replicas: 5" >> current-state.txt
```

#### Output of drift detection and reconciliation:
```
arinapetuhova@MacBook-Air-Arina ~ % ./reconcile.sh
суббота, 14 марта 2026 г. 13:33:01 (MSK) - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
суббота, 14 марта 2026 г. 13:33:01 (MSK) - ✅ Reconciliation complete
```

#### Output showing synchronized state after reconciliation:
```
arinapetuhova@MacBook-Air-Arina ~ % diff desired-state.txt current-state.txt
arinapetuhova@MacBook-Air-Arina ~ % cat current-state.txt
version: 1.0
app: myapp
replicas: 3
```

#### Output from continuous reconciliation loop detecting auto-healing:
```
arinapetuhova@MacBook-Air-Arina ~ % watch -n 5 ./reconcile.sh



                              8:35         ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
суббота, 14 марта 2026 г. 13:38:35 (MSK) - ✅ Reconciliation complete

arinapetuhova@MacBook-Air-Arina ~ % watch -n 5 ./reconcile.sh



                              8:45         ✅ States synchronized
```

#### Analysis:
The GitOps reconciliation loop works by continuously comparing the desired state (in Git/desired-state.txt) with the actual current state (in the cluster/current-state.txt). As shown in the output, when I manually changed current-state.txt to have version 2.0 and replicas 5, the reconcile.sh script immediately detected this drift at 13:33:01 and automatically copied the desired state back to current state. This prevents configuration drift by constantly enforcing that the actual system always matches the declared configuration in Git, automatically fixing any manual changes or unexpected modifications within seconds.

#### Reflection:
Declarative configuration is better for production because you simply describe what you want (like "replicas: 3") instead of typing specific commands to make changes. As shown in the output, when I used imperative commands to manually change the state to version 2.0 and replicas 5, the declarative approach automatically detected this and reverted it back to the correct version 1.0 with replicas 3. This makes production systems more reliable, self-healing, and easier to manage because you never have to remember what commands were run - you just look at the declarative config files to know exactly what your system should look like.

## Task 2: GitOps Health Monitoring
#### Contents of healthcheck.sh script:
```
#!/bin/bash
# healthcheck.sh - Monitor GitOps sync health

DESIRED_MD5=$(md5 -q desired-state.txt)
CURRENT_MD5=$(md5 -q current-state.txt)

if [ "$DESIRED_MD5" != "$CURRENT_MD5" ]; then
    echo "$(date) - ❌ CRITICAL: State mismatch detected!" | tee -a health.log
    echo "  Desired MD5: $DESIRED_MD5" | tee -a health.log
    echo "  Current MD5: $CURRENT_MD5" | tee -a health.log
else
    echo "$(date) - ✅ OK: States synchronized" | tee -a health.log
fi
```

#### Output showing "OK" status when states match:
```
arinapetuhova@MacBook-Air-Arina ~ % ./healthcheck.sh
cat health.log
суббота, 14 марта 2026 г. 13:48:43 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:48:43 (MSK) - ✅ OK: States synchronized
```

#### Output showing "CRITICAL" status when drift is detected:
```
arinapetuhova@MacBook-Air-Arina ~ % echo "unapproved-change: true" >> current-state.txt
arinapetuhova@MacBook-Air-Arina ~ % ./healthcheck.sh
cat health.log
суббота, 14 марта 2026 г. 13:48:55 (MSK) - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
суббота, 14 марта 2026 г. 13:48:43 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:48:55 (MSK) - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

#### Complete health.log file showing multiple checks:
```
arinapetuhova@MacBook-Air-Arina ~ % cat health.log
суббота, 14 марта 2026 г. 13:48:43 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:48:55 (MSK) - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
суббота, 14 марта 2026 г. 13:49:04 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:02 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:05 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:08 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:12 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:15 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:18 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:21 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:24 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:27 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:30 (MSK) - ✅ OK: States synchronized
```

#### Output from monitor.sh showing continuous monitoring:
```
arinapetuhova@MacBook-Air-Arina ~ % ./monitor.sh
Starting GitOps monitoring...

--- Check #1 ---
суббота, 14 марта 2026 г. 13:50:02 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:02 (MSK) - ✅ States synchronized

--- Check #2 ---
суббота, 14 марта 2026 г. 13:50:05 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:05 (MSK) - ✅ States synchronized

--- Check #3 ---
суббота, 14 марта 2026 г. 13:50:08 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:09 (MSK) - ✅ States synchronized

--- Check #4 ---
суббота, 14 марта 2026 г. 13:50:12 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:12 (MSK) - ✅ States synchronized

--- Check #5 ---
суббота, 14 марта 2026 г. 13:50:15 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:15 (MSK) - ✅ States synchronized

--- Check #6 ---
суббота, 14 марта 2026 г. 13:50:18 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:18 (MSK) - ✅ States synchronized

--- Check #7 ---
суббота, 14 марта 2026 г. 13:50:21 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:21 (MSK) - ✅ States synchronized

--- Check #8 ---
суббота, 14 марта 2026 г. 13:50:24 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:24 (MSK) - ✅ States synchronized

--- Check #9 ---
суббота, 14 марта 2026 г. 13:50:27 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:27 (MSK) - ✅ States synchronized

--- Check #10 ---
суббота, 14 марта 2026 г. 13:50:30 (MSK) - ✅ OK: States synchronized
суббота, 14 марта 2026 г. 13:50:30 (MSK) - ✅ States synchronized
```

#### Analysis:
Checksums like MD5 act like a digital fingerprint for files. When you run the `md5` command on `desired-state.txt` and `current-state.txt,` it creates unique hash values based on the exact content inside each file. If someone adds, removes, or changes even one character in a file, the MD5 hash completely changes. In my output, when I added "unapproved-change: true" to `current-state.txt`, its MD5 hash changed from `a15a1a4f...` to `48168ff3...`, which immediately told the healthcheck script that something was wrong without having to compare the actual text line by line.

#### Comparison:
This is exactly how ArgoCD and other GitOps tools monitor sync status in production. In my output, `healthcheck.sh` comparing MD5 hashes is like ArgoCD comparing what's in Git (`desired-state.txt`) against what's running in Kubernetes (`current-state.txt`). When my script showed "❌ CRITICAL: State mismatch detected!", that's the same as ArgoCD showing "Out of Sync" status. And when it later showed "✅ OK: States synchronized", that's ArgoCD's "Synced" status. The `health.log` file acts like ArgoCD's history of sync status changes over time.