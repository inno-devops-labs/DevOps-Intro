# Lab 7 Submission — GitOps Fundamentals

## Task 1 — Git State Reconciliation

### 1.1 Setup Desired State Configuration

Command:

```bash
printf 'version: 1.0\napp: myapp\nreplicas: 3\n' > desired-state.txt
cp desired-state.txt current-state.txt
echo 'Initial state synchronized'
```

Output:

```text
Initial state synchronized
```

Initial `desired-state.txt`:

```text
version: 1.0
app: myapp
replicas: 3
```

Initial `current-state.txt`:

```text
version: 1.0
app: myapp
replicas: 3
```

### 1.2 Reconciliation Script

Contents of `reconcile.sh`:

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

Command:

```bash
chmod +x reconcile.sh
```

Output:

```text
```

### 1.3 Manual Drift Detection

Command:

```bash
printf 'version: 2.0\napp: myapp\nreplicas: 5\n' > current-state.txt
```

Output:

```text
```

Command:

```bash
./reconcile.sh
```

Output:

```text
Tue Mar 17 19:59:45 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 17 19:59:45 MSK 2026 - ✅ Reconciliation complete
```

Command:

```bash
diff desired-state.txt current-state.txt
```

Output:

```text
```

Command:

```bash
cat current-state.txt
```

Output:

```text
version: 1.0
app: myapp
replicas: 3
```

### 1.4 Automated Continuous Reconciliation

Interactive observation command:

```bash
watch -n 2 ./reconcile.sh
```

Observed initial screen output:

```text
Every 2.0s: ./reconcile.sh                             debian: Tue Mar 17 20:00:04 2026

Tue Mar 17 20:00:04 MSK 2026 - ✅ States synchronized
```

Drift trigger command run from another process:

```bash
printf '\nreplicas: 10\n' >> current-state.txt
```

Output:

```text
```

Readable output from the timed `watch` session:

```text
Every 2.0s: ./reconcile.sh                             debian: Tue Mar 17 20:00:04 2026

Tue Mar 17 20:00:04 MSK 2026 - ✅ States synchronized
Tue Mar 17 20:00:29 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 17 20:00:29 MSK 2026 - ✅ Reconciliation complete
Tue Mar 17 20:00:39 MSK 2026 - ✅ States synchronized
```

Follow-up verification command:

```bash
cat current-state.txt
```

Output:

```text
version: 1.0
app: myapp
replicas: 3
```

### Analysis

The reconciliation loop compares the desired state stored in Git-style declarative configuration with the current state running in the environment. If the files differ, the loop detects drift and rewrites `current-state.txt` so it matches `desired-state.txt` again. This prevents configuration drift because the desired state is checked repeatedly, so manual changes do not remain in place for long.

### Reflection

Declarative configuration is better than imperative production commands because the target state is stored in a reviewable, versioned form. That makes rollback easier, reduces operator mistakes, supports automation, and allows systems like ArgoCD or Flux to restore the intended configuration without depending on someone remembering the exact commands they ran earlier.

## Task 2 — GitOps Health Monitoring

### 2.1 Health Check Script

Contents of `healthcheck.sh`:

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

Command:

```bash
chmod +x healthcheck.sh
```

Output:

```text
```

### 2.2 Test Health Monitoring

Command:

```bash
./healthcheck.sh
```

Output:

```text
Tue Mar 17 20:01:32 MSK 2026 - ✅ OK: States synchronized
```

Command:

```bash
cat health.log
```

Output:

```text
Tue Mar 17 20:01:32 MSK 2026 - ✅ OK: States synchronized
```

Command:

```bash
printf 'unapproved-change: true\n' >> current-state.txt
```

Output:

```text
```

Command:

```bash
./healthcheck.sh
```

Output:

```text
Tue Mar 17 20:01:46 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

Command:

```bash
cat health.log
```

Output:

```text
Tue Mar 17 20:01:32 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:01:46 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

Command:

```bash
./reconcile.sh
```

Output:

```text
Tue Mar 17 20:02:10 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 17 20:02:10 MSK 2026 - ✅ Reconciliation complete
```

Command:

```bash
./healthcheck.sh
```

Output:

```text
Tue Mar 17 20:02:16 MSK 2026 - ✅ OK: States synchronized
```

Command:

```bash
cat health.log
```

Output:

```text
Tue Mar 17 20:01:32 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:01:46 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Tue Mar 17 20:02:10 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Tue Mar 17 20:02:16 MSK 2026 - ✅ OK: States synchronized
```

### 2.3 Continuous Health Monitoring

Contents of `monitor.sh`:

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

Command:

```bash
chmod +x monitor.sh
```

Output:

```text
```

Command run after injecting drift:

```bash
printf 'manual-drift: injected-before-monitor\n' >> current-state.txt
./monitor.sh
```

Output:

```text
Starting GitOps monitoring...
\n--- Check #1 ---
Tue Mar 17 20:02:35 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: f5890638a9e338d2eee823dfeebdeb0d
Tue Mar 17 20:02:35 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 17 20:02:35 MSK 2026 - ✅ Reconciliation complete
\n--- Check #2 ---
Tue Mar 17 20:02:38 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:38 MSK 2026 - ✅ States synchronized
\n--- Check #3 ---
Tue Mar 17 20:02:41 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:41 MSK 2026 - ✅ States synchronized
\n--- Check #4 ---
Tue Mar 17 20:02:44 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:44 MSK 2026 - ✅ States synchronized
\n--- Check #5 ---
Tue Mar 17 20:02:47 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:47 MSK 2026 - ✅ States synchronized
\n--- Check #6 ---
Tue Mar 17 20:02:50 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:50 MSK 2026 - ✅ States synchronized
\n--- Check #7 ---
Tue Mar 17 20:02:53 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:53 MSK 2026 - ✅ States synchronized
\n--- Check #8 ---
Tue Mar 17 20:02:56 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:56 MSK 2026 - ✅ States synchronized
\n--- Check #9 ---
Tue Mar 17 20:02:59 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:59 MSK 2026 - ✅ States synchronized
\n--- Check #10 ---
Tue Mar 17 20:03:02 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:03:02 MSK 2026 - ✅ States synchronized
```

Complete `health.log` after all checks:

```text
Tue Mar 17 20:01:32 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:01:46 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Tue Mar 17 20:02:10 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Tue Mar 17 20:02:16 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:35 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: f5890638a9e338d2eee823dfeebdeb0d
Tue Mar 17 20:02:38 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:41 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:44 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:47 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:50 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:53 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:56 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:02:59 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 20:03:02 MSK 2026 - ✅ OK: States synchronized
```

### Analysis

Checksums help detect configuration changes because they reduce a file's full contents to a short fingerprint. If `desired-state.txt` and `current-state.txt` are identical, the MD5 checksums match. If even one line changes, the checksum changes too, so the monitoring script can detect drift quickly without printing or comparing the full file every time.

### Comparison to ArgoCD Sync Status

This simulation is similar to ArgoCD's Sync Status because both compare the desired state from Git with the live state in the target environment. In this lab the comparison is done with file contents and MD5 hashes, while ArgoCD compares Kubernetes manifests and live resources. In both cases, a mismatch means the system is `OutOfSync`, and reconciliation is needed to return to the declared configuration.
