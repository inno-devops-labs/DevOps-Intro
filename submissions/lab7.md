# Lab 7 submission

`playbook.yaml'

```
---
- hosts: vagrant
  become: true

  vars:
    addr: ":8080"
    data_dir: "/var/lib/quicknotes"
    bin: "/usr/local/bin/quicknotes"
    data_path: "/var/lib/quicknotes"
    seed_path: "/var/lib/quicknotes/seed.json"

  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted

  tasks:

    - name: Create user
      ansible.builtin.user:
        name: quicknotes
        shell: /usr/sbin/nologin
        system: true

    - name: Create data directory
      ansible.builtin.file:
        path: /var/lib/quicknotes
        state: directory
        owner: quicknotes
        group: quicknotes
        mode: "0750"

    - name: Copy binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: /usr/local/bin/quicknotes
        owner: root
        group: root
        mode: "0755"
      notify: restart quicknotes

    - name: Deploy service file
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
      notify: restart quicknotes

    - name: Reload systemd
      ansible.builtin.systemd:
        daemon_reload: true

    - name: Enable service
      ansible.builtin.systemd:
        name: quicknotes
        enabled: true

    - name: Start service
      ansible.builtin.systemd:
        name: quicknotes
        state: started
```

`inventory.ini`

```
[vagrant]
labvm ansible_host=127.0.0.1

[vagrant:vars]
ansible_user=vagrant
ansible_port=2222
ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key
```

```
PLAY [vagrant] *************************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************************
ok: [labvm]

TASK [Create user] *********************************************************************************************************************
changed: [labvm]

TASK [Create data directory] ***********************************************************************************************************
changed: [labvm]

TASK [Copy binary] *********************************************************************************************************************
changed: [labvm]

TASK [Deploy service file] *************************************************************************************************************
changed: [labvm]

TASK [Reload systemd] ******************************************************************************************************************
ok: [labvm]

TASK [Enable service] ******************************************************************************************************************
changed: [labvm]

TASK [Start service] *******************************************************************************************************************
changed: [labvm]

RUNNING HANDLER [restart quicknotes] ***************************************************************************************************
changed: [labvm]

PLAY RECAP *****************************************************************************************************************************
labvm                      : ok=9    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

```
curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

```
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [vagrant] **************************************************************************************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************************************************************************
ok: [labvm]

TASK [Create user] **********************************************************************************************************************************************************************
ok: [labvm]

TASK [Create data directory] ************************************************************************************************************************************************************
ok: [labvm]

TASK [Copy binary] **********************************************************************************************************************************************************************
ok: [labvm]

TASK [Deploy service file] **************************************************************************************************************************************************************
ok: [labvm]

TASK [Reload systemd] *******************************************************************************************************************************************************************
ok: [labvm]

TASK [Enable service] *******************************************************************************************************************************************************************
ok: [labvm]

TASK [Start service] ********************************************************************************************************************************************************************
ok: [labvm]

PLAY RECAP ******************************************************************************************************************************************************************************
labvm                      : ok=8    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
```

- a. Command just runs a shell command and usually cannot determine the desired state. Dedicated modules are idempotent: they check the current state and only make changes when needed.

- b. handler runs only if change is detected. It is good, because service won't rerun without need and playbook runs faster

- c. For this lab:

  - group_vars/ — environment-specific settings (dev, staging, prod).
  - Role defaults/ — sensible default values that can be overridden.
  - Playbook vars: — values tightly coupled to this specific playbook.

This keeps configuration separate from automation logic.

- d. No. This playbook does not use any ansible_* facts. I can set `gather_facts: false` and it will skips the setup task, reducing SSH traffic and saving roughly a few hundred milliseconds to a couple of seconds per host per run.