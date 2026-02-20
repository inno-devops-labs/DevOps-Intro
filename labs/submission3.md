# Task 1

Successful Run link:
https://github.com/myavg/DevOps-Intro/actions/runs/22226803324


Key concepts learned (jobs, steps, runners, triggers)

Trigger — an event that starts the workflow (here: push).

Job — a group of tasks executed on the same runner.

Steps — individual commands executed sequentially inside a job.

Runner — the machine that executes the job (GitHub-hosted ubuntu-latest).

What caused the run to trigger

The workflow was triggered automatically after a commit was pushed to the feature/lab3 branch, because the workflow listens to the push event.

Analysis of workflow execution process

After the push event, GitHub created a workflow run and started a hosted Ubuntu runner. The runner executed the job and its steps in order, printed the output to the logs, and completed successfully.

# Task 2

Changes made to the workflow file

Added the workflow_dispatch trigger to allow manual execution.

Added a new step to collect system information from the runner (OS, CPU, memory, disk).

Gathered system information from the runner

The runner is a GitHub-hosted Ubuntu virtual machine.
The logs show details about the operating system, CPU architecture, available memory, and disk space.

Comparison of manual vs automatic workflow triggers

Automatic trigger (push) — runs automatically when commits are pushed to the repository.

Manual trigger (workflow_dispatch) — started manually from the GitHub Actions UI.

Both execute the same workflow but are initiated differently.

Analysis of runner environment and capabilities

The workflow runs on a cloud-based GitHub-hosted runner (ubuntu-latest).
It provides a preconfigured Linux environment with standard development tools and limited virtual hardware resources suitable for CI tasks.