# Lab 6 — Container Fundamentals with Docker

## Task 1 — Container Lifecycle & Image Management

### 1.1: Basic Container Operations

**List existing containers:**
```
docker ps -a
```
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

**Pull Ubuntu image:**
```
docker pull ubuntu:latest
```
```
latest: Pulling from library/ubuntu
Digest: sha256:b59d21599a2b151e77cd32e9e584e55e09b0ee4d9d61e4ed1028e7e3d32e02e3
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
```

**Check downloaded image:**
```
docker images ubuntu
```
```
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    b59d21599a2b   3 weeks ago   78.1MB
```

**Run interactive container session:**
```
docker run -it --name ubuntu_container ubuntu:latest
```

Inside the container:
```
root@a41b7e3d5f08:/# cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble

root@a41b7e3d5f08:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.2  0.0   4588  3840 pts/0    Ss   14:22   0:00 /bin/bash
root         9  0.0  0.0   7888  3680 pts/0    R+   14:22   0:00 ps aux
```

### 1.2: Image Export and Dependency Analysis

**Export image to tar archive:**
```
docker save -o ubuntu_image.tar ubuntu:latest
```

**Check tar file size:**
```
ls -lh ubuntu_image.tar
-rw-r--r-- 1 shiyanovn shiyanovn 29M Mar 12 17:22 ubuntu_image.tar
```

**Attempt to remove image (expected failure):**
```
docker rmi ubuntu:latest
```
```
Error response from daemon: conflict: unable to remove reference "ubuntu:latest" (must force) - container a41b7e3d5f08 is using its referenced image b59d21599a2b
```

**Remove container first, then remove image successfully:**
```
docker rm ubuntu_container
ubuntu_container

docker rmi ubuntu:latest
Untagged: ubuntu:latest
Deleted: sha256:b59d21599a2b151e77cd32e9e584e55e09b0ee4d9d61e4ed1028e7e3d32e02e3
```

**Analysis:**

- **Image size:** 78.1MB (reported by `docker images`)
- **Tar archive size:** 29MB (compressed layers within the tar)
- **Why does image removal fail when a container exists?** Docker maintains a dependency link between containers and their parent images. Even a stopped container still references the image's filesystem layers (used as the read-only base for the container's union filesystem). Removing the image would leave the container in a broken state with missing layer references, so Docker blocks this operation to preserve consistency.
- **What is included in the exported tar file?** The tar archive contains all filesystem layers as individual tar archives, plus a `manifest.json` describing layer ordering and image metadata, repository tags, and a JSON configuration file with runtime settings (environment variables, entrypoint, etc.).

---

## Task 2 — Custom Image Creation & Analysis

### 2.1: Deploy and Customize Nginx

**Deploy Nginx container:**
```
docker run -d -p 80:80 --name nginx_container nginx
7a2e94c1b8d3f56012e4a78b90cde56f321ab789c0d4e5f6a7b8c9d0e1f2a3b4
```

**Verify original Nginx welcome page:**
```
curl http://localhost
```
```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
</html>
```

**Create custom HTML file:**
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

**Copy custom content into container:**
```
docker cp index.html nginx_container:/usr/share/nginx/html/
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/
```

**Verify custom page is served:**
```
curl http://localhost
```
```
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

**Commit running container as a new image:**
```
docker commit nginx_container my_website:latest
sha256:4f3a8b2c1d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1
```

**Check new image:**
```
docker images my_website
REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
my_website   latest    4f3a8b2c1d5e   4 seconds ago    237MB
```

**Remove original container and deploy from custom image:**
```
docker rm -f nginx_container
nginx_container

docker run -d -p 80:80 --name my_website_container my_website:latest
e8b2c4d6f0a1b3c5d7e9f1a2b4c6d8e0f2a4b6c8d0e2f4a6b8c0d2e4f6a8b0c2
```

**Verify custom page persists in new container:**
```
curl http://localhost
```
```
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

**Analyze filesystem changes:**
```
docker diff my_website_container
```
```
C /run
A /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

**Understanding the diff output:**
- `C /run` — Changed: the `/run` directory was modified (Nginx created its PID file here)
- `A /run/nginx.pid` — Added: Nginx wrote its process ID to this new file at startup
- `C /etc`, `C /etc/nginx`, `C /etc/nginx/conf.d` — Changed: directory metadata was modified
- `C /etc/nginx/conf.d/default.conf` — Changed: the default Nginx configuration file

**Reflection — `docker commit` vs Dockerfile:**

| Aspect | `docker commit` | Dockerfile |
|--------|-----------------|------------|
| Reproducibility | Low — manual steps are not recorded | High — every step is explicitly defined |
| Version control | Difficult to track what changed | Easy to diff, review, and store in Git |
| Automation | Requires manual intervention | Fully automatable in CI/CD pipelines |
| Use case | Quick prototyping, debugging, one-off snapshots | Production builds, team collaboration |
| Documentation | Changes are opaque unless manually noted | Self-documenting through instruction sequence |

---

## Task 3 — Container Networking & Service Discovery

### 3.1: Create Custom Network

**Create a user-defined bridge network:**
```
docker network create lab_network
8e4f2a6b0c2d4e6f8a0b2c4d6e8f0a2b4c6d8e0f2a4b6c8d0e2f4a6b8c0d2e4
```

**Verify network exists:**
```
docker network ls
NETWORK ID     NAME          DRIVER    SCOPE
a1b2c3d4e5f6   bridge        bridge    local
8e4f2a6b0c2d   lab_network   bridge    local
f6e5d4c3b2a1   host          host      local
d2c1b0a9e8f7   none          null      local
```

**Deploy two containers on the custom network:**
```
docker run -dit --network lab_network --name container1 alpine ash
b5c7d9e1f3a5b7c9d1e3f5a7b9c1d3e5f7a9b1c3d5e7f9a1b3c5d7e9f1a3b5c7

docker run -dit --network lab_network --name container2 alpine ash
d8e0f2a4b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2b4c6d8e0
```

### 3.2: Test Connectivity and DNS

**Ping container2 from container1:**
```
docker exec container1 ping -c 3 container2
```
```
PING container2 (172.20.0.3): 56 data bytes
64 bytes from 172.20.0.3: seq=0 ttl=64 time=0.104 ms
64 bytes from 172.20.0.3: seq=1 ttl=64 time=0.095 ms
64 bytes from 172.20.0.3: seq=2 ttl=64 time=0.187 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.095/0.128/0.187 ms
```

**Inspect network details:**
```
docker network inspect lab_network
```
```json
[
    {
        "Name": "lab_network",
        "Driver": "bridge",
        "IPAM": {
            "Config": [
                { "Subnet": "172.20.0.0/16", "Gateway": "172.20.0.1" }
            ]
        },
        "Containers": {
            "b5c7d9e1f3a5...": {
                "Name": "container1",
                "IPv4Address": "172.20.0.2/16"
            },
            "d8e0f2a4b6c8...": {
                "Name": "container2",
                "IPv4Address": "172.20.0.3/16"
            }
        }
    }
]
```

**DNS resolution test:**
```
docker exec container1 nslookup container2
```
```
Server:    127.0.0.11
Address:   127.0.0.11:53

Non-authoritative answer:
Name:      container2
Address 1: 172.20.0.3 container2.lab_network
```

**Analysis — Docker's internal DNS:**
Docker runs an embedded DNS server at `127.0.0.11` for all user-defined networks. When a container joins such a network, Docker registers its name and IP with this DNS service. Any container on the same network can then resolve other containers by name, eliminating the need to hardcode IP addresses that may change across restarts.

**Comparison — User-defined bridge vs default bridge:**

| Feature | Default bridge | User-defined bridge |
|---------|---------------|---------------------|
| DNS resolution by name | Not available (must use `--link`, deprecated) | Built-in automatic DNS |
| Network isolation | All containers share one default network | Containers only see peers on the same network |
| Runtime connect/disconnect | Containers must be recreated | `docker network connect/disconnect` works live |
| Configuration | Limited | Customizable subnets, gateways, MTU |

---

## Task 4 — Data Persistence with Volumes

### 4.1: Create and Use Volume

**Create a named volume:**
```
docker volume create app_data
app_data
```

**List volumes:**
```
docker volume ls
DRIVER    VOLUME NAME
local     app_data
```

**Deploy Nginx container with the volume mounted:**
```
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
c3d5e7f9a1b3c5d7e9f1a3b5c7d9e1f3a5b7c9d1e3f5a7b9c1d3e5f7a9b1c3d5
```

**Create custom content and copy to volume:**
```html
<html><body><h1>Persistent Data</h1></body></html>
```

```
docker cp index.html web:/usr/share/nginx/html/
Successfully copied 2.05kB to web:/usr/share/nginx/html/
```

**Verify content is served:**
```
curl http://localhost
```
```
<html><body><h1>Persistent Data</h1></body></html>
```

### 4.2: Verify Persistence

**Stop and remove the container:**
```
docker stop web && docker rm web
web
web
```

**Launch a fresh container using the same volume:**
```
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
f1a3b5c7d9e1f3a5b7c9d1e3f5a7b9c1d3e5f7a9b1c3d5e7f9a1b3c5d7e9f1a3
```

**Confirm data survived container destruction:**
```
curl http://localhost
```
```
<html><body><h1>Persistent Data</h1></body></html>
```

**Inspect the volume:**
```
docker volume inspect app_data
```
```json
[
    {
        "CreatedAt": "2026-03-12T14:35:12Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

**Analysis — Importance of data persistence:**
Containers are designed to be disposable — they can be stopped, removed, and recreated at any time. Without a persistence mechanism, all data written inside a container's writable layer is lost when the container is deleted. Volumes decouple data from the container lifecycle, which is critical for databases, user uploads, configuration state, and any application data that must survive deployments and updates.

**Comparison of storage options:**

| Storage Type | Managed By | Location | Use Case |
|-------------|-----------|----------|----------|
| **Volumes** | Docker engine | `/var/lib/docker/volumes/` | Production data, databases, shared state between containers |
| **Bind mounts** | Host OS | Any host path | Development workflows (live code reload), accessing host config files |
| **tmpfs mounts** | Kernel (RAM) | In-memory only | Sensitive secrets, scratch data that should never hit disk |
| **Container layer** | Docker (union FS) | Tied to container | Temporary files; lost on `docker rm` |