# Lab 3 — CI/CD with GitHub Actions & GitLab CI

## Task 1 — First GitHub Actions Workflow

### Steps Followed:

1. **Created workflow directory structure**:
   ```bash
   mkdir -p .github/workflows
   ```

2. **Created workflow file** `.github/workflows/github-actions-demo.yml`:
   ```yaml
   name: GitHub Actions Demo
   run-name: ${{ github.actor }} is testing out GitHub Actions 🚀
   on: [push]
   jobs:
     Explore-GitHub-Actions:
       runs-on: ubuntu-latest
       steps:
         - run: echo "🎉 The job was automatically triggered by a ${{ github.event_name }} event."
         - run: echo "🐧 This job is now running on a ${{ runner.os }} server hosted by GitHub!"
         - run: echo "🔎 The name of your branch is ${{ github.ref }} and your repository is ${{ github.repository }}."
         - name: Check out repository code
           uses: actions/checkout@v4
         - run: echo "💡 The ${{ github.repository }} repository has been cloned to the runner."
         - run: echo "🖥️ The workflow is now ready to test your code on the runner."
         - name: List files in the repository
           run: |
             ls ${{ github.workspace }}
         - run: echo "🍏 This job's status is ${{ job.status }}."
   ```

3. **Committed and pushed** the workflow file to the repository

### Key Observations:

- The workflow appears with the name "GitHub Actions Demo" in the Actions tab

### Trigger Details

**What caused the run to trigger:**
A push event to the repository triggered the workflow because I specified `on: [push]` in the workflow file. When I committed and pushed the workflow file itself, it triggered the first run.

### Workflow Execution Process Analysis:

1. **Trigger Phase**:
   - GitHub detects the push event to the repository
   - The event contains metadata about the commit, branch, and pusher
   - GitHub matches the event to workflows configured for `push` triggers

2. **Setup Phase**:
   - GitHub provisions a fresh Ubuntu virtual machine (runner)
   - The runner checks out the repository code at the specific commit SHA
   - Environment variables and context are prepared

3. **Job Execution Phase**:
   - The job "Explore-GitHub-Actions" starts on the Ubuntu runner

4. **Completion Phase**:
   - Runner is terminated/cleaned up
   - Logs are stored and available in Actions tab

### Links

[Link to successful workflow run](https://https://github.com/thallars/DevOps-Intro/actions/runs/22237502793)

## Manual Trigger + System Information

### Changes

To `github-actions-demo.yml` added:

```yaml
on: [push, workflow_dispatch]
```

```yaml
- name: Gather System Information
run: |
    echo "### Hardware Information"
    lscpu | grep -E 'Model name|CPU\(s\)|Thread\(s\) per core|Core\(s\) per socket'
    echo "### Memory Information"
    free -h
    echo "### OS Information"
    lsb_release -a
    echo "### Disk Information"
    df -h
```

### Gathered information

```bash
### Hardware Information
CPU(s):                               4
On-line CPU(s) list:                  0-3
Model name:                           AMD EPYC 7763 64-Core Processor
Thread(s) per core:                   2
Core(s) per socket:                   2
NUMA node0 CPU(s):                    0-3
### Memory Information
               total        used        free      shared  buff/cache   available
Mem:            15Gi       1.0Gi        13Gi        40Mi       1.8Gi        14Gi
Swap:          3.0Gi          0B       3.0Gi
### OS Information
Distributor ID:	Ubuntu
Description:	Ubuntu 24.04.3 LTS
Release:	24.04
Codename:	noble
### Disk Information
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       145G   53G   92G  37% /
tmpfs           7.9G   84K  7.9G   1% /dev/shm
tmpfs           3.2G 1008K  3.2G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
efivarfs        128M   26K  128M   1% /sys/firmware/efi/efivars
/dev/sda16      881M   62M  758M   8% /boot
/dev/sda15      105M  6.2M   99M   6% /boot/efi
tmpfs           1.6G   12K  1.6G   1% /run/user/1001
```

### Comparison: Manual vs Automatic Workflow Triggers

| Aspect | Automatic (push) | Manual (workflow_dispatch) |
|--------|-------------------|---------------------------|
| **Trigger Method** | Code push to repository | User clicks "Run workflow" in UI |
| **Use Case** | CI/CD on code changes | On-demand testing, manual deployments |
| **Branch Selection** | Uses branch of the push | User can select any branch |
| **Frequency** | Every push to configured branches | As needed by developer |
| **User Control** | No user intervention required | Full user control over when to run |
| **Audit Trail** | Tied to specific commits | Tied to manual trigger by user |
| **Parameters** | Uses commit context | Can accept input parameters (if configured) |

### Analysis of Runner Environment and Capabilities

1. Each run gets a fresh VM, ensuring isolation between workflows
2. Ubuntu runners come with many tools pre-installed (git, curl, docker, etc.)
3. Full outbound internet access (useful for fetching dependencies)
4. No data persists between runs (ephemeral environment)
5. 2 CPU cores and 8GB RAM sufficient for most build/test operations

