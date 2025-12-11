# CI/CD with GitHub Actions
## 1. First GitHub Actions Workflow
### 1. [Link to the successful run](https://github.com/GurbanG/F25-DevOps-Intro/actions/runs/20119395633/job/57736104239)
### 2. Key concepts learned (jobs, steps, runners, triggers).
- **Workflow: an automated process defined in a YAML file.**
- **Trigger: defines when the workflow runs, e.g on push**
- **Jobs: logical groups of work. Each workflow can have multiple jobs.**
- **Steps: each job consists of steps that run shell commands or external actions.**
- **Runners: virtual machines (e.g., ubuntu-latest) where jobs are executed.**
### 3. A short note on what caused the run to trigger.
A push event in workflow trigerred the run.
```bash
on: [push]
jobs:
  Explore-GitHub-Actions:
  ...
```
### 4. Analysis of workflow execution process.
- **The runner ran the job on ubuntu-latest**
- **Some greeting messages were printed**
- **`actions/checkout@v5` copied the repo to the runner:**
```bash
- name: Check out repository code
        uses: actions/checkout@v5
```
- **`ls ${{ github.workspace }}` listed the files in the repo.**

## 2. Manual Trigger + System Information

### 1. Changes made to the workflow file.
```bash
name: GitHub Actions Demo
run-name: ${{ github.actor }} is testing out GitHub Actions 🚀
on: 
  push:
    branches:
      - main
      - feature/lab3
  workflow_dispatch:

jobs:
  basic-info:
    runs-on: ubuntu-latest

    steps:
      - name: Check out repository code
        uses: actions/checkout@v4

      - name: Print greeting
        run: echo "Hello from GitHub Actions!"

      - name: Gather system information
        run: |
          echo "### SYSTEM INFORMATION START ###"
          echo "CPU Info:"
          lscpu
          echo
          echo "Memory Info:"
          free -h
          echo
          echo "Disk Info:"
          df -h
          echo
          echo "Environment Variables:"
          env
          echo "### SYSTEM INFORMATION END ###"
```

### 2. The gathered system information from runner.
- CPU info:
    - Architecture: x86_64
    - CPU(s): 4
    - Model name: AMD EPYC 7763 64-Core Processor
- Memory info:
    - total: 15 Gi
    - free: 9.6 Gi
- Disk info:
    - root filesystem size: 72Gb
    - root filesystem available: 19Gb

### 3. Comparison of manual vs automatic workflow triggers.
**Both triggers run the exact same workflow, but the initiation method is different. Manual workflow is trigerred via Github UI.**