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

### Links/Screenshots

[Link to successful workflow run](https://https://github.com/thallars/DevOps-Intro/actions/runs/22237502793)

## Manual Trigger + System Information

### Changes

To `github-actions-demo.yml` added:

```yaml
on:
  push:
  workflow_dispatch:
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

