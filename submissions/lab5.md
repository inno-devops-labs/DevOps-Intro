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
