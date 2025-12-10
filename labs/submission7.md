## Task 1

Initial versions
```sh
[RatPC|rightrat F25-DevOps-Intro] cat ./desired-state.txt
version: 1.0
app: myapp
replicas: 3
[RatPC|rightrat F25-DevOps-Intro] cat ./current-state.txt
version: 1.0
app: myapp
replicas: 3
```

Reconciliation script
```sh
[RatPC|rightrat F25-DevOps-Intro] cat ./reconcile.sh
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

Manual drift
```sh
[RatPC|rightrat F25-DevOps-Intro] echo "version: 2.0" > current-state.txt
[RatPC|rightrat F25-DevOps-Intro] echo "app: myapp" >> current-state.txt
[RatPC|rightrat F25-DevOps-Intro] echo "replicas: 5" >> current-state.txt
[RatPC|rightrat F25-DevOps-Intro] cat ./current-state.txt
version: 2.0
app: myapp
replicas: 5
```

Reconciliation complete
```sh
[RatPC|rightrat F25-DevOps-Intro] ./reconcile.sh
Ср 10 дек 2025 16:03:48 MSK - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Ср 10 дек 2025 16:03:48 MSK - ✅ Reconciliation complete
[RatPC|rightrat F25-DevOps-Intro] diff ./desired-state.txt ./current-state.txt
```

Before drift
```sh
Every 5,0s: ./reconcile.sh                                                                                                                                                       RatPC: 16:06:13
                                                                                                                                                                                   in 0,005s (0)
Ср 10 дек 2025 16:06:13 MSK - ✅ States synchronized
```

After detecting drift
```sh
Every 5,0s: ./reconcile.sh                                                                                                                                                       RatPC: 16:07:23
                                                                                                                                                                                   in 0,006s (0)
Ср 10 дек 2025 16:07:23 MSK - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Ср 10 дек 2025 16:07:23 MSK - ✅ Reconciliation complete
```
No diff since the versions are identical.


The reconciliation script detects drift by comparing the files of interest. Notably any changes aside from the *current-state.txt* will be ignored. Desired state can also be altered and will become the new "source of truth", so this primitive approach will not guarantee drift prevention.

## Task 2

Healthcheck script
```sh
[RatPC|rightrat F25-DevOps-Intro] micro healthcheck.sh
[RatPC|rightrat F25-DevOps-Intro] cat ./healthcheck.sh
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

Initial check
```sh
[RatPC|rightrat F25-DevOps-Intro] ./healthcheck.sh
Ср 10 дек 2025 16:22:50 MSK - ✅ OK: States synchronized
[RatPC|rightrat F25-DevOps-Intro] cat ./health.log
Ср 10 дек 2025 16:22:50 MSK - ✅ OK: States synchronized
```

Drift creation and detection
```sh
[RatPC|rightrat F25-DevOps-Intro] echo "unapproved-change: true" >> current-state.txt
[RatPC|rightrat F25-DevOps-Intro] ./healthcheck.sh
Ср 10 дек 2025 16:23:32 MSK - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
[RatPC|rightrat F25-DevOps-Intro] cat ./health.log
Ср 10 дек 2025 16:22:50 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:23:32 MSK - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

Output after reconciling
```sh
[RatPC|rightrat F25-DevOps-Intro] ./reconcile.sh
Ср 10 дек 2025 16:24:09 MSK - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Ср 10 дек 2025 16:24:09 MSK - ✅ Reconciliation complete
[RatPC|rightrat F25-DevOps-Intro] ./healthcheck.sh
Ср 10 дек 2025 16:24:14 MSK - ✅ OK: States synchronized
[RatPC|rightrat F25-DevOps-Intro] cat ./health.log
Ср 10 дек 2025 16:22:50 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:23:32 MSK - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Ср 10 дек 2025 16:24:14 MSK - ✅ OK: States synchronized
```

Monitoring output before and after manual drift
```sh
[RatPC|rightrat F25-DevOps-Intro] ./monitor.sh
Starting GitOps monitoring...
\n--- Check #1 ---
Ср 10 дек 2025 16:25:50 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:25:50 MSK - ✅ States synchronized
\n--- Check #2 ---
Ср 10 дек 2025 16:25:53 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:25:53 MSK - ✅ States synchronized
\n--- Check #3 ---
Ср 10 дек 2025 16:25:56 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:25:56 MSK - ✅ States synchronized
\n--- Check #4 ---
Ср 10 дек 2025 16:25:59 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:25:59 MSK - ✅ States synchronized
\n--- Check #5 ---
Ср 10 дек 2025 16:26:02 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:26:02 MSK - ✅ States synchronized
\n--- Check #6 ---
Ср 10 дек 2025 16:26:05 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:26:05 MSK - ✅ States synchronized
\n--- Check #7 ---
Ср 10 дек 2025 16:26:08 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:26:08 MSK - ✅ States synchronized
\n--- Check #8 ---
Ср 10 дек 2025 16:26:11 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:26:11 MSK - ✅ States synchronized
\n--- Check #9 ---
Ср 10 дек 2025 16:26:14 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:26:14 MSK - ✅ States synchronized
\n--- Check #10 ---
Ср 10 дек 2025 16:26:17 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:26:17 MSK - ✅ States synchronized
[RatPC|rightrat F25-DevOps-Intro] ./monitor.sh
Starting GitOps monitoring...
\n--- Check #1 ---
Ср 10 дек 2025 16:27:04 MSK - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 149ac19e2313b6d5dd08b17aa23afa90
Ср 10 дек 2025 16:27:04 MSK - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Ср 10 дек 2025 16:27:04 MSK - ✅ Reconciliation complete
\n--- Check #2 ---
Ср 10 дек 2025 16:27:07 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:27:07 MSK - ✅ States synchronized
\n--- Check #3 ---
Ср 10 дек 2025 16:27:10 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:27:10 MSK - ✅ States synchronized
\n--- Check #4 ---
Ср 10 дек 2025 16:27:13 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:27:13 MSK - ✅ States synchronized
\n--- Check #5 ---
Ср 10 дек 2025 16:27:16 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:27:16 MSK - ✅ States synchronized
\n--- Check #6 ---
Ср 10 дек 2025 16:27:19 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:27:19 MSK - ✅ States synchronized
\n--- Check #7 ---
Ср 10 дек 2025 16:27:22 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:27:22 MSK - ✅ States synchronized
\n--- Check #8 ---
Ср 10 дек 2025 16:27:25 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:27:25 MSK - ✅ States synchronized
\n--- Check #9 ---
Ср 10 дек 2025 16:27:28 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:27:28 MSK - ✅ States synchronized
\n--- Check #10 ---
Ср 10 дек 2025 16:27:31 MSK - ✅ OK: States synchronized
Ср 10 дек 2025 16:27:31 MSK - ✅ States synchronized
```
Checksums are more reliable in terms of detecting discrepancies. Hashes guarantee identity of files as opposed to string comparisons used by (maybe custom) executables

As stated above, this way of health monitoting and drift resolution is quite crude and unreliable
