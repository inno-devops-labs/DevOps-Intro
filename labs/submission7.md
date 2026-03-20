# Lab 7 — GitOps Fundamentals

**Student:** Kamilya Shakirova
**Date:** 20-03-2026


---


## Task 1 — Git State Reconciliation

- [x] Initial desired-state.txt and current-state.txt contents
- [x] Screenshot or output of drift detection and reconciliation
- [x] Output showing synchronized state after reconciliation
- [x] Output from continuous reconciliation loop detecting auto-healing
- [x] Analysis: Explain the GitOps reconciliation loop. How does this prevent configuration drift?
- [x] Reflection: What advantages does declarative configuration have over imperative commands in production?

### 1.1: Setup Desired State Configuration

1. **Create Desired State (Source of Truth):**

```bash
PS D:\Programs\DevOps-Intro> echo "version: 1.0" > desired-state.txt
PS D:\Programs\DevOps-Intro> echo "app: myapp" >> desired-state.txt
PS D:\Programs\DevOps-Intro> echo "replicas: 3" >> desired-state.txt
```

2. **Simulate Current Cluster State:**

```bash
PS D:\Programs\DevOps-Intro> cp desired-state.txt current-state.txt
PS D:\Programs\DevOps-Intro> echo "Initial state synchronized"
Initial state synchronized
```

### 1.2: Create Reconciliation Loop

1. **Create Reconciliation Script:**

Created a file named `reconcile.sh`:

```bash
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

2. **Make Script Executable:**

```bash
PS D:\Programs\DevOps-Intro> wsl
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ chmod +x reconcile.sh
```

### 1.3: Test Manual Drift Detection

1. **Simulate Manual Drift:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ echo "version: 2.0" > current-state.txt
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ echo "app: myapp" >> current-state.txt
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ echo "replicas: 5" >> current-state.txt
```

2. **Run Reconciliation Manually:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ ./reconcile.sh
./reconcile.sh: line 4: warning: command substitution: ignored null byte in input
Fri Mar 20 17:25:13 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 17:25:13 MSK 2026 - ✅ Reconciliation complete
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ diff desired-state.txt current-state.txt
```

3. **Verify Drift Was Fixed:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ cat current-state.txt
��version: 1.0
app: myapp
replicas: 3
```

### 1.4: Automated Continuous Reconciliation

1. **Start Continuous Reconciliation Loop:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ watch -n 5 ./reconcile.sh

Every 5.0s: ./reconcile.sh                                                                                                                                     Kama: Fri Mar 20 17:26:29 2026

./reconcile.sh: line 4: warning: command substitution: ignored null byte in input
./reconcile.sh: line 5: warning: command substitution: ignored null byte in input
Fri Mar 20 17:26:30 MSK 2026 - ✅ States synchronized


kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ watch -n 5 ./reconcile.sh

Every 5.0s: ./reconcile.sh                                                                                                                                     Kama: Fri Mar 20 17:28:53 2026

./reconcile.sh: line 4: warning: command substitution: ignored null byte in input
./reconcile.sh: line 5: warning: command substitution: ignored null byte in input
Fri Mar 20 17:28:53 MSK 2026 - ✅ States synchronized
```

2. **In Another Terminal, Trigger Drift:**

```bash
PS D:\Programs\DevOps-Intro> echo "replicas: 10" >> current-state.txt
```

3. **Observe Auto-Healing:**

```bash
Every 5.0s: ./reconcile.sh                                                                                                                    Kama: Fri Mar 20 17:31:18 2026

./reconcile.sh: line 4: warning: command substitution: ignored null byte in input
./reconcile.sh: line 5: warning: command substitution: ignored null byte in input
Fri Mar 20 17:31:18 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 17:31:18 MSK 2026 - ✅ Reconciliation complete


Every 5.0s: ./reconcile.sh                                                                                                                    Kama: Fri Mar 20 17:32:03 2026

./reconcile.sh: line 4: warning: command substitution: ignored null byte in input
./reconcile.sh: line 5: warning: command substitution: ignored null byte in input
Fri Mar 20 17:32:03 MSK 2026 - ✅ States synchronized
```

### Analysis
#### Explain the GitOps reconciliation loop. How does this prevent configuration drift?
The GitOps reconciliation loop is a continuous process that compares desired state (stored in Git) against actual system state, automatically correcting any differences. As demonstrated with a script running every 5 seconds, it detects drift - like someone manually changing replicas from 3 to 10 - and immediately overwrites it back to the desired configuration. This creates a self-healing system where Git remains the immutable source of truth.

### Reflection
#### What advantages does declarative configuration have over imperative commands in production?
Declarative configuration defines what you want (e.g., replicas: 3) rather than how to achieve it. This provides idempotency, self-healing capabilities, and complete audit trails through Git history. Unlike imperative commands that bypass review processes and leave no trace, declarative approaches enable team collaboration via pull requests, simplify disaster recovery, and eliminate configuration drift - making them essential for reliable, production-grade systems.







---

## Task 2 — GitOps Health Monitoring

- [x] Contents of healthcheck.sh script
- [x] Output showing "OK" status when states match
- [x] Output showing "CRITICAL" status when drift is detected
- [x] Complete health.log file showing multiple checks
- [x] Output from monitor.sh showing continuous monitoring
- [x] Analysis: How do checksums (MD5) help detect configuration changes?
- [x] Comparison: How does this relate to GitOps tools like ArgoCD's "Sync Status"?

### 2.1: Create Health Check Script

1. **Create Health Check Script:**

Created a file named `healthcheck.sh`:

```bash
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

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ chmod +x healthcheck.sh
```

### 2.2: Test Health Monitoring

1. **Test Healthy State:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ ./healthcheck.sh
Fri Mar 20 17:54:09 MSK 2026 - ✅ OK: States synchronized

kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ cat health.log
Fri Mar 20 17:54:09 MSK 2026 - ✅ OK: States synchronized
```

2. **Simulate Configuration Drift:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ echo "unapproved-change: true" >> current-state.txt
```

3. **Run Health Check on Drifted State:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ ./healthcheck.sh
Fri Mar 20 17:55:29 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: 71a29f10311a1948c950c6f5528a5937
  Current MD5: 6ed6f9d4d12daea40d2144e2e22f1914

kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ cat health.log
Fri Mar 20 17:54:09 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 17:55:29 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: 71a29f10311a1948c950c6f5528a5937
  Current MD5: 6ed6f9d4d12daea40d2144e2e22f1914
```

4. **Fix Drift and Verify:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ ./reconcile.sh

./reconcile.sh: line 4: warning: command substitution: ignored null byte in input
./reconcile.sh: line 5: warning: command substitution: ignored null byte in input
Fri Mar 20 17:55:53 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 17:55:53 MSK 2026 - ✅ Reconciliation complete

kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ ./healthcheck.sh
Fri Mar 20 17:56:03 MSK 2026 - ✅ OK: States synchronized

kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ cat health.log
Fri Mar 20 17:54:09 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 17:55:29 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: 71a29f10311a1948c950c6f5528a5937
  Current MD5: 6ed6f9d4d12daea40d2144e2e22f1914
Fri Mar 20 17:56:03 MSK 2026 - ✅ OK: States synchronized
```

### 2.3: Continuous Health Monitoring

1. **Create Combined Monitoring Script:**

Created a file named `monitor.sh`:

```bash
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

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ chmod +x monitor.sh
```

2. **Run Monitoring Loop:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ ./monitor.sh
Starting GitOps monitoring...
\n--- Check #1 ---
Fri Mar 20 17:58:14 MSK 2026 - ✅ OK: States synchronized
./reconcile.sh: line 4: warning: command substitution: ignored null byte in input
./reconcile.sh: line 5: warning: command substitution: ignored null byte in input
Fri Mar 20 17:58:15 MSK 2026 - ✅ States synchronized
\n--- Check #2 ---
Fri Mar 20 17:58:18 MSK 2026 - ✅ OK: States synchronized
./reconcile.sh: line 4: warning: command substitution: ignored null byte in input
./reconcile.sh: line 5: warning: command substitution: ignored null byte in input
Fri Mar 20 17:58:18 MSK 2026 - ✅ States synchronized
\n--- Check #3 ---
Fri Mar 20 17:58:21 MSK 2026 - ✅ OK: States synchronized
./reconcile.sh: line 4: warning: command substitution: ignored null byte in input
./reconcile.sh: line 5: warning: command substitution: ignored null byte in input
Fri Mar 20 17:58:21 MSK 2026 - ✅ States synchronized
\n--- Check #4 ---
Fri Mar 20 17:58:24 MSK 2026 - ✅ OK: States synchronized
./reconcile.sh: line 4: warning: command substitution: ignored null byte in input
./reconcile.sh: line 5: warning: command substitution: ignored null byte in input
Fri Mar 20 17:58:24 MSK 2026 - ✅ States synchronized
\n--- Check #5 ---
Fri Mar 20 17:58:27 MSK 2026 - ✅ OK: States synchronized
./reconcile.sh: line 4: warning: command substitution: ignored null byte in input
./reconcile.sh: line 5: warning: command substitution: ignored null byte in input
Fri Mar 20 17:58:27 MSK 2026 - ✅ States synchronized
```

3. **Review Complete Health Log:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ cat health.log
Fri Mar 20 17:54:09 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 17:55:29 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: 71a29f10311a1948c950c6f5528a5937
  Current MD5: 6ed6f9d4d12daea40d2144e2e22f1914
Fri Mar 20 17:56:03 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 17:58:14 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 17:58:18 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 17:58:21 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 17:58:24 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 17:58:27 MSK 2026 - ✅ OK: States synchronized
```

### Analysis
#### How do checksums (MD5) help detect configuration changes?
Checksums (MD5) create unique fingerprints of configuration content. When desired-state.txt changes from MD5 71a29f10... to 6ed6f9d4..., the hash mismatch immediately signals drift - even a single character change produces a completely different hash. This provides cryptographic certainty that configurations differ, enabling automated detection without comparing entire files line-by-line.

### Comparison
#### How does this relate to GitOps tools like ArgoCD's "Sync Status"?
ArgoCD's "Sync Status" works identically to this health check. ArgoCD continuously computes hashes of: desired state (manifests stored in Git), live state (resources running in Kubernetes). When these hashes diverge, ArgoCD marks the application "OutOfSync" (like MD5 mismatch alert). The "Synced" status appears only when hashes match. The reconciliation loop then automatically applies Git manifests to restore sync - the same auto-healing mechanism ArgoCD provides through its built-in sync policies.


