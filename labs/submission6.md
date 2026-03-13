# Lab 6 — Submission

## Task 1 — Container Lifecycle & Image Management

### 1.1: Basic Container Operations

**`docker ps -a` (before pulling ubuntu):**

```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

**`docker pull ubuntu:latest` & `docker images ubuntu`:**

```
latest: Pulling from library/ubuntu
01d7766a2e4a: Download complete
Digest: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest

REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    d1e2e92c075e   4 weeks ago   117MB
```

**Inside `ubuntu_container` — `cat /etc/os-release`:**

```
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo
```

**`ps aux` inside container:**

```
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  5.0  0.0   7888  3608 ?        Rs   19:53   0:00 ps aux
```

### 1.2: Image Export and Dependency Analysis

**`docker save` & tar file size:**

```
-rw-r--r-- 1 harne 197609 29M Mar 13 22:53 ubuntu_image.tar
```

Image size: **117 MB** (uncompressed layers). Tar file: **29 MB** (compressed).

**First `docker rmi ubuntu:latest` — error:**

```
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced)
- container 3019b44ba14f is using its referenced image d1e2e92c075e
```

**After `docker rm ubuntu_container` → `docker rmi ubuntu:latest`:**

```
ubuntu_container
Untagged: ubuntu:latest
Deleted: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
```

### Analysis

**Why does image removal fail when a container exists?**

Docker maintains a reference-counting dependency graph between images and containers. A container is essentially a running (or stopped) instance built on top of a read-only image — its writable layer references the underlying image layers. As long as any container (even stopped) references an image, Docker prevents its deletion to avoid leaving a dangling container with a broken filesystem. You must first remove all dependent containers before the image can be deleted.

**What is included in the exported tar file?**

`docker save` produces a tar archive containing all layers that make up the image, each as a compressed tar of filesystem changes, plus metadata files (`manifest.json`, `config.json`) that describe layer ordering, environment variables, entrypoint, and other image configuration. This allows the image to be fully reconstructed on another machine via `docker load`.

---

## Task 2 — Custom Image Creation & Analysis

### 2.1: Deploy and Customize Nginx

**Original Nginx welcome page (`curl http://localhost`):**

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
<h1>Welcome to nginx!</h1>
<p>If you see this page, nginx is successfully installed and working.</p>
...
</html>
```

**Custom `index.html` content:**

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

**`curl http://localhost` after `docker cp`:**

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

### 2.2: Create and Test Custom Image

**`docker commit` & `docker images my_website`:**

```
sha256:44e7c854d2da480c7d224f4052e03e271d4feeb3c76eb596140eb05c5f2a9488

REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
my_website   latest    44e7c854d2da   1 second ago   237MB
```

**`curl http://localhost` from `my_website_container`:**

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

**`docker diff my_website_container`:**

```
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

### Analysis

**Explanation of `docker diff` output:**

The diff shows only `C` (Changed) entries relative to the image the container was started from (`my_website:latest`). Because the custom `index.html` was already baked into the image via `docker commit`, it no longer appears as a change. The entries shown are:

- `/etc/nginx/conf.d/default.conf` — nginx updates its config timestamps at runtime.
- `/run/nginx.pid` — the PID file is created by the nginx master process when it starts; it doesn't exist in the image layer and is written at container startup.

`A` (Added) and `D` (Deleted) entries would appear if files were created or removed inside the running container after it started.

**`docker commit` vs Dockerfile:**

| | `docker commit` | Dockerfile |
|---|---|---|
| **Advantages** | Fast, interactive — useful for quick prototyping or capturing live changes | Reproducible, version-controlled, auditable, supports build cache |
| **Disadvantages** | Not reproducible, history is opaque, layers can contain secrets or intermediate state | Requires upfront planning; slower to iterate |

For production, Dockerfiles are strongly preferred because they can be reviewed, stored in git, and rebuilt deterministically.

---

## Task 3 — Container Networking & Service Discovery

### 3.1: Create Custom Network

**`docker network create lab_network` & `docker network ls`:**

```
affaf3745d31adef2056e16a405c16ceadf60091aa0f0bc6419d4e6c2a886d92

NETWORK ID     NAME          DRIVER    SCOPE
c8e34ffbd6ef   bridge        bridge    local
659d0f6f3381   host          host      local
affaf3745d31   lab_network   bridge    local
abc3b6f94350   none          null      local
```

### 3.2: Test Connectivity and DNS

**`docker exec container1 ping -c 3 container2`:**

```
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.077 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.064 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.063 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.063/0.068/0.077 ms
```

**`docker network inspect lab_network`:**

```json
[
    {
        "Name": "lab_network",
        "Id": "affaf3745d31adef2056e16a405c16ceadf60091aa0f0bc6419d4e6c2a886d92",
        "Driver": "bridge",
        "IPAM": {
            "Config": [{ "Subnet": "172.18.0.0/16", "Gateway": "172.18.0.1" }]
        },
        "Containers": {
            "76c5d712...": { "Name": "container1", "IPv4Address": "172.18.0.2/16" },
            "b58adbac...": { "Name": "container2", "IPv4Address": "172.18.0.3/16" }
        }
    }
]
```

**`docker exec container1 nslookup container2`:**

```
Server:    127.0.0.11
Address:   127.0.0.11:53

Non-authoritative answer:
Name:  container2
Address: 172.18.0.3
```

### Analysis

**How does Docker's internal DNS enable container-to-container communication by name?**

Docker runs an embedded DNS server at `127.0.0.11` inside each container on a user-defined network. When a container is attached to a user-defined network, Docker registers its name (and any aliases) in this DNS resolver. When `container1` sends a ping to `container2`, the kernel routes the DNS query to `127.0.0.11`, which looks up the name in its internal table and returns the IP `172.18.0.3`. This means containers can communicate by name without knowing each other's IP addresses — which may change on restart.

**User-defined bridge vs default bridge:**

| Feature | Default bridge (`bridge`) | User-defined bridge (`lab_network`) |
|---|---|---|
| DNS / name resolution | Not available (IP only) | Built-in — containers resolve each other by name |
| Network isolation | All containers share same bridge | Only containers explicitly attached can communicate |
| Dynamic connect/disconnect | Not supported | `docker network connect/disconnect` at runtime |
| Custom subnet/gateway | Requires daemon config | Per-network config via `--subnet`, `--gateway` |

User-defined networks provide better isolation, automatic DNS, and more flexibility for multi-container applications.

---

## Task 4 — Data Persistence with Volumes

### 4.1: Create and Use Volume

**`docker volume create app_data` & `docker volume ls`:**

```
app_data

DRIVER    VOLUME NAME
local     app_data
```

**Custom `index.html`:**

```html
<html><body><h1>Persistent Data</h1></body></html>
```

**`curl http://localhost` after `docker cp`:**

```
<html><body><h1>Persistent Data</h1></body></html>
```

### 4.2: Verify Persistence

**`curl http://localhost` after container recreation (`web_new`):**

```
<html><body><h1>Persistent Data</h1></body></html>
```

Data is intact — the volume preserved the file across container destruction and recreation.

**`docker volume inspect app_data`:**

```json
[
    {
        "CreatedAt": "2026-03-13T19:58:12Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

### Analysis

**Why is data persistence important in containerized applications?**

Containers are ephemeral by design — their writable layer is destroyed when the container is removed. Without persistence, any data written at runtime (user uploads, database records, logs, config changes) would be lost on every redeploy. Volumes decouple the lifecycle of data from the lifecycle of the container, which is essential for stateful services like databases, file storage, and caching layers in production.

**Volumes vs bind mounts vs container storage:**

| | Named Volume | Bind Mount | Container Storage (writable layer) |
|---|---|---|---|
| **Managed by** | Docker daemon | Host OS | Docker (copy-on-write) |
| **Data survives container removal** | Yes | Yes | No |
| **Path on host** | `/var/lib/docker/volumes/<name>/_data` | Any host path specified | Internal union filesystem |
| **Portability** | High (abstracted from host) | Low (host path must exist) | None |
| **Performance** | Good | Best (direct I/O) | Worst (overlay overhead) |
| **When to use** | Databases, persistent app data, shared data between containers | Development (hot reload), access to host config files | Temporary scratch space, cache, build artifacts |
