# Lab 7 Submission – GitOps Fundamentals

## Task 1 — Git State Reconciliation

### Setting the Baseline
- `desired-state.txt` and the initial `current-state.txt` both described the same target:

```startLine:endLine:gitops-lab/desired-state.txt
version: 1.0
app: myapp
replicas: 3
```

- I made sure the reconciliation script matched the lab brief:

```startLine:endLine:gitops-lab/reconcile.sh
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

### Manual Drift And Recovery
- I intentionally rewrote `current-state.txt` with different values and ran the script:

```
$ ./reconcile.sh
Wed Nov 12 13:27:25 MSK 2025 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed Nov 12 13:27:25 MSK 2025 - ✅ Reconciliation complete
```

- A quick `diff` afterwards returned nothing, and `current-state.txt` snapped back to the desired definition.

### Continuous Loop (watch Replacement)
- The macOS shell here doesn’t ship with `watch`, so I mimicked the same five-second patrol with a tiny loop that injects drift mid-run:

```
$ bash -lc 'for i in 1 2 3; do echo "--- loop $i ---"; if [ "$i" -eq 2 ]; then echo "(injecting drift)"; echo "replicas: 10" >> current-state.txt; fi; ./reconcile.sh; sleep 1; done'
--- loop 1 ---
Wed Nov 12 13:28:54 MSK 2025 - ✅ States synchronized
--- loop 2 ---
(injecting drift)
Wed Nov 12 13:28:55 MSK 2025 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Wed Nov 12 13:28:55 MSK 2025 - ✅ Reconciliation complete
--- loop 3 ---
Wed Nov 12 13:28:56 MSK 2025 - ✅ States synchronized
```

- The second pass spotted the unexpected `replicas: 10`, repaired the file, and the third pass confirmed the state was back in sync—close enough to a manual Argo-style reconciliation dance.

### Task 1 Takeaways
- **How the loop prevents drift:** Git holds the golden copy, and every run of `reconcile.sh` compares the cluster snapshot (`current-state.txt`) against it. Any difference is overwritten instantly, which keeps the runtime state from drifting away from the declared truth.
- **Why declarative wins:** A single desired file is much easier to audit, peer-review, and roll back than a pile of ad-hoc `kubectl` commands. Once the desired state is committed, automation can keep enforcing it while humans focus on reasoned changes instead of firefights.

## Task 2 — GitOps Health Monitoring

### MD5-Based Health Checks
- The checksum-based watcher from the brief lives in `healthcheck.sh`:

```startLine:endLine:gitops-lab/healthcheck.sh
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

- With everything clean, the output and log looked like this:

```
$ ./healthcheck.sh
Wed Nov 12 13:29:15 MSK 2025 - ✅ OK: States synchronized
```

- After appending `unapproved-change: true` to `current-state.txt`:

```
$ ./healthcheck.sh
Wed Nov 12 13:29:25 MSK 2025 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

- Running `./reconcile.sh` and `./healthcheck.sh` once more cleared the alert.

### health.log Timeline
- The log retains every check, so you can see the initial alert followed by a bunch of green confirmations:

```startLine:endLine:gitops-lab/health.log
Wed Nov 12 13:29:15 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:29:25 MSK 2025 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Wed Nov 12 13:29:37 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:29:50 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:29:53 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:29:56 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:29:59 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:02 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:05 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:08 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:11 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:14 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:17 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:33 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:36 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:39 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:42 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:45 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:48 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:52 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:55 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:58 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:31:01 MSK 2025 - ✅ OK: States synchronized
```

### monitor.sh In Action
- I wrapped the health check and reconciliation into one script for a quick-and-dirty “operator”:

```startLine:endLine:gitops-lab/monitor.sh
#!/bin/bash
# monitor.sh - Combined reconciliation and health monitoring

printf "Starting GitOps monitoring...\n"
for i in {1..10}; do
    printf "\n--- Check #%d ---\n" "$i"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 3
done
```

- A single run produces a steady stream of happy logs:

```
$ ./monitor.sh
Starting GitOps monitoring...

--- Check #1 ---
Wed Nov 12 13:30:33 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:30:33 MSK 2025 - ✅ States synchronized
# (output trimmed for brevity — checks 2 through 9 look identical)
--- Check #10 ---
Wed Nov 12 13:31:01 MSK 2025 - ✅ OK: States synchronized
Wed Nov 12 13:31:01 MSK 2025 - ✅ States synchronized
```

### Task 2 Thoughts
- **Checksums catch everything:** Comparing MD5 hashes is cheaper than diffing the whole file and flags any byte-level change, even if it is just a whitespace tweak. That’s essentially what GitOps controllers do when they calculate manifests’ fingerprints.
- **Link to ArgoCD:** ArgoCD’s sync status shows “Synced” or “OutOfSync” based on the same idea—hashing rendered manifests and comparing them against what’s running. When it spots a mismatch it can either alert you or immediately “reconcile” just like our scripts.
- **Why logs matter:** Keeping `health.log` gives you a timeline to trace when drift started, similar to Operator events in Kubernetes. That history is invaluable when you need to prove compliance or find a noisy component.

## Final Reflection
- Having a tiny Git repo plus these three scripts was enough to feel the GitOps feedback loop end-to-end: declare once, let automation do the rest, and capture evidence whenever state wiggles out of line.
- The exercise also highlighted that tooling gaps (like missing `watch`) are easy to work around as long as the core principles stay intact: Git as the source of truth, automatic reconciliation, and health reporting built on top of simple, auditable commands.
- Compared with manually babysitting configs, this workflow felt calmer—once the guardrails were in place, any drift became obvious and short-lived.

