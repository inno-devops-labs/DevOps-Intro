# Submission 6 - Container Fundamentals with Docker

## Environment

- Host VM: Ubuntu 24.04.4 LTS
- Docker installed from official Docker APT repository

Verification:

```text
docker: command not found (before installation)
```

After installation, Docker commands executed successfully in the lab tasks.

## Task 1 - Container Lifecycle & Image Management

### 1.1 Basic container operations

Commands:

```bash
docker ps -a
docker pull ubuntu:latest
docker images ubuntu
docker inspect ubuntu:latest --format 'Image size bytes: {{.Size}}'
docker inspect ubuntu:latest --format 'Layer count: {{len .RootFS.Layers}}'
docker run -it --name ubuntu_container ubuntu:latest
```

Output snippets:

```text
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

```text
latest: Pulling from library/ubuntu
817807f3c64e: Pull complete
Digest: sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
```

```text
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   186072bba1b2        119MB         31.7MB
Image size bytes: 29741401
Layer count: 1
```

Inside `ubuntu_container`:

```text
PRETTY_NAME="Ubuntu 24.04.4 LTS"
VERSION="24.04.4 LTS (Noble Numbat)"
...
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0   4596  3992 pts/0    Ss   18:23   0:00 /bin/bash
root          11  0.0  0.0   7896  4136 pts/0    R+   18:25   0:00 ps aux
```

### 1.2 Image export and dependency analysis

Commands:

```bash
docker save -o ubuntu_image.tar ubuntu:latest
ls -lh ubuntu_image.tar
docker rmi ubuntu:latest
docker rm ubuntu_container
docker rmi ubuntu:latest
```

Output:

```text
-rw------- 1 david docker 31M Mar 19 21:26 ubuntu_image.tar
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container b95d3fb6fcaa is using its referenced image 186072bba1b2
ubuntu_container
Untagged: ubuntu:latest
Deleted: sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c
```

Analysis:

- First `docker rmi ubuntu:latest` failed because `ubuntu_container` still referenced that image.
- Docker enforces image-container dependency: an image cannot be removed while existing containers (even stopped ones) depend on it.
- After removing the container, image deletion succeeded.

Tar file explanation:

- `docker save` tar includes image layers, image config JSON, and manifest metadata required to load the image later (`docker load`).
- Tar size (~31M) is close to content size (31.7MB) and smaller than the reported disk usage due to Docker storage overhead/metadata.

## Task 2 - Custom Image Creation & Analysis

### 2.1 Deploy and customize Nginx

Commands:

```bash
docker run -d -p 80:80 --name nginx_container nginx
curl -s http://localhost | head -n 8
cat > index.html
docker cp index.html nginx_container:/usr/share/nginx/html/
curl -s http://localhost
```

Output snippets:

```text
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
...
Status: Downloaded newer image for nginx:latest
c7db02e64660c16a3d9eff5d47641cae2fe1886889a9b98501d94bc29322091d
```

Custom `index.html` used:

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

Verification after copy:

```text
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

### 2.2 Create and test custom image

Commands:

```bash
docker commit nginx_container my_website:latest
docker images my_website
docker rm -f nginx_container
docker run -d -p 80:80 --name my_website_container my_website:latest
docker diff my_website_container
```

Output:

```text
sha256:73a3a53b6c6fb337a0a5dd7e7ce9841fd6faa34c9c7e72d5a8e1b528aca9ccc5
IMAGE               ID             DISK USAGE   CONTENT SIZE   EXTRA
my_website:latest   73a3a53b6c6f        237MB         62.9MB
nginx_container
3175ae87266621e9c25aa39cf130654c456c30b5494e6a4b9076da18f1b40d20
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

Analysis of `docker diff`:

- `C` means changed paths inside container writable layer.
- Nginx runtime modifies files like PID and config-related paths during startup.

Reflection (`docker commit` vs Dockerfile):

- `docker commit` advantages: quick, convenient for experiments, easy snapshot of live container.
- `docker commit` disadvantages: weak reproducibility, hidden/manual history, poor reviewability.
- Dockerfile is preferred for production because it is declarative, versioned, repeatable, and CI/CD-friendly.

## Task 3 - Container Networking & Service Discovery

Commands:

```bash
docker network create lab_network
docker network ls
docker run -dit --network lab_network --name container1 alpine ash
docker run -dit --network lab_network --name container2 alpine ash
docker exec container1 ping -c 3 container2
docker network inspect lab_network
docker exec container1 nslookup container2
```

Key outputs:

```text
NETWORK ID     NAME          DRIVER    SCOPE
4a3acace4237   bridge        bridge    local
ea37cd16effe   host          host      local
c1091e960912   lab_network   bridge    local
fb229e408e88   none          null      local
```

```text
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.654 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.076 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.071 ms
--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
```

Network inspect (IPs):

```text
"container1" -> "IPv4Address": "172.18.0.2/16"
"container2" -> "IPv4Address": "172.18.0.3/16"
```

DNS resolution:

```text
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:
Name:   container2
Address: 172.18.0.3
```

Analysis:

- Docker embedded DNS on user-defined bridge resolves container names to container IPs.
- That is why `container1` can reach `container2` by name without manual hosts configuration.

Comparison with default bridge:

- User-defined bridge has automatic DNS-based name resolution.
- Better isolation and explicit network scoping.
- Easier service-to-service communication and cleaner multi-container setups.

## Task 4 - Data Persistence with Volumes

Commands:

```bash
docker volume create app_data
docker volume ls
docker rm -f my_website_container
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
cat > index.html
docker cp index.html web:/usr/share/nginx/html/
curl -s http://localhost
docker stop web
docker rm web
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
curl -s http://localhost
docker volume inspect app_data
```

Output:

```text
app_data
DRIVER    VOLUME NAME
local     app_data
my_website_container
069dc3b93a88a18eac6123bccc5d7d1f231e5a2a30e6687fc9bc280445a9443f
<html><body><h1>Persistent Data</h1></body></html>
Successfully copied 2.05kB to web:/usr/share/nginx/html/
web
web
3440edb57cab5a541742a56d5aac89b79889f267625ed348647cf89258c88528
[
    {
        "CreatedAt": "2026-03-19T21:29:02+03:00",
        "Driver": "local",
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Scope": "local"
    }
]
```

Analysis:

- Volume data outlives container lifecycle, so content remains after container removal/recreation.
- This is critical for stateful data (uploads, configs, DB files) in containerized applications.

Comparison:

- Volumes: managed by Docker, best for persistent app data in containers.
- Bind mounts: map host paths directly, useful in development and when host-side file control is needed.
- Container writable layer: ephemeral, removed with container, not suitable for persistent data.

## Final reflection

Lab results demonstrate core Docker fundamentals:

- images and containers have strict dependency rules;
- container state can be captured into custom images;
- Docker networking provides built-in service discovery;
- volumes provide persistence across container lifecycle events.
