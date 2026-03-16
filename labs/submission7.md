# Lab 7

## Task 1


### 1.1: Setup Desired State Configuration

<details>
<summary>Terminal Output</summary>

```bash
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> echo "version: 1.0" > desired-state.txt
                                               echo "app: myapp" >> desired-state.txt
                                               echo "replicas: 3" >> desired-state.txt
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> cat desired-state.txt 
version: 1.0
app: myapp
replicas: 3
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> cp desired-state.txt current-state.txt
                                               echo "Initial state synchronized"
Initial state synchronized
```

</details>

### 1.2: Create Reconciliation Script

<details>
<summary>Terminal Output</summary>

```bash
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> nvim reconcile.sh
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> cat reconcile.sh 
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
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> cat current-state.txt
version: 1.0
app: myapp
replicas: 3
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> diff desired-state.txt current-state.txt
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> chmod +x reconcile.sh
```

</details>

### 1.3: Test Manual Drift Detection

<details>
<summary>Terminal Output</summary>

```bash
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> echo "version: 2.0" > current-state.txt
                                               echo "app: myapp" >> current-state.txt
                                               echo "replicas: 5" >> current-state.txt
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> cat current-state.txt
version: 2.0
app: myapp
replicas: 5
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> diff desired-state.txt current-state.txt
1c1
< version: 1.0
---
> version: 2.0
3c3
< replicas: 3
---
> replicas: 5
platon@arch ~/D/D/l/gitops-lab (feature/lab7) [1]> ./reconcile.sh
Mon Mar 16 06:55:05 PM MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Mon Mar 16 06:55:05 PM MSK 2026 - ✅ Reconciliation complete
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> diff desired-state.txt current-state.txt
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> cat current-state.txt
version: 1.0
app: myapp
replicas: 3
```

</details>

### 1.4: Automated Continuous Reconciliation

<details>
<summary>Terminal Output</summary>

```bash
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> watch -n 5 ./reconcile.sh
Mon Mar 16 10:24:20 PM MSK 2026 - ✅ States synchronized
Mon Mar 16 10:24:25 PM MSK 2026 - ✅ States synchronized
Mon Mar 16 10:24:30 PM MSK 2026 - ✅ States synchronized
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> echo "replicas: 10" >> current-state.txt
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> watch -n 5 ./reconcile.sh
Mon Mar 16 10:25:08 PM MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Mon Mar 16 10:25:08 PM MSK 2026 - ✅ Reconciliation complete
Mon Mar 16 10:25:13 PM MSK 2026 - ✅ States synchronized
Mon Mar 16 10:25:18 PM MSK 2026 - ✅ States synchronized
```

 </details>

---

**Explain the GitOps reconciliation loop. How does this prevent configuration drift?** — This is the loop which continuously checks the current state against the desired state and applies changes to ensure they match. By doing this, it automatically detects and corrects any drift that may occur, ensuring the system remains in the desired state.

**What advantages does declarative configuration have over imperative commands in production?** — Declarative config is the desired end-state stored in Git — idempotent, auditable, and automatically enforced. Imperative commands are one-shot actions with no memory: they can't detect or fix drift, have no audit trail, and require manual rollback.

## Task 2

### 2.1: Create Health Check Script

<details>
<summary>Terminal Output</summary>

```bash
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> nvim healthcheck.sh
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> cat healthcheck.sh 
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
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> chmod +x healthcheck.sh 
```

</details>

### 2.2: Test Health Monitoring

<details>
<summary>Terminal Output</summary>

```bash
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> ./healthcheck.sh 
Mon Mar 16 10:00:02 PM MSK 2026 - ✅ OK: States synchronized
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> cat health.log
Mon Mar 16 10:00:02 PM MSK 2026 - ✅ OK: States synchronized
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> echo "unapproved-change: true" >> current-state.txt 
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> ./healthcheck.sh 
Mon Mar 16 10:00:46 PM MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> cat health.log
Mon Mar 16 10:00:02 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:00:46 PM MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> ./reconcile.sh
Mon Mar 16 10:01:05 PM MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Mon Mar 16 10:01:05 PM MSK 2026 - ✅ Reconciliation complete
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> ./healthcheck.sh
Mon Mar 16 10:01:09 PM MSK 2026 - ✅ OK: States synchronized
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> cat health.log
Mon Mar 16 10:00:02 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:00:46 PM MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Mon Mar 16 10:01:09 PM MSK 2026 - ✅ OK: States synchronized
```

</details>

### 2.3: Continuous Health Monitoring

<details>
<summary>Terminal Output</summary>

```bash
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> nvim monitor.sh
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> cat monitor.sh 
#!/bin/bash
# monitor.sh - Combined reconciliation and health monitoring

echo "Starting GitOps monitoring..."
for i in {1..10}; do
    echo "--- Check #$i ---"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 3
done
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> chmod +x monitor.sh 
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> cat health.log
Mon Mar 16 10:00:02 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:00:46 PM MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Mon Mar 16 10:01:09 PM MSK 2026 - ✅ OK: States synchronized
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> ./monitor.sh
Starting GitOps monitoring...
--- Check #1 ---
Mon Mar 16 10:03:15 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:15 PM MSK 2026 - ✅ States synchronized
--- Check #2 ---
Mon Mar 16 10:03:18 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:18 PM MSK 2026 - ✅ States synchronized
--- Check #3 ---
Mon Mar 16 10:03:21 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:21 PM MSK 2026 - ✅ States synchronized
--- Check #4 ---
Mon Mar 16 10:03:24 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:24 PM MSK 2026 - ✅ States synchronized
--- Check #5 ---
Mon Mar 16 10:03:27 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:27 PM MSK 2026 - ✅ States synchronized
--- Check #6 ---
Mon Mar 16 10:03:30 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:30 PM MSK 2026 - ✅ States synchronized
--- Check #7 ---
Mon Mar 16 10:03:33 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:33 PM MSK 2026 - ✅ States synchronized
--- Check #8 ---
Mon Mar 16 10:03:36 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:36 PM MSK 2026 - ✅ States synchronized
--- Check #9 ---
Mon Mar 16 10:03:39 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:39 PM MSK 2026 - ✅ States synchronized
--- Check #10 ---
Mon Mar 16 10:03:42 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:42 PM MSK 2026 - ✅ States synchronized
platon@arch ~/D/D/l/gitops-lab (feature/lab7)> cat health.log
Mon Mar 16 10:00:02 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:00:46 PM MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Mon Mar 16 10:01:09 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:15 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:18 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:21 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:24 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:27 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:30 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:33 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:36 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:39 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:03:42 PM MSK 2026 - ✅ OK: States synchronized
```

</details>

---

**How do checksums (MD5) help detect configuration changes?** — Every change in the file will change the MD5 hash. By comparing the MD5 hashes of the {desired,current}-state files, we can quickly grasp if files have changed.

**How does this relate to GitOps tools like ArgoCD's "Sync Status"?** — ArgoCD also uses hashes to detect if files have changed and if the current state is in sync with the desired state in git. ArgoCD hashes the manifests stored in Git and compares them against the live cluster state fetched from the Kubernetes API — if they differ, Sync Status shows `OutOfSync`.