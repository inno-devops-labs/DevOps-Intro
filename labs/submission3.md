# TASK 1

1. I have copy-pasted the demo workflow to `.github/actions/github-actions-demo.yml`, commited and pushed to the lab branch.

Run Link: https://github.com/sasaSilver/DevOps-Intro/actions/runs/22117120284/job/63927977686

I have learned:
- A job is basically a scheduled process to run on some event in a repository.
- A step is a __job step__, meant to represent a single unit of work that the job does.
- A runner is the machine that runs the job
- Trigger is the event that __triggers__ the runner to pick up and start a job

The run was triggered by a push to my repo's branch, as specified in the worklow's `.yml` file.

The job echoed some strings, checked out the code, and listed files in the repo.

# TASK 2

I added a new workflow file instead, `.github/worfklows/manual-action.yml`.

First, it only accepted an input to echo `"Hello, ${{ inputs.name }}!"`, then i added a step to collect system info:

```
--- OS info ---
Distributor ID:	Ubuntu
Description:	Ubuntu 24.04.3 LTS
Release:	24.04
Codename:	noble
--- CPU info ---
Model name:                              Intel(R) Xeon(R) Platinum 8370C CPU @ 2.80GHz
--- Memory info ---
               total        used        free      shared  buff/cache   available
Mem:            15Gi       1.2Gi        12Gi        36Mi       1.8Gi        14Gi
Swap:          3.0Gi          0B       3.0Gi
--- Disk info ---
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       145G   53G   92G  37% /
```

Run Link: https://github.com/sasaSilver/DevOps-Intro/actions/runs/22117838007/job/63930392605

I think manual and automatic triggers are different by __what triggers them__. I triggered the manual one through Github UI, and the automatic one happenned after a push to remote.

This runner is running on Ubuntu 24.04 LTS (Noble) with nice resources including a high-performance Intel Xeon Platinum 8370C CPU, 15GB of RAM, and 145GB of storage, making it well-suited for heavy CI/CD workloads. The environment shows low current utilization with 12GB free memory and 92GB available disk space, indicating it can handle resource-intensive build and test operations efficiently.
