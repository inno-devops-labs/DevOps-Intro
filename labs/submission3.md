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
