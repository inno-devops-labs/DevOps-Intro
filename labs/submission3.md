# Task 1

## Link to the successful run
https://github.com/I-y6o-I/DevOps-Intro/actions/runs/22110362383

## Key concepts learned (jobs, steps, runners, triggers)
- Jobs  
  Independent units of work in a workflow. Each job runs on a runner and can run in parallel by default.

- Steps  
  Ordered commands inside a job. Steps run sequentially, can execute shell commands (`run:`) or reuse actions (`uses:`), and can pass data via outputs and environment variables

- Runners  
  Machines that execute jobs — GitHub-hosted (ephemeral VMs) or self-hosted. Selected with `runs-on:` (e.g., `ubuntu-latest`).

- Triggers  
  Events that start workflows, defined under `on:` (e.g., `push`, `pull_request`, `schedule`). Triggers can be filtered by branches, paths, or event types to control when workflows run.

## A short note on what caused the run to trigger
In `.github/workflows/lab-3-actions-test.yml` stated that run triggers on push: `on: [push]`

## Analysis of workflow execution process
1. Trigger: an event matching the workflow's `on:`, then creates a workflow run.

2. Runner allocation: for each job, a runner is selected/provisioned (GitHub-hosted VM or self-hosted machine) according to `runs-on:`.

3. Workspace setup: the runner prepares the workspace, checks out the repository, and sets up environment/tooling specified by steps.

4. Step execution: steps execute sequentially inside each job; steps can be shell commands (`run:`) or reusable actions (`uses:`). Actions are fetched and executed in the runner environment.

6. Outputs, artifacts and cache: steps and jobs can produce outputs, upload artifacts, and use caching; these are stored and made available to other jobs or the user.

7. Failure handling and continuation: jobs fail on non-zero exit codes by default; job dependencies determine whether downstream jobs run. Logs and exit statuses are recorded.

8. Completion: workflow finishes when all jobs complete; results, logs, and artifacts are accessible in the Actions UI and can trigger notifications or further automation.

# Task 2


