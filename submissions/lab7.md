# Lab 7 submission
### Ansible configuration
[`playbook.yaml`](../ansible/playbook.yaml)\
[`inventory.yaml`](../ansible/inventory.yaml)\
[`quicknotes.service.j2`](../ansible/templates/quicknotes.service.j2)

### Play recap
```sh
$ ansible-playbook -i inventory.yaml playbook.yaml

PLAY [Deploy QuickNotes] *****************************************************************************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************************************************************************************
[WARNING]: Host 'qn_host_01' is using the discovered Python interpreter at '/usr/bin/python3.10', but future installation of another Python interpreter could cause a different interpreter to be discovered. See https://docs.ansible.com/ansible-core/2.21/reference_appendices/interpreter_discovery.html for more information.
ok: [qn_host_01]

TASK [Create group] **********************************************************************************************************************************************************************
changed: [qn_host_01]

TASK [Create user] ***********************************************************************************************************************************************************************
changed: [qn_host_01]

TASK [Create data directory] *************************************************************************************************************************************************************
changed: [qn_host_01]

TASK [Install QuickNotes binary] *********************************************************************************************************************************************************
changed: [qn_host_01]

TASK [Render systemd unit] ***************************************************************************************************************************************************************
changed: [qn_host_01]

TASK [Start QuickNotes unit] *************************************************************************************************************************************************************
changed: [qn_host_01]

RUNNING HANDLER [Restart QuickNotes Service] *********************************************************************************************************************************************
changed: [qn_host_01]

PLAY RECAP *******************************************************************************************************************************************************************************
qn_host_01                 : ok=8    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Health check
```sh
$ curl -S http://localhost:18080/health
{"notes":0,"status":"ok"}
```

### Idempotency proof
```sh
$ ansible-playbook -i inventory.yaml playbook.yaml
...
PLAY RECAP *******************************************************************************************************************************************************************************
qn_host_01                 : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
```

### Variable change
```sh
$ ansible-playbook -i inventory.yaml playbook.yaml

PLAY [Deploy QuickNotes] *****************************************************************************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************************************************************************************
[WARNING]: Host 'qn_host_01' is using the discovered Python interpreter at '/usr/bin/python3.10', but future installation of another Python interpreter could cause a different interpreter to be discovered. See https://docs.ansible.com/ansible-core/2.21/reference_appendices/interpreter_discovery.html for more information.
ok: [qn_host_01]

TASK [Create group] **********************************************************************************************************************************************************************
ok: [qn_host_01]

TASK [Create user] ***********************************************************************************************************************************************************************
ok: [qn_host_01]

TASK [Create data directory] *************************************************************************************************************************************************************
ok: [qn_host_01]

TASK [Install QuickNotes binary] *********************************************************************************************************************************************************
ok: [qn_host_01]

TASK [Render systemd unit] ***************************************************************************************************************************************************************
changed: [qn_host_01]

TASK [Start QuickNotes unit] *************************************************************************************************************************************************************
ok: [qn_host_01]

RUNNING HANDLER [Restart QuickNotes Service] *********************************************************************************************************************************************
changed: [qn_host_01]

PLAY RECAP *******************************************************************************************************************************************************************************
qn_host_01                 : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

### Variable change with diff
```sh
$ ansible-playbook -i inventory.yaml playbook.yaml --check --diff

PLAY [Deploy QuickNotes] *****************************************************************************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************************************************************************************
[WARNING]: Host 'qn_host_01' is using the discovered Python interpreter at '/usr/bin/python3.10', but future installation of another Python interpreter could cause a different interpreter to be discovered. See https://docs.ansible.com/ansible-core/2.21/reference_appendices/interpreter_discovery.html for more information.
ok: [qn_host_01]

TASK [Create group] **********************************************************************************************************************************************************************
ok: [qn_host_01]

TASK [Create user] ***********************************************************************************************************************************************************************
ok: [qn_host_01]

TASK [Create data directory] *************************************************************************************************************************************************************
ok: [qn_host_01]

TASK [Install QuickNotes binary] *********************************************************************************************************************************************************
ok: [qn_host_01]

TASK [Render systemd unit] ***************************************************************************************************************************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/arsenez/.ansible/tmp/ansible-local-4536393z7uka5/tmpvsfobhl_/quicknotes.service.j2
@@ -12,7 +12,7 @@
 Restart=on-failure
 RestartSec=5s
 
-Environment="ADDR=:9090"
+Environment="ADDR=:8080"
 Environment="DATA_PATH=/var/lib/quicknotes/data"
 Environment="SEED_PATH=/var/lib/quicknotes/seed.json"
 

changed: [qn_host_01]

TASK [Start QuickNotes unit] *************************************************************************************************************************************************************
ok: [qn_host_01]

RUNNING HANDLER [Restart QuickNotes Service] *********************************************************************************************************************************************
changed: [qn_host_01]

PLAY RECAP *******************************************************************************************************************************************************************************
qn_host_01                 : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Design questions
a) The `command:` module blindly executes CLI commands and almost always reports a status of `changed`. Dedicated modules (like `file` or `copy`) are declarative and idempotent, meaning they check the current state of the system first and only make changes if the actual state differs from the desired state. This ensures that running the playbook multiple times is safe and won't disrupt an already properly configured system.\
b) A handler fires at the end of the play only if the task that notified it reported a `changed` status. It does not fire if the task returns an `ok` status, indicating that no modifications were needed. This is the correct default behavior because restarting services causes unnecessary downtime and resource usage if the underlying binary or configuration hasn't changed.\
c) 
1. `defaults/` inside a role to set baseline paths or values that can be easily overridden by users.
2. `group_vars/` to store environment-specific configurations like application ports and listen addresses.
3. `playbook vars` to explicitly define constants required specifically by this deployment scenario.

d) No, this playbook does not require facts because it does not rely on target system variables like OS architecture or network interface details. Turning gather_facts off saves several seconds per execution by skipping the SSH invocation of the setup module on the managed host.\
e) The second run reports `changed=0` because the target environment already matches the desired state declared in the playbook. The `file` module verifies the directory's existence, owner, group, and permissions mask, while the `template` module computes a checksum of the rendered file and compares it to the hash of the existing file on the VM.\
f) Using a `shell` command would overwrite the file and return `changed=1` on every single run, completely breaking idempotency. This would trigger the systemd restart handler on every execution, causing unnecessary service downtime and reloading systemd daemons even when no configuration changes actually occurred. \
g) `ansible-playbook --check` is dry-run. `--diff` shows changes. What's the bug you'd catch by running `--check --diff` before a production deploy that you'd miss with plain --check? A plain `--check` only tells you if a file will change, but `--diff` shows you exactly what lines will be modified, added, or deleted. Running with `--diff` allows you to catch destructive typos, unintended variable overrides, or configuration truncations before they are deployed to production.