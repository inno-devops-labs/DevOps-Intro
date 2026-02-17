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
![img_6.png](screenshots%2Fimg_6.png)
![img_7.png](screenshots%2Fimg_7.png)

### Key concepts learned
- Workflow: YAML pipeline stored in .github/workflows/
- Trigger: event (push) that starts the workflow
- Job: a group of steps executed on a runner
- Step: an individual task within a job
- Runner: a virtual machine that executes the job
