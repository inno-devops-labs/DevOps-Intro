# Lab 7 — Submission

## Task 1 — Git State Reconciliation

### 1.1 Setup Desired State Configuration
Command:
```
cat desired-state.txt
```
Output:
```
version: 1.0
app: myapp
replicas: 3
```
Command:
```
cat current-state.txt
```
Output:
```
version: 1.0
app: myapp
replicas: 3
```
### 1.2 Reconciliation Script
Script (reconcile.sh):
```
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
### 1.3 Manual Drift Detection
Command:
```
echo "version: 2.0" > current-state.txt
echo "app: myapp" >> current-state.txt
echo "replicas: 5" >> current-state.txt
cat current-state.txt
```
Output:
```
version: 2.0
app: myapp
replicas: 5
```
Command:
```
./reconcile.sh
```
Output:
```
Tue Mar 17 06:47:59 PM MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 17 06:47:59 PM MSK 2026 - ✅ Reconciliation complete
```
Command:
```
diff desired-state.txt current-state.txt
```
Output:
```
(no differences)
```
Command:
```
cat current-state.txt
```
Output:
```
version: 1.0
app: myapp
replicas: 3
```
### 1.4 Continuous Reconciliation
Command:
```
watch -n 5 ./reconcile.sh
```
Output:

![7_img_1.png](screenshots%2F7_img_1.png)

### Analysis
The reconciliation loop compares the desired state with the current state.
If the states differ, the script detects configuration drift and restores the current state so that it matches the desired state file.
This prevents configuration drift because any manual or unauthorized changes are automatically overwritten.
As a result, the system continuously returns to the declared source of truth.

### Reflection
Declarative configuration has several advantages over imperative commands in production.

Advantages:
- the desired state is explicitly defined
- configuration is version-controlled
- environments are reproducible
- changes are easier to audit
- automatic reconciliation reduces human error
- systems can recover from drift automatically

This makes infrastructure management more reliable, predictable, and scalable.

## Task 2 — GitOps Health Monitoring

### 2.1 Health Check Script
Script (healthcheck.sh):
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

### 2.2 Health Monitoring
Command:
```
./healthcheck.sh
```
Output:
```
Tue Mar 17 07:26:54 PM MSK 2026 - ✅ OK: States synchronized
```
Command:
```
echo "unapproved-change: true" >> current-state.txt
```

Command:
```
./healthcheck.sh
```
Output:
```
Tue Mar 17 07:27:47 PM MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```
Command:
```
./reconcile.sh
./healthcheck.sh
```
Output:
```
Tue Mar 17 07:29:12 PM MSK 2026 - ✅ OK: States synchronized
```
Command:
```
cat health.log
```
Output:
![7_img_4.png](screenshots%2F7_img_4.png)

### 2.3 Continuous Monitoring
Script (monitor.sh):
```
#!/bin/bash
# monitor.sh - Combined reconciliation and health monitoring

echo "Starting GitOps monitoring..."
for i in {1..10}; do
    echo ""
    echo "--- Check #$i ---"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 3
done
```

Command:
```
./monitor.sh
```
Output (fragment):

![7_img_2.png](screenshots%2F7_img_2.png)
![7_img_3.png](screenshots%2F7_img_3.png)

### Analysis
Checksums (MD5) allow detecting configuration changes by comparing hash values of files instead of their full contents.  
If even a single character changes in the file, the resulting hash value will be completely different.

This makes change detection efficient and reliable, especially for large configurations.

### Comparison
This approach is similar to GitOps tools like ArgoCD.

In ArgoCD, the "Sync Status" compares the desired state stored in Git with the actual state in the cluster.  
If a mismatch is detected, the system reports an "OutOfSync" state and can automatically reconcile it.

Similarly, in this lab:
- MD5 comparison detects drift
- reconciliation restores the desired state
- monitoring ensures continuous system health

This demonstrates the core principle of GitOps: automated synchronization between declared and actual system state.