# Task 1

## 1. Initial desired-state.txt and current-state.txt contents

### desired-state.txt

```txt id="6w0mow"
version: 1.0
app: myapp
replicas: 3
```

### current-state.txt

```txt id="wul69c"
version: 1.0
app: myapp
replicas: 3
```

---

## 2. Screenshot or output of drift detection and reconciliation

### Drift simulation

Modified `current-state.txt`:

```txt id="7b6s5g"
version: 2.0
app: myapp
replicas: 5
```

### Reconciliation output

```bash id="k0qj71"
./reconcile.sh

Thu Mar 19 03:20:13 PM MSK 2026 - DRIFT DETECTED!
Reconciling current state with desired state...
Thu Mar 19 03:20:13 PM MSK 2026 - Reconciliation complete
```

---

## 3. Output showing synchronized state after reconciliation

```bash id="w3w6yr"
cat current-state.txt
```

Output:

```txt id="3pdw7s"
version: 1.0
app: myapp
replicas: 3
```

---

## 4. Output from continuous reconciliation loop detecting auto-healing

### Start continuous reconciliation

```bash id="ppg6wu"
watch -n 5 ./reconcile.sh
```

### Trigger drift in second terminal

```bash id="gsp7oz"
echo "replicas: 10" >> current-state.txt
```

### Auto-healing result

The reconciliation loop automatically detects drift and restores the desired state within 5 seconds, returning the file to:

```txt id="5el3fu"
version: 1.0
app: myapp
replicas: 3
```

---

## 5. Analysis

The reconciliation loop continuously compares the desired configuration stored in `desired-state.txt` with the current system state stored in `current-state.txt`. When drift is detected, the script automatically restores the desired state by copying the source-of-truth configuration into the current state file. This prevents configuration drift by ensuring that accidental or manual changes cannot persist.

---

## 6. Reflection

Declarative configuration is more advantageous in production because it describes the final desired system state rather than a sequence of manual commands. This improves reproducibility, enables version control, simplifies auditing, and supports automatic self-healing through GitOps reconciliation mechanisms.

___
# Task 2 

## 1. Contents of healthcheck.sh script

```bash
#!/bin/bash
# healthcheck.sh - Monitor GitOps sync health

DESIRED_MD5=$(md5sum desired-state.txt | awk '{print $1}')
CURRENT_MD5=$(md5sum current-state.txt | awk '{print $1}')

if [ "$DESIRED_MD5" != "$CURRENT_MD5" ]; then
    echo "$(date) - CRITICAL: State mismatch detected!" | tee -a health.log
    echo "  Desired MD5: $DESIRED_MD5" | tee -a health.log
    echo "  Current MD5: $CURRENT_MD5" | tee -a health.log
else
    echo "$(date) - OK: States synchronized" | tee -a health.log
fi
```

---

## 2. Output showing "OK" status when states match

```bash
./healthcheck.sh
```

Output:

```bash
Thu Mar 19 03:43:59 PM MSK 2026 - OK: States synchronized
```

---

## 3. Output showing "CRITICAL" status when drift is detected

Drift was simulated with:

```bash
echo "unapproved-change: true" >> current-state.txt
```

Then the script was run again:

```bash
./healthcheck.sh
```

Output:

```bash
Thu Mar 19 03:44:53 PM MSK 2026 - CRITICAL: State mismatch detected!
Desired MD5: d7e40ed0649724b95788b8ba02314ada
Current MD5: 39856f67e618e2ff0c34f2b1c1a88126
```

---

## 4. Complete health.log file showing multiple checks

```bash
cat health.log
```

Output:

```bash
Thu Mar 19 03:43:59 PM MSK 2026 - OK: States synchronized
Thu Mar 19 03:44:53 PM MSK 2026 - CRITICAL: State mismatch detected!
Desired MD5: d7e40ed0649724b95788b8ba02314ada
Current MD5: 39856f67e618e2ff0c34f2b1c1a88126
Thu Mar 19 03:45:25 PM MSK 2026 - OK: States synchronized
```

---

## 5. Output from monitor.sh showing continuous monitoring

### monitor.sh script

```bash
#!/bin/bash
# monitor.sh - Combined reconciliation and health monitoring

echo "Starting GitOps monitoring..."
for i in {1..10}; do
    echo "\n--- Check #$i ---"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 3
done
```

### Run command

```bash
./monitor.sh
```

### Example output

```bash
Starting GitOps monitoring...

--- Check #1 ---
Thu Mar 19 03:46:59 PM MSK 2026 - OK: States synchronized
Thu Mar 19 03:46:59 PM MSK 2026 - States synchronized

--- Check #2 ---
Thu Mar 19 03:47:02 PM MSK 2026 - OK: States synchronized
Thu Mar 19 03:47:02 PM MSK 2026 - States synchronized
```

---

## 6. Analysis

MD5 checksums help detect configuration changes because even a very small modification in a file produces a completely different hash value. Comparing checksums is an efficient way to detect drift without comparing every line manually. If the hashes differ, the system immediately knows that the live configuration no longer matches the desired state.

---

## 7. Comparison

This is similar to GitOps tools such as ArgoCD and their Sync Status mechanism. ArgoCD continuously compares the desired state stored in Git with the live cluster state. In this lab, MD5 hashes simulate that same comparison: matching hashes indicate synchronization, while different hashes indicate drift and trigger corrective action.
