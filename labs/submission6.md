# Lab 6 — Container Fundamentals with Docker

## Task 1 — Container Lifecycle & Image Management

### 1.1 Basic Container Operations

**Commands executed**

```bash
# List all containers
docker ps -a

# Pull ubuntu image and show images
docker pull ubuntu:latest
docker images ubuntu

# Run interactive container
docker run -it --name ubuntu_container ubuntu:latest
# inside container:
# cat /etc/os-release
# ps aux
# exit
```

**Actual output**

```
$ docker ps -a
CONTAINER ID   IMAGE         COMMAND    CREATED          STATUS                      PORTS     NAMES
c70422130145   hello-world   "/hello"   10 minutes ago   Exited (0) 10 minutes ago             sad_napier

$ docker pull ubuntu:latest
docker images ubuntu
latest: Pulling from library/ubuntu
01d7766a2e4a: Pull complete
fd8cda969ed2: Download complete
Digest: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest


IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   d1e2e92c075e        119MB         31.7MB
nikita@Nikitj:~$


root@814f9edad5d9:/# cat /etc/os-release
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


root@814f9edad5d9:/# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0   4588  3988 pts/0    Ss   06:34   0:00 /bin/bash
root          10  0.0  0.0   7888  3992 pts/0    R+   06:35   0:00 ps aux
```

### 1.2 Image Export and Dependency Analysis

**Commands executed**

```bash
# Save image to tar
docker save -o ubuntu_image.tar ubuntu:latest
ls -lh ubuntu_image.tar

# Try to remove image (while container exists)
docker rmi ubuntu:latest

# Remove container and remove image
docker rm ubuntu_container
docker rmi ubuntu:latest
```

**Actual output**

```
$ docker save -o ubuntu_image.tar ubuntu:latest
$ ls -lh ubuntu_image.tar
-rw------- 1 nikita nikita 31M мар 10 11:08 ubuntu_image.tar

$ docker rmi ubuntu:latest
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container 814f9edad5d9 is using its referenced image d1e2e92c075e

$ docker rm ubuntu_container
$ docker rmi ubuntu:latest
ubuntu_container
Untagged: ubuntu:latest
Deleted: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
```

**Documented values:**
- Image ID: `d1e2e92c075e`
- Image size: 119MB (virtual) / 31.7MB (content)
- Layer count: 7 layers
- Tar file size: **31MB**

**Analysis:**  
Image removal fails when a container exists because Docker enforces a strict dependency relationship. Containers (even stopped ones) reference the image layers they were created from. Deleting the image while a container still exists would break that container. This is a built-in safety mechanism. The image is the immutable template; containers are the runtime instances. Once the container was removed with `docker rm`, the reference was cleared and `docker rmi` succeeded.

**Explanation:**  
The exported `ubuntu_image.tar` file contains:
- All filesystem layers (as separate tar archives)
- `manifest.json` (image configuration and layer order)
- Repository/tag mapping
- Layer metadata files  
This makes the image fully portable — it can be loaded on any Docker host with `docker load -i ubuntu_image.tar`.
---

## Task 2 — Custom Image Creation & Analysis

### 2.1: Deploy and Customize Nginx

**Deploy original Nginx container:**
```sh
docker run -d -p 80:80 --name nginx_container nginx
```
Container started: `ca7a1cb385b3...`

**Original Nginx welcome page (first curl):**
```sh
curl http://localhost
```

![alt text](image-7.png)

**Custom `index.html` file created locally:**
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

```sh
docker cp index.html nginx_container:/usr/share/nginx/html/
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
Custom page is now served correctly.

### 2.2: Create and Test Custom Image

**Commit the modified container to a new image:**
```sh
docker commit nginx_container my_website:latest
docker images my_website
```
```
REPOSITORY    TAG       IMAGE ID       CREATED          SIZE
my_website    latest    ca037530ba13   ... moments ago   237MB (virtual) / 62.9MB (content)
```

**Remove original container and run new one from custom image:**
```sh
docker rm -f nginx_container
docker run -d -p 80:80 --name my_website_container my_website:latest
```
New container: `752f2d89fb52...`

**Verify custom content still present:**
```sh
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

**Filesystem changes (docker diff):**
```sh
docker diff my_website_container
```
```
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

**Analysis of `docker diff` output:**
- `C` = Changed  
All listed paths show **changed** status, because:
  - `/usr/share/nginx/html/index.html` was **overwritten** (considered a change to an existing file)
  - Nginx runtime files in `/etc/nginx` and `/run` were modified during startup/configuration (PID file, possibly slight config tweaks)
  - No files were **added** (`A`) or **deleted** (`D`) in a way that docker diff highlighted beyond these changes.

The most important change (our custom `index.html`) appears as a **modification** rather than an addition because the original file already existed in the base image.

**Reflection: Advantages and disadvantages of `docker commit` vs Dockerfile**

**`docker commit` advantages:**
- Very fast and simple - great for quick experiments and debugging
- No need to write or maintain build instructions
- Captures exact runtime state (including manual changes, installed packages, logs, etc.)

**`docker commit` disadvantages:**
- Opaque - no history of what changes were made or why
- Not reproducible - you can't easily recreate the same image later
- Creates inefficient images (no layer optimization, includes unnecessary runtime artifacts)
- Poor auditability and versioning
- Harder to collaborate or CI/CD integrate


**Conclusion:** Use `docker commit` only for temporary / one-off debugging or when you don't plan to reuse or share the image. For any real application or team work, always prefer **Dockerfile**-based builds.

---

## Task 3 — Container Networking & Service Discovery

### 3.1: Create Custom Network

**Create user-defined bridge network:**
```sh
docker network create lab_network
```
Network ID: `b19fcf212b6f49d0cb54fa1edb26ce3dbc8cd3cd31905a71d932e38ece9a398a`

**List all networks:**
```sh
docker network ls
```
```
NETWORK ID     NAME          DRIVER    SCOPE
7538b8bea543   bridge        bridge    local
933144fe078f   host          host      local
b19fcf212b6f   lab_network   bridge    local
132cbec47b7c   none          null      local
```

### 3.2: Test Connectivity and DNS

**Deploy two Alpine containers on the custom network:**
```sh
docker run -dit --network lab_network --name container1 alpine ash
docker run -dit --network lab_network --name container2 alpine ash
```
Container IDs:  
- container1: `3db13e9817f1...`  
- container2: `76a67314ea21...`

**Test container-to-container communication by name:**
```sh
docker exec container1 ping -c 3 container2
```
```
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.042 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.045 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.047 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.042/0.044/0.047 ms
```

Successful ping confirms connectivity using container name instead of IP.

**Network inspection (relevant Containers section):**
```sh
docker network inspect lab_network
```
```json
"Containers": {
    "3db13e9817f17778c97e6101b25565ba179240d750f67bbac6d2032c4bb74819": {
        "Name": "container1",
        "EndpointID": "ada7d5566d1cb9d9767fcb9e59ad08719bdc7f0db36bef2b97a31239c8b8fffd",
        "MacAddress": "66:ab:1c:98:0b:f9",
        "IPv4Address": "172.18.0.2/16",
        "IPv6Address": ""
    },
    "76a67314ea21c2208d7e7941496a1fdb339e1ec074669fb977e2f6f8bf6d81fb": {
        "Name": "container2",
        "EndpointID": "8ba91a2f8d8e2ca7889fb4c31a1c45293cb79886813b5d6bf1e8f9ab7517e9e9",
        "MacAddress": "fa:64:8f:fd:c6:ce",
        "IPv4Address": "172.18.0.3/16",
        "IPv6Address": ""
    }
}
```

- container1 IP: `172.18.0.2`  
- container2 IP: `172.18.0.3`

**DNS resolution test:**
```sh
docker exec container1 nslookup container2
```
```
Server:         127.0.0.11
Address:        127.0.0.11#53

Non-authoritative answer:
Name:   container2
Address: 172.18.0.3
```

**Analysis: How does Docker's internal DNS enable container-to-container communication by name?**  
Docker runs an embedded DNS server inside each container on user-defined networks (at IP `127.0.0.11`). When a container starts and joins a user-defined network, Docker automatically registers its name and assigned IP in this DNS resolver. Containers on the same network can then resolve each other by name (e.g., `container2`) instead of hard-coding IPs. This provides automatic service discovery without external tools.

**Comparison: Advantages of user-defined bridge networks over the default bridge network**  
- **Built-in DNS name resolution** - containers can communicate using names (default bridge only supports IP addresses)  
- **Better isolation** - each user-defined network gets its own subnet; containers on different user networks cannot communicate unless explicitly connected  
- **Cleaner architecture** - easier to group related services (e.g., frontend + backend + db) in one network  
- **Customizable** - supports options like custom subnets, gateways, MTU, etc.  
- **Avoids port conflicts** - default bridge shares the host's network namespace more directly, which can cause port binding issues  

Default bridge is simpler for quick single-container tests but lacks DNS and strong isolation - user-defined networks are the recommended choice for multi-container applications.

---

## Task 4 — Data Persistence with Volumes

### 4.1: Create and Use Volume

**Create named volume:**
```sh
docker volume create app_data
docker volume ls
```
```
DRIVER    VOLUME NAME
local     app_data
```

**Deploy container with volume mount:**
```sh
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
```
Container ID: `25d316a2f3be...`

**Custom `index.html` content used:**
```html
<html><body><h1>Persistent Data</h1></body></html>
```

**Copy file into volume-mounted container and verify:**
```sh
docker cp index.html web:/usr/share/nginx/html/
curl http://localhost
```

![alt text](image-8.png)

### 4.2: Verify Persistence

**Stop and remove the original container:**
```sh
docker stop web && docker rm web
```
```
web
web
```

**Recreate a new container using the same volume:**
```sh
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
```
New container ID: `ce0d7a6ae69f...`

**Verify data still exists after container recreation:**
```sh
curl http://localhost
```
```
<html><body><h1>Persistent Data</h1></body></html>
```
The custom content persisted perfectly.

**Volume inspection:**
```sh
docker volume inspect app_data
```
```json
[
    {
        "CreatedAt": "2026-03-10T13:35:44+03:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

**Analysis: Why is data persistence important in containerized applications?**  
Containers are designed to be ephemeral (short-lived and disposable). Any data written to the container’s internal filesystem is deleted when the container is removed (`docker rm`). Without persistence, stateful applications (databases, user uploads, configuration files, logs, etc.) would lose all data on every restart, scaling event, or failure. Volumes solve this by storing data outside the container lifecycle on the host (or remote storage), enabling reliable, production-grade deployments.

**Comparison: Volumes vs Bind Mounts vs Container Storage**

| Type                  | Description                                      | Persistence | Use Case                              | Pros                              | Cons                              |
|-----------------------|--------------------------------------------------|-------------|---------------------------------------|-----------------------------------|-----------------------------------|
| **Volumes** | Docker-managed directories on host               | Yes         | Production databases, shared data     | Portable, backed up, remote drivers (cloud), secure | Slightly slower than bind mounts |
| **Bind Mounts**       | Direct mapping of host directory/path            | Yes         | Development (hot-reload), config files| Instant sync, easy editing on host| Host OS dependent, security risks |
| **Container Storage** (ephemeral) | Inside container filesystem                   | No          | Temporary caches, logs, scratch space | Fastest access                    | Data lost on `docker rm`          |

**When to use each:**
- **Volumes** $\rightarrow$ Production (databases, persistent app data)
- **Bind mounts** $\rightarrow$ Local development (code changes reflected immediately)
- **Container storage** $\rightarrow$ Only for temporary/non-critical data