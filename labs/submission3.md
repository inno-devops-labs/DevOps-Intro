# Lab 3 

## Task 1

### 1.1 Quickstart Implementation
I followed the GitHub Actions quickstart guide to create the workflow. The key steps were:
1. Creating the `.github/workflows` directory
2. Creating a YAML file with workflow configuration
3. Defining the trigger event (`on: push`)
4. Adding jobs and steps

### 1.2 Workflow Configuration
**Workflow File:** `.github/workflows/lab3-workflow.yml`
[Link to run](https://github.com/ghshark63/DevOps-Intro/actions/runs/22193831339)
was triggerd by push

### Concepts
Jobs: Independent units of work that can run in parallel
Steps: Individual tasks within a job that execute sequentially
Runners: GitHub-hosted or self-hosted servers that execute workflows
Triggers: Events that start workflow execution (push, pull_request, workflow_dispatch)
Actions: Reusable units of code (like checkout@v4)

## Task 2
Main changes are: 

 - Add new job to show system information
 - Add new trigger to run workflow manually

[Link to manuall run](https://github.com/ghshark63/DevOps-Intro/actions/runs/22194162804)

Small snippet of system info:

```
Run echo "Operating System Details"
Operating System Details
===========================
OS Release:
PRETTY_NAME="Ubuntu 24.04.3 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.3 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo

Kernel Version:
Linux runnervmieams 6.14.0-1017-azure #17~24.04.1-Ubuntu SMP Mon Dec  1 20:10:50 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux

Hostname: runnervmieams

Run echo "CPU Information"
CPU Information
=================
CPU Model:
model name	: AMD EPYC 7763 64-Core Processor
Number of CPU cores: 4

CPU Architecture:
Architecture:                            x86_64

CPU Details:
CPU(s):                                  4
On-line CPU(s) list:                     0-3
Model name:                              AMD EPYC 7763 64-Core Processor
Thread(s) per core:                      2
Core(s) per socket:                      2
Socket(s):                               1
NUMA node0 CPU(s):                       0-3
```


Key Observations:
- GitHub-hosted runners are ephemeral (fresh for each job)
- Runners have limited but sufficient resources for CI/CD tasks
- The environment is clean with minimal pre-installed software
- Runners are optimized for quick job execution
- No persistent state between runs
