# Lab 3 — Submission
Platform: GitHub Actions

## Task 1 — First GitHub Actions Workflow

Workflow file: `.github/workflows/ci.yml`

Run trigger:
The workflow was automatically triggered by a `git push` to the `feature/lab3` branch.

Log snippet (Print basic info step):

```text
Hello from GitHub Actions!
Repository: krasand/DevOps-Intro
Branch: refs/heads/feature/lab3
Commit: f9b099db99fc3213768b28a39d40514c462e297c
Fri Feb 20 20:04:48 UTC 2026
```

Key concepts demonstrated:
- A workflow is defined in YAML inside `.github/workflows/`.
- The workflow runs on specific events (`push`).
- A job runs on a GitHub-hosted runner (`ubuntu-latest`).
- Steps inside a job execute sequential shell commands.
- Logs show environment variables like `$GITHUB_REPOSITORY`, `$GITHUB_REF`, and `$GITHUB_SHA`.

Short analysis:
The workflow successfully executed on a hosted Ubuntu runner.  
It printed repository metadata and demonstrated how GitHub Actions reacts automatically to push events.

---

## Task 2 — Manual Trigger + System Information

Changes made:
- Added `workflow_dispatch` event to enable manual execution.
- Added a new step to print system information of the runner.

Manual run log snippet (System information step):

```text
OS:
Linux runnervmwffz4 6.11.0-1018-azure #18~24.04.1-Ubuntu SMP Sat Jun 28 04:46:03 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux

CPU cores:
4

Memory:
total: 15Gi
used: 816Mi
free: 13Gi

Disk:
/dev/root 145G total, 53G used, 92G available
```

Comparison between triggers:
- `push` automatically runs the workflow when new commits are pushed.
- `workflow_dispatch` allows manual execution from the GitHub UI.

Short analysis:
The runner environment is a temporary Linux virtual machine provided by GitHub.  
Printing system information helps understand available CPU, memory, and disk resources, which is useful for debugging CI failures and performance issues.