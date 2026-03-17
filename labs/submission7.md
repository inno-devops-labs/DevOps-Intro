# Task 1

## 1.1 Setup Desired State

I created the desired state file (source of truth) with this content:

```
version: 1.0
app: myapp
replicas: 3
```

I copied it to `current-state.txt` so both files matched at the start. Then I created `reconcile.sh` (compare desired vs current, on mismatch copy desired over current and log) and made it executable.

## 1.2 & 1.3 Manual Drift and Reconciliation

I changed `current-state.txt` to simulate drift (version 2.0, replicas 5), then ran the reconciliation script:

```
$ echo "version: 2.0" > current-state.txt
$ echo "app: myapp" >> current-state.txt
$ echo "replicas: 5" >> current-state.txt

$ ./reconcile.sh
Tue Mar 17 19:49:07 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 17 19:49:07 MSK 2026 - ✅ Reconciliation complete
```

After reconciliation I ran `diff desired-state.txt current-state.txt` — no output, so the files were identical. I verified current state:

```
$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3
```

So the drift was fixed and current state again matched desired.

## 1.4 Continuous Reconciliation (watch)

I ran `watch -n 5 ./reconcile.sh`. At first both states were in sync:

```
Every 5.0s: ./reconcile.sh
Tue Mar 17 23:39:27 MSK 2026 - ✅ States synchronized
```

Then in another terminal I introduced drift (e.g. changed replicas in `current-state.txt`). Within 5 seconds the loop detected and fixed it:

```
Tue Mar 17 23:40:11 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 17 23:40:11 MSK 2026 - ✅ Reconciliation complete

Every 5.0s: ./reconcile.sh
Tue Mar 17 23:40:16 MSK 2026 - ✅ States synchronized
```

So I saw the loop automatically bring current state back to desired state.

## Analysis

From what I did here, the reconciliation loop periodically compares **desired state** (in my case `desired-state.txt`, in real GitOps it would be Git/manifests) with **current state** (here `current-state.txt`, in GitOps the cluster). If they differ, it applies the desired state to the current one (here I overwrote the file; in GitOps it would apply/delete/sync resources). So any manual or accidental change to current state gets detected and reverted. That way the system stays aligned with the declared source of truth and configuration drift is prevented without me having to fix it by hand.

## Reflection

With **declarative** config I describe the target state (“replicas: 3”, “image: v1.0”) and something else (operator, controller) figures out how to get there and keeps it there. With **imperative** commands I would have to say exactly what to do (“scale to 3”, “update image”) each time. I see declarative as better in production because: the same desired state always leads to the same result; I can re-run reconciliation and it fixes drift; history lives in Git (who changed what); and tools like ArgoCD/Flux can continuously sync without human intervention. With imperative, if someone changes the cluster by hand, nothing automatically corrects it.


# Task 2

## 2.1 Health Check Script

I created `healthcheck.sh` that compares MD5 checksums of desired-state.txt and current-state.txt and appends the result to `health.log`:

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

## 2.2 Test Health Monitoring

When both states matched, the health check reported OK:

```
$ ./healthcheck.sh
Tue Mar 17 23:43:35 MSK 2026 - ✅ OK: States synchronized

$ cat health.log
Tue Mar 17 23:43:35 MSK 2026 - ✅ OK: States synchronized
```

Then I introduced drift by appending a line to current-state.txt:

```
$ echo "unapproved-change: true" >> current-state.txt
$ ./healthcheck.sh
Tue Mar 17 23:43:49 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

After that I ran reconcile to fix the drift and ran healthcheck again — it went back to OK:

```
$ ./reconcile.sh
Tue Mar 17 23:44:00 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Tue Mar 17 23:44:00 MSK 2026 - ✅ Reconciliation complete

$ ./healthcheck.sh
Tue Mar 17 23:44:04 MSK 2026 - ✅ OK: States synchronized
```

## 2.3 Continuous Monitoring

I created `monitor.sh` that runs healthcheck and reconcile in a loop 10 times with a 3-second pause. When I ran it, all 10 checks reported OK (states were already in sync):

```
$ ./monitor.sh
Starting GitOps monitoring...

--- Check #1 ---
Tue Mar 17 23:44:37 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 23:44:37 MSK 2026 - ✅ States synchronized
--- Check #2 ---
...
--- Check #10 ---
Tue Mar 17 23:45:05 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 23:45:05 MSK 2026 - ✅ States synchronized
```

Complete `health.log` after all steps (including the earlier CRITICAL and recovery):

```
Tue Mar 17 23:43:35 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 23:43:49 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Tue Mar 17 23:44:04 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 23:44:37 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 23:44:40 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 23:44:43 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 23:44:46 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 23:44:49 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 23:44:53 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 23:44:56 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 23:44:59 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 23:45:02 MSK 2026 - ✅ OK: States synchronized
Tue Mar 17 23:45:05 MSK 2026 - ✅ OK: States synchronized
```

## Analysis

MD5 (or any hash) gives a short fingerprint of the whole file. If a single character or line changes, the hash changes. So I don’t need to compare files line by line — I just compare two hashes. That makes it easy to see whether desired and current state are identical and to log “in sync” vs “mismatch” without storing full file contents. In GitOps, tools often use commit hashes or manifest hashes in a similar way to know if the cluster matches Git.

## Comparison

In ArgoCD, “Sync Status” shows whether the live cluster state matches the desired state from Git (Synced / OutOfSync). My healthcheck is a simple version of that: I compare desired vs current and report OK or CRITICAL. ArgoCD does the same idea at scale — it compares Git manifests to cluster resources and shows drift. So my script is like a minimal “sync status” check: it tells me at a glance if my current state has drifted from the source of truth and gives me a log to review later.
