# Lab 7 — GitOps Fundamentals

## Task 1 — Git State Reconciliation

### Initial desired-state.txt and current-state.txt contents
```sh
cat current-state.txt

version: 2.0
app: myapp
replicas: 5
```

```sh
cat desired-state.txt

version: 1.0
app: myapp
replicas: 3
```

### Screenshot or output of drift detection and reconciliation
```sh
pixel@pixelbook:~/DevOps-Intro/labs$ ./reconcile.sh
diff desired-state.txt current-state.txt
Wed Mar 18 11:29:58 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed Mar 18 11:29:58 MSK 2026 - ✅ Reconciliation complete
```

### Output showing synchronized state after reconciliation
```sh
Every 5.0s: ./reconcile.sh                                                                                              pixelbook: Wed Mar 18 11:36:35 2026

Wed Mar 18 11:36:35 MSK 2026 - ✅ States synchronized
```

### Output from continuous reconciliation loop detecting auto-healing
```sh
Every 5.0s: ./reconcile.sh                                                                                              pixelbook: Wed Mar 18 11:37:14 2026

Wed Mar 18 11:37:14 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed Mar 18 11:37:14 MSK 2026 - ✅ Reconciliation complete
```

### Analysis: Explain the GitOps reconciliation loop. How does this prevent configuration drift?
The GitOps reconciliation loop is a continuous process that keeps your system in sync with what’s defined in Git.

Here’s how it works:
1. It reads the desired configuration from a Git repository.
2. It checks the actual state of the system.
3. It compares the two.
4. If there are differences, it updates the system to match what’s in Git.

This loop runs continuously.

It prevents configuration drift by constantly detecting and correcting differences between the real system and the desired state. If someone makes a manual change directly in the system, the next reconciliation cycle will notice the mismatch and revert it back to what’s defined in Git.

### Reflection: What advantages does declarative configuration have over imperative commands in production?
Declarative configuration describes the desired end state, while imperative commands describe step-by-step actions.

In production, declarative has key advantages:
- More consistent and repeatable (same config → same result)
- Prevents drift by continuously enforcing the desired state
- Easy to track changes with version control (Git)
- Simple rollbacks (just revert the config)
- Less human error and easier to automate at scale

In short: declarative is safer, more reliable, and easier to manage than imperative.


## Task 2 — GitOps Health Monitoring

### Contents of healthcheck.sh script
```sh
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

### Output showing "OK" status when states match
```sh
pixel@pixelbook:~/DevOps-Intro/labs$ ./healthcheck.sh
Wed Mar 18 11:41:27 MSK 2026 - ✅ OK: States synchronized
```

### Output showing "CRITICAL" status when drift is detected
```sh
pixel@pixelbook:~/DevOps-Intro/labs$ ./healthcheck.sh
Wed Mar 18 11:41:38 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

### Complete health.log file showing multiple checks
```sh
pixel@pixelbook:~/DevOps-Intro/labs$ cat health.log 
Wed Mar 18 11:41:27 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 11:41:38 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Wed Mar 18 11:41:47 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 11:42:11 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 11:42:14 MSK 2026 - ✅ OK: States synchronized
```

### Output from monitor.sh showing continuous monitoring
```sh
pixel@pixelbook:~/DevOps-Intro/labs$ ./monitor.sh
Starting GitOps monitoring...
\n--- Check #1 ---
Wed Mar 18 11:42:11 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 11:42:11 MSK 2026 - ✅ States synchronized
\n--- Check #2 ---
Wed Mar 18 11:42:14 MSK 2026 - ✅ OK: States synchronized
Wed Mar 18 11:42:14 MSK 2026 - ✅ States synchronized
^C
```

### Analysis: How do checksums (MD5) help detect configuration changes?
Checksums like MD5 turn a file’s contents into a unique hash value.

When you generate a hash for a configuration file, it acts like a fingerprint. If the file changes in any way—even a single character—the hash will also change.

To detect changes, you compare the current hash with a previously stored one. If they are different, it means the configuration has been modified.

### Comparison: How does this relate to GitOps tools like ArgoCD's "Sync Status"?
MD5 checksums and ArgoCD’s Sync Status are based on the same core idea: compare desired state with actual state to detect differences.

**Relationship**

- MD5 checksums. Compare a file’s current hash with a known hash
→ If different, the file has changed
- ArgoCD Sync Status. Compares what’s in Git (desired state) with what’s running in the cluster (actual state)
→ If different, the app is marked OutOfSync

**Key connection**

Both are essentially diff mechanisms:
- MD5 → detects changes at the file content level
- ArgoCD → detects changes at the resource/state level (YAML → live objects)

**Key difference**

- MD5 gives a simple “changed or not” signal
- ArgoCD shows what changed and can automatically fix it (reconcile)