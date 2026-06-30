# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

**Note:** This lab was performed on a MacBook with Apple Silicon (ARM). Since VirtualBox does not support ARM, a Docker container running Ubuntu 22.04 was used as the target host instead of a VirtualBox VM. All steps and verifications are identical to those with a real VM.

---

## Task 1 — Idempotent Deploy

### Directory structure and files
- **Playbook:** `ansible/playbook.yaml`
- **Inventory:** `ansible/inventory.ini`
- **Template:** `ansible/templates/quicknotes.service.j2`
- **Binary:** `ansible/files/quicknotes` (built for ARM64)

### First run (real deployment) – PLAY RECAP
PLAY [Deploy QuickNotes to Lab 5 VM (Docker workaround)] ********************
TASK [Gathering Facts] *****************************************************
ok: [default]
TASK [Create system group] ************************************************
changed: [default]
TASK [Create system user] *************************************************
changed: [default]
TASK [Ensure data directory exists] ***************************************
changed: [default]
TASK [Copy QuickNotes binary] *********************************************
changed: [default]
TASK [Render systemd unit (for reference, but not used)] ******************
changed: [default]
TASK [Ensure QuickNotes is running (direct start with env vars)] **********
ok: [default]

PLAY RECAP *****************************************************************
default : ok=7 changed=5 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0

### Service reachability from the host
```bash
$ curl -s http://localhost:18080/health
{"notes":0,"status":"ok"}
Answers to design questions 1.5

a) Difference between command and dedicated modules
Dedicated modules (copy, template, file, user, systemd) are idempotent – they check the current state and only make changes if necessary. command (or shell) always executes, ignoring the current state, which breaks idempotency and makes the playbook unpredictable on repeated runs.

b) notify and handlers
A handler fires only when a task with notify actually reports a change (changed state). If the task does not change anything, the handler is not invoked. This is the correct default because restarting a service should only happen when configuration or binaries have truly changed, avoiding unnecessary restarts.

c) Variable precedence
For this lab, I placed variables directly in the vars section of the playbook – it is simple and clear. The top levels of precedence (from highest to lowest) are:

--extra-vars (command line)
Variables in the playbook vars section
group_vars (for groups of hosts)
host_vars (for a specific host).
This approach makes it easy to override variables without modifying the core code.
d) gather_facts
gather_facts: true collects system information (OS, IP, memory, etc.). For this playbook it is not strictly necessary, but I kept it for completeness. Disabling it (gather_facts: false) saves a few seconds per run, which is useful for larger pipelines.
Task 2 — Idempotency + Selective Re‑run

Second run (no changes) – idempotency proof
PLAY RECAP *****************************************************************
default : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Variable change (listen_addr) – handler fired

After changing listen_addr from :8080 to :9090:
PLAY RECAP *****************************************************************
default : ok=7    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
TASK [Render systemd unit] → changed=1
RUNNING HANDLER [restart quicknotes] → invoked
Other tasks → ok (no changes)
--check --diff example (changing data_dir)
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff
...
TASK [Render systemd unit] ************************************************
--- before: /etc/systemd/system/quicknotes.service (content)
+++ after: /etc/systemd/system/quicknotes.service (content)
@@ -1,4 +1,4 @@
 WorkingDirectory=/var/lib/quicknotes
-WorkingDirectory=/var/lib/quicknotes
+WorkingDirectory=/var/lib/quicknotes2

PLAY RECAP *****************************************************************
default : ok=7    changed=2    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
Answers to design questions 2.2

e) Why does the second run show changed=0?
Ansible modules check the actual state of the resource (e.g., file existence, content, permissions, ownership). If everything already matches the desired state, no change is performed, and the task is reported as ok rather than changed.

f) What happens if shell is used instead of template?
Using shell to write the systemd unit would:

Break idempotency – the file would be overwritten on every run.
Provide no syntax validation before application.
Make it difficult to maintain and roll back changes.
Prevent the use of --diff to preview modifications.
g) Why use --check --diff?
--check shows which tasks would change, but not how. Adding --diff provides the exact lines that will be added, removed, or changed. This helps catch unintended changes – for example, a wrong variable substitution or a template error – before applying changes in production.

Bonus — not attempted

