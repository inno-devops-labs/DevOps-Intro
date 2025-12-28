# Lab 7 — GitOps and Configuration Management

## Task 1 — Git State Reconciliation

### 1.1: Setup Desired State Configuration

**Make directory:**

Commands:

```bash
mkdir gitops-lab && cd gitops-lab
```

**Create Desired State (Source of Truth):**

Commands:

```bash
echo "version: 1.0" > desired-state.txt
echo "app: myapp" >> desired-state.txt
echo "replicas: 3" >> desired-state.txt
```

**Initial desired-state.txt contents:**

```txt
version: 1.0
app: myapp
replicas: 3
```

**Simulate Current Cluster State:**

Commands:

```bash
cp desired-state.txt current-state.txt
echo "Initial state synchronized"
```

**Initial current-state.txt contents:**

```txt
version: 1.0
app: myapp
replicas: 3
```

### 1.2: Create Reconciliation Loop

**Create Reconciliation Script:**

Created file `reconcile.sh`:

```bash
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

**Make Script Executable:**

Command:

```bash
chmod +x reconcile.sh
```

### 1.3: Test Manual Drift Detection

**Simulate Manual Drift:**

Commands:

```bash
echo "version: 2.0" > current-state.txt
echo "app: myapp" >> current-state.txt
echo "replicas: 5" >> current-state.txt
```

**Current state after drift:**

```txt
version: 2.0
app: myapp
replicas: 5
```

**Run Reconciliation Manually:**

Commands:

```bash
./reconcile.sh
diff desired-state.txt current-state.txt
```

Output:

```bash
Mon Oct 13 17:42:45 MSK 2025 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Mon Oct 13 17:42:45 MSK 2025 - ✅ Reconciliation complete
```

**Verify Drift Was Fixed:**

Command:

```bash
cat current-state.txt
```

Output:

```txt
version: 1.0
app: myapp
replicas: 3
```

### 1.4: Automated Continuous Reconciliation

**Start Continuous Reconciliation Loop:**

Command:

```bash
watch -n 5 ./reconcile.sh
```

**In Another Terminal, Trigger Drift:**

Commands:

```bash
cd gitops-lab
echo "replicas: 10" >> current-state.txt
```

**Observe Auto-Healing:**

Output from continuous reconciliation loop:

```bash
Mon Oct 13 17:46:36 MSK 2025 - ✅ States synchronized
Mon Oct 13 17:46:41 MSK 2025 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Mon Oct 13 17:46:41 MSK 2025 - ✅ Reconciliation complete
Mon Oct 13 17:46:46 MSK 2025 - ✅ States synchronized
```

### Task 1 Analysis

#### Initial desired-state.txt and current-state.txt contents

Already provided above (1.1: Initialize Git Repository and Desired State)

#### Screenshot or output of drift detection and reconciliation

Already provided above. (1.3: Test Manual Drift Detection)

#### Output showing synchronized state after reconciliation

Already provided above. (1.3: Test Manual Drift Detection)

#### Output from continuous reconciliation loop detecting auto-healing

Already provided above. (1.4: Automated Continuous Reconciliation)

#### Analysis: Explain the GitOps reconciliation loop. How does this prevent configuration drift?

The GitOps reconciliation loop works through a continuous control mechanism:

1. **Desired State Definition**: Git repository serves as the single source of truth for system configuration
2. **Current State Monitoring**: Continuously monitors the actual system state
3. **Drift Detection**: Compares desired state (Git) with current state (system) at regular intervals
4. **Automatic Reconciliation**: When differences are detected, automatically applies changes to align current state with desired state
5. **Convergence**: System continuously converges toward the desired state defined in Git

**Prevention of Configuration Drift:**

- **Automated Detection**: Regular comparison prevents drift from accumulating unnoticed
- **Self-Healing**: Automatic correction eliminates manual intervention delays
- Git as source of truth prevents ad-hoc changes from persisting
- All changes are tracked through Git commits
- **Rollback Capability**: Easy reversion to previous known-good states

#### Reflection: What advantages does declarative configuration have over imperative commands in production?

**Declarative Configuration Advantages:**

1. Same configuration always produces same result, regardless of current state
2. Configuration files describe the desired end state clearly
3. **Version Control**: Easy to track, review, and rollback configuration changes
4. **Predictability**: Outcomes are deterministic and repeatable
5. **Automation-Friendly**: Machines can easily understand and apply declarative configurations
6. Can detect and correct drift from desired state
7. **Scalability**: Works consistently across multiple environments and systems

**Imperative Commands Disadvantages:**

1. Commands must be executed in specific sequence
2. Need to know current state to determine correct commands
3. Manual execution increases risk of mistakes
4. **No Self-Healing**: Cannot automatically detect or correct configuration drift
5. Command history doesn't represent current system state
6. **Hard to Replicate**: Recreating exact system state requires remembering all commands

**Production Impact:**

- **Reliability**: Declarative systems are more predictable and less prone to human error
- **Maintainability**: Easier to understand and modify system configuration
- **Compliance**: Better audit trails and change management
- **Disaster Recovery**: Faster and more reliable system restoration
- **Team Collaboration**: Configuration as code enables better collaboration and code review processes

## Task 2 — GitOps Health Monitoring

### 2.1: Create Health Check Script

**Create Health Check Script:**

Created file `healthcheck.sh`:

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

**Make Script Executable:**

Command:

```bash
chmod +x healthcheck.sh
```

### 2.2: Test Health Monitoring

**Test Healthy State:**

Commands:

```bash
./healthcheck.sh
cat health.log
```

Output:

```bash
Mon Oct 13 18:02:27 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:02:27 MSK 2025 - ✅ OK: States synchronized
```

**Simulate Configuration Drift:**

Command:

```bash
echo "unapproved-change: true" >> current-state.txt
```

**Run Health Check on Drifted State:**

Commands:

```bash
./healthcheck.sh
cat health.log
```

Output:

```bash
Mon Oct 13 18:03:13 MSK 2025 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Mon Oct 13 18:02:27 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:03:13 MSK 2025 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
```

**Fix Drift and Verify:**

Commands:

```bash
./reconcile.sh
./healthcheck.sh
cat health.log
```

Output:

```bash
Mon Oct 13 18:05:05 MSK 2025 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Mon Oct 13 18:05:05 MSK 2025 - ✅ Reconciliation complete
Mon Oct 13 18:05:05 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:02:27 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:03:13 MSK 2025 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Mon Oct 13 18:05:05 MSK 2025 - ✅ OK: States synchronized
```

### 2.3: Continuous Health Monitoring

**Create Combined Monitoring Script:**

Created file `monitor.sh`:

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

Command:

```bash
chmod +x monitor.sh
```

**Run Monitoring Loop:**

Command:

```bash
./monitor.sh
```

Output:

```bash
Starting GitOps monitoring...
\n--- Check #1 ---
Mon Oct 13 18:07:20 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:07:20 MSK 2025 - ✅ States synchronized
\n--- Check #2 ---
Mon Oct 13 18:07:23 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:07:23 MSK 2025 - ✅ States synchronized
\n--- Check #3 ---
Mon Oct 13 18:07:26 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:07:26 MSK 2025 - ✅ States synchronized
\n--- Check #4 ---
Mon Oct 13 18:07:29 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:07:29 MSK 2025 - ✅ States synchronized
\n--- Check #5 ---
Mon Oct 13 18:07:32 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:07:32 MSK 2025 - ✅ States synchronized
\n--- Check #6 ---
Mon Oct 13 18:07:35 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:07:35 MSK 2025 - ✅ States synchronized
```

**Review Complete Health Log:**

Command:

```bash
cat health.log
```

Output:

```bash
Mon Oct 13 18:02:27 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:03:13 MSK 2025 - ❌ CRITICAL: State mismatch detected!
  Desired MD5: a15a1a4f965ecd8f9e23a33a6b543155
  Current MD5: 48168ff3ab5ffc0214e81c7e2ee356f5
Mon Oct 13 18:05:05 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:07:20 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:07:23 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:07:26 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:07:29 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:07:32 MSK 2025 - ✅ OK: States synchronized
Mon Oct 13 18:07:35 MSK 2025 - ✅ OK: States synchronized
```

### Task 2 Analysis

#### Contents of healthcheck.sh script

Already provided above in section 2.1

#### Output showing "OK" status when states match

Already provided in sections 2.2, 2.3

#### Output showing "CRITICAL" status when drift is detected

Already provided in sections 2.2, 2.3

#### Complete health.log file showing multiple checks

Already provided in section 2.3

#### Output from monitor.sh showing continuous monitoring

Already provided in section 2.3

#### Analysis: How do checksums (MD5) help detect configuration changes?

Checksums like MD5 provide efficient change detection by:

1. **Content Fingerprinting**: MD5 creates a unique 128-bit hash representing the entire file content
2. **Fast Comparison**: Instead of comparing file contents line-by-line, we compare short hash values
3. **Sensitive Detection**: Any change, even a single character, produces a completely different hash
4. **Efficient Storage**: Hash values are small and can be logged/stored efficiently
5. **Version Agnostic**: Works regardless of file format or content structure
6. **Tamper Detection**: Can detect unauthorized modifications quickly

**In GitOps Context:**

- **Drift Detection**: Quickly identifies when actual state differs from desired state
- **Change Validation**: Ensures configurations haven't been modified outside the GitOps process
- **Audit Trail**: Provides verifiable proof of configuration integrity over time
- **Performance**: Avoids expensive file comparisons in large configurations

#### Comparison: How does this relate to GitOps tools like ArgoCD's "Sync Status"?

**Similarities with ArgoCD Sync Status:**

1. **Continuous Monitoring**: Both continuously monitor for differences between desired and actual state
2. **State Comparison**: Compare Git repository (source of truth) with cluster state
3. **Health Reporting**: Provide clear status indicators (Synced/OutOfSync vs OK/CRITICAL)
4. **Automatic Detection**: Detect drift without manual intervention
5. **Remediation Triggers**: Can trigger automatic or manual reconciliation

**ArgoCD Advanced Features:**

1. **Kubernetes Integration**: Directly compares Kubernetes manifests with cluster resources
2. **Resource-Level Granularity**: Shows exactly which resources are out of sync
3. **Visual Dashboard**: Provides UI for monitoring sync status across multiple applications
4. **Selective Sync**: Can sync specific resources or exclude certain fields
5. **Rollback Capabilities**: Easy rollback to previous Git commits
6. **Multi-Cluster Support**: Manages sync across multiple Kubernetes clusters

**Our Implementation vs ArgoCD:**

| Feature | Our Script | ArgoCD |
|---------|------------|---------|
| Scope | File-based simulation | Kubernetes resources |
| Detection Method | MD5 checksums | Resource comparison |
| Interface | Command line | Web UI + CLI |
| Remediation | Script-based | Kubernetes API |
| Scalability | Single application | Enterprise-scale |
| Integration | Standalone | Kubernetes-native |
