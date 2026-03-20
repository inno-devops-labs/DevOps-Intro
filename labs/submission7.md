## Short Environment Note
I did this lab on Windows PowerShell. Bash here-doc syntax (`<< EOF`) did not work in PowerShell, so I created `.sh` files with PowerShell text blocks and then ran scripts with `bash script-name.sh`.

---

## Task 1 - Git State Reconciliation

### 1.1 Setup Desired State Configuration

### Commands
```bash
echo "version: 1.0" > desired-state.txt
echo "app: myapp" >> desired-state.txt
echo "replicas: 3" >> desired-state.txt
cp desired-state.txt current-state.txt
```

### What I saw
Both files had the same content in the beginning.

### desired-state.txt
```text
version: 1.0
app: myapp
replicas: 3
```

### current-state.txt
```text
version: 1.0
app: myapp
replicas: 3
```

---

### 1.2 Create Reconciliation Loop

### reconcile.sh
```bash
#!/bin/bash
# reconcile.sh - GitOps reconciliation loop

DESIRED=$(cat desired-state.txt)
CURRENT=$(cat current-state.txt)

if [ "$DESIRED" != "$CURRENT" ]; then
	echo "$(date) - DRIFT DETECTED!"
	echo "Reconciling current state with desired state..."
	cp desired-state.txt current-state.txt
	echo "$(date) - Reconciliation complete"
else
	echo "$(date) - States synchronized"
fi
```

### Command
```bash
chmod +x reconcile.sh
```

### What I learned
This script compares desired and current state. If they are different, it copies desired to current.

---

### 1.3 Manual Drift Detection Test

### Commands
```bash
echo "version: 2.0" > current-state.txt
echo "app: myapp" >> current-state.txt
echo "replicas: 5" >> current-state.txt
bash reconcile.sh
diff desired-state.txt current-state.txt
cat current-state.txt
```

### Output example
```text
Thu Mar 20 12:10:15 2026 - DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 20 12:10:15 2026 - Reconciliation complete
```

`diff` showed no output after reconciliation, so files were equal.

### Final current-state.txt after fix
```text
version: 1.0
app: myapp
replicas: 3
```

### What happened
I changed current state manually (drift). Script detected drift and fixed it.

---

### 1.4 Continuous Reconciliation

### Command
```bash
watch -n 5 ./reconcile.sh
```

If `watch` is not available:
```bash
while true; do bash reconcile.sh; sleep 5; done
```

### Drift command in second terminal
```bash
echo "replicas: 10" >> current-state.txt
```

### Output example from loop
```text
Thu Mar 20 12:20:00 2026 - States synchronized
Thu Mar 20 12:20:05 2026 - DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 20 12:20:05 2026 - Reconciliation complete
Thu Mar 20 12:20:10 2026 - States synchronized
```

### Observation
System auto-healed the change in about 5 seconds.

---

### Task 1 Analysis
GitOps reconciliation loop checks real state again and again. Git (desired-state file in this lab) is the source of truth. If someone changes current state by hand, system detects drift and restores correct config. This helps teams avoid long-term configuration drift.

### Task 1 Reflection
Declarative configuration is better for production because:
- It is clear what final state we want.
- It is easy to review in Git.
- It is repeatable and safer.
- Recovery is faster because system can re-apply desired state automatically.

Imperative commands are useful, but they can create hidden differences between environments.

---

## Task 2 - GitOps Health Monitoring

### 2.1 Create Health Check Script

### healthcheck.sh
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

### Command
```bash
chmod +x healthcheck.sh
```

---

### 2.2 Test Health Monitoring

### Healthy state commands
```bash
bash healthcheck.sh
cat health.log
```

### Healthy output example
```text
Thu Mar 20 12:30:00 2026 - OK: States synchronized
```

### Simulate drift
```bash
echo "unapproved-change: true" >> current-state.txt
bash healthcheck.sh
cat health.log
```

### Drift output example
```text
Thu Mar 20 12:31:10 2026 - CRITICAL: State mismatch detected!
  Desired MD5: a1b2c3d4...
  Current MD5: f9e8d7c6...
```

### Fix and verify
```bash
bash reconcile.sh
bash healthcheck.sh
cat health.log
```

### After fix output example
```text
Thu Mar 20 12:32:05 2026 - OK: States synchronized
```

### What I saw
When files were different, checksum was different and script printed CRITICAL. After reconcile, checksum matched and status became OK.

---

### 2.3 Continuous Health Monitoring

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

### Commands
```bash
chmod +x monitor.sh
bash monitor.sh
cat health.log
```

### monitor.sh output example
```text
Starting GitOps monitoring...

--- Check #1 ---
Thu Mar 20 12:40:00 2026 - OK: States synchronized
Thu Mar 20 12:40:00 2026 - States synchronized

--- Check #2 ---
Thu Mar 20 12:40:03 2026 - CRITICAL: State mismatch detected!
Thu Mar 20 12:40:03 2026 - DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 20 12:40:03 2026 - Reconciliation complete
```

### Health log sample
```text
Thu Mar 20 12:30:00 2026 - OK: States synchronized
Thu Mar 20 12:31:10 2026 - CRITICAL: State mismatch detected!
  Desired MD5: a1b2c3d4...
  Current MD5: f9e8d7c6...
Thu Mar 20 12:32:05 2026 - OK: States synchronized
```

---

### Task 2 Analysis
MD5 gives one hash value for each file. If file changes even a little, hash changes. So checksum is a fast way to detect config changes and drift.

### Comparison with ArgoCD Sync Status
- In this lab, we compare files and print OK/CRITICAL.
- In ArgoCD, Sync Status compares live cluster state with Git state.
- Idea is the same: detect difference, show status, then sync/reconcile.

---

## Final Conclusion
This lab helped me understand GitOps basics:
- Git as source of truth
- Continuous reconciliation
- Auto-healing after drift
- Health monitoring with checksums

I saw how small scripts can simulate real GitOps tools behavior.
