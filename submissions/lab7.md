# Lab 7 — Configuration Management (Ansible)

The playbook deploys QuickNotes as a systemd service: a system user, a data dir, the binary,
a templated unit, and a handler that restarts only when the binary or unit changes.

> Note on the target: Lab 5's deploy target was a Vagrant VirtualBox VM, but VirtualBox can't run
> on this Apple Silicon host. So the target here is a **systemd-enabled Ubuntu 24.04 container**
> reached over Ansible's docker connection. Everything the playbook does is identical to a VM —
> system user, systemd unit, handlers, idempotency. The container publishes its `8080` to the
> host's `18080`, so `curl :18080` works exactly like the Vagrant port-forward. The inventory file
> shows the equivalent Vagrant SSH inventory in a comment.

## Task 1 — Idempotent deploy

### Layout

```
ansible/
├── inventory.ini
├── playbook.yaml
├── files/quicknotes          (static linux/arm64 binary, CGO_ENABLED=0)
├── files/seed.json
└── templates/quicknotes.service.j2
```

### playbook.yaml

```yaml
- name: Deploy QuickNotes
  hosts: quicknotes_vm
  become: true
  gather_facts: false
  vars:
    qn_user: quicknotes
    qn_bin: /usr/local/bin/quicknotes
    qn_data_dir: /var/lib/quicknotes
    listen_addr: ":8080"
    data_path: /var/lib/quicknotes/notes.json
    seed_path: /var/lib/quicknotes/seed.json
  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd_service:
        name: quicknotes
        state: restarted
        daemon_reload: true
  tasks:
    - name: Create the quicknotes system user
      ansible.builtin.user:
        name: "{{ qn_user }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false
    - name: Ensure the data directory exists
      ansible.builtin.file:
        path: "{{ qn_data_dir }}"
        state: directory
        owner: "{{ qn_user }}"
        group: "{{ qn_user }}"
        mode: "0750"
    - name: Ship the QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ qn_bin }}"
        mode: "0755"
      notify: restart quicknotes
    - name: Ship the seed data
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ seed_path }}"
        owner: "{{ qn_user }}"
        group: "{{ qn_user }}"
        mode: "0644"
    - name: Render the systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        mode: "0644"
      notify: restart quicknotes
    - name: Enable and start QuickNotes
      ansible.builtin.systemd_service:
        name: quicknotes
        enabled: true
        state: started
        daemon_reload: true
```

The template (`quicknotes.service.j2`) renders to a unit that starts after `network-online.target`,
runs as the `quicknotes` user, sets `ADDR`/`DATA_PATH`/`SEED_PATH` from variables, sets
`WorkingDirectory` to the data dir, and restarts on failure.

### First run (PLAY RECAP)

```text
TASK [Create the quicknotes system user] ... changed
TASK [Ensure the data directory exists]   ... changed
TASK [Ship the QuickNotes binary]         ... changed
TASK [Ship the seed data]                 ... changed
TASK [Render the systemd unit]            ... changed
TASK [Enable and start QuickNotes]        ... changed
RUNNING HANDLER [restart quicknotes]      ... changed

PLAY RECAP
lab7vm : ok=7  changed=7  unreachable=0  failed=0
```

### It's running and reachable

```text
$ docker exec lab7vm systemctl is-active quicknotes
active   (MainPID=679, User=quicknotes)

$ curl -s http://localhost:18080/health      # from the host, via the published port
{"notes":4,"status":"ok"}
```

### Design questions

**a) `command:` vs dedicated modules — which is idempotent and why it matters?**
`command:`/`shell:` just run a command every time; Ansible can't tell whether anything actually
changed, so it reports `changed` every run (unless you hand-write `creates:`/`changed_when:`). The
dedicated modules are declarative and idempotent: `copy`/`template` compare the content checksum
(plus owner/group/mode), `file` checks the path's state, `systemd` checks enabled/active — and they
only act when reality differs from the desired state. That matters because re-running has to be safe
and the `changed` count has to be honest; with `shell:` you'd restart the service on every run and
never know if anything really changed.

**b) When does a handler fire, and when not?**
A handler fires only if a task that `notify`s it reports `changed`. It runs once, at the **end** of
the play, even if several tasks notified it. It does **not** fire when the notifying task is `ok`
(no change). That's the right default because you only want to restart QuickNotes when its binary or
unit file actually changed — not on every harmless re-run.

**c) Variable hierarchy — top 3 places for this lab?**
From most-overridable to most-specific: (1) **role/play defaults** — sane baselines like
`listen_addr: ":8080"`; (2) **`group_vars/quicknotes_vm`** — values that belong to this host group
(e.g. per-environment paths); (3) **playbook `vars:`** — play-scoped values. `-e` extra-vars sit
above all of them for one-off overrides (I used `-e listen_addr=...` for the Task 2 demo). I kept
the vars in the playbook here for simplicity; in a bigger setup they'd live in `group_vars`.

**d) Do you need `gather_facts`?**
No — this play uses no `ansible_*` facts. I set `gather_facts: false`, which skips the `setup`
module on the target every run. That saves the fact-collection round-trip (one less remote Python
execution per run) — small here, but free.

## Task 2 — Idempotency + selective re-run

### Second run = `changed=0`

```text
PLAY RECAP
lab7vm : ok=6  changed=0  unreachable=0  failed=0
```

Every task reported `ok`; the handler didn't fire.

### Change one variable → only the template changes

`-e listen_addr=:9090`:

```text
TASK [Render the systemd unit]       ... changed
TASK [Enable and start QuickNotes]   ... ok
RUNNING HANDLER [restart quicknotes] ... changed

PLAY RECAP
lab7vm : ok=7  changed=2   (template + restart handler; everything else ok)
```

### `--check --diff` preview (third change, `:7070`)

```text
TASK [Render the systemd unit]
--- before: /etc/systemd/system/quicknotes.service
+++ after:  .../quicknotes.service.j2
@@ -7,7 +7,7 @@
-Environment=ADDR=:9090
+Environment=ADDR=:7070
changed: [lab7vm]
```

Nothing was applied (check mode); the diff just previews what *would* change.

### Design questions

**e) Why does the second run report `changed=0`?**
`copy`/`template` compute the desired file and compare its **checksum** (and owner/group/mode) to
what's already on the target; `file` compares the directory's state/owner/mode. When everything
matches, the modules report `ok` and rewrite nothing — so no handler is notified either.

**f) What if you used `shell: 'echo ... > unit'` instead of `template:`?**
It would rewrite the file on **every** run, so it always reports `changed` → the restart handler
fires every single run (needless restarts). You also lose `--check`/`--diff` (no preview), lose
checksum/owner/mode management, and invite quoting/escaping bugs and partial writes. Basically every
safety the `template` module gives you is gone.

**g) What does `--check --diff` catch that plain `--check` misses?**
Plain `--check` tells you a task *would* change, but not *what* to. `--diff` shows the actual
before/after lines — so you catch a task that's about to write the **wrong** value (a typo'd `ADDR`,
or silently reverting someone's hand-fix). `--check` alone would just say "1 changed" and you'd
apply it to prod without noticing the content was wrong.

## Bonus — ansible-pull GitOps loop

Inside the VM I installed git, added a local inventory (`ansible_connection=local` — the VM
reconciles itself), and a systemd service + timer that runs `ansible-pull` every 5 minutes.

> For a self-contained, reproducible demo the live timer pulls from a local git mirror
> (`file:///srv/gitops`) on the VM; the committed `ansible-pull-quicknotes.service` points at the
> real fork URL + `feature/lab7`, which is what a real GitOps loop uses.

### Timer is active (every 5 min)

```text
$ systemctl list-timers ansible-pull-quicknotes.timer
NEXT                        LEFT      LAST                        UNIT
Sat 2026-06-27 11:51:46 UTC 4min 35s  Sat 2026-06-27 11:46:46 UTC ansible-pull-quicknotes.timer
```

(`OnBootSec=1min`, `OnUnitActiveSec=5min`.)

### Convergence, observed

```text
deployed ADDR before:        Environment=ADDR=:8080
[11:47:11] git commit "change listen_addr to :9090" in the source repo
[11:47:15] ansible-pull cycle runs (the same service the 5-min timer fires)
deployed ADDR after:         Environment=ADDR=:9090     ← reconciled, no host-side ansible run
```

I pushed one variable change into git and the VM converged to it on the next pull cycle — about 4
seconds here because I triggered the cycle; in normal operation it's within the 5-minute timer
window.

### Design questions

**h) Security benefit of pull mode vs push?**
In pull mode the node initiates the connection and fetches its config from git. There's no central
control node holding SSH keys that can log into every machine — so no single "push box" whose
compromise hands an attacker the whole fleet, and nodes don't have to expose inbound SSH for config
management. Each node only needs **read** access to the repo. Fewer standing credentials, smaller
blast radius.

**i) Same pattern at the Kubernetes layer?**
**GitOps** with **ArgoCD / Flux** — the cluster continuously pulls desired state from git and
reconciles to it. `ansible-pull` is a fair VM-layer simulator: it's the same loop — declarative
desired state in git, an agent on the target that periodically pulls and reconciles drift — just at
the OS layer with a systemd timer instead of a controller running inside the cluster.
