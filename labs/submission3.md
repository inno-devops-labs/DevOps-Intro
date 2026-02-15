# Lab 3 Submission

## Task 1 - First GitHub Actions Workflow

### Link to the successful run 

#### Screenshot
![Successful run](screenshots/screenshot1.png)

#### Link
https://github.com/GreatDruk/DevOps-Intro/actions/runs/22039687305/job/63678443376


### Key concepts learned
`Jobs` - a set of steps that run together on the same machine (runner) inside a workflow. Jobs can run in parallel by default, but you can also configure them to run in a specific order.

`Steps` - individual actions inside a job, like running a command or using an action. They execute one by one and share the same environment.

`Runners` - machine where jobs run. It can be a GitHub-hosted virtual machine (Ubuntu, Windows, macOS) or your own server.

`Triggers` - events that start a workflow. For example: push, pull request, schedule, or manual dispatch. They determine when the automation runs.


### What caused the run to trigger
The workflow was triggered automatically by a push event because the workflow configuration includes `on: [push]`. Any commit pushed to any branch starts the workflow, which then runs the job on a GitHub-hosted Ubuntu runner.


### Analysis of workflow execution process
1. **Trigger Activation (`on: [push]`)**  
   Whenever a push happens, GitHub automatically starts a new workflow run. The run is labeled with the workflow name and shows the user who pushed the changes.

2. **Job Queuing and Runner Provisioning**  
   The workflow has one job, `Explore-GitHub-Actions`, set to run on ubuntu-latest. GitHub provisions a virtual Ubuntu machine and prepares the workspace for the job.
3. **Sequential Step Execution**  
   All steps run sequentially on the same runner, using the same environment and filesystem.

4. **Step Details:**  
   - `echo` commands print info about the triggering event (`push`), the runner OS, branch name, and repository.
   - `actions/checkout@v5` clones the repository so following steps can access the code.
   - Additional `echo` commands provide status messages.
   - `ls ${{ github.workspace }}` lists the repository files to confirm checkout success.
   - The last step prints the job status (usually `success` if no errors occurred).

5. **Completion and Result**  
   If all steps finish successfully (exit code 0), the job and workflow are marked as successful. If any step fails, the job stops, and the workflow run is marked as failed.


## Task 2 - Manual Trigger + System Information

### Changes Made to the Workflow File

Added `workflow_dispatch` trigger to the workflow file:

```yaml
on: [push, workflow_dispatch]
```

The workflow was triggered manually via the Actions tab using the `Run workflow` button.

![Manual workflow trigger](screenshots/screenshot2.png)

**Link**: https://github.com/GreatDruk/DevOps-Intro/actions/runs/22041227548/job/63682377149

Added a `System Information` step to the workflow:

```yaml
- name: System Information
    run: |
        echo "OS Information"
        uname -a

        echo "Memory Info"
        free -h

        echo "Disk Space"
        df -h

        echo "CPU Cores"
        nproc

        echo "CPU Info"
        cat /proc/cpuinfo | head -20
```

**Link**: https://github.com/GreatDruk/DevOps-Intro/actions/runs/22041476967/job/63683031462


### The gathered system information from runner

```
OS Information
Linux runnervmjduv7 6.14.0-1017-azure #17~24.04.1-Ubuntu SMP Mon Dec  1 20:10:50 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
Memory Info
               total        used        free      shared  buff/cache   available
Mem:            15Gi       871Mi        13Gi        40Mi       1.8Gi        14Gi
Swap:          3.0Gi          0B       3.0Gi
Disk Space
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       145G   53G   92G  37% /
tmpfs           7.9G   84K  7.9G   1% /dev/shm
tmpfs           3.2G  1.0M  3.2G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
efivarfs        128M   32K  128M   1% /sys/firmware/efi/efivars
/dev/sda16      881M   63M  757M   8% /boot
/dev/sda15      105M  6.2M   99M   6% /boot/efi
tmpfs           1.6G   12K  1.6G   1% /run/user/1001
CPU Cores
4
CPU Info
processor	: 0
vendor_id	: GenuineIntel
cpu family	: 6
model		: 106
model name	: Intel(R) Xeon(R) Platinum 8370C CPU @ 2.80GHz
stepping	: 6
microcode	: 0xffffffff
cpu MHz		: 3491.797
cache size	: 49152 KB
physical id	: 0
siblings	: 4
core id		: 0
cpu cores	: 2
apicid		: 0
initial apicid	: 0
fpu		: yes
fpu_exception	: yes
cpuid level	: 27
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx pdpe1gb rdtscp lm constant_tsc rep_good nopl xtopology tsc_reliable nonstop_tsc cpuid aperfmperf tsc_known_freq pni pclmulqdq vmx ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch tpr_shadow ept vpid ept_ad fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm avx512f avx512dq rdseed adx smap avx512ifma clflushopt clwb avx512cd sha_ni avx512bw avx512vl xsaveopt xsavec xgetbv1 xsaves vnmi avx512vbmi umip avx512_vbmi2 gfni vaes vpclmulqdq avx512_vnni avx512_bitalg avx512_vpopcntdq la57 rdpid fsrm arch_capabilities
```


### Comparison of manual vs automatic workflow triggers

#### Automatic Trigger

The workflow runs automatically every time changes are pushed to the repository. This supports continuous integration by providing immediate feedback after each commit. It requires no user interaction and ensures that the code is tested or validated consistently.

* Starts automatically on every push
* Used for continuous integration
* `github.event_name` is `push`
* The branch is determined by where the push occurred
* Can run frequently if many commits are made

#### Manual Trigger

The workflow is started manually by a user from the GitHub Actions tab. It is useful for controlled or on-demand tasks such as debugging, maintenance, or deployments.

* Started manually from the Actions tab
* Used for on-demand execution
* `github.event_name` is `workflow_dispatch`
* The branch is selected manually in the interface
* Runs only when explicitly triggered


### Analysis of runner environment and capabilities
The workflow runs on a GitHub-hosted `ubuntu-latest` runner, which is a temporary virtual machine created for each workflow run.

#### Environment Overview

* `OS`: Linux (Ubuntu 24.04 on Azure, kernel 6.14.0-1017-azure, x86_64)
* `CPU`: Intel Xeon Platinum 8370C @ 2.80GHz
* `CPU Cores`: 4 vCPUs
* `RAM`: 15 GB total (~14 GB available)
* `Disk`: 145 GB total, 92 GB free
* `Swap`: 3 GB

The runner is hosted on Azure infrastructure and provides a modern 64-bit Linux environment.

#### Capabilities

* Full Linux shell access
* Multiple CPU cores suitable for parallel builds
* Sufficient RAM for compiling and testing medium-sized projects
* Large disk space for dependencies and build artifacts
* Internet access for downloading packages
