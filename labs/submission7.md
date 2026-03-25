# Lab 7 — GitOps Fundamentals

## Task 1 — Git State Reconciliation

### Setup Desired State Configuration

Initial desired-state.txt and current-state.txt contents:

```
version: 1.0
app: myapp
replicas: 3
```

```
version: 1.0
app: myapp
replicas: 3
```

### Drift Detection and Reconciliation

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ ./reconcile.sh
Wed 25 Mar 2026 11:40:08 AM MSK - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed 25 Mar 2026 11:40:08 AM MSK - ✅ Reconciliation complete
```

Synchronized state after reconciliation:

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ diff desired-state.txt current-state.txt
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3
```

### Automated Continuous Reconciliation

```bash
Every 5.0s: ./reconcile.sh           ASUS-TUF: Wed Mar 25 11:43:02 2026

Wed 25 Mar 2026 11:43:02 AM MSK - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed 25 Mar 2026 11:43:02 AM MSK - ✅ Reconciliation complete
```

### Analysis: Explain the GitOps reconciliation loop. How does this prevent configuration drift?

The GitOps reconciliation loop continuously compares the live system state against the desired state defined in Git; if drift is detected, an automated agent immediately applies the Git-specified configuration to revert any manual changes or inconsistencies.

### Reflection: What advantages does declarative configuration have over imperative commands in production?

Declarative configuration provides a single source of truth, enabling version control, automated rollbacks, and consistency across environments, whereas imperative commands are error-prone, unrepeatable, and obscure the desired end state.

## Task 2 — GitOps Health Monitoring

### Health Check Script

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

### Test Health Monitoring

Output showing "OK" status when states match:

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro/gitops-lab$ ./healthcheck.sh
Wed 25 Mar 2026 11:55:20 AM MSK - ✅ OK: States synchronized
```

Output showing "CRITICAL" status when drift is detected:

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro/gitops-lab$ ./healthcheck.sh
Wed 25 Mar 2026 11:55:40 AM MSK - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

Complete health.log file showing multiple checks:

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro/gitops-lab$ cat health.log
Wed 25 Mar 2026 11:55:20 AM MSK - ✅ OK: States synchronized
Wed 25 Mar 2026 11:55:40 AM MSK - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Wed 25 Mar 2026 11:59:36 AM MSK - ✅ OK: States synchronized
```

### Continuous Health Monitoring

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro/gitops-lab$ cat health.log
Wed 25 Mar 2026 11:55:20 AM MSK - ✅ OK: States synchronized
Wed 25 Mar 2026 11:55:40 AM MSK - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Wed 25 Mar 2026 11:59:36 AM MSK - ✅ OK: States synchronized
Wed 25 Mar 2026 12:02:06 PM MSK - ✅ OK: States synchronized
Wed 25 Mar 2026 12:02:09 PM MSK - ✅ OK: States synchronized
Wed 25 Mar 2026 12:02:12 PM MSK - ✅ OK: States synchronized
Wed 25 Mar 2026 12:02:15 PM MSK - ✅ OK: States synchronized
```

### Analysis: How do checksums (MD5) help detect configuration changes?

Checksums (MD5) generate a unique fingerprint of a configuration file's content; any unauthorized or accidental change alters the fingerprint, allowing the system to immediately detect and flag the drift.

### Comparison: How does this relate to GitOps tools like ArgoCD's "Sync Status"?

ArgoCD's "Sync Status" uses similar hashing logic—it compares the live resource's hash against the desired state's hash from Git—to determine if the cluster is "Synced" (matching) or "OutOfSync" (drifted), automating the detection process that a manual MD5 check would serve.