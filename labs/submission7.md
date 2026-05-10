### Task 1

#### 1.1: Setup Desired State Configuration

```bash
$ echo "version: 1.0" > desired-state.txt
$ echo "app: myapp" >> desired-state.txt
$ echo "replicas: 3" >> desired-state.txt

$ cp desired-state.txt current-state.txt
$ echo "Initial state synchronized"
Initial state synchronized
```

Initial `desired-state.txt`:

```bash
version: 1.0
app: myapp
replicas: 3
```

Initial `current-state.txt`:

```bash
version: 1.0
app: myapp
replicas: 3
```

#### 1.2: Create Reconciliation Loop

Created `reconcile.sh` and made it executable:

```bash
$ chmod +x reconcile.sh
```

#### 1.3: Test Manual Drift Detection

I changed the current state manually:

```bash
$ echo "version: 2.0" > current-state.txt
$ echo "app: myapp" >> current-state.txt
$ echo "replicas: 5" >> current-state.txt
```

Then ran reconciliation:

```bash
$ ./reconcile.sh
Sun May 10 12:55:01 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun May 10 12:55:01 MSK 2026 - ✅ Reconciliation complete
```

After reconciliation:

```bash
$ diff desired-state.txt current-state.txt
```

```bash
$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3
```

#### 1.4: Automated Continuous Reconciliation

Initially `watch` was not installed, so I installed it with Homebrew and then started the loop:

```bash
$ watch -n 5 ./reconcile.sh
```

Output from continuous reconciliation loop after triggering drift:

```bash
Every 5.0s: ./reconcile.sh                                                            TomatoComputer.local: Sun May 10 12:57:52 2026

Sun May 10 12:57:52 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun May 10 12:57:52 MSK 2026 - ✅ Reconciliation complete
```

This shows that the loop detected drift and automatically restored the desired state.

### Observations and Analysis

The GitOps reconciliation loop continuously compares the current state with the desired state stored in Git. If drift appears, the loop detects it and replaces the current state with the desired one. This prevents configuration drift because any manual or unintended change is overwritten during the next reconciliation cycle.

Declarative configuration is better than imperative commands in production because it defines the final expected state instead of a sequence of manual actions. This makes changes easier to review, version, repeat, and recover.

### Task 2

#### 2.1: Create Health Check Script

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

Made it executable:

```bash
$ chmod +x healthcheck.sh
```

#### 2.2: Test Health Monitoring

Healthy state:

```bash
$ ./healthcheck.sh
$ cat health.log
Sun May 10 13:02:36 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:02:36 MSK 2026 - ✅ OK: States synchronized
```

Then I simulated configuration drift:

```bash
$ echo "unapproved-change: true" >> current-state.txt
```

Health check on drifted state:

```bash
$ ./healthcheck.sh
$ cat health.log
Sun May 10 13:02:46 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Sun May 10 13:02:36 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:02:46 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

Fix drift and verify:

```bash
$ ./reconcile.sh
$ ./healthcheck.sh
$ cat health.log
Sun May 10 13:02:52 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun May 10 13:02:52 MSK 2026 - ✅ Reconciliation complete
Sun May 10 13:02:52 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:02:36 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:02:46 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Sun May 10 13:02:52 MSK 2026 - ✅ OK: States synchronized
```

#### 2.3: Continuous Health Monitoring

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

Made it executable:

```bash
$ chmod +x monitor.sh
```

Output from `monitor.sh`:

```bash
$ ./monitor.sh
Starting GitOps monitoring...
\n--- Check #1 ---
Sun May 10 13:03:14 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:14 MSK 2026 - ✅ States synchronized
\n--- Check #2 ---
Sun May 10 13:03:17 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:17 MSK 2026 - ✅ States synchronized
\n--- Check #3 ---
Sun May 10 13:03:20 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:20 MSK 2026 - ✅ States synchronized
\n--- Check #4 ---
Sun May 10 13:03:23 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:23 MSK 2026 - ✅ States synchronized
\n--- Check #5 ---
Sun May 10 13:03:26 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:26 MSK 2026 - ✅ States synchronized
\n--- Check #6 ---
Sun May 10 13:03:29 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:29 MSK 2026 - ✅ States synchronized
\n--- Check #7 ---
Sun May 10 13:03:32 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:32 MSK 2026 - ✅ States synchronized
\n--- Check #8 ---
Sun May 10 13:03:35 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:35 MSK 2026 - ✅ States synchronized
\n--- Check #9 ---
Sun May 10 13:03:38 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:38 MSK 2026 - ✅ States synchronized
\n--- Check #10 ---
Sun May 10 13:03:41 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:41 MSK 2026 - ✅ States synchronized
```

Complete `health.log`:

```bash
$ cat health.log
Sun May 10 13:02:36 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:02:46 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Sun May 10 13:02:52 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:14 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:17 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:20 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:23 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:26 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:29 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:32 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:35 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:38 MSK 2026 - ✅ OK: States synchronized
Sun May 10 13:03:41 MSK 2026 - ✅ OK: States synchronized
```

### Observations and Analysis

Checksums (MD5) help detect configuration changes because they give a compact fingerprint of file contents. If the desired and current files are different, their MD5 values will also be different, so the script can quickly detect drift.

This is similar to GitOps tools like ArgoCD showing sync status. In both cases, the system compares the actual state with the desired state and reports whether they match. My script prints `OK` or `CRITICAL`, while ArgoCD would show synced or out-of-sync status in its UI.

