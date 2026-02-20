# Lab 3 — CI/CD with GitHub Actions

**Student:** Kamilya Shakirova
**Date:** 20-02-2026

---

## Task 1 — First GitHub Actions Workflow (6 pts)
- [x] Link to the successful run (or screenshots).
- [x] Key concepts learned (jobs, steps, runners, triggers).
- [x] A short note on what caused the run to trigger.
- [x] Analysis of workflow execution process.


### 1.1 Follow GitHub Actions Quickstart
Created `.github/workflows/lab3.yml` with basic CI/CD pipeline:
``` sh
PS D:\Programs\DevOps-Intro> mkdir -p .github/workflows
    Каталог: D:\Programs\DevOps-Intro\.github
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        21.02.2026      1:52                workflows

PS D:\Programs\DevOps-Intro> New-Item -Path .github/workflows/lab3.yml -ItemType File
    Каталог: D:\Programs\DevOps-Intro\.github\workflows
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        21.02.2026      1:52              0 lab3.yml
```

### 1.2 Test Workflow Trigger

**Workflow Run #1:** https://github.com/Kamilya05/DevOps-Intro/actions/runs/22244425440

**Status:** Success

**Trigger:** `push` event (automatic when code was pushed to `feature/lab3`)

**Jobs Executed:** `Explore-GitHub-Actions` (5s)


### 1.3 Key Concepts Learned

**Workflows:** YAML-based automation files (`.github/workflows/lab3.yml`) that define CI/CD pipelines. Execute on specified events (push, pull requests, manual dispatch, scheduled times).

**Jobs:** Parallel execution units within a workflow. Each job runs on a separate runner instance. In our workflow:
- `Explore-GitHub-Actions` — shows you how GitHub Actions can work with the contents of your repository

**Steps:** Sequential commands/actions within a job. Types:
- `uses: actions/checkout@v5` — Clone repository code
- `run: |` — Execute shell commands (bash on Linux)

**Runners:** Virtual machines provided by GitHub. GitHub-hosted runners available:
- `ubuntu-latest` (Ubuntu 22.04)
- `windows-latest` (Windows Server 2022)
- `macos-latest` (macOS)

**Triggers:** Events that start workflows. Configured in `on:` section:
- `push:` — Automatic on commit (can filter by branch/tag/path)

### 1.4 Workflow Execution Process

1. **Event Detection:** GitHub detected `.github/workflows/lab3.yml` when commit was pushed to `feature/lab3`
2. **Queue & Allocate:** Workflow queued; GitHub allocated fresh Ubuntu runner
3. **Repository Checkout:** Runner cloned repository using `actions/checkout@v4`
4. **Job Execution:** `Explore-GitHub-Actions` job ran
5. **Step Execution:** Each step's `run:` commands executed sequentially
6. **Output Capture:** All stdout captured and displayed in Actions logs
7. **Success Status:** All steps passed (green checkmarks), workflow marked complete



---

## Task 2 — Manual Trigger + System Information
- [] Changes made to the workflow file.
- [] The gathered system information from runner.
- [] Comparison of manual vs automatic workflow triggers.
- [] Analysis of runner environment and capabilities.

### 2.1 Add Manual Trigger

### 2.2 Test Manual Dispatch

### 2.3 Gather System Information


