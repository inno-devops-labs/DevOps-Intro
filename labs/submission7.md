# Lab 7 Submission

## Task 1 - Git State Reconciliation

### 1.1. Setup Desired State Configuration

#### Create Desired State (Source of Truth)

I create a file that represents the desired system configuration.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ echo "version: 1.0" > desired-state.txt
echo "app: myapp" >> desired-state.txt
echo "replicas: 3" >> desired-state.txt

seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ cat desired-state.txt
version: 1.0
app: myapp
replicas: 3
```

The file `desired-state.txt` now contains the expected configuration.
This file acts as the single source of truth for the system.


#### Simulate Current Cluster State

I copy the desired state to simulate the current system state.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ cp desired-state.txt current-state.txt
echo "Initial state synchronized"
Initial state synchronized
```

The current state is now identical to the desired state.
There is no difference between them at this point.


### 1.2. Create Reconciliation Loop

#### Create Reconciliation Script

I create a script that compares desired and current states and fixes differences.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ cat reconcile.sh
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

The script checks if states are different.
If they differ, it replaces the current state with the desired one.


#### Make Script Executable

I make the script executable so it can be run.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ chmod +x reconcile.sh
```

The script can now be executed using `./reconcile.sh`.
Permissions are correctly set.


### 1.3. Test Manual Drift Detection

#### Simulate Manual Drift

I manually change the current state to simulate configuration drift.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ echo "version: 2.0" > current-state.txt
echo "app: myapp" >> current-state.txt
echo "replicas: 5" >> current-state.txt

seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ cat current-state.txt
version: 2.0
app: myapp
replicas: 5
```

The current state is now different from the desired state.
This simulates an unauthorized or accidental change.


#### Run Reconciliation Manually

I run the reconciliation script to detect and fix the drift.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ ./reconcile.sh
Tue Mar 17 12:02:25 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 17 12:02:25 MSK 2026 - ✅ Reconciliation complete

seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ diff desired-state.txt current-state.txt
```

The script detected the drift and fixed it.
The `diff` command shows no differences after reconciliation.


#### Verify Drift Was Fixed

I check the current state after reconciliation.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3
```

The current state matches the desired state again.
The system is now consistent.


### 1.4. Automated Continuous Reconciliation

#### Start Continuous Reconciliation Loop

I start a loop that runs the reconciliation script every 5 seconds.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ watch -n 5 ./reconcile.sh
Tue Mar 17 12:03:10 MSK 2026 - ✅ States synchronized
Tue Mar 17 12:03:15 MSK 2026 - ✅ States synchronized
Tue Mar 17 12:03:20 MSK 2026 - ✅ States synchronized
Tue Mar 17 12:03:25 MSK 2026 - ✅ States synchronized
```

The system continuously checks for differences.
At this moment, no drift is detected.


#### In Another Terminal, Trigger Drift

I introduce a change in the current state while the loop is running.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ echo "replicas: 10" >> current-state.txt
```

This creates a mismatch between desired and current states.
The system is now in a drifted state.


#### Observe Auto-Healing

I observe how the system automatically fixes the drift.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ watch -n 5 ./reconcile.sh
Tue Mar 17 12:04:17 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 17 12:03:22 MSK 2026 - ✅ Reconciliation complete
Tue Mar 17 12:03:27 MSK 2026 - ✅ States synchronized
Tue Mar 17 12:03:32 MSK 2026 - ✅ States synchronized
```

The system detects the drift automatically.
It restores the correct state without manual action (self-healing).


### Analysis: Explain the GitOps reconciliation loop. How does this prevent configuration drift?

The reconciliation loop continuously compares the desired state with the current state.
If any difference is detected, the system automatically restores the correct configuration.
This process runs periodically, so drift cannot persist for a long time.
As a result, the system always converges to the desired state.
This prevents manual changes from breaking consistency.


### Reflection: What advantages does declarative configuration have over imperative commands in production?

Declarative configuration defines the final desired state, not the steps to reach it.
This makes the system easier to understand and reproduce.
It also allows automatic correction of errors through reconciliation.
In production, this reduces human mistakes and improves stability.
Additionally, all changes are stored in `Git`, which provides version control and traceability.


## Task 2 - GitOps Health Monitoring

### 2.1. Create Health Check Script

#### Create Health Check Script

I create a script that compares checksums of desired and current states.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ cat healthcheck.sh
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

seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ chmod +x healthcheck.sh
```

The script calculates MD5 hashes for both files.
If hashes are different, it reports a critical error and logs it.


### 2.2. Test Health Monitoring

#### Test Healthy State

I run the health check when both states are synchronized.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ ./healthcheck.sh
cat health.log
Tue Mar 17 12:09:56 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:09:56 MSK 2026 - ✅ OK: States synchronized
```

The system reports `OK` because states are identical.
The result is also saved to the log file.


#### Simulate Configuration Drift

I introduce a change to simulate configuration drift.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ echo "unapproved-change: true" >> current-state.txt
```

The current state is now different from the desired state.
This simulates an unauthorized modification.


#### Run Health Check on Drifted State

I run the health check again after introducing drift.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ ./healthcheck.sh
cat health.log
Tue Mar 17 12:10:53 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Tue Mar 17 12:09:56 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:10:53 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

The system detects a mismatch using MD5 hashes.
The log clearly shows different checksum values.


#### Fix Drift and Verify

I fix the drift using reconciliation and check the health again.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ ./reconcile.sh
./healthcheck.sh
cat health.log
Tue Mar 17 12:11:28 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 17 12:11:28 MSK 2026 - ✅ Reconciliation complete
Tue Mar 17 12:11:28 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:09:56 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:10:53 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Tue Mar 17 12:11:09 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Tue Mar 17 12:11:28 MSK 2026 - ✅ OK: States synchronized
```

After reconciliation, the system returns to a healthy state.
The log shows both failed and successful checks.


### 2.3. Continuous Health Monitoring

#### Create Combined Monitoring Script

I create a script that combines health checks and reconciliation in a loop.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ cat monitor.sh
#!/bin/bash
# monitor.sh - Combined reconciliation and health monitoring

echo "Starting GitOps monitoring..."
for i in {1..10}; do
    echo "\n--- Check #$i ---"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 3
done
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ chmod +x monitor.sh
```

The script runs multiple checks in sequence.
It monitors and fixes the system continuously.


#### Run Monitoring Loop

I run the monitoring script to observe continuous behavior.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ ./monitor.sh
Starting GitOps monitoring...
\n--- Check #1 ---
Tue Mar 17 12:13:33 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:13:33 MSK 2026 - ✅ States synchronized
\n--- Check #2 ---
Tue Mar 17 12:13:36 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:13:36 MSK 2026 - ✅ States synchronized
\n--- Check #3 ---
Tue Mar 17 12:13:40 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:13:40 MSK 2026 - ✅ States synchronized
\n--- Check #4 ---
Tue Mar 17 12:13:43 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:13:43 MSK 2026 - ✅ States synchronized
\n--- Check #5 ---
Tue Mar 17 12:13:46 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:13:46 MSK 2026 - ✅ States synchronized
\n--- Check #6 ---
Tue Mar 17 12:13:49 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:13:49 MSK 2026 - ✅ States synchronized
^C
```

The system continuously reports a healthy state.
No drift is detected during the monitoring loop.


#### Review Complete Health Log

I review the full log file with all recorded checks.

```bash
seva@Seva:/mnt/c/.../DevOps-Intro/gitops-lab$ cat health.log
Tue Mar 17 12:09:56 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:10:53 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Tue Mar 17 12:11:09 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Tue Mar 17 12:11:28 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:11:51 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:13:33 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:13:36 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:13:40 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:13:43 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:13:46 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 12:13:49 MSK 2026 - ✅ OK: States synchronized
```

The log shows the full history of system states.
It includes both errors and successful recoveries.


### Analysis: How do checksums (MD5) help detect configuration changes?

Checksums provide a simple way to compare file contents.
Even a small change in the file produces a completely different `MD5 hash`.
This makes it easy to detect any modification in configuration.
The system does not need to compare files line by line.
As a result, detection is fast and reliable.


### Comparison: How does this relate to GitOps tools like ArgoCD's "Sync Status"?

In `GitOps` tools like `ArgoCD`, the system continuously compares desired and actual states.
This is similar to comparing checksums in this lab.
If a difference is detected, the system marks it as `OutOfSync`.
Then it can automatically fix the state or notify the user.
So this script is a simplified version of real GitOps monitoring.