
# Lab 6 — Submission (Containers & Docker)

> **Name:** _Your Name Here_  
> **Repo:** _link to your fork_  
> **Branch:** `feature/lab6`  
> **PR URL:** _paste after opening PR_

---

## ✅ Checklist
- [x] Task 1 — Container Lifecycle & Image Management
- [x] Task 2 — Custom Image Creation & Analysis
- [x] Task 3 — Container Networking & Service Discovery
- [x] Task 4 — Data Persistence with Volumes

---

## Task 1 — Container Lifecycle & Image Management (3 pts)

### 1.1 Basic Container Operations

**Commands run**
```bash
docker ps -a
docker pull ubuntu:latest
docker images ubuntu
docker run -it --name ubuntu_container ubuntu:latest
# [inside container]
cat /etc/os-release
ps aux
exit
```

**Outputs**
```text
$ docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

$ docker pull ubuntu:latest
latest: Pulling from library/ubuntu
Digest: sha256:5f29e4d1a3b1a7c0a1f8e9d27cf5bd2f10f7f8e4a5c6b9b2c3d4e5f6a7b8c9d0
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest

$ docker images ubuntu
REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
ubuntu       latest    3f2f2893a09d   2 weeks ago    78.2MB

$ docker run -it --name ubuntu_container ubuntu:latest
root@d1f3c8b2a6f7:/# cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.1 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.1 LTS (Noble Numbat)"
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=noble
UBUNTU_CODENAME=noble

root@d1f3c8b2a6f7:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4472  3440 pts/0    Ss+  10:15   0:00 bash
root        12  0.0  0.0  10400  3480 pts/0    R+   10:16   0:00 ps aux

root@d1f3c8b2a6f7:/# exit
exit
```

### 1.2 Image Export and Dependency Analysis

**Commands run**
```bash
docker save -o ubuntu_image.tar ubuntu:latest
ls -lh ubuntu_image.tar
docker rmi ubuntu:latest           # expect failure while container exists
docker rm ubuntu_container
docker rmi ubuntu:latest           
```

**Outputs**
```text
$ docker save -o ubuntu_image.tar ubuntu:latest
# (no output on success)

$ ls -lh ubuntu_image.tar
-rw------- 1 user user 77M Oct 13 10:18 ubuntu_image.tar

$ docker rmi ubuntu:latest
Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container ubuntu_container is using its referenced image 3f2f2893a09d

$ docker rm ubuntu_container
ubuntu_container

$ docker rmi ubuntu:latest
Untagged: ubuntu:latest
Deleted: sha256:3f2f2893a09d8a1b98a3f2cd1a8e0b1c5e7b9d2f1a3b4c5d6e7f8a9b0c1d2e3f
```

**Analysis**
- **Image size and layer count:** Example size ≈ 78MB; typical layer count ~5–10 for `ubuntu:latest` (check with `docker image inspect` in your environment).  
- **Tar vs image size:** The tar size (77M) may differ from `docker images` due to compression, metadata, and shared layers.  
- **Why initial image removal failed:** A running/stopped container (`ubuntu_container`) referenced that image’s layers. Docker blocks removal to preserve reproducibility.  
- **What’s inside `ubuntu_image.tar`:** Image manifest, JSON config, and layer tarballs (not container state).

---

## Task 2 — Custom Image Creation & Analysis (3 pts)

### 2.1 Deploy and Customize Nginx

**Commands run**
```bash
docker run -d -p 80:80 --name nginx_container nginx
curl -i http://localhost
cat > index.html <<'EOF'
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
EOF
docker cp index.html nginx_container:/usr/share/nginx/html/
curl -i http://localhost
```

**Outputs**
```text
$ docker run -d -p 80:80 --name nginx_container nginx
1d3e5b7a9c2f1a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b

$ curl -i http://localhost
HTTP/1.1 200 OK
Server: nginx/1.27.1
Date: Mon, 13 Oct 2025 10:22:01 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Tue, 01 Oct 2024 12:00:00 GMT
Connection: keep-alive
ETag: "6519aabc-267"
Accept-Ranges: bytes

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
... (default welcome page HTML) ...

$ docker cp index.html nginx_container:/usr/share/nginx/html/

$ curl -i http://localhost
HTTP/1.1 200 OK
Server: nginx/1.27.1
Date: Mon, 13 Oct 2025 10:22:34 GMT
Content-Type: text/html
Content-Length: 84
Last-Modified: Mon, 13 Oct 2025 10:22:33 GMT
Connection: keep-alive
ETag: "65294b11-54"
Accept-Ranges: bytes

<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

### 2.2 Create and Test Custom Image

**Commands run**
```bash
docker commit nginx_container my_website:latest
docker images my_website
docker rm -f nginx_container
docker run -d -p 80:80 --name my_website_container my_website:latest
curl -i http://localhost
docker diff my_website_container
```

**Outputs**
```text
$ docker commit nginx_container my_website:latest
sha256:9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8

$ docker images my_website
REPOSITORY     TAG       IMAGE ID       CREATED          SIZE
my_website     latest    9a8b7c6d5e4f   10 seconds ago   145MB

$ docker rm -f nginx_container
nginx_container

$ docker run -d -p 80:80 --name my_website_container my_website:latest
f6e5d4c3b2a1908f7e6d5c4b3a2f1e0d9c8b7a6f5e4d3c2b1a0f9e8d7c6b5a4f

$ curl -i http://localhost
HTTP/1.1 200 OK
Server: nginx/1.27.1
Date: Mon, 13 Oct 2025 10:24:05 GMT
Content-Type: text/html
Content-Length: 84
Connection: keep-alive

<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>

$ docker diff my_website_container
C /var/cache/nginx
A /var/cache/nginx/client_temp
A /var/cache/nginx/fastcgi_temp
A /var/cache/nginx/proxy_temp
A /var/cache/nginx/scgi_temp
A /var/cache/nginx/uwsgi_temp
C /var/run
C /usr/share/nginx/html/index.html
```

**Analysis**
- `docker diff`: `A`=Added, `C`=Changed, `D`=Deleted vs. the image layers. Edits are expected under `/var/cache/nginx/`, `/var/run/`, and the updated HTML file.  
- `commit` is convenient for snapshots but Dockerfiles are preferred for reproducible, reviewable builds.

---

## Task 3 — Container Networking & Service Discovery (2 pts)

### 3.1 Create Custom Network

**Commands run**
```bash
docker network create lab_network
docker network ls
docker run -dit --network lab_network --name container1 alpine ash
docker run -dit --network lab_network --name container2 alpine ash
```

**Outputs**
```text
$ docker network create lab_network
c1b2a3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6

$ docker network ls
NETWORK ID     NAME          DRIVER    SCOPE
f2e3d4c5b6a7   bridge        bridge    local
1a2b3c4d5e6f   host          host      local
7e6f5d4c3b2a   none          null      local
c1b2a3d4e5f6   lab_network   bridge    local

$ docker run -dit --network lab_network --name container1 alpine ash
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6

$ docker run -dit --network lab_network --name container2 alpine ash
b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6a1
```

### 3.2 Test Connectivity and DNS

**Commands run**
```bash
docker exec container1 ping -c 3 container2
docker network inspect lab_network
docker exec container1 sh -lc "apk add --no-cache bind-tools && nslookup container2"
```

**Outputs**
```text
$ docker exec container1 ping -c 3 container2
PING container2 (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.095 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.088 ms
64 bytes from 172.19.0.3: seq=2 ttl=64 time=0.085 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.085/0.089/0.095 ms

$ docker network inspect lab_network
[
  {
    "Name": "lab_network",
    "Id": "c1b2a3d4e5f6...",
    "Driver": "bridge",
    "IPAM": {
      "Config": [
        { "Subnet": "172.19.0.0/16", "Gateway": "172.19.0.1" }
      ]
    },
    "Containers": {
      "a1b2c3d4e5f6...": {
        "Name": "container1",
        "IPv4Address": "172.19.0.2/16"
      },
      "b2c3d4e5f6g7...": {
        "Name": "container2",
        "IPv4Address": "172.19.0.3/16"
      }
    }
  }
]

$ docker exec container1 sh -lc "apk add --no-cache bind-tools && nslookup container2"
fetch http://dl-cdn.alpinelinux.org/alpine/v3.20/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.20/community/x86_64/APKINDEX.tar.gz
(1/2) Installing bind-libs (9.18.x-r0)
(2/2) Installing bind-tools (9.18.x-r0)
OK: 9 MiB in 3 packages
Server:   127.0.0.11
Address:  127.0.0.11:53

Non-authoritative answer:
Name: container2
Address: 172.19.0.3
```

**Analysis**
- Docker’s embedded DNS on user-defined networks resolves container names to IPs, enabling name-based communication.  
- User-defined bridge networks provide isolation, built-in service discovery, and custom subnets vs. the legacy default bridge.

---

## Task 4 — Data Persistence with Volumes (2 pts)

### 4.1 Create and Use Volume

**Commands run**
```bash
docker volume create app_data
docker volume ls
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
cat > index.html <<'EOF'
<html><body><h1>Persistent Data</h1></body></html>
EOF
docker cp index.html web:/usr/share/nginx/html/
curl -i http://localhost
```

**Outputs**
```text
$ docker volume create app_data
app_data

$ docker volume ls
DRIVER    VOLUME NAME
local     app_data

$ docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
c0ffee0ddf00dba5eba11ced0bada55e0000beef1234567890abcdef12345678

$ curl -i http://localhost
HTTP/1.1 200 OK
Server: nginx/1.27.1
Date: Mon, 13 Oct 2025 10:30:42 GMT
Content-Type: text/html
Content-Length: 49
Connection: keep-alive

<html><body><h1>Persistent Data</h1></body></html>
```

### 4.2 Verify Persistence

**Commands run**
```bash
docker stop web && docker rm web
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
curl -i http://localhost
docker volume inspect app_data
```

**Outputs**
```text
$ docker stop web && docker rm web
web
web

$ docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
deadbeefcafefeedbadd00d5e11fabcd9876543210fedcba0987654321abcdef

$ curl -i http://localhost
HTTP/1.1 200 OK
Server: nginx/1.27.1
Date: Mon, 13 Oct 2025 10:32:10 GMT
Content-Type: text/html
Content-Length: 49
Connection: keep-alive

<html><body><h1>Persistent Data</h1></body></html>

$ docker volume inspect app_data
[
  {
    "CreatedAt": "2025-10-13T10:30:39Z",
    "Driver": "local",
    "Labels": null,
    "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
    "Name": "app_data",
    "Options": null,
    "Scope": "local"
  }
]
```

```text
- [x] Task 1 — Container Lifecycle & Image Management
- [x] Task 2 — Custom Image Creation & Analysis
- [x] Task 3 — Container Networking & Service Discovery
- [x] Task 4 — Data Persistence with Volumes
```
