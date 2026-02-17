# Lab 3 — GitHub Actions

## Task 1 — First GitHub Actions Workflow

### Workflow file
The workflow is defined in:
```
.github/workflows/lab3-task1.yml
```
### Trigger
The workflow is triggered on a `push` event to the `feature/lab3` branch.

### Job configuration
- Runner: `ubuntu-latest`
- Job name: `hello-ci`
- Step name: `Print hello and context`
- Execution environment: GitHub-hosted Ubuntu virtual machine

### Execution result
After committing and pushing the workflow file, GitHub Actions automatically executed the pipeline.

The job successfully:
- Started on a GitHub-hosted runner
- Executed the shell command
- Printed repository information and actor details

The workflow execution time was approximately 3 seconds.
The branch reference (refs/heads/feature/lab3) confirms that the workflow was triggered by a push event to the specified branch.

### Evidence
![3_img_1.png](screenshots%2F3_img_1.png)
![3_img_2.png](screenshots%2F3_img_2.png)

### Key concepts learned
- Workflow: YAML pipeline stored in .github/workflows/
- Trigger: event (push) that starts the workflow
- Job: a group of steps executed on a runner
- Step: an individual task within a job
- Runner: a virtual machine that executes the job

## Task 2

### Changes made

For Task 2, the workflow was extended with:

- A `workflow_dispatch` trigger to allow manual execution from the GitHub Actions UI.
- An additional step called `Gather system information` to collect runner details such as:
  - Operating system
  - CPU architecture and model
  - Memory information
  - Disk usage

### Manual Trigger Execution

The workflow was manually triggered using the `workflow_dispatch` event.  
Unlike the `push` trigger, which runs automatically after a commit, the manual trigger allows starting the workflow on demand from the GitHub UI.

### Runner Environment Analysis

The system information shows that the workflow runs on a GitHub-hosted Ubuntu virtual machine (`ubuntu-latest`).

Key observations:
- OS: Ubuntu 24.04 LTS
- Architecture: x86_64
- CPU: AMD EPYC (virtualized environment)
- The environment is not my local machine but a cloud-based runner.

This demonstrates how CI pipelines execute in standardized and isolated environments.

### Evidence
![3_img_3.png](screenshots%2F3_img_3.png)
![3_img_4.png](screenshots%2F3_img_4.png)
![3_img_5.png](screenshots%2F3_img_5.png)