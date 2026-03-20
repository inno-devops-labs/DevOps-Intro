# TASK 1

```bash
> cat .\current-state.txt
version: 1.0
app: myapp
replicas: 3
```

```bash
cat .\desired-state.txt # after syncing
version: 1.0
app: myapp
replicas: 3
```

```bash
> ./reconcile.sh 
Fri Mar 20 17:34:54 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 17:34:54 MSK 2026 - ✅ Reconciliation complete
```

```bash
> diff desired-state.txt current-state.txt
# empty
```

```bash
> cat current-state.txt 
version: 1.0
app: myapp
replicas: 3
```

```bash
Fri Mar 20 17:37:09 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 17:37:09 MSK 2026 - ✅ Reconciliation complete
```

The GitOps reconciliation loop is a continuous process where an operator automatically compares the desired state defined in a Git repository with the actual state of the target environment, constantly applying corrections to align them. This prevents configuration drift by ensuring any manual changes, unauthorized edits, or environmental inconsistencies are automatically overwritten and reverted to match the version-controlled source of truth.

Declarative configuration defines the desired end state of a system, enabling version control, automated reconciliation, and consistent reproducibility across environments. In contrast, imperative commands are manual, error-prone, and create a fragile record of changes that cannot be reliably audited or rolled back in production.

# TASK 2

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

```bash
> cat health.log
Fri Mar 20 17:39:44 MSK 2026 - ✅ OK: States synchronized
```

```bash
> ./healthcheck.sh
Fri Mar 20 17:40:57 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: aa5250acc87fa7312c1afc6747a0b6e7
  Current MD5: a818adc74b8521533aeed8f867caaee1
```

```bash
> cat health.log
Fri Mar 20 17:39:44 MSK 2026 - ✅ OK: States synchronized
Fri Mar 20 17:40:57 MSK 2026 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: aa5250acc87fa7312c1afc6747a0b6e7
  Current MD5: a818adc74b8521533aeed8f867caaee1
```

```
Every 5.0s: ./reconcile.sh                                                            ob0china: Fri Mar 20 17:42:12 2026

Fri Mar 20 17:42:12 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Fri Mar 20 17:42:12 MSK 2026 - ✅ Reconciliation complete
```

Checksums generate a unique digital fingerprint of a configuration file's content, allowing systems to quickly detect any alteration by comparing the current fingerprint against a previously recorded baseline. If the checksum differs, it signals that the configuration has changed—whether from an authorized update, manual tampering, or corruption—triggering automated reconciliation to restore the intended state.

In GitOps, the checksum (or similar hash) of a configuration serves as the fundamental basis for ArgoCD's "Sync Status", allowing the tool to instantly determine if the live state's checksum matches the desired state's checksum from Git. If a configuration change causes these checksums to diverge—such as from manual edits or drift—ArgoCD marks the application as "OutOfSync" and can automatically initiate a sync to reconcile the difference.