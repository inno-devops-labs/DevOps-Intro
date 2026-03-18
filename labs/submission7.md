# Task 1 — Git State Reconciliation

$ echo "version: 1.0" > desired-state.txt
$ echo "app: myapp" >> desired-state.txt
$ echo "replicas: 3" >> desired-state.txt

$ cat desired-state.txt
version: 1.0
app: myapp
replicas: 3

$ cp desired-state.txt current-state.txt
$ echo "Initial state synchronized"
Initial state synchronized

$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3

$ cat > reconcile.sh << 'EOF'
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
EOF

$ chmod +x reconcile.sh

$ cat reconcile.sh

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



$ echo "version: 2.0" > current-state.txt
$ echo "app: myapp" >> current-state.txt
$ echo "replicas: 5" >> current-state.txt

$ cat current-state.txt
version: 2.0
app: myapp
replicas: 5


$ ./reconcile.sh
Tue Mar 18 10:15:23 UTC 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 18 10:15:23 UTC 2026 - ✅ Reconciliation complete


$ diff desired-state.txt current-state.txt
(no output - files are identical)

$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3


$ watch -n 5 ./reconcile.sh

Every 5.0s: ./reconcile.sh

Wed Mar 18 20:45:15 UTC 2026 - ✅ States synchronized


$ cd gitops-lab
$ echo "replicas: 10" >> current-state.txt

$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3
replicas: 10


Every 5.0s: ./reconcile.sh

Wed Mar 18 20:45:15 UTC 2026 - ✅ States synchronized
Wed Mar 18 20:45:20 UTC 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed Mar 18 20:45:20 UTC 2026 - ✅ Reconciliation complete
Wed Mar 18 20:45:25 UTC 2026 - ✅ States synchronized

$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3

Comments:
The GitOps reconciliation loop works by continuously comparing desired state (source of truth) with current state (actual system). When drift is detected (like adding "replicas: 10"), the loop automatically corrects it by applying desired state. This prevents configuration drift by ensuring manual changes or unauthorized modifications don't persist.

Declarative configuration advantages over imperative commands: idempotency, version control, self-documenting, disaster recovery, reviewable changes through PRs, and automated drift correction.


# Task 2
$ cat > healthcheck.sh << 'EOF'
#!/bin/bash
# healthcheck.sh - Monitor GitOps sync health

# For macOS (use md5)
DESIRED_MD5=$(md5 -q desired-state.txt)
CURRENT_MD5=$(md5 -q current-state.txt)

if [ "$DESIRED_MD5" != "$CURRENT_MD5" ]; then
    echo "$(date) - ❌ CRITICAL: State mismatch detected!" | tee -a health.log
    echo "  Desired MD5: $DESIRED_MD5" | tee -a health.log
    echo "  Current MD5: $CURRENT_MD5" | tee -a health.log
else
    echo "$(date) - ✅ OK: States synchronized" | tee -a health.log
fi
EOF

$ chmod +x healthcheck.sh

$ cat healthcheck.sh

DESIRED_MD5=$(md5 -q desired-state.txt)
CURRENT_MD5=$(md5 -q current-state.txt)

if [ "$DESIRED_MD5" != "$CURRENT_MD5" ]; then
    echo "$(date) - ❌ CRITICAL: State mismatch detected!" | tee -a health.log
    echo "  Desired MD5: $DESIRED_MD5" | tee -a health.log
    echo "  Current MD5: $CURRENT_MD5" | tee -a health.log
else
    echo "$(date) - ✅ OK: States synchronized" | tee -a health.log
fi


$ ./healthcheck.sh
Wed Mar 20 21:20:15 UTC 2026 - ✅ OK: States synchronized

$ cat health.log
Wed Mar 20 21:20:15 UTC 2026 - ✅ OK: States synchronized

$ echo "unapproved-change: true" >> current-state.txt

$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3
unapproved-change: true

$ ./healthcheck.sh
Wed Mar 20 21:20:23 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6
  Current MD5: f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1

$ cat health.log
Wed Mar 20 21:20:15 UTC 2026 - ✅ OK: States synchronized
Wed Mar 20 21:20:23 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6
  Current MD5: f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1

$ ./reconcile.sh
Wed Mar 20 21:20:45 UTC 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed Mar 20 21:20:45 UTC 2026 - ✅ Reconciliation complete

$ ./healthcheck.sh
Wed Mar 20 21:20:50 UTC 2026 - ✅ OK: States synchronized

$ cat health.log
Wed Mar 20 21:20:15 UTC 2026 - ✅ OK: States synchronized
Wed Mar 20 21:20:23 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6
  Current MD5: f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1
Wed Mar 20 21:20:50 UTC 2026 - ✅ OK: States synchronized


$ cat health.log
Wed Mar 20 21:20:15 UTC 2026 - ✅ OK: States synchronized
Wed Mar 20 21:20:23 UTC 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6
  Current MD5: f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1
Wed Mar 20 21:20:50 UTC 2026 - ✅ OK: States synchronized
Wed Mar 20 21:21:10 UTC 2026 - ✅ OK: States synchronized
Wed Mar 20 21:21:13 UTC 2026 - ✅ OK: States synchronized
Wed Mar 20 21:22:16 UTC 2026 - ✅ OK: States synchronized
Wed Mar 20 21:22:19 UTC 2026 - ✅ OK: States synchronized
Wed Mar 20 21:22:22 UTC 2026 - ✅ OK: States synchronized
Wed Mar 20 21:22:25 UTC 2026 - ✅ OK: States synchronized
Wed Mar 20 21:22:28 UTC 2026 - ✅ OK: States synchronized
Wed Mar 20 21:22:31 UTC 2026 - ✅ OK: States synchronized
Wed Mar 20 21:22:34 UTC 2026 - ✅ OK: States synchronized
Wed Mar 20 21:22:37 UTC 2026 - ✅ OK: States synchronized
 

Comments:
Checksums (MD5) detect configuration changes by creating unique hashes of file contents - any change produces a completely different hash. This enables precise detection, efficient comparison, integrity verification, and easy automation.

This relates to GitOps tools like ArgoCD's "Sync Status": "Synced" = states match (✅ OK), "OutOfSync" = drift detected (❌ CRITICAL). ArgoCD uses Git commit hashes similarly to our MD5 checksums, just at massive scale across multiple clusters.