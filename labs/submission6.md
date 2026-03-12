# Lab 6 Submission — Container Fundamentals with Docker

**Student:** Diana Minnakhmetova  
**Date:** 12-03-2026

---

## Prerequisites

```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker --version
Docker version 29.2.1, build a5c7197
```

---

## Task 1 — Container Lifecycle & Image Management

- [x] Listed existing containers
- [x] Pulled Ubuntu image and documented size/layers
- [x] Ran interactive container and explored OS/processes
- [x] Exported image to tar and compared sizes
- [x] Demonstrated image removal dependency error
- [x] Removed container and successfully deleted image

### 1.1 Basic Container Operations

**docker ps -a (before pull):**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker ps -a
CONTAINER ID   IMAGE     COMMAND                  CREATED      STATUS                    PORTS     NAMES
7e6c6b477655   mongo:7   "docker-entrypoint.s…"   7 days ago   Exited (137) 7 days ago             mongo1
59ade23e82e6   mongo:7   "docker-entrypoint.s…"   7 days ago   Exited (137) 7 days ago             mongo2
8c1cb309bce5   mongo:7   "docker-entrypoint.s…"   7 days ago   Exited (137) 7 days ago             mongo3
```

**docker pull ubuntu:latest:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker pull ubuntu:latest
latest: Pulling from library/ubuntu
66a4bbbfab88: Pull complete 
9c2a2ec78563: Download complete 
Digest: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
```

**docker images ubuntu:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker images ubuntu
                                                                                                                                                                                                                                                                            i Info →   U  In Use
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   d1e2e92c075e        141MB         30.8MB        
```

- **Image size on disk:** 141MB  
- **Content size:** 30.8MB  
- **Layer count:** 2 layers (`66a4bbbfab88`, `9c2a2ec78563`)

**Inside ubuntu_container — cat /etc/os-release:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker run -it --name ubuntu_container ubuntu:latest
root@2b321806ac7b:/# cat /etc/os-release
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

**Inside ubuntu_container — ps aux:**
```
root@2b321806ac7b:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4300  3624 pts/0    Ss   15:45   0:00 /bin/bash
root        10  0.0  0.0   7632  3656 pts/0    R+   16:05   0:00 ps aux
root@2b321806ac7b:/# exit
exit
```

**docker ps -a (after container exit):**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker ps -a
CONTAINER ID   IMAGE           COMMAND                  CREATED          STATUS                          PORTS     NAMES
2b321806ac7b   ubuntu:latest   "/bin/bash"              21 minutes ago   Exited (0) About a minute ago             ubuntu_container
7e6c6b477655   mongo:7         "docker-entrypoint.s…"   7 days ago       Exited (137) 7 days ago                   mongo1
59ade23e82e6   mongo:7         "docker-entrypoint.s…"   7 days ago       Exited (137) 7 days ago                   mongo2
8c1cb309bce5   mongo:7         "docker-entrypoint.s…"   7 days ago       Exited (137) 7 days ago                   mongo3
```

### 1.2 Image Export and Dependency Analysis

**docker save + ls -lh:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker save -o ubuntu_image.tar ubuntu:latest
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % ls -lh ubuntu_image.tar
-rw-------@ 1 dminnakhmetova  staff    29M 12 мар 19:09 ubuntu_image.tar
```

**Size comparison:**
| Metric | Size |
|--------|------|
| Image disk usage | 141MB |
| Image content size | 30.8MB |
| Exported tar file | 29MB |

The tar file closely matches the content size because it stores compressed layer data. The disk usage is larger due to how Docker accounts for layers internally on the host filesystem.

**First removal attempt (ERROR):**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker rmi ubuntu:latest
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container 2b321806ac7b is using its referenced image d1e2e92c075e
```

**After container removal — successful deletion:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker rm ubuntu_container
ubuntu_container
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker rmi ubuntu:latest
Untagged: ubuntu:latest
Deleted: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker images ubuntu
                                                                                                                                                                                                                                                                            i Info →   U  In Use
IMAGE   ID             DISK USAGE   CONTENT SIZE   EXTRA
```

### Analysis

**Why does image removal fail when a container exists?**

Docker enforces a dependency relationship between images and containers. Every container — even a stopped one — holds a reference to the image it was created from. The image's read-only layers serve as the foundation of the container's filesystem. As long as any container (running or exited) references an image, Docker refuses to delete it to prevent data corruption.

The dependency chain works like this:
```
Image (ubuntu:latest)  ←  referenced by  ←  Container (ubuntu_container, Exited)
```
To delete the image, all containers referencing it must be removed first. This is a safety mechanism — Docker protects you from accidentally deleting an image that a container still depends on.

**What is included in the exported tar file?**

The `docker save` command exports the full image in OCI (Open Container Initiative) format. The tar archive contains:
- All read-only filesystem layers (as compressed tar archives)
- A manifest JSON file describing the image structure and layer order
- Image configuration JSON (entrypoint, env variables, architecture, OS)
- An `oci-layout` file specifying the OCI format version

This archive is self-contained — it can be transferred to another machine and loaded with `docker load -i ubuntu_image.tar` to fully restore the image without needing Docker Hub access.

---

## Task 2 — Custom Image Creation & Analysis

- [x] Deployed Nginx container and captured default welcome page
- [x] Created custom HTML and copied it into the container
- [x] Committed container to custom image
- [x] Deployed new container from custom image and verified custom content
- [x] Analyzed filesystem changes with docker diff

### 2.1 Deploy and Customize Nginx

**Deploy Nginx:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker run -d -p 80:80 --name nginx_container nginx

Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
a87363d30ab0: Pull complete 
d456cad1d0ff: Pull complete 
7e3a4af256ee: Pull complete 
fbeac1abb084: Pull complete 
fca7a914ec95: Pull complete 
2e1e80a9149a: Pull complete 
91b7c54c9127: Download complete 
a50bc5888f62: Download complete 
Digest: sha256:bc45d248c4e1d1709321de61566eb2b64d4f0e32765239d66573666be7f13349
Status: Downloaded newer image for nginx:latest
6d8276e69be56f14385415c7e89133eab4dfdb631604efc8edab9252e23d4201
```

**Original Nginx welcome page (curl http://localhost):**
```html
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % curl http://localhost
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
<p>If you see this page, nginx is successfully installed and working.
Further configuration is required for the web server, reverse proxy, 
API gateway, load balancer, content cache, or other features.</p>

<p>For online documentation and support please refer to
<a href="https://nginx.org/">nginx.org</a>.<br/>
To engage with the community please visit
<a href="https://community.nginx.org/">community.nginx.org</a>.<br/>
For enterprise grade support, professional services, additional 
security features and capabilities please refer to
<a href="https://f5.com/nginx">f5.com/nginx</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

**Custom index.html created:**
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

**After docker cp — curl http://localhost:**
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

Custom HTML successfully served by Nginx.

```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % ls -la index.html
-rw-r--r--@ 1 dminnakhmetova  staff  85 12 мар 19:14 index.html
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker cp index.html nginx_container:/usr/share/nginx/html/
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % curl http://localhost
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>%   
```

### 2.2 Create and Test Custom Image

**docker commit:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker commit nginx_container my_website:latest
sha256:a65a2ca3f9f1ae61b09c4939edf149db25b25e43517e1d1f6528a69f7f3cc8b9
```

**docker images my_website:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker images my_website
IMAGE               ID             DISK USAGE   CONTENT SIZE   EXTRA
my_website:latest   a65a2ca3f9f1        255MB         61.3MB       
```

**Deploy from custom image:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker rm -f nginx_container
nginx_container
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker run -d -p 80:80 --name my_website_container my_website:latest
f920b59446f0e0191c275f066ff5659699ff4484956f3d2e45696e13cabc8d72
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % curl http://localhost
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>%                                                                                                                                                                                       
```

New container launched from custom image serves the correct custom content.

**docker diff my_website_container:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker diff my_website_container
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

### Analysis

**Explanation of docker diff output:**

`docker diff` shows changes in the container's writable layer compared to its base image. The legend: `A` = Added, `C` = Changed, `D` = Deleted.

| Change | Path | Reason |
|--------|------|--------|
| C | /etc/nginx/conf.d/default.conf | Nginx may update its config at runtime |
| C | /etc/nginx, /etc/nginx/conf.d | Parent directories reflect changes |
| C | /run/nginx.pid | PID file created when Nginx process started |
| C | /run | Parent directory reflects PID file creation |

Notably, our custom `index.html` does **not** appear in the diff. This is because the file was changed in `nginx_container`, then frozen into `my_website:latest` via `docker commit`. The new container (`my_website_container`) starts with `index.html` already baked into its image layer — so from its perspective, nothing changed. Only changes made **after** container start are visible in `docker diff`.

**docker commit vs Dockerfile:**

| Criterion | docker commit | Dockerfile |
|-----------|---------------|------------|
| Speed | ⚡ Instant (one command) | Slower (build process) |
| Reproducibility |  Hard to replicate |  Fully reproducible |
| Change history |  Black box |  Every step documented |
| Image size | Larger (copies all layers) | Optimizable |
| Version control |  Binary blobs in registry |  Text file in Git |
| Production use |  Not recommended |  Industry standard |

**When to use each:**

`docker commit` is appropriate for quick local prototyping or learning. It is not suitable for production because there is no record of what commands were run — the resulting image is essentially a black box. `Dockerfile` provides full traceability, can be versioned in Git, reviewed in PRs, and rebuilt identically on any machine. In production and team environments, Dockerfile is always the correct choice.

---

## Task 3 — Container Networking & Service Discovery

- [x] Created user-defined bridge network
- [x] Deployed two containers on the same network
- [x] Verified container-to-container ping by hostname
- [x] Inspected network to confirm IP assignments
- [x] Verified DNS resolution via nslookup

### 3.1 Create Custom Network

**docker network create:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker network create lab_network
8749acf5540057f644489697c4a6d281a8833606aecc4f442474fa1a42bee91e
```

**docker network ls:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker network ls

NETWORK ID     NAME                            DRIVER    SCOPE
a94f71cdf060   bridge                          bridge    local
6c4025d4968b   foursquare_assignment_default   bridge    local
de7242489039   host                            host      local
8749acf55400   lab_network                     bridge    local
8f363c44f49c   none                            null      local
```

**Deploy containers:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker run -dit --network lab_network --name container1 alpine ash

Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
d8ad8cd72600: Pull complete 
cb94f19e6ea6: Download complete 
37093440b0e0: Download complete 
Digest: sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659
Status: Downloaded newer image for alpine:latest
0cc8a960bc19b7c50eb5ad937ff3ca7e4aaa99bd71717fe9400557ac80155019
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker run -dit --network lab_network --name container2 alpine ash
adfc677406c199de8f6d73595d777320041ca14166229d5dd45bedab2e848c96
```

### 3.2 Test Connectivity and DNS

**Ping test (container1 → container2 by name):**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker exec container1 ping -c 3 container2
PING container2 (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.183 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.193 ms
64 bytes from 172.19.0.3: seq=2 ttl=64 time=0.162 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.162/0.179/0.193 ms
```

Successful communication by container name, 0% packet loss.

**docker network inspect lab_network:**
```json
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker network inspect lab_network
[
    {
        "Name": "lab_network",
        "Id": "8749acf5540057f644489697c4a6d281a8833606aecc4f442474fa1a42bee91e",
        "Created": "2026-03-12T16:29:50.711814593Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.19.0.0/16",
                    "Gateway": "172.19.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Options": {
            "com.docker.network.enable_ipv4": "true",
            "com.docker.network.enable_ipv6": "false"
        },
        "Labels": {},
        "Containers": {
            "0cc8a960bc19b7c50eb5ad937ff3ca7e4aaa99bd71717fe9400557ac80155019": {
                "Name": "container1",
                "EndpointID": "3e5c44c0f73362a873d2f0b66d59ddac218b34f51b9d230b65fe374bb9c329f3",
                "MacAddress": "ea:db:5e:88:d4:59",
                "IPv4Address": "172.19.0.2/16",
                "IPv6Address": ""
            },
            "adfc677406c199de8f6d73595d777320041ca14166229d5dd45bedab2e848c96": {
                "Name": "container2",
                "EndpointID": "23b70602dcb3fced81bbfef30469a1ea27d6b56d83e22e63a2fae213276542dd",
                "MacAddress": "5a:d6:7b:66:db:d0",
                "IPv4Address": "172.19.0.3/16",
                "IPv6Address": ""
            }
        },
        "Status": {
            "IPAM": {
                "Subnets": {
                    "172.19.0.0/16": {
                        "IPsInUse": 5,
                        "DynamicIPsAvailable": 65531
                    }
                }
            }
        }
    }
]

```

- **container1:** `172.19.0.2`  
- **container2:** `172.19.0.3`  
- **Subnet:** `172.19.0.0/16`, **Gateway:** `172.19.0.1`

**DNS resolution (nslookup):**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker exec container1 nslookup container2
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:   container2
Address: 172.19.0.3
```

 `container2` resolved to `172.19.0.3` via Docker's embedded DNS at `127.0.0.11`.

### Analysis

**How does Docker's internal DNS enable container-to-container communication by name?**

Docker runs an embedded DNS server inside every container at the fixed address `127.0.0.11:53`. When a container joins a user-defined network, its name is automatically registered in this DNS server. Any DNS query from a container on the same network is intercepted and resolved locally — no external DNS is needed.

The flow for `ping container2` from container1:
1. container1 sends a DNS query for `container2` to `127.0.0.11:53`
2. Docker's embedded DNS looks up `container2` in the `lab_network` registry
3. Returns IP `172.19.0.3`
4. container1 sends ICMP packets directly to `172.19.0.3`

This makes container communication resilient to IP changes — if a container is replaced, the new instance registers under the same name and traffic continues without any reconfiguration.

**User-defined bridge vs default bridge:**

| Feature | User-defined (lab_network) | Default bridge (docker0) |
|---------|---------------------------|--------------------------|
| DNS by container name |  Works automatically |  Not supported |
| Network isolation |  Per-network isolation |  All containers share docker0 |
| Dynamic connect/disconnect |  Supported without restart |  Requires container restart |
| IP predictability |  Consistent | 🤔 Can change |
| Production readiness |  Recommended |  Legacy, not recommended |

The default bridge network exists only for backward compatibility. It does not support DNS by container name — containers can only communicate via hardcoded IP addresses. User-defined networks provide automatic DNS discovery, better isolation, and flexible management, making them the correct choice for any multi-container application.

---

## Task 4 — Data Persistence with Volumes

- [x] Created named volume app_data
- [x] Deployed Nginx container with volume mounted
- [x] Added custom HTML content and verified via curl
- [x] Destroyed container and recreated from same volume
- [x] Verified content persists across container lifecycle
- [x] Inspected volume to identify mount point

### 4.1 Create and Use Volume

**docker volume create + ls:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker volume create app_data

app_data
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker volume ls
DRIVER    VOLUME NAME
local     2343c5e9d00c7ac7239509c3772f00dc7f4ef18aff61e4508fea266f77aad5f5
local     42549ae832ade7c63a6419700e900455d5cef1472e71585f02a3f8161b3fe799
local     ac7d30deeba447666ff10439168726b1984a9d6510864955efa8298339f8121a
local     app_data
local     b0d6a0ed76a12adebc252b1472510aaf701831c5fad4a7880767d2377be80be5
local     c94f8f842eda9c354c15ef6fb691b186b73116af269c2574223e8e0f564f8047
local     ccd12d629460e5bb56434de29ede72a31924a25fed673060463073f2061c3724
local     foursquare_assignment_citus_coordinator_data
local     foursquare_assignment_citus_worker1_data
local     foursquare_assignment_citus_worker2_data
local     foursquare_assignment_mongo1_data
local     foursquare_assignment_mongo2_data
local     foursquare_assignment_mongo3_data
local     foursquare_assignment_scylla1_data
local     foursquare_assignment_scylla2_data
local     foursquare_assignment_scylla3_data
```

**Deploy Nginx with volume:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
3aaa9aa958a0f0b35426e5efba1c48c73404cd3ff04f748523a514e449aacad0
```

The `-v app_data:/usr/share/nginx/html` flag mounts the `app_data` volume to Nginx's web root. Any files written there are stored in the volume, not the container's writable layer.

**Custom index.html:**
```html
<html><body><h1>Persistent Data</h1></body></html>
```

**Copy and verify:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker cp labs/index.html web:/usr/share/nginx/html/

Successfully copied 2.05kB to web:/usr/share/nginx/html/
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>
```

 Custom content served correctly.

### 4.2 Verify Persistence

**Destroy container:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker stop web && docker rm web
web
web
```

The container is gone — but the volume `app_data` remains on the host.

**Recreate from same volume:**
```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
1e3e7f8d9f99b99dc8c4df86524575e824d9eb704ea7ad0718e4c217a1e5e78b
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>
```

 Data persisted across complete container destruction and recreation.

**docker volume inspect app_data:**
```json
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker volume inspect app_data
[
    {
        "CreatedAt": "2026-03-12T16:35:01Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

- **Mountpoint:** `/var/lib/docker/volumes/app_data/_data` — the actual location of files on the host
- **Driver:** `local` — stored on the local filesystem
- **Scope:** `local` — available only on this host

### Analysis

**Why is data persistence important in containerized applications?**

Containers are ephemeral by design — when a container is removed, its writable layer is deleted along with it. This is intentional for stateless workloads, but creates a critical problem for stateful applications like databases, file storage, and message queues.

Without persistence:
- A database container that crashes loses all records
- An application that restarts loses session state, uploaded files, logs
- Scaling or updating a service means losing data

With volumes, data lives outside the container lifecycle. The container can be stopped, deleted, updated, or replaced — the volume remains untouched. This enables zero-data-loss deployments, rolling updates, and disaster recovery.

**Differences between volumes, bind mounts, and container storage:**

| Type | Storage Location | Managed By | Persists After rm | Best Use Case |
|------|-----------------|------------|-------------------|---------------|
| **Volume** | `/var/lib/docker/volumes/` | Docker |  Yes | Production databases, stateful apps |
| **Bind mount** | Any host path | User |  Yes (on host) | Local development, hot reload |
| **Container storage** | Container writable layer | Docker |  No | Temporary files, cache |

**Volumes** are the recommended production solution. Docker manages them, they are portable between containers, and they can be backed up easily with `docker run --volumes-from`. They work identically across operating systems.

**Bind mounts** map a specific directory on the host directly into the container. They are ideal in development because you can edit source code on your machine and immediately see changes inside the container without rebuilding the image. However, they are host-dependent — a path that exists on a developer's Mac may not exist on a CI/CD server.

**Container storage** (the writable layer) requires no setup but is lost the moment the container is removed. It is appropriate only for truly temporary data — PID files, runtime caches, or anything that should not survive a restart.

In practice: use volumes for any data that must survive container restarts; use bind mounts during development for code that changes frequently; rely on container storage only for transient runtime artifacts.
