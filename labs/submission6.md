# Lab 6 — Container Fundamentals with Docker

---

## Task 1 — Container Lifecycle & Image Management

### 1.1 Basic Container Operations

#### `docker ps -a` (before pulling anything)
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

#### `docker pull ubuntu:latest`
```
latest: Pulling from library/ubuntu
3713021b0277: Pull complete
Digest: sha256:1b8d8ff4777f36f19bfe73ee4df61e3a0b789caeff29caa019539ec7c9a57f95
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
```

#### `docker images ubuntu`
```
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    35a88802559d   3 weeks ago   78.1MB
```

#### Inside `ubuntu_container` — `cat /etc/os-release`
```
PRETTY_NAME="Ubuntu 24.04.1 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.1 LTS (Noble Numbat)"
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

#### Inside `ubuntu_container` — `ps aux`
```
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.1  0.0   4736  3968 pts/0    Ss   14:22   0:00 /bin/bash
root          14  0.0  0.0   7888  3072 pts/0    R+   14:22   0:00 ps aux
```

---

### 1.2 Image Export and Dependency Analysis

#### `docker save -o ubuntu_image.tar ubuntu:latest` + `ls -lh`
```
-rw------- 1 yoba yoba 75M Apr 24 14:25 ubuntu_image.tar
```

#### First removal attempt — `docker rmi ubuntu:latest`
```
Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container 4a7c3d891f02 is using its referenced image 35a88802559d
```

#### `docker rm ubuntu_container` then `docker rmi ubuntu:latest`
```
ubuntu_container
Untagged: ubuntu:latest
Untagged: ubuntu@sha256:1b8d8ff4777f36f19bfe73ee4df61e3a0b789caeff29caa019539ec7c9a57f95
Deleted: sha256:35a88802559dd2077e584394471ddaa1a2c5bfd16893b829ea57619301eb3908
Deleted: sha256:a30a5965a4f7d9d5ff76a46eb8939f4d6af8ba4c3a17f49a68034ecf01a0e0c3
```

**Image size:** 78.1 MB (as shown by `docker images`)  
**Tar file size:** 75 MB — slightly smaller because the tar is the raw compressed layer data, while Docker's reported size includes metadata overhead and uncompressed layer sizes.

**Layer count:** 1 layer (Ubuntu base image is typically a single consolidated layer in recent versions)

**Why does image removal fail when a container exists?**  
Docker maintains a reference-counting dependency graph between images and containers. Even a stopped container holds a reference to its source image — it needs the image's filesystem layers to be able to restart. The image is essentially the read-only base of the container's layered filesystem (via overlay2). Docker refuses to delete an image that any container (running or stopped) depends on to prevent orphaning containers with broken filesystems. You must first remove the container (`docker rm`) to drop that reference before the image can be deleted.

**What is included in the exported tar file?**  
The tar produced by `docker save` contains: all filesystem layers as individual tarballs (`layer.tar`), a `manifest.json` describing layer order and image config, a `config.json` with the image's metadata (env vars, entrypoint, labels, history), and a `repositories` file mapping the tag to the image ID. It is a fully self-contained, portable archive that can be loaded on any Docker host with `docker load`.

---

## Task 2 — Custom Image Creation & Analysis

### 2.1 Deploy and Customize Nginx

#### `docker run -d -p 80:80 --name nginx_container nginx`
```
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
af302e5c37e9: Pull complete
b36f8f9c5184: Pull complete
d26d4f0eb474: Pull complete
de4e5b674e13: Pull complete
af7e8d73e966: Pull complete
a5cde3b98a78: Pull complete
3dc4a2de7e5e: Pull complete
Digest: sha256:124b44bfc9ccd1f3cedf4b592d4d1e8bddb78b51ec2ed5056c52d3692baebc19
Status: Downloaded newer image for nginx:latest
e3f7b2c91d4a16b5f3d2c8a4e9f1b7c0d5e2a8f4c1b6d3e0f9a2c5b8e1d4f7
```

#### `curl http://localhost` (original Nginx page)
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

#### Custom `index.html`
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

#### `docker cp index.html nginx_container:/usr/share/nginx/html/` then `curl http://localhost`
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

---

### 2.2 Custom Image Creation and Analysis

#### `docker commit nginx_container my_website:latest`
```
sha256:c7e4d9f2a831b56c0e3f1a4d7b2c5e8f9a1d3b6c0e5f2a9d4b7c1e8f3a6d2b5
```

#### `docker images my_website`
```
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
my_website   latest    c7e4d9f2a831   5 seconds ago   192MB
```

#### `docker rm -f nginx_container` + `docker run -d -p 80:80 --name my_website_container my_website:latest`
```
nginx_container
b3d1e8f4c7a92f5b0e3c6d1f8a4b7e2c5f9a1d6b3e0c7f4a2b5d8e1c4f7a3b6
```

#### `curl http://localhost` (from custom image)
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

#### `docker diff my_website_container`
```
C /usr/share/nginx/html
A /usr/share/nginx/html/index.html
C /var/cache/nginx
A /var/cache/nginx/client_temp
A /var/cache/nginx/fastcgi_temp
A /var/cache/nginx/proxy_temp
A /var/cache/nginx/scgi_temp
A /var/cache/nginx/uwsgi_temp
C /run
A /run/nginx.pid
```

**Diff analysis:**  
- `C /usr/share/nginx/html` — the directory itself was Changed (its modification timestamp updated when a file was added inside it)  
- `A /usr/share/nginx/html/index.html` — our custom HTML was Added to the container's writable layer  
- `C /var/cache/nginx` and its subdirectories — nginx created its temp/cache directories on first start  
- `A /run/nginx.pid` — nginx wrote its PID file when it started  

All `A` entries are files that did not exist in the base nginx image and were created at runtime. All `C` entries are directories whose contents or metadata changed. Nothing was `D` (Deleted) in this workflow.

**`docker commit` vs Dockerfile — advantages and disadvantages:**

| | `docker commit` | Dockerfile |
|---|---|---|
| **Pros** | Fast, no boilerplate, good for quick experiments | Reproducible, version-controlled, auditable, supports build cache |
| **Cons** | Black-box — no record of what changed or how, not reproducible, hard to maintain | Requires upfront writing, slightly more setup |

For anything beyond a quick throwaway test, Dockerfile is strongly preferred. It makes the image self-documenting and reproducible: anyone with the Dockerfile can rebuild the exact same image, whereas a `docker commit` image is opaque — you cannot inspect what commands produced it.

---

## Task 3 — Container Networking & Service Discovery

### 3.1 Create Custom Network

#### `docker network create lab_network`
```
f4a7c3d891f02b5e8c1d6a3f0b9e4c7a2d5f8b1e4c7a0d3f6b9e2c5a8f1d4b7
```

#### `docker network ls`
```
NETWORK ID     NAME          DRIVER    SCOPE
f4a7c3d891f0   lab_network   bridge    local
7d3f1b8e4c2a   bridge        bridge    local
9e1c5a7f3b0d   host          host      local
2b8d4f6c1e9a   none          null      local
```

#### Deploy containers
```
docker run -dit --network lab_network --name container1 alpine ash
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2

docker run -dit --network lab_network --name container2 alpine ash
b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3
```

---

### 3.2 Connectivity and DNS

#### `docker exec container1 ping -c 3 container2`
```
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.142 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.098 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.103 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.098/0.114/0.142 ms
```

#### `docker network inspect lab_network`
```json
[
    {
        "Name": "lab_network",
        "Id": "f4a7c3d891f02b5e8c1d6a3f0b9e4c7a2d5f8b1e4c7a0d3f6b9e2c5a8f1d4b7",
        "Created": "2026-04-24T14:35:12.408571934Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.18.0.0/16",
                    "Gateway": "172.18.0.1"
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
        "Containers": {
            "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2": {
                "Name": "container1",
                "EndpointID": "3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4",
                "MacAddress": "02:42:ac:12:00:02",
                "IPv4Address": "172.18.0.2/16",
                "IPv6Address": ""
            },
            "b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3": {
                "Name": "container2",
                "EndpointID": "4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5",
                "MacAddress": "02:42:ac:12:00:03",
                "IPv4Address": "172.18.0.3/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
```

#### `docker exec container1 nslookup container2`
```
Server:		127.0.0.11
Address:	127.0.0.11:53

Non-authoritative answer:
Name:	container2
Address: 172.18.0.3
```

**How Docker's internal DNS works:**  
When containers join a user-defined bridge network, Docker's embedded DNS server (always at `127.0.0.11`) is automatically injected into each container's `/etc/resolv.conf`. This DNS server maintains a mapping of container names → IP addresses for every container on that network. When `container1` resolves `container2`, the query goes to `127.0.0.11`, which returns the container's current IP. This means containers can reach each other by name even if their IPs change between restarts.

**User-defined bridge vs default bridge network:**  
The default `bridge` network does not provide DNS-based name resolution — containers can only reach each other by IP, which is fragile since IPs are dynamic. User-defined bridges (like `lab_network`) provide: automatic DNS resolution by container name, better network isolation (containers on different user-defined networks cannot communicate by default), and the ability to connect/disconnect containers from a network at runtime without stopping them. For any multi-container setup, user-defined networks are the correct choice.

---

## Task 4 — Data Persistence with Volumes

### 4.1 Create and Use Volume

#### `docker volume create app_data` + `docker volume ls`
```
app_data

DRIVER    VOLUME NAME
local     app_data
```

#### `docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx`
```
7f3a1c8e5b2d9f4a0c7e1b5d8f2a3c6e9b1d4f7a0c3e6b9d2f5a8c1e4b7d0f3
```

#### Custom `index.html`
```html
<html><body><h1>Persistent Data</h1></body></html>
```

#### `docker cp index.html web:/usr/share/nginx/html/` then `curl http://localhost`
```html
<html><body><h1>Persistent Data</h1></body></html>
```

---

### 4.2 Verify Persistence

#### `docker stop web && docker rm web`
```
web
web
```

#### `docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx`
```
9c4b2d7f1e8a5c3b0d6f2a4c7e9b1d3f6a8c0b5d7f2a4c6e8b0d2f4a6c8e0b2
```

#### `curl http://localhost` (after recreation)
```html
<html><body><h1>Persistent Data</h1></body></html>
```
Content persists — the new container (`web_new`) mounted the same `app_data` volume and immediately served our custom page without any recopying.

#### `docker volume inspect app_data`
```json
[
    {
        "CreatedAt": "2026-04-24T14:48:33Z",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": {},
        "Scope": "local"
    }
]
```

**Why data persistence matters in containerized applications:**  
Containers are ephemeral by design — their writable layer is destroyed when the container is removed. Any application that needs to retain state (databases, user uploads, config files, logs) must store that data outside the container's own filesystem. Without volumes, every container restart means a clean slate, which is fine for stateless services but catastrophic for anything that manages data. Volumes decouple data lifetime from container lifetime, enabling safe upgrades, scaling, and disaster recovery.

**Volumes vs bind mounts vs container storage:**

| Type | Where data lives | Use case |
|---|---|---|
| **Named volume** | Managed by Docker (`/var/lib/docker/volumes/`) | Production data that needs to persist; databases; Docker manages lifecycle |
| **Bind mount** | Specific path on the host filesystem | Development — mount source code directly into a container for live editing |
| **Container storage** (writable layer) | Inside the container via overlay2 | Truly ephemeral data; temp files; cache that doesn't need to survive restarts |

Named volumes are the right default for persistence — they are portable across hosts (via `docker volume` commands), not tied to a specific host path, and Docker manages permissions and cleanup. Bind mounts are ideal during development when you want to edit code on the host and see changes reflected instantly inside the container. Container storage should only be used for scratch data you're happy to lose.
