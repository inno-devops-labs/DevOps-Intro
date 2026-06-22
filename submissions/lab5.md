# Task 1

## Design questions

1. Synced folders: Vagrant supports nfs, rsync, virtualbox, and smb mount types. Which did you pick and why? What's the trade-off?

Answer: for this use case I use rsync since I need only pushing from host to guest. Moreover, I need to do it only once. Therefore, I will use `rsync`, not `rsync__auto`.
Additionally, my host is macOS, and any other choice, including VirtualBox, is overhead for me.

2. NAT vs Bridged vs Host-only: which network mode are you using (it's the default, but say which it is)? Why is 127.0.0.1-bound port forwarding safer than a Bridged interface for a course exercise?

Answer: By default NAT is used. And this is the best choice here. With NAT my VM has only private IP and nobody in my LAN can access it. Meanwhile, with Bridged mode my VM become accessible for other network users, which is not what I want. With host-only I do not have an Internet access, so I basically cannot download Go, for example.

3. Provisioning options: Vagrant supports shell, ansible, ansible_local, puppet, chef, … which did you pick for installing Go and why?

Answer: I have chosen shell for its simplicity and absence of dependency on other tools. However, it can be useful for cases where I do `vagrant up` several times. Shell will rerun. Tools like Ansible can do it smarter.

4. Why pin Go to a specific point release (1.24.5) instead of 1.24?

Answer: A patch version like 1.24.5 is immutable — no one can silently replace it, so every vagrant up gets the exact same binary.

## `vagrant up` output

```
==> default: Running provisioner: download-go (shell)...
    default: Running: inline script
    default: --2026-06-22 20:19:02--  https://go.dev/dl/go1.24.5.linux-arm64.tar.gz
    default: Resolving go.dev (go.dev)... 216.239.36.21, 216.239.38.21, 216.239.32.21, ...
    default: Connecting to go.dev (go.dev)|216.239.36.21|:443... connected.
    default: HTTP request sent, awaiting response... 302 Found
    default: Location: https://dl.google.com/go/go1.24.5.linux-arm64.tar.gz [following]
    default: --2026-06-22 20:19:03--  https://dl.google.com/go/go1.24.5.linux-arm64.tar.gz
    default: Resolving dl.google.com (dl.google.com)... 173.194.221.91, 173.194.221.136, 173.194.221.190, ...
    default: Connecting to dl.google.com (dl.google.com)|173.194.221.91|:443... connected.
    default: HTTP request sent, awaiting response... 200 OK
    default: Length: 74805101 (71M) [application/x-gzip]
    default: Saving to: ‘/tmp/go1.24.5.linux-arm64.tar.gz.1’
    default: 
    default:      0K .......... .......... .......... .......... ..........  0%  362K 3m21s
    <manually truncated>
    default:  73000K .......... .......... .......... .......... .......... 99% 34.4M 0s
    default:  73050K .                                                     100% 3.46T=3.2s
    default: 
    default: 2026-06-22 20:19:06 (22.5 MB/s) - ‘/tmp/go1.24.5.linux-arm64.tar.gz.1’ saved [74805101/74805101]
    default: 
==> default: Running provisioner: unpack-go (shell)...
    default: Running: inline script
==> default: Running provisioner: add-go-to-path (shell)...
    default: Running: inline script
```

## `curl` outputs

### `curl` output from host:

Input: `curl -s http://localhost:18080/health`

Output: `{"notes":6,"status":"ok"}`

### `curl` output from VM:

Input: `vagrant ssh -c 'curl http://localhost:8080/health'`

Output: `{"notes":6,"status":"ok"}`

# Task 2

## Breaking and restoring VM

1. Take a snapshot of the working VM, give it a meaningful name

Action: `vagrant snapshot save quicknotes-vm-stable`

2. Break the VM deliberately

Action: `vagrant ssh -c 'sudo rm -rf /usr/local/go'`

3. Verify it's broken with a command that proves it

Action: `vagrant ssh -c 'go version'`
Output: 
```
bash: line 1: go: command not found
```

4. Restore from the snapshot

Action: `vagrant snapshot restore quicknotes-vm-stable`

5. Verify recovery

Action: `vagrant ssh -c 'go version'`
Output: `go version go1.24.5 linux/arm64`

6. Time the restore

Action: `time vagrant snapshot restore quicknotes-vm-stable`
Output:
```
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'quicknotes-vm-stable'...
==> default: Checking if box 'bento/ubuntu-22.04' version '202510.26.0' is up to date...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key
==> default: Machine booted and ready!
==> default: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> default: flag to force provisioning. Provisioners marked to run always will still run.
vagrant snapshot restore quicknotes-vm-stable  1.45s user 1.00s system 18% cpu 13.421 total
```

## Design questions

1. Snapshots are not backups. Explain why in 2-3 sentences — what failure modes is a snapshot useless for?

Answer: Snapshots are saved states of the VM disk. Firstly, if there was an error in the VM at the moment of the snapshot, it won't help to get rid of it. Secondly, snapshots are stored on the same disk the VM is running on — if that disk is broken, snapshots will be also lost. Thirdly, if someone runs `vagrant destroy`, snapshots will be lost too.

2. Copy-on-write: Vagrant snapshots are copy-on-write under VirtualBox. What does that mean for disk usage when you take 10 snapshots vs 1?

Answer: copy-on-write approach means that snapshot is not a copy of the disk, but delta from the previous snapshot. The problem is that if we save 10 snapshots that contain adding, deleting and other operations with data, in sum it will contain several times bigger info than only 1 equivalent of disk data. But if we have only 1 snapshot, it means we have the amount of data needed to save the state, not more.

3. When is snapshotting an antipattern?

Answer: Snapshotting is an antipattern when it substitutes reproducible provisioning — if the Vagrantfile can rebuild the VM cleanly, `vagrant destroy -f && vagrant up` is the correct approach. It is also an antipattern when used on a running database (the filesystem may be mid-write, producing an inconsistent snapshot), or when a long chain of snapshots is treated as incremental backups (they are not — disk usage and restore time grow with each delta, and a single disk failure loses everything).
