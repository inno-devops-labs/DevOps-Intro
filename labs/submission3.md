# Lab 3 — Submission

## Task 1 — First GitHub Actions Workflow

### Run link
- [Successful workflow run](https://github.com/belyakova-anna/F25-DevOps-Intro/actions/runs/17896049687)

### Screenshots
- Workflow run list
![Workflow run list](https://github.com/user-attachments/assets/74d5d767-a089-4d07-8b43-be28e29427d4)
- Step log output
![Step log output](https://github.com/user-attachments/assets/73e61527-119c-4b73-8fb1-f22274437aef)

### Steps I followed

1. **Create a feature branch locally**

```
git switch -c feature/lab3
```

2. **Create the workflow file locally**
```
mkdir .github\workflows
echo. > .github\workflows\github-actions-demo.yml
```

4. **Paste the Quickstart YML content to `github-actions-demo.yml`** 
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

5. **Commit locally**

```
git add .github/workflows/github-actions-demo.yml
git commit -m "feat: add workflow"
```

6. **Push the branch to GitHub (this push triggers the workflow)**

```
git push -u origin feature/lab3
```

7. **Verify the run on GitHub**

Open repository → Actions tab → Workflow: GitHub Actions Demo → latest run.

### Key concepts learned
- **Jobs** are groups of steps executed on a single runner.
- **Steps** are the individual commands or actions inside a job.
- **Runners** are virtual machines provided by GitHub (in this case `ubuntu-latest`) where jobs run.
- **Triggers** define when workflows start. Here, the trigger was `on: push`.

### What caused the run?
The run was automatically triggered by a **push event** when I committed and pushed changes to the repository.

### Execution analysis
1. GitHub Actions created a new Ubuntu-based runner (`ubuntu-latest`).
2. It executed the steps in order:
   - Printed messages with `echo`.
   - Checked out the repository code with `actions/checkout`.
   - Listed repository files using `ls`.
3. Each step was logged and could be expanded to see detailed output.
4. The workflow finished successfully, confirming the workflow configuration works as expected

## Task 2 — Manual Trigger + System Information

### Changes made to the workflow
1. **Enabled manual runs alongside push-triggered runs:**
  ```yaml
  on:
    push:
    workflow_dispatch:
  ```
2. **Added steps to collect runner system information:**
  ```yaml
  - name: CPU info
  run: lscpu
  - name: Memory info
  run: free -h
  - name: Disk info
  run: df -h
  - name: Environment variables
  run: env | sort
  ```

### Manual dispatch test

The Run workflow button became visible after the workflow file was present on the main branch.
![Workflow button](https://github.com/user-attachments/assets/2798e136-bf39-403b-b459-c5f84742e83d)

I manually dispatched the workflow from the GitHub UI: Actions → GitHub Actions Demo → Run workflow → Branch: main.

Manual run link: [here](https://github.com/belyakova-anna/F25-DevOps-Intro/actions/runs/17897676883)

![Jobs](https://github.com/user-attachments/assets/d9e39c12-6b8e-400e-8be7-f17bf035f925)

### Gathered system information (from logs)

**CPU**
```
Architecture: x86_64
CPU(s):       4   (Threads per core: 2; Cores per socket: 2; Sockets: 1)
Vendor ID:    AuthenticAMD
Model name:   AMD EPYC 7763 64-Core Processor
Hypervisor:   Microsoft (Virtualization type: full)
```

**Memory**
```
Mem: 15Gi total, 754Mi used, 13Gi free, 1.5Gi buff/cache, 14Gi available
Swap: 4.0Gi total, 0B used
```

**Disk**
```
/dev/root  72G size, 46G used, 27G avail (64%)  mounted at /
/dev/sda1  74G size, 4.1G used, 66G avail       mounted at /mnt
```

**Environment (selected)**
```
RUNNER_OS=Linux
ImageOS=ubuntu24
ImageVersion=20250907.24.1
GITHUB_EVENT_NAME=workflow_dispatch
GITHUB_REF_NAME=main
GITHUB_WORKFLOW=GitHub Actions Demo
GITHUB_WORKSPACE=/home/runner/work/F25-DevOps-Intro/F25-DevOps-Intro
```

### Comparison: manual vs automatic triggers

- Automatic (`on: push`)\
  Runs when I push commits. In the env,   `GITHUB_EVENT_NAME=push`.

- Manual (`workflow_dispatch`)\
  Runs only when I click Run workflow in the Actions tab. In the env, `GITHUB_EVENT_NAME=workflow_dispatch`.
  Useful for re-running without new commits or for ad-hoc checks.

### Runner environment and capabilities

- **OS:** Ubuntu (Image: ubuntu24, ImageVersion=20250907.24.1)

- **CPU:** 4 vCPUs (AMD EPYC 7763 under virtualization)

- **Memory:** 15 GiB total, ~14 GiB available at start

- **Disk:** Root FS 72 GB (27 GB free), additional mount at /mnt 74 GB (66 GB free)

- **Capabilities:** Standard Linux userland tools preinstalled; GitHub Actions environment variables expose repo, ref, and run context.