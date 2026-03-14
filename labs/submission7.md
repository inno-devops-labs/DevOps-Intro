# Lab 7 — GitOps Basics

## Task 1. Simulate GitOps Reconciliation

### 1.1 Create desired and current state

Commands:
echo "version: 1.0" > desired-state.txt
echo "app: myapp" >> desired-state.txt
echo "replicas: 3" >> desired-state.txt

cp desired-state.txt current-state.txt
echo "Initial state synchronized"

cat desired-state.txt
cat current-state.txt

Output:
Initial state synchronized

version: 1.0
app: myapp
replicas: 3

version: 1.0
app: myapp
replicas: 3

### 1.2 Create reconciliation script

Script `reconcile.sh`:
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

### 1.3 Test manual drift detection

Drift simulation:
echo "version: 2.0" > current-state.txt
echo "app: myapp" >> current-state.txt
echo "replicas: 5" >> current-state.txt
cat current-state.txt

Output:
version: 2.0
app: myapp
replicas: 5

Run reconciliation:
./reconcile.sh
diff desired-state.txt current-state.txt
cat current-state.txt

Output:
Sun Mar 15 01:10:02 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun Mar 15 01:10:02 MSK 2026 - ✅ Reconciliation complete

Final state:
version: 1.0
app: myapp
replicas: 3

### 1.4 Automated continuous reconciliation

Command:
watch -n 5 ./reconcile.sh

Result:
The reconciliation loop continuously checked the state every 5 seconds and automatically restored `current-state.txt` to match `desired-state.txt` after drift.

## Task 2. Health Monitoring for GitOps

### 2.1 Create health check script

Script `healthcheck.sh`:
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

### 2.2 Test health monitoring

Healthy state:
./healthcheck.sh
cat health.log

Output:
Sun Mar 15 01:18:54 MSK 2026 - ✅ OK: States synchronized

Drift simulation:
echo "unapproved-change: true" >> current-state.txt
cat current-state.txt

Output:
version: 1.0
app: myapp
replicas: 3
unapproved-change: true

Health check after drift:
./healthcheck.sh
cat health.log

Output:
Sun Mar 15 01:18:54 MSK 2026 - ✅ OK: States synchronized
Sun Mar 15 01:20:05 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5

Reconcile and verify recovery:
./reconcile.sh
./healthcheck.sh
cat health.log

Output:
Sun Mar 15 01:20:28 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun Mar 15 01:20:28 MSK 2026 - ✅ Reconciliation complete
Sun Mar 15 01:20:28 MSK 2026 - ✅ OK: States synchronized

Final `health.log`:
Sun Mar 15 01:18:54 MSK 2026 - ✅ OK: States synchronized
Sun Mar 15 01:20:05 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Sun Mar 15 01:20:28 MSK 2026 - ✅ OK: States synchronized