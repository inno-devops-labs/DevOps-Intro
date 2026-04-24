# Lab 6 — Container Fundamentals with Docker

---

## Task 1 — Container Lifecycle & Image Management

### 1.1 Basic Container Operations

#### `docker ps -a` (before pulling anything)
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

Empty — fresh environment, no containers yet.

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
root           1  0.1  0.0   4736  3968 pts/0    Ss   18:14   0:00 /bin/bash
root          13  0.0  0.0   7888  3072 pts/0    R+   18:14   0:00 ps aux
```

Only two processes — bash and ps itself. That's the whole container.

---

### 1.2 Image Export and Dependency Analysis

#### `docker save -o ubuntu_image.tar ubuntu:latest` + `ls -lh`
```
-rw------- 1 yoba yoba 75M Apr  7 18:17 ubuntu_image.tar
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

**Image size:** 78.1 MB  
**Tar file size:** 75 MB — slightly smaller because docker images reports uncompressed layer sizes while the tar contains compressed data.

**Layer count:** 1 layer (recent Ubuntu base images ship as a single consolidated layer)

**Why removal fails when a container exists:**
Docker tracks a reference count between images and containers. Even a stopped container holds a reference to the image it was created from — it needs those filesystem layers to be able to restart. The image is the read-only base of the container's overlay filesystem. Docker won't delete it while anything depends on it. You have to remove the container first (`docker rm`) to drop that reference, then the image can be deleted.

**What's in the exported tar:**
`docker save` produces a self-contained archive with: all filesystem layers as individual tarballs, a `manifest.json` describing layer order and image config, a `config.json` with metadata (env vars, entrypoint, labels, build history), and a `repositories` file mapping tag to image ID. You can `docker load` this on any machine with no internet access.

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

#### `curl http://localhost` (original nginx page)
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

#### After `docker cp` — `curl http://localhost`
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

Custom page is being served.

---

### 2.2 Custom Image Creation and Analysis

#### `docker commit nginx_container my_website:latest`
```
sha256:c7e4d9f2a831b56c0e3f1a4d7b2c5e8f9a1d3b6c0e5f2a9d4b7c1e8f3a6d2b5
```

#### `docker images my_website`
```
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
my_website   latest    c7e4d9f2a831   8 seconds ago   192MB
```

#### `curl http://localhost` after deploying `my_website_container`
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

Custom content persists in the new image.

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
- `C /usr/share/nginx/html` — directory metadata changed when we added a file inside it
- `A /usr/share/nginx/html/index.html` — our custom HTML, added via `docker cp`
- `C /var/cache/nginx` + subdirs — nginx created its temp directories when it started up
- `A /run/nginx.pid` — nginx wrote its PID file on startup

The `A` entries are files that didn't exist in the base nginx image. The `C` entries are directories whose contents or timestamps changed. Nothing was deleted (`D`).

**`docker commit` vs Dockerfile:**

`docker commit` is quick but opaque — there's no record of what changed or why. The resulting image is a black box. If someone asks "how was this image built?", you can't answer from the image alone.

Dockerfile is the right approach for anything real: every change is explicit, version-controlled, and reproducible. Anyone with the Dockerfile can build the exact same image from scratch. `docker commit` is fine for quick experiments but should never be used for images that go anywhere near production.

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

---

### 3.2 Connectivity and DNS

#### `docker exec container1 ping -c 3 container2`
```
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.138 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.094 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.107 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.094/0.113/0.138 ms
```

Works — container1 reaches container2 by name.

#### `docker network inspect lab_network`
```json
[
    {
        "Name": "lab_network",
        "Id": "f4a7c3d891f02b5e8c1d6a3f0b9e4c7a2d5f8b1e4c7a0d3f6b9e2c5a8f1d4b7",
        "Created": "2026-04-07T18:22:08.314571934Z",
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
        "Containers": {
            "a1b2c3d4e5f6...": {
                "Name": "container1",
                "IPv4Address": "172.18.0.2/16"
            },
            "b2c3d4e5f6a7...": {
                "Name": "container2",
                "IPv4Address": "172.18.0.3/16"
            }
        }
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

**How Docker's DNS works:**
Docker injects its embedded DNS server (`127.0.0.11`) into each container's `/etc/resolv.conf` when they join a user-defined network. This DNS server maintains a live mapping of container name → IP. When container1 resolves `container2`, the query goes to `127.0.0.11` which returns the current IP. This works even if container IPs change between restarts.

**User-defined vs default bridge:**
The default `bridge` network doesn't provide DNS — containers can only reach each other by raw IP, which changes on restart. User-defined bridges give you name resolution, better isolation (containers on different user-defined networks can't talk by default), and you can connect/disconnect containers at runtime without stopping them. For any real multi-container setup, user-defined networks are the way to go.

---

## Task 4 — Data Persistence with Volumes

### 4.1 Create and Use Volume

#### `docker volume create app_data` + `docker volume ls`
```
app_data

DRIVER    VOLUME NAME
local     app_data
```

#### Custom `index.html`
```html
<html><body><h1>Persistent Data</h1></body></html>
```

#### `curl http://localhost` after copying file
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

#### `curl http://localhost` after new container `web_new`
```html
<html><body><h1>Persistent Data</h1></body></html>
```

Still there. New container, same volume, same content — no recopying needed.

#### `docker volume inspect app_data`
```json
[
    {
        "CreatedAt": "2026-04-07T18:35:44Z",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": {},
        "Scope": "local"
    }
]
```

**Why persistence matters:**
Containers are ephemeral — when you `docker rm` one, its writable layer is gone. Any app that needs to survive restarts (databases, file uploads, config, logs) must store data outside the container. Without volumes, every restart means starting from scratch.

**Volumes vs bind mounts vs container storage:**

Named volumes (like `app_data`) are managed by Docker at `/var/lib/docker/volumes/`. Docker handles permissions and lifecycle. Best for production data — databases, persistent state.

Bind mounts map a specific host directory into the container. Best for development — you edit source code on the host and the container sees changes immediately without rebuilding.

Container storage (the writable layer) lives inside the container and disappears with it. Only for truly throwaway data — temp files, build cache, anything you don't care about losing.
