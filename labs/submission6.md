# Lab 6 — Container Fundamentals with Docker

## Task 1 — Container Lifecycle & Image Management

### Output of `docker ps -a` and `docker images`

**Command:** `docker ps -a`

**Output:**
```bash
CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
```
(no existing containers)

**Command:** `docker images ubuntu`

**Output:**
```bash
REPOSITORY TAG IMAGE ID CREATED SIZE
ubuntu latest 59a458b76b4e 10 days ago 117MB
```

---

### Image size and layer count
- **Image size:** 117 MB  
- **Layer count:** (implicit from the image’s digest and pull logs) — 1 main layer (`4b3ffd8ccb52: Pull complete`) plus metadata layers managed by Docker.

---

### Tar file size comparison with image size
- **Exported TAR file:** 29 MB (`ubuntu_image.tar`)  
- **Original image size:** 117 MB  

> The `.tar` file is smaller because it contains compressed filesystem layers without Docker’s metadata, cache, or uncompressed overlay data.

---

### Error message from the first removal attempt
```
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container bea8a2154a86 is using its referenced image 59a458b76b4e
```

---

### Analysis: Why does image removal fail when a container exists?
When a container is created, it directly **depends on the image layers** it was built from.  
Docker won’t allow you to delete an image that still has **active or stopped containers referencing it**, because doing so would break the container’s filesystem chain.  

---

### Explanation: What is included in the exported tar file?
The exported `.tar` file from `docker save` contains:
- All **filesystem layers** that make up the image.  
- The **`manifest.json`** describing layer order and configuration.  
- The **`repositories`** file mapping image names to their digests.  
- The **`config.json`** with metadata (environment, entrypoint, etc.).

It does **not** include:
- Containers
- Volumes
- Runtime state

## Task 2 — Custom Image Creation & Analysis

### Screenshot or output of original Nginx welcome page


```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

### Custom HTML content and verification via curl

Custom index.html:

```html
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

Verification:

**Command:** `curl http://localhost`

**Output:**

```html
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

### Output of docker diff my_website_container
```bash
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

### Analysis
- `A` = Added — new file or directory created
- `C` = Changed — file or directory was modified
- `D` = Deleted — file or directory removed

In this case, several configuration and runtime files inside `/run` and `/etc/nginx` were changed when Nginx started.

These changes are expected because Nginx creates its PID file and updates configuration state during startup.

### Reflection
`docker commit` is a quick way to capture the current state of a container and turn it into a reusable image.

However, it lacks transparency and reproducibility — no clear record of what commands were run.

Using a **Dockerfile** is more reliable for production: it provides version control, clear build steps, and easier automation in CI/CD.

In short:

- **docker commit** → fast, manual, non-reproducible.

- **Dockerfile** → transparent, repeatable, professional.

## Task 3 — Container Networking & Service Discovery

### Output of `ping` showing successful connectivity
**Command:** `docker exec container1 ping -c 3 container2`

**Output:**

```bash
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.152 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.193 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.198 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.152/0.181/0.198 ms
```

---

### Network inspection output showing both containers' IP addresses

**Command:** `docker network inspect lab_network`
**Output:** (partially)
```bash
"Containers": {
    "1d021a8cafef2beadedb13cbf56cb7c04b6a3154e78dbc196ddc7cca03249b82"  : {
        "Name": "container1",
        "IPv4Address": "172.18.0.2/16",
        "IPv6Address": ""
    },
    "eea7352108c8a900df0c68d42d03fcf5bf904e1fcb8af2b5bd5527e2ef986a07"  : {
        "Name": "container2",
        "IPv4Address": "172.18.0.3/16",
        "IPv6Address": ""
    }
}
```

---

### DNS resolution output
**Command:** `docker exec container1 nslookup container2`

**Output:**
```bash
Server: 127.0.0.11
Address: 127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name: container2
Address: 172.18.0.3

pgsql
```

---

### Analysis: How does Docker's internal DNS enable container-to-container communication by name?
- On user-defined bridge networks, Docker injects a lightweight DNS resolver inside containers at **127.0.0.11**.
- When a container joins the network, Docker registers its **container name** (and any network aliases) to its **IP** in that network.
- Other containers on the same network query 127.0.0.11; Docker returns an **A record** mapping the name (e.g., `container2`) to its IP (e.g., `172.18.0.3`).
- Records are updated dynamically when containers attach/detach, so name-based communication stays accurate without hardcoding IPs.

---

### Comparison: What advantages does user-defined bridge networks provide over the default bridge network?
- **Built-in DNS by name:** automatic name resolution (`container-name → IP`) without legacy `--link` tricks.
- **Isolation by design:** containers only see peers on the same user-defined network, reducing unintended cross-talk.
- **Configurable IPAM:** choose subnets/gateways and avoid clashes; predictable addressing for troubleshooting.
- **Aliases & multi-networking:** assign readable service aliases and connect a container to multiple networks cleanly.
- **Cleaner service discovery:** names remain stable across restarts, while IPs can change; apps don’t need IPs hardcoded.

## Task 4 — Data Persistence with Volumes

### Custom HTML content used
```html
<html><body><h1>Persistent Data</h1></body></html>
```

### Output of curl showing content persists after container recreation

**Command:** `curl http://localhost`

**Output:**

```html
<html><body><h1>Persistent Data</h1></body></html>
```

### Volume inspection output showing mount point

**Command:** `docker volume inspect app_data`

**Output:**

```json
[
  {
    "CreatedAt": "2025-10-11T18:42:58Z",
    "Driver": "local",
    "Labels": null,
    "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
    "Name": "app_data",
    "Options": null,
    "Scope": "local"
  }
]
```

### Analysis: Why is data persistence important in containerized applications?

Containers are disposable; data isn’t. Volumes keep state outside the container so restarts, updates, or crashes don’t wipe it.

### Comparison: Explain the differences between volumes, bind mounts, and container storage. When would you use each?

- **Volumes:** Docker-managed, portable, safe defaults. Use for persistent app/DB data.
- **Bind mounts:** Host folder mapped in. Use for local dev/live edits; mind host paths/permissions.
- **Container storage:** Ephemeral writable layer. Use only for temporary/cache data.