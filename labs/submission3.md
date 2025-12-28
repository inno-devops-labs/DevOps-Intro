# Lab 3

## Task 1

### GitHub Actions Quickstart

1. **Branch Creation**: Created `feature/lab3` branch for this lab
2. **Workflow Directory Creation**: Created `.github/workflows/` directory structure
3. **Workflow File Creation**: Created `github-actions-demo.yml` with the provided quickstart template

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
        uses: actions/checkout@v5
      - run: echo "💡 The ${{ github.repository }} repository has been cloned to the runner."
      - run: echo "🖥️ The workflow is now ready to test your code on the runner."
      - name: List files in the repository
        run: |
          ls ${{ github.workspace }}
      - run: echo "🍏 This job's status is ${{ job.status }}."
```

#### Concepts learned from [quickstart](https://docs.github.com/en/actions/quickstart)

**Workflows**: YAML files that define automated processes, stored in `.github/workflows/` directory

**Jobs**: Units of work that run on fresh vms, can run sequentially or in parallel

**Steps**: Individual tasks within a job, can run commands or use pre-built actions

**Runners**: GitHub-hosted vms (ubuntu-latest, windows-latest, macos-latest) that execute workflows

**Triggers**: Events that start workflows (`on: [push]` means workflow runs on every push to any branch)

**Contexts**: Dynamic information available during workflow execution (e.g., `${{ github.actor }}`, `${{ runner.os }}`)

#### Workflow components

- **`name`**: Display name for the workflow in GitHub UI
- **`on: [push]`**: Trigger configuration - runs on any push event
- **`jobs`**: Contains all jobs (in this case, one job named "Explore-GitHub-Actions")
- **`runs-on`**: Specifies runner type
- **`steps`**: Sequential list of actions/commands to execute
- **`uses: actions/checkout@v5`**: Pre-built action to download repository code
- **Context variables**: `${{ github.actor }}`, `${{ runner.os }}`, etc. provides runtime information

### Analysis of [workflow](https://github.com/RailSAB/F25-DevOps-Intro/actions/runs/17894182583/job/50878574885) run

```bash
echo "🎉 The job was automatically triggered by a push event."
echo "🐧 This job is now running on a Linux server hosted by GitHub!"
echo "🔎 The name of your branch is refs/heads/feature/lab3 and your repository is RailSAB/F25-DevOps-Intro."

Run actions/checkout@v5
Syncing repository: RailSAB/F25-DevOps-Intro
Getting Git version info
  Working directory is '/home/runner/work/F25-DevOps-Intro/F25-DevOps-Intro'
  /usr/bin/git version
  git version 2.51.0
Temporarily overriding HOME='/home/runner/work/_temp/83770cb5-32d0-46c6-b20e-9439be2054cd' before making global git config changes
Adding repository directory to the temporary git global config as a safe directory
/usr/bin/git config --global --add safe.directory /home/runner/work/F25-DevOps-Intro/F25-DevOps-Intro
Deleting the contents of '/home/runner/work/F25-DevOps-Intro/F25-DevOps-Intro'
Initializing the repository
Disabling automatic garbage collection
Setting up auth
Fetching the repository
Determining the checkout info
/usr/bin/git sparse-checkout disable
/usr/bin/git config --local --unset-all extensions.worktreeConfig
Checking out the ref
/usr/bin/git log -1 --format=%H
b6b118df3f3fbbd991621f42f6c9e16830eff714

echo "💡 The RailSAB/F25-DevOps-Intro repository has been cloned to the runner."
echo "🖥️ The workflow is now ready to test your code on the runner."
ls /home/runner/work/F25-DevOps-Intro/F25-DevOps-Intro
README.md
labs
lectures

echo "🍏 This job's status is success."
Post job cleanup.
```

1. **Trigger**: Push event initiates workflow
2. **Runner Allocation**: GitHub provisions fresh Ubuntu vm
3. **Job Execution**: Single job "Explore-GitHub-Actions" starts
4. **Step Execution**: Each step runs sequentially:
   - Environment information gathering
   - Repository checkout using `actions/checkout@v5`
   - File system exploration
   - Status reporting
5. **Cleanup**: Runner is destroyed after job completion

## Task 2

## Task 2 — Manual Trigger + System Information

### Changes Made to Workflow File

**1. Added Manual Trigger:**

```yaml
on: 
  push:
  workflow_dispatch: 
```

**2. Created System Information Job:**

```yaml
System-Info-Collection:
  runs-on: ubuntu-latest
  steps:
    - name: Displaying trigger event
    - name: Displaying system information  
    - name: Runtime Environment Information
```

#### Complete Updated Workflow

```yaml
name: GitHub Actions Demo
run-name: ${{ github.actor }} is testing out GitHub Actions 🚀
on: 
  push:
  workflow_dispatch:

jobs:
  Explore-GitHub-Actions:
    runs-on: ubuntu-latest
    steps:
      - run: echo "🎉 The job was automatically triggered by a ${{ github.event_name }} event."
      - run: echo "🐧 This job is now running on a ${{ runner.os }} server hosted by GitHub!"
      - run: echo "🔎 The name of your branch is ${{ github.ref }} and your repository is ${{ github.repository }}."
      - name: Check out repository code
        uses: actions/checkout@v5
      - run: echo "💡 The ${{ github.repository }} repository has been cloned to the runner."
      - run: echo "🖥️ The workflow is now ready to test your code on the runner."
      - name: List files in the repository
        run: ls ${{ github.workspace }}
      - run: echo "🍏 This job's status is ${{ job.status }}."

  System-Info-Collection:
    runs-on: ubuntu-latest
    steps:
      - name: Displaying trigger event
        run: |
          echo "This workflow was triggered by the ${{ github.event_name }} event."
          echo "Repository: ${{ github.repository }}"
          echo "Branch: ${{ github.ref_name }}"
      
      - name: Displaying system information
        run: |
          echo "This job is running on a ${{ runner.os }} server hosted by GitHub."
          echo "CPU Information:"
          lscpu | head -15
          echo "Memory Information:"
          free -h
          echo "Disk Information:"
          df -h
      
      - name: Runtime Environment Information
        run: |
          echo "User: $(whoami)"
          echo "Home: $HOME"
          echo "Working Directory: $(pwd)"
          echo "Shell: $SHELL"
```

### Manual Workflow Dispatch

#### How to Trigger Manually

#### Workflow must be in default branch (main)

1. **Navigate**: GitHub Repository → **Actions** tab
2. **Select**: "GitHub Actions Demo" workflow  
3. **Trigger**: Click **"Run workflow"** button
4. **Configure**: Select branch `feature/lab3`
5. **Execute**: Click **"Run workflow"** to dispatch

[Manual Trigger Run](https://github.com/RailSAB/F25-DevOps-Intro/actions/runs/17894506342/job/50879311077)

### System Information Analysis

#### Trigger Event Verification

```bash
This workflow was triggered by the workflow_dispatch event
...
```

#### Hardware Specifications

**CPU Information:**

```bash
The server has the following processors:
Architecture:                         x86_64
CPU op-mode(s):                       32-bit, 64-bit
Address sizes:                        48 bits physical, 48 bits virtual
Byte Order:                           Little Endian
CPU(s):                               4
On-line CPU(s) list:                  0-3
Vendor ID:                            AuthenticAMD
Model name:                           AMD EPYC 7763 64-Core Processor
CPU family:                           25
...
```

**Memory Information:**

```bash
The server has the following amount of free memory:
               total        used        free      shared  buff/cache   available
Mem:            15Gi       744Mi        13Gi        36Mi       1.5Gi        14Gi
Swap:          4.0Gi          0B       4.0Gi
```

**Storage Information:**

```bash
Root Filesystem: 72GB total, 27GB available (64% used)
Boot Partition: 881MB  
Additional Mount: 74GB (/mnt)
Temporary Storage: 7.9GB (/dev/shm)
```

#### Runtime Environment

**System Context:**

```bash
username: runner
home directory: /home/runner
current working directory: /home/runner/work/F25-DevOps-Intro/F25-DevOps-Intro
PATH: /snap/bin:/home/runner/.local/bin:/opt/pipx_bin:/home/runner/.cargo/bin:/home/runner/.config/composer/vendor/bin:/usr/local/.ghcup/bin:/home/runner/.dotnet/tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
shell: /bin/bash
env variables:
...
```

### Comparison

#### Manual vs Automatic Triggers

| Aspect | Push Trigger | Manual Trigger |
|--------|-------------|----------------|
| **Event Name** | `push` | `workflow_dispatch` |
| **Activation** | Automatic on code push | Manual via GitHub UI/API |
| **Control** | Developer commits | Explicit user action |
| **Frequency** | Every push | When needed |

#### Runner Environment Capabilities

**Infrastructure:**

- 4-core AMD EPYC processor, 15GB RAM, 72GB storage
- GitHub-hosted on Microsoft Azure with full internet access

**Software:**

- Languages: Java, Python, Node.js, Go
- Tools: Git, Docker, npm, pip
- Development platforms ready to use

**Security:**

- Fresh isolated VM per workflow run
- Non-privileged `runner` user
- Automatic cleanup after completion

#### Key Insights

**Manual Dispatch Benefits:**

- Test workflows without commits
- Run on-demand operations
- Safe experimentation

**System Capabilities:**

- Auto-scaled runners for concurrent workflows
- Comprehensive development environment
- Consistent and reliable execution
