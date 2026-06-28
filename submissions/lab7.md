 # Task 1

## Design questions:

a. **What's the difference between `command:` and the dedicated modules** (`apt`, `file`, `copy`, `systemd`)? Which is idempotent, and why does it matter?

Answer: 
When Ansible runs `command`, it runs raw shell command. It does not know what it produces and what to expect from it. Therefore, it cannot be stated as idempotent in theory since it's impossible to check. Meanwhile, dedicated modules provided by Ansible know what to expect from each command and therefore can state if command is idempotent or not.


### `apt`
command: apt install nginx - not idempotent since Ansible will always run it
apt: name=nginx state=present - can be idempotent if nginx is already installed, Ansible will check it

### `mkdir`
command: mkdir /something - not idempotent since Ansible will always run it

```
file:
    path=/something
    state=directory
``` 
can be idempotent if /something is already there, Ansible will check it

### `copy`

command: copy a b - not idempotent since Ansible will always run itb

```
copy:
    src=a
    dest=b
```
can be idempotent if a and b have same hashsums, Ansible will check it

### `systemd`

command: systemctl start coolservice - not idempotent since Ansible will always run itb

```
systemd:
    name: coolservice
    state: started
```
can be idempotent if coolservice is already started

b. **`notify:` and handlers:** when does a handler fire? When does it *not* fire? Why is that the right default?

A handler fires when both:
1. Task which has `notify: <handler_name>` reports "changed".
2. All tasks are completed successfully.

A handler does not fire on:
1. No tasks that reported "changed"
2. Some tasks failed
3. Handler does not fire twice if two or more tasks notified it.

c. **Variable hierarchy:** Ansible has at least 22 levels of variable precedence. List the top 3 places you'd put a variable for this lab (defaults, group_vars, playbook vars, …) and why

1. vars - good for lab-specific tasks. It's simple to use and change.
2. group_vars - good for environment-specific variables.
3. defaults - good for having a default values that can be overwritten.

d. **`gather_facts: true` is the default.** Do you need it for *this* playbook? What does turning it off save you per run?

In this playbook it's not needed since we do not use any fact. All values are hardcoded variables. Turning it off can save me 2-5 since there is not any gathering.

## Full recap

Input: `ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check`

Output:
```
[WARNING]: Invalid characters were found in group names but not replaced, use -vvvv to see details

PLAY [Install and run QuickNotes] ******************************************************************************************************

TASK [Create system user] **************************************************************************************************************
[WARNING]: Platform linux on host qn-vm-1 is using the discovered Python interpreter at /usr/bin/python3.10, but future installation of
another Python interpreter could change the meaning of that path. See https://docs.ansible.com/ansible-
core/2.18/reference_appendices/interpreter_discovery.html for more information.
changed: [qn-vm-1]

TASK [Configure QuickNotes data directory] *********************************************************************************************
[WARNING]: failed to look up user quicknotes. Create user up to this point in real play
[WARNING]: failed to look up group quicknotes. Create group up to this point in real play
changed: [qn-vm-1]

TASK [Copy QuickNotes binary] **********************************************************************************************************
changed: [qn-vm-1]

TASK [Render QuickNotes systemd unit] **************************************************************************************************
changed: [qn-vm-1]

TASK [Enable and start QuickNotes systemd unit] ****************************************************************************************
fatal: [qn-vm-1]: FAILED! => {"changed": false, "msg": "Could not find the requested service quicknotes: host"}

PLAY RECAP *****************************************************************************************************************************
qn-vm-1                    : ok=4    changed=4    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
```

Input: `ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml`

Output:

```
[WARNING]: Invalid characters were found in group names but not replaced, use -vvvv to see details

PLAY [Install and run QuickNotes] ******************************************************************************************************

TASK [Create system user] **************************************************************************************************************
[WARNING]: Platform linux on host qn-vm-1 is using the discovered Python interpreter at /usr/bin/python3.10, but future installation of
another Python interpreter could change the meaning of that path. See https://docs.ansible.com/ansible-
core/2.18/reference_appendices/interpreter_discovery.html for more information.
changed: [qn-vm-1]

TASK [Configure QuickNotes data directory] *********************************************************************************************
changed: [qn-vm-1]

TASK [Copy QuickNotes binary] **********************************************************************************************************
changed: [qn-vm-1]

TASK [Render QuickNotes systemd unit] **************************************************************************************************
changed: [qn-vm-1]

TASK [Enable and start QuickNotes systemd unit] ****************************************************************************************
changed: [qn-vm-1]

RUNNING HANDLER [Reload systemd] *******************************************************************************************************
ok: [qn-vm-1]

RUNNING HANDLER [Restart QuickNotes] ***************************************************************************************************
changed: [qn-vm-1]

PLAY RECAP *****************************************************************************************************************************
qn-vm-1                    : ok=7    changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Input: `curl -s http://localhost:18080/health`

Output:

```
{"notes":0,"status":"ok"}
```

# Task 2 

First run:

Input: `ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml`

Output:

```
[WARNING]: Invalid characters were found in group names but not replaced, use -vvvv to see details

PLAY [Install and run QuickNotes] ********************************************************************************************************

TASK [Create system user] ****************************************************************************************************************
[WARNING]: Platform linux on host qn-vm-1 is using the discovered Python interpreter at /usr/bin/python3.10, but future installation of
another Python interpreter could change the meaning of that path. See https://docs.ansible.com/ansible-
core/2.18/reference_appendices/interpreter_discovery.html for more information.
ok: [qn-vm-1]

TASK [Configure QuickNotes data directory] ***********************************************************************************************
ok: [qn-vm-1]

TASK [Copy QuickNotes binary] ************************************************************************************************************
ok: [qn-vm-1]

TASK [Render QuickNotes systemd unit] ****************************************************************************************************
ok: [qn-vm-1]

TASK [Enable and start QuickNotes systemd unit] ******************************************************************************************
ok: [qn-vm-1]

PLAY RECAP *******************************************************************************************************************************
qn-vm-1                    : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Input after change: `ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml`

Output:

```
[WARNING]: Invalid characters were found in group names but not replaced, use -vvvv to see details

PLAY [Install and run QuickNotes] ********************************************************************************************************

TASK [Create system user] ****************************************************************************************************************
[WARNING]: Platform linux on host qn-vm-1 is using the discovered Python interpreter at /usr/bin/python3.10, but future installation of
another Python interpreter could change the meaning of that path. See https://docs.ansible.com/ansible-
core/2.18/reference_appendices/interpreter_discovery.html for more information.
ok: [qn-vm-1]

TASK [Configure QuickNotes data directory] ***********************************************************************************************
ok: [qn-vm-1]

TASK [Copy QuickNotes binary] ************************************************************************************************************
ok: [qn-vm-1]

TASK [Render QuickNotes systemd unit] ****************************************************************************************************
changed: [qn-vm-1]

TASK [Enable and start QuickNotes systemd unit] ******************************************************************************************
ok: [qn-vm-1]

RUNNING HANDLER [Reload systemd] *********************************************************************************************************
ok: [qn-vm-1]

RUNNING HANDLER [Restart QuickNotes] *****************************************************************************************************
changed: [qn-vm-1]

PLAY RECAP *******************************************************************************************************************************
qn-vm-1                    : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Input after second change: `ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff >> submissions/lab7.md`

Output:
```
PLAY [Install and run QuickNotes] **********************************************

TASK [Create system user] ******************************************************
ok: [qn-vm-1]

TASK [Configure QuickNotes data directory] *************************************
ok: [qn-vm-1]

TASK [Copy QuickNotes binary] **************************************************
ok: [qn-vm-1]

TASK [Render QuickNotes systemd unit] ******************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /Users/ilnarkhasanov/.ansible/tmp/ansible-local-921277wh0fteb/tmp5fubg_i_/quicknotes.service.j2
@@ -5,7 +5,7 @@
 [Service]
 User=quicknotes
 WorkingDirectory=/var/lib/quicknotes
-Environment=ADDR=:9090
+Environment=ADDR=:9091
 Environment=DATA_PATH=/var/lib/quicknotes/data.json
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
 ExecStart=/usr/local/bin/quicknotes

changed: [qn-vm-1]

TASK [Enable and start QuickNotes systemd unit] ********************************
ok: [qn-vm-1]

RUNNING HANDLER [Reload systemd] ***********************************************
ok: [qn-vm-1]

RUNNING HANDLER [Restart QuickNotes] *******************************************
changed: [qn-vm-1]

PLAY RECAP *********************************************************************
qn-vm-1                    : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

## Design questions

e) Why does the second run report changed=0? What specifically does file / template check?

Each module checks current state against desired state before acting:

- file — checks path exists, owner, group, and mode match. If all match → ok
- copy — computes MD5/SHA1 checksum of source and destination. If identical → ok
- template — renders the template in memory, then compares the result to the file on disk (checksum). If identical → ok
- user — checks if user exists with matching uid, shell, groups. If matches → ok
- systemd — checks if service is active and enabled. If already both → ok

Nothing changed between runs, so every module finds the system already in the desired state → changed=0 → no handlers fire → no restart.

---
f) What would happen if you used shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'?

Multiple failure modes:

1. Always changed=1 — shell: has no idea what the file contains before running. It overwrites every time, so the handler fires every run, restarting the service unnecessarily
2. Kills idempotency — changed=0 on second run becomes impossible. You can never prove the system is in the desired state
3. No diff support — --check --diff can't show you what would change because shell: doesn't know what it's about to write
4. Error-prone templating — manually echoing a multi-line systemd unit with correct escaping, quoting, and newlines in a shell command is fragile and hard to read
5. No variable substitution safety — if a variable contains special shell characters, it can break the echo or worse cause command injection

---
g) What bug does --check --diff catch that plain --check misses?

--check only tells you whether something would change — yes or no.

--diff shows you what would change — the actual before/after content.

Example: you change listen_addr from :8080 to :9090. Plain --check tells you:
template: changed

With --diff you see:
- Environment=ADDR=:8080
+ Environment=ADDR=:9090

The bug you'd catch: a variable substitution that went wrong. For example, if listen_addr was accidentally set to an empty string, --check still reports changed (file differs), but --diff shows you:
- Environment=ADDR=:8080
+ Environment=ADDR=

You'd catch a misconfigured or missing variable before it ever hits production — something --check alone would never reveal.

