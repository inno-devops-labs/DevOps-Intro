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

Run link: https://github.com/I-y6o-I/DevOps-Intro/actions/runs/22112271984

## Changes made to the workflow file.
I have added `workflow_dispatch` trigger and removed example messages
Also I have added system info printing

## The gathered system information from runner
```
=== Runner Information ===
Runner OS: Linux
Runner Architecture: X64
Runner Name: GitHub Actions 1000000174
Runner Tool Cache: /opt/hostedtoolcache

 === Hardware Specifications ===
CPU Information:
Architecture:                            x86_64
CPU op-mode(s):                          32-bit, 64-bit
Address sizes:                           48 bits physical, 48 bits virtual
Byte Order:                              Little Endian
CPU(s):                                  4
On-line CPU(s) list:                     0-3
Vendor ID:                               AuthenticAMD
Model name:                              AMD EPYC 7763 64-Core Processor
CPU family:                              25
Model:                                   1
Thread(s) per core:                      2
Core(s) per socket:                      2
Socket(s):                               1
Stepping:                                1
BogoMIPS:                                4890.85

Memory Information:
               total        used        free      shared  buff/cache   available
Mem:            15Gi       980Mi        13Gi        36Mi       1.8Gi        14Gi
Swap:          3.0Gi          0B       3.0Gi

Disk Space:
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       145G   53G   92G  37% /
tmpfs           7.9G   84K  7.9G   1% /dev/shm
tmpfs           3.2G 1008K  3.2G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
efivarfs        128M   26K  128M   1% /sys/firmware/efi/efivars
/dev/sda16      881M   63M  757M   8% /boot
/dev/sda15      105M  6.2M   99M   6% /boot/efi
tmpfs           1.6G   12K  1.6G   1% /run/user/1001

Number of CPU cores:
4

=== Environment Variables ===
HOME: /home/runner
USER: runner
SHELL: /bin/bash
PATH: /snap/bin:/home/runner/.local/bin:/opt/pipx_bin:/home/runner/.cargo/bin:/home/runner/.config/composer/vendor/bin:/usr/local/.ghcup/bin:/home/runner/.dotnet/tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
```

## Comparison of manual vs automatic workflow triggers
**Automatic triggers** (`push`, `pull_request`) execute workflows immediately when code changes occur, enabling continuous integration and immediate feedback on commits. They're used for automated testing, builds, and deployments without human intervention.

**Manual triggers** (`workflow_dispatch`) require explicit user action through the GitHub Actions UI. They're useful for tasks like production deployments, maintenance operations, or testing workflows without making code changes. Manual triggers can include custom input parameters for flexible execution.


## Analysis of runner environment and capabilities
The GitHub-hosted runner provides a production-ready Linux environment suitable for diverse CI/CD workflows. It includes pre-installed development tools, package managers, and language runtimes accessible through the system PATH, eliminating manual setup for common tasks.

The runner environment supports typical development operations including compilation, automated testing, containerization with Docker, artifact generation, and deployment tasks. Its pre-configured tooling and clean-slate approach make it reliable for continuous integration pipelines

