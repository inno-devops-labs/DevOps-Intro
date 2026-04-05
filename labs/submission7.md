# Lab 7 — GitOps Fundamentals

## Task 1 — Git State Reconciliation (6 pts)

### Initial desired-state.txt and current-state.txt

**desired-state.txt:**

echo "version: 1.0" > desired-state.txt
echo "app: myapp" >> desired-state.txt
echo "replicas: 3" >> desired-state.txt
cp desired-state.txt current-state.txt
echo "Initial state synchronized"
Initial state synchronized


version: 1.0
app: myapp
replicas: 3


**current-state.txt:**



### reconcile.sh script

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

Drift detection and reconciliation output

Manual drift simulation (version: 2.0, replicas: 5):

$ echo "version: 2.0" > current-state.txt
$ echo "app: myapp" >> current-state.txt
$ echo "replicas: 5" >> current-state.txt
$ ./reconcile.sh


Sun Apr  5 12:54:35 RTZ 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun Apr  5 12:54:35 RTZ 2026 - ✅ Reconciliation complete

Verification that drift was fixed:

$ cat current-state.txt

version: 1.0
app: myapp
replicas: 3

##Output from continuous reconciliation loop (auto-healing)


$ while true; do ./reconcile.sh; sleep 5; done

Sun Apr  5 12:56:21 RTZ 2026 - ✅ States synchronized
Sun Apr  5 12:56:26 RTZ 2026 - ✅ States synchronized
Sun Apr  5 12:56:32 RTZ 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun Apr  5 12:56:32 RTZ 2026 - ✅ Reconciliation complete
Sun Apr  5 12:56:37 RTZ 2026 - ✅ States synchronized
Sun Apr  5 12:56:42 RTZ 2026 - ✅ States synchronized
Sun Apr  5 12:56:47 RTZ 2026 - ✅ States synchronized
Sun Apr  5 12:56:52 RTZ 2026 - ✅ States synchronized


### Explain the GitOps reconciliation loop. How does this prevent configuration drift?

The GitOps reconciliation loop is a continuous process that compares the desired state (stored in Git as the source of truth) with the current state of the system. In my simulation, the reconcile.sh script compares desired-state.txt and current-state.txt every 5 seconds. When a difference is detected, it automatically copies the desired state to the current state, fixing the drift. This prevents unauthorized changes from accumulating because any drift (e.g., manually modifying current-state.txt) is detected and corrected within the next synchronization cycle. This approach ensures the system always matches the configuration stored in Git, which is a core principle of GitOps.

### What advantages does declarative configuration have over imperative commands in production?

Declarative configuration describes what should be (the desired state), while imperative commands describe how to achieve it (step-by-step instructions). In production, the declarative approach has key advantages: (1) configuration is versioned in Git, providing full change history; (2) the system automatically corrects drift without manual intervention; (3) auditing and rollback to previous states are simplified; (4) human error is reduced since no manual command execution is needed. Imperative commands are useful for one-time operations and debugging, but in large systems they lead to desynchronization and "snowflake" configurations that are hard to reproduce.


###Task 2 — GitOps Health Monitoring


healthcheck.sh script


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


$ ./healthcheck.sh

Sun Apr  5 12:59:04 RTZ 2026 - ✅ OK: States synchronized

$ echo "unapproved-change: true" >> current-state.txt
$ ./healthcheck.sh

Sun Apr  5 13:00:24 RTZ 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5


Complete health.log file showing multiple checks


$ cat health.log


Sun Apr  5 12:59:04 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 12:59:13 RTZ 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Sun Apr  5 12:59:18 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 12:59:35 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 12:59:38 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 12:59:42 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 12:59:45 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 12:59:48 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 12:59:52 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 13:00:24 RTZ 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Sun Apr  5 13:00:40 RTZ 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Sun Apr  5 13:00:44 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 13:00:47 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 13:00:50 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 13:00:54 RTZ 2026 - ✅ OK: States synchronized


Output from monitor.sh showing continuous monitoring

$ ./monitor.sh

Starting GitOps monitoring...

--- Check #1 ---
Sun Apr  5 13:00:40 RTZ 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Sun Apr  5 13:00:40 RTZ 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun Apr  5 13:00:40 RTZ 2026 - ✅ Reconciliation complete

--- Check #2 ---
Sun Apr  5 13:00:44 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 13:00:44 RTZ 2026 - ✅ States synchronized

--- Check #3 ---
Sun Apr  5 13:00:47 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 13:00:47 RTZ 2026 - ✅ States synchronized

--- Check #4 ---
Sun Apr  5 13:00:50 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 13:00:51 RTZ 2026 - ✅ States synchronized

--- Check #5 ---
Sun Apr  5 13:00:54 RTZ 2026 - ✅ OK: States synchronized
Sun Apr  5 13:00:54 RTZ 2026 - ✅ States synchronized


### How do checksums (MD5) help detect configuration changes?

MD5 is a cryptographic hash function that generates a unique fixed-length string for any input file. Even a tiny change to a file (e.g., adding a single space or newline) results in a completely different MD5 hash. In my healthcheck.sh script, I compute MD5 for both desired-state.txt and current-state.txt. If the hashes differ, it definitively means the file contents are different. This approach enables fast and efficient drift detection without needing line-by-line file comparison, which is especially important for large configuration files.

###  How does this relate to GitOps tools like ArgoCD's "Sync Status"?

ArgoCD uses an identical concept to monitor Kubernetes cluster state. It continuously compares manifests stored in a Git repository with resources running in the cluster. When a discrepancy is found, ArgoCD displays an "OutOfSync" status (similar to my "❌ CRITICAL"). With auto-sync enabled, ArgoCD corrects the drift (like my reconcile.sh), bringing the cluster back into alignment with Git. The health.log in my simulation is analogous to ArgoCD's sync history, which shows when and why drift occurred and whether it was corrected. The main difference is scale — ArgoCD handles thousands of resources in a cluster, but the fundamental principle remains the same: declarative state plus continuous reconciliation.
