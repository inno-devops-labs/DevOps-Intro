# Lab 7 Solution

## Task 1

```bash
lexi:~/DevOps-Intro$ nano reconcile.sh
lexi:~/DevOps-Intro$ chmod +x reconcile.sh
lexi:~/DevOps-Intro$ echo "version: 2.0" > current-state.txt
lexi:~/DevOps-Intro$ echo "app: myapp" >> current-state.txt
lexi:~/DevOps-Intro$ echo "replicas: 5" >> current-state.txt
lexi:~/DevOps-Intro$ ./reconcile.sh
Tue Mar 17 05:55:44 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 17 05:55:44 MSK 2026 - ✅ Reconciliation complete
lexi:~/DevOps-Intro$ diff desired-state.txt current-state.txt
lexi:~/DevOps-Intro$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3
lexi:~/DevOps-Intro$ watch -n 5 ./reconcile.sh
```

In another teminal I ran `echo "replicas: 10" >> current-state.txt` and got the following output:

```bash
Every 5.0s: ./reconcile.sh

Tue Mar 17 05:58:54 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 17 05:58:54 MSK 2026 - ✅ Reconciliation complete
```

<!-- Explain the GitOps reconciliation loop. How does this prevent configuration drift? -->
 <!-- What advantages does declarative configuration have over imperative commands in production? -->
**Analysis & Reflection:**

- The reconciliation loop is a continuous process where an agent (like ArgoCD) constantly compares the desired state (stored in Git) with the actual state (running in your cluster). It prevents configuration drift because if someone makes an unauthorized manual change directly to the cluster, the loop detects the mismatch and automatically overrides the cluster back to exactly what is defined in Git.
- Declarative configuration describes what the final result should look like (e.g., "I want 3 replicas"), while imperative defines how to do it step-by-step. Declarative is better for production because it is version-controllable, predictable, easier to review in pull requests, and allows automated tools to reliably figure out the safest way to achieve that state.

## Task 2

```bash
lexi:~/DevOps-Intro$ nano healthcheck.sh
lexi:~/DevOps-Intro$ chmod +x healthcheck.sh
lexi:~/DevOps-Intro$ ./healthcheck.sh
Tue Mar 17 06:02:01 MSK 2026 - ✅ OK: States synchronized
lexi:~/DevOps-Intro$ echo "unapproved-change: true" >> current-state.txt
lexi:~/DevOps-Intro$ ./healthcheck.sh
Tue Mar 17 06:02:21 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
lexi:~/DevOps-Intro$ ./reconcile.sh
Tue Mar 17 06:02:26 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 17 06:02:26 MSK 2026 - ✅ Reconciliation complete
lexi:~/DevOps-Intro$ ./healthcheck.sh
Tue Mar 17 06:02:30 MSK 2026 - ✅ OK: States synchronized
lexi:~/DevOps-Intro$ cat health.log
Tue Mar 17 06:02:01 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 06:02:21 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Tue Mar 17 06:02:30 MSK 2026 - ✅ OK: States synchronized
```

Then I started monitoring:

```bash
lexi:~/DevOps-Intro$ nano monitor.sh
lexi:~/DevOps-Intro$ chmod +x monitor.sh
lexi:~/DevOps-Intro$ ./monitor.sh
Starting GitOps monitoring...
\n--- Check \#1 ---
Tue Mar 17 06:04:11 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 06:04:11 MSK 2026 - ✅ States synchronized
\n--- Check \#2 ---
Tue Mar 17 06:04:14 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 06:04:14 MSK 2026 - ✅ States synchronized
\n--- Check \#3 ---
Tue Mar 17 06:04:17 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 06:04:17 MSK 2026 - ✅ States synchronized
```

And checked logs from another terminal:

```bash
lexi:~/DevOps-Intro$ cat health.log
Tue Mar 17 06:02:01 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 06:02:21 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Tue Mar 17 06:02:30 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 06:04:11 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 06:04:14 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 06:04:17 MSK 2026 - ✅ OK: States synchronized
```

<!-- How do checksums (MD5) help detect configuration changes? -->
<!-- How does this relate to GitOps tools like ArgoCD's "Sync Status"? -->
**Analysis & Comparison:** ...

- A checksum acts as a unique digital "fingerprint" for a file's contents. If even a single character in the configuration file is modified, the resulting checksum changes completely. By simply comparing checksums, you can instantly verify if a file has been altered without having to read through the entire file line-by-line.
- GitOps tools use similar hashing concepts (like Git commit hashes) to quickly check if the desired state in your repository matches the live state in the cluster. If the hashes match, the app is "Synced". If the hashes differ, it means a change occurred, the app becomes "Out of Sync", and the tool knows it needs to take action to make them match again.
