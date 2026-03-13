# Lab 6 Submission — Container Fundamentals with Docker

---

## Task 1 — Container Lifecycle & Image Management

### 1.1 Basic Container Operations

**Command:** `docker ps -a`

```
CONTAINER ID   IMAGE                  COMMAND                    CREATED        STATUS                      PORTS     NAMES
5e1555fa078e   mongo:7                "bash -c 'sleep 10 &…"     6 days ago     Exited (0) 6 days ago                 bd_mongo_init
7dbe6cd2a37f   mongo:7                "docker-entrypoint.s…"     6 days ago     Exited (137) 4 days ago               bd_mongo_3
88073ce5e670   mongo:7                "docker-entrypoint.s…"     6 days ago     Exited (137) 4 days ago               bd_mongo_2
877013b9cbde   mongo:7                "docker-entrypoint.s…"     6 days ago     Exited (137) 4 days ago               bd_mongo_1
45f96f492845   citusdata/citus:12.1   "docker-entrypoint.s…"     7 days ago     Exited (0) 4 days ago                 bd_citus_coordinator
63d6e749beda   citusdata/citus:12.1   "docker-entrypoint.s…"     7 days ago     Exited (0) 4 days ago                 bd_citus_worker_2
84bd2a9f02ec   citusdata/citus:12.1   "docker-entrypoint.s…"     7 days ago     Exited (0) 4 days ago                 bd_citus_worker_1
91b66ee07853   postgres:16            "docker-entrypoint.s…"     7 days ago     Exited (0) 4 days ago                 bd_postgres
9d40a20e6b93   scylladb/scylla:5.4    "/docker-entrypoint.…"     7 days ago     Exited (137) 4 days ago               bd_scylla_2
1f08d7b07dc4   scylladb/scylla:5.4    "/docker-entrypoint.…"     7 days ago     Exited (137) 4 days ago               bd_scylla_3
e8b4ccd1dc16   scylladb/scylla:5.4    "/docker-entrypoint.…"     7 days ago     Exited (137) 4 days ago               bd_scylla_1
```

**Command:** `docker pull ubuntu:latest && docker images ubuntu`

```
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    d1e2e92c075e   4 weeks ago   139MB
```

**Command:** `docker run -it --name ubuntu_container ubuntu:latest`

Inside the container:

```
root@0f6b20092c1b:/# cat /etc/os-release
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

root@0f6b20092c1b:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4296  3548 pts/0    Ss   19:03   0:00 /bin/bash
root        10  0.0  0.0   7628  3532 pts/0    R+   19:04   0:00 ps aux
```

### 1.2 Image Export and Dependency Analysis

**Command:** `docker save -o ubuntu_image.tar ubuntu:latest && ls -lh ubuntu_image.tar`

```
-rw-------@ 1 jeanne  staff    28M 13 мар 22:04 ubuntu_image.tar
```

- **Image size:** 139 MB (uncompressed layers)
- **Tar file size:** 28 MB (compressed)

**First removal attempt (expected error):**

```
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - 
container 0f6b20092c1b is using its referenced image d1e2e92c075e
```

**After removing container:**

```
docker rm ubuntu_container   → ubuntu_container
docker rmi ubuntu:latest     → Untagged: ubuntu:latest
                               Deleted: sha256:d1e2e92c075e...
```

### Analysis

**Why does image removal fail when a container exists?**

Docker images and containers have a parent-child dependency relationship. A container is essentially a thin writable layer on top of a read-only image. Docker prevents deletion of an image while any container — even a stopped one — references it, because the container still depends on the image's filesystem layers to exist. Removing the image while the container exists would leave the container in a broken, unresolvable state. The container must be removed first to release the reference, after which the image can be safely deleted.

**What is included in the exported tar file?**

The `docker save` tar archive contains all image layers as individual tarballs, along with metadata files: `manifest.json` (describing layer order and image config), `config.json` (environment variables, entrypoint, labels), and `repositories` (image name/tag mappings). This makes the tar self-contained and portable — it can be loaded on any Docker host using `docker load` without needing registry access. The tar is smaller than the reported image size because Docker compresses the layer data during export.

---

## Task 2 — Custom Image Creation & Analysis

### 2.1 Deploy and Customize Nginx

**Original Nginx welcome page:**

```bash
$ curl http://localhost
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

**Custom index.html:**

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

**After copying to container:**

```bash
$ docker cp index.html nginx_container:/usr/share/nginx/html/
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/

$ curl http://localhost
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

### 2.2 Custom Image

**Commands:**

```bash
$ docker commit nginx_container my_website:latest
sha256:4c2900e449cfcf5623c6382cccc9da923014f4335d6f7e92e60d1a0424ce02dd

$ docker images my_website
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
my_website   latest    4c2900e449cf   4 seconds ago   255MB
```

**Deployed from custom image and verified:**

```bash
$ docker run -d -p 80:80 --name my_website_container my_website:latest
$ curl http://localhost
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

**Filesystem diff:**

```bash
$ docker diff my_website_container
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

### Analysis

**Explanation of diff output:**

All entries are marked `C` (Changed):
- `/etc/nginx/conf.d/default.conf` — Nginx updates its config file at runtime with active server settings.
- `/run/nginx.pid` — Nginx writes its process ID file here when it starts. This is normal runtime behavior.
- `/etc` and `/etc/nginx` are marked `C` as parent directories because their contents changed.

No `A` (Added) entries appear because the custom `index.html` was committed into the image itself — the diff only shows changes made after the container started from that image.

**`docker commit` vs Dockerfile:**

| | `docker commit` | Dockerfile |
|---|---|---|
| **Advantages** | Fast, no extra files needed, good for quick experiments | Reproducible, version-controlled, auditable, supports CI/CD |
| **Disadvantages** | No history of changes, not reproducible, hard to maintain | Requires writing and maintaining a file |

In production, Dockerfiles are strongly preferred because they document every change and allow rebuilding from scratch. `docker commit` is useful for quick prototyping or saving an exploratory session, but it creates opaque "black box" images that are difficult to audit or reproduce.

---

## Task 3 — Container Networking & Service Discovery

### 3.1 Custom Network

```bash
$ docker network create lab_network
21a91f663c308e464a4f8bea772d534dccc5f37df4cd7d61007ab52da98d9436

$ docker network ls
NETWORK ID     NAME                        DRIVER    SCOPE
d69cca8168f0   assignment1-pmldl_default   bridge    local
575e57ede7a7   bridge                      bridge    local
a835ecdcbb5b   host                        host      local
21a91f663c30   lab_network                 bridge    local
97d54f73a8ef   none                        null      local
```

### 3.2 Connectivity and DNS

**Ping test:**

```bash
$ docker exec container1 ping -c 3 container2
PING container2 (172.22.0.3): 56 data bytes
64 bytes from 172.22.0.3: seq=0 ttl=64 time=0.192 ms
64 bytes from 172.22.0.3: seq=1 ttl=64 time=0.231 ms
64 bytes from 172.22.0.3: seq=2 ttl=64 time=0.343 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.192/0.255/0.343 ms
```

**Network inspection:**

```json
[
    {
        "Name": "lab_network",
        "Driver": "bridge",
        "IPAM": {
            "Config": [{ "Subnet": "172.22.0.0/16", "Gateway": "172.22.0.1" }]
        },
        "Containers": {
            "3f6a898a2db1...": {
                "Name": "container2",
                "IPv4Address": "172.22.0.3/16"
            },
            "636be41db3ea...": {
                "Name": "container1",
                "IPv4Address": "172.22.0.2/16"
            }
        }
    }
]
```

**DNS resolution:**

```bash
$ docker exec container1 nslookup container2
Server:		127.0.0.11
Address:	127.0.0.11:53

Non-authoritative answer:
Name:	container2
Address: 172.22.0.3
```

### Analysis

**How Docker's internal DNS works:**

Docker runs an embedded DNS server at `127.0.0.11` inside each container on a user-defined network. When a container performs a name lookup (e.g. `ping container2`), the request goes to this DNS server, which resolves the container name to its current IP address dynamically. This means containers can find each other by name regardless of what IP address Docker assigns them — IP addresses can change between restarts, but the name always resolves correctly.

**User-defined vs default bridge network:**

| | Default bridge | User-defined bridge (lab_network) |
|---|---|---|
| DNS by name | ❌ Not supported | ✅ Automatic |
| Isolation | Shared with all containers | Only containers explicitly attached |
| Network scope control | Limited | Full control |
| Recommended for | Quick tests | All real applications |

User-defined networks provide automatic DNS-based service discovery, better isolation, and the ability to connect/disconnect containers at runtime — none of which are available on the default bridge network.

---

## Task 4 — Data Persistence with Volumes

### 4.1 Volume Creation and Content

```bash
$ docker volume create app_data
app_data

$ docker volume ls
DRIVER    VOLUME NAME
local     app_data
local     bigdatahw_citus_coordinator_data
...
```

**Custom HTML content:**

```html
<html><body><h1>Persistent Data</h1></body></html>
```

**After copying to volume-backed container:**

```bash
$ curl http://localhost
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

### 4.2 Persistence Verification

**After destroying and recreating the container:**

```bash
$ docker stop web && docker rm web
$ docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
$ curl http://localhost
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

Content persisted successfully after full container destruction and recreation.

**Volume inspection:**

```json
[
    {
        "CreatedAt": "2026-03-13T19:11:15Z",
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

Containers are ephemeral by design — their writable layer is destroyed when the container is removed. Without persistence, any data written inside a container (user uploads, database records, logs, config changes) is permanently lost on restart or redeploy. In production, stateful services like databases, file storage, and caches must survive container lifecycle events. Volumes decouple data from the container, allowing data to persist independently of how many times the container is recreated or updated.

**Volumes vs Bind Mounts vs Container Storage:**

| | Volumes | Bind Mounts | Container Storage |
|---|---|---|---|
| **Managed by** | Docker | Host OS | Docker (ephemeral) |
| **Location** | `/var/lib/docker/volumes/` | Any host path | Inside container layer |
| **Persists after `rm`** | ✅ Yes | ✅ Yes | ❌ No |
| **Portable** | ✅ Yes | ❌ Host-dependent | N/A |
| **Best for** | Databases, stateful apps | Dev: sharing source code with container | Temp files, caches |

**When to use each:**
- **Volumes** — production databases, persistent application data, anything that needs to survive container rebuilds.
- **Bind mounts** — development workflows where you want live code changes reflected inside the container without rebuilding.
- **Container storage** — truly temporary data that only needs to exist for the lifetime of that container run.
