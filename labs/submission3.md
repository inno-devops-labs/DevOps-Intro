# Lab 3 — CI/CD (GitHub Actions)

## Platform
GitHub Actions

---

## Task 1 — First GitHub Actions Workflow

### Workflow file
- `.github/workflows/lab3.yml`

### Evidence
- Run link: https://github.com/vozamhcak/DevOps-Intro/actions/runs/22237239314

### What triggered the run?
- The workflow was triggered by a `push` to the `feature/lab3` branch.

### Key concepts
- **Workflow**: YAML configuration stored in `.github/workflows/`
- **Jobs**: logical groups of steps executed on a runner
- **Steps**: individual commands or actions inside a job
- **Runner**: virtual machine that executes jobs (`ubuntu-latest`)
- **Trigger**: event that starts workflow execution (`push`)

### Notes / analysis
- The workflow checks out the repository using `actions/checkout`.
- It prints GitHub environment variables and basic system info.
- Logs are accessible via the GitHub Actions UI (Actions → workflow run → job logs).



---

## Task 2 — Manual Trigger + System Information

### Workflow changes
- Added `workflow_dispatch` trigger to enable manual runs.
- Extended workflow with a step that gathers runner system information.

### Evidence (automatic run after changes)
- Run link: https://github.com/vozamhcak/DevOps-Intro/actions/runs/22237477623

### System information (excerpt from logs)
Example data collected from runner:
- OS: Ubuntu (GitHub-hosted runner)
- CPU: multiple cores (nproc + lscpu output)
- Memory: reported via `free -h`
- Disk: reported via `df -h`

### Manual vs automatic triggers
- Automatic trigger: executed on push to `feature/lab3`.
- Manual trigger: enabled via `workflow_dispatch` in workflow YAML.

### Runner environment analysis
- GitHub-hosted runners provide Linux-based ephemeral environments.
- Each workflow run executes in a clean VM.
- Useful for reproducible CI pipelines and testing.
