# **Lab 7 — GitOps Fundamentals**

## **Task 1 — Git State Reconciliation**

* Initial `desired-state.txt` content:

```
version: 1.0
app: myapp
replicas: 3
```

* Initial `current-state.txt` content:

```
version: 1.0
app: myapp
replicas: 3
```

* Output of drift detection and reconciliation:

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp/lab7 (feature/lab7)
$ ./reconcile.sh
Fri Mar 20 23:14:08 RTZST 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 23:14:08 RTZST 2026 - ✅ Reconciliation complete
```

* State after reconciliation:

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp/lab7 (feature/lab7)
$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3
```

* Output from continuous reconciliation loop:

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp/lab7 (feature/lab7)
$ while true; do echo "--- $(date) ---"; ./reconcile.sh; sleep 5; done
--- Fri Mar 20 23:18:38 RTZST 2026 ---
Fri Mar 20 23:18:38 RTZST 2026 - ✅ States synchronized
--- Fri Mar 20 23:18:44 RTZST 2026 ---
Fri Mar 20 23:18:44 RTZST 2026 - ✅ States synchronized
--- Fri Mar 20 23:18:49 RTZST 2026 ---
Fri Mar 20 23:18:49 RTZST 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 23:18:49 RTZST 2026 - ✅ Reconciliation complete
--- Fri Mar 20 23:18:54 RTZST 2026 ---
Fri Mar 20 23:18:54 RTZST 2026 - ✅ States synchronized
```

* Analysis of the GitOps reconciliation loop:

The `reconciliation loop` is a process that compares the desired state of a file with the current state. If a difference detected, the desired state is automatically applied. Any unwanted changes that do not comply with `Git` are tracked and then restored.

* Advantages of declarative configuration over imperative commands in production:

A declarative configuration guarantees versioning, automize the drift preventing, and guarantees the environments consistency that is critical for the production.

## **Task 2 — GitOps Health Monitoring**

* Contents of `healthcheck.sh` script:

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

* The `OK` status output:

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp/lab7 (feature/lab7)
$ ./healthcheck.sh
Fri Mar 20 23:37:23 RTZST 2026 - ✅ OK: States synchronized
```

* The `CRITICAL` status output:

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp/lab7 (feature/lab7)
$ cat health.log
Fri Mar 20 23:33:14 RTZST 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5:
  Current MD5: bcd10397f65a22721ef45971e55dba28
Fri Mar 20 23:37:23 RTZST 2026 - ✅ OK: States synchronized
```

* Complete `health.log` file:

```bash
Fri Mar 20 23:32:52 RTZST 2026 - ✅ OK: States synchronized
Fri Mar 20 23:33:14 RTZST 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: 
  Current MD5: bcd10397f65a22721ef45971e55dba28
Fri Mar 20 23:37:23 RTZST 2026 - ✅ OK: States synchronized
Fri Mar 20 23:38:32 RTZST 2026 - ✅ OK: States synchronized
Fri Mar 20 23:38:35 RTZST 2026 - ✅ OK: States synchronized
Fri Mar 20 23:38:38 RTZST 2026 - ✅ OK: States synchronized
```

* Output from `monitor.sh`:

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp/lab7 (feature/lab7)
$ ./monitor.sh
Starting GitOps monitoring...
\n--- Check #1 ---
Fri Mar 20 23:38:32 RTZST 2026 - ✅ OK: States synchronized
Fri Mar 20 23:38:32 RTZST 2026 - ✅ States synchronized
\n--- Check #2 ---
Fri Mar 20 23:38:35 RTZST 2026 - ✅ OK: States synchronized
Fri Mar 20 23:38:35 RTZST 2026 - ✅ States synchronized
\n--- Check #3 ---
Fri Mar 20 23:38:38 RTZST 2026 - ✅ OK: States synchronized
Fri Mar 20 23:38:38 RTZST 2026 - ✅ States synchronized
\n--- Check #4 ---
Fri Mar 20 23:38:42 RTZST 2026 - ✅ OK: States synchronized
Fri Mar 20 23:38:42 RTZST 2026 - ✅ States synchronized
...
```

* Analysis of checksums:

Hash functions are constructed to provide a unique hash value for a file. If some change is added, the checksum is completely different from the original file checksum. Therefore, it is a fast way of detecting the differences of file contents. 

* Comparison with GitOps tools:

The implementation is a simplified model of how ArgoCD tracks and displays synchronization state in GitOps processes.
