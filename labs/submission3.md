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