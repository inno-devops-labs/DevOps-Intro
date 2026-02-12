# Lab 3 — CI/CD with GitHub Actions

## Task 1 — First GitHub Actions Workflow

Key concepts observed:
- **Workflow**: YAML automation stored in `.github/workflows/`.
- **Trigger (event)**: `push` automatically starts a run when commits are pushed.
- **Job**: A group of steps executed on the same runner VM.
- **Steps**: Individual commands/actions executed sequentially.
- **Runner**: The machine executing the job (GitHub-hosted runner via `runs-on`).




## Task 2 — Manual Trigger + System Information


### `.github/workflows/lab3-ci.yml`:

- Initial setup
- Manual trigger
- System information collection

### Gathered System Information from Runner

- Operating System: Ubuntu (ubuntu-latest GitHub-hosted runner)
- Kernel Version: Linux kernel version displayed via `uname -a`
- CPU Architecture: x86_64
- Memory: RAM size and usage displayed via free `-h`
- Disk Space: Available and used storage displayed via `df -h`

### Comparison of Manual vs Automatic Workflow Triggers

**Automatic Trigger**:
- Activated automatically when code is pushed to the repository.
- Event type shown in logs as: `push`.
- Used for continuous integration to validate changes immediately after commit.
- Ensures automated testing and validation without manual intervention.


**Manual Trigger (`workflow_dispatch`)**:
- Triggered manually via GitHub UI
- Event type shown in logs as: `workflow_dispatch`.
