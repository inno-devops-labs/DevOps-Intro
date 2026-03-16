# Task 1

### Initial state
```bash
cat desired-state.txt 

version: 1.0
app: myapp
replicas: 3
```

### Manual drift and reconciliation
```bash
nvim reconcile.sh


chmod +x reconcile.sh


echo "version: 2.0" > current-state.txt
  echo "app: myapp" >> current-state.txt
  echo "replicas: 5" >> current-state.txt


./reconcile.sh

Mon Mar 16 10:04:38 PM MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Mon Mar 16 10:04:38 PM MSK 2026 - ✅ Reconciliation complete
```

### Verification
```bash
diff desired-state.txt current-state.txt
```
Here no output since there is no diff.


### Autohealing

```bash
Mon Mar 16 10:15:34 PM MSK 2026 - ✅ States synchronized
Mon Mar 16 10:15:39 PM MSK 2026 - ✅ States synchronized
Mon Mar 16 10:15:44 PM MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Mon Mar 16 10:15:49 PM MSK 2026 - ✅ Reconciliation complete
Mon Mar 16 10:15:54 PM MSK 2026 - ✅ States synchronized
```

### Analysis of gitops reconciliation loop

A reconciliation loop continuously compares the desired system state stored in Git with the actual system state in the environment. 
If a difference (configuration drift) is detected, the system automatically applies the desired configuration to restore the correct state.

In this simulation:

- desired-state.txt - acts as the source of truth.

- current-state.txt - represents the running cluster state.

- reconcile.sh - continuously checks for differences.

When drift occurs, the script automatically restores the desired configuration.

This process prevents configuration drift because the system continuously enforces the desired configuration, 
ensuring that manual or accidental changes are automatically corrected.


### Reflection - Declarative vs imperative configuration

Declarative configuration describes what the final system state should be, rather than listing the exact commands needed to achieve it.

Advantages in production environments include:

- Consistency: Systems are always reconciled back to the declared state.
 
- Automation: Continuous reconciliation reduces manual intervention.
 
- Version control: Git stores configuration history and enables rollbacks.
 
- Auditability: Every change is tracked through commits and pull requests.

- Self-healing: If systems drift from the desired state, automation restores them.

In contrast, imperative commands (e.g., manual configuration changes) can lead to configuration drift, 
undocumented changes, and inconsistent environments.


# Task 2
The following is just step by step comands execution

```bash
 ./healthcheck.sh
  cat health.log
Mon Mar 16 10:21:58 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:21:58 PM MSK 2026 - ✅ OK: States synchronized
```

```bash

./healthcheck.sh
Mon Mar 16 10:22:22 PM MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5

```

```bash
cat health.log
Mon Mar 16 10:21:58 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:22:22 PM MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5

```

```bash
./reconcile.sh
Mon Mar 16 10:22:41 PM MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Mon Mar 16 10:22:41 PM MSK 2026 - ✅ Reconciliation complete

```

```bash
./healthcheck.sh
Mon Mar 16 10:22:46 PM MSK 2026 - ✅ OK: States synchronized
```

```bash
cat health.log
Mon Mar 16 10:21:58 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:22:22 PM MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Mon Mar 16 10:22:46 PM MSK 2026 - ✅ OK: States synchronized
```
```bash
./monitor.sh
Starting GitOps monitoring...
\n--- Check #1 ---
Mon Mar 16 10:27:17 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:27:17 PM MSK 2026 - ✅ States synchronized
\n--- Check #2 ---
Mon Mar 16 10:27:20 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:27:20 PM MSK 2026 - ✅ States synchronized
\n--- Check #3 ---
Mon Mar 16 10:27:23 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:27:23 PM MSK 2026 - ✅ States synchronized

```
```bash
cat health.log
Mon Mar 16 10:21:58 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:22:22 PM MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Mon Mar 16 10:22:46 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:27:17 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:27:20 PM MSK 2026 - ✅ OK: States synchronized
Mon Mar 16 10:27:23 PM MSK 2026 - ✅ OK: States synchronized

```

### Analysis - why use checksums?

Checksums such as MD5 generate a unique hash value for file contents. 
If even a single character in the file changes, the checksum value changes as well.

Benefits:

- Quickly detect configuration changes
 
- Efficient comparison of system states
 
- Useful for monitoring and automation
 
- Helps identify unauthorized or accidental modifications

Thus, comparing checksums allows the system to reliably detect configuration drift.


### Relationship to ArgoCD's "Sync Status"
This simulation reflects how Argo CD manages synchronization between a Git repository and a running system. 
In GitOps, the Git repository defines the desired configuration, while the deployed environment represents the current state. 
ArgoCD continuously compares these two states and reports a Sync Status that shows whether they match. 
If the cluster configuration differs from what is stored in Git, ArgoCD marks the application as “OutOfSync” and can automatically reconcile the 
environment to restore the desired configuration. In this lab, the desired-state.txt file acts as the source of truth and current-state.txt 
represents the running state, while the reconciliation and health check scripts mimic the process of detecting drift and restoring synchronization, 
similar to how ArgoCD maintains consistency between Git and the deployed infrastructure.
