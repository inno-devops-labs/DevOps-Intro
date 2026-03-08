# lab 6

## 1.
### 1.1.

<details>
<summary>Outputs</summary>

```bash
platon@arch ~> docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
platon@arch ~> docker pull ubuntu:latest
latest: Pulling from library/ubuntu
01d7766a2e4a: Pull complete 
Digest: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
platon@arch ~> docker images
                                                                                                                        i Info →   U  In Use
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   bbdabce66f1b       78.1MB             0B        
platon@arch ~ [125]> docker run -ti --name ubuntu_container ubuntu:latest
root@5e07f8fca169:/# cat /etc/os-release  
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
root@5e07f8fca169:/# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.1  0.0   4596  3960 pts/0    Ss   09:19   0:00 /bin/bash
root          10  0.0  0.0   7896  4124 pts/0    R+   09:20   0:00 ps aux
root@5e07f8fca169:/# exit
exit
platon@arch ~> docker ps -a
CONTAINER ID   IMAGE           COMMAND       CREATED              STATUS                      PORTS     NAMES
5e07f8fca169   ubuntu:latest   "/bin/bash"   About a minute ago   Exited (0) 56 seconds ago             ubuntu_container
```

</details>

**Image size**: The `ubuntu:latest` image has a size of approx 78.1MB.

**Layer count**: 6 layers, as shown by the `docker history` command output, and maybe one is the base layer, beacuse just one layer has a size of 78.1MB, and the rest are 0B.

```bash
platon@arch ~> docker history ubuntu:latest 
IMAGE          CREATED       CREATED BY                                      SIZE      COMMENT
bbdabce66f1b   3 weeks ago   /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B        
<missing>      3 weeks ago   /bin/sh -c #(nop) ADD file:1ae27d2ef43693611…   78.1MB    
<missing>      3 weeks ago   /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B        
<missing>      3 weeks ago   /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B        
<missing>      3 weeks ago   /bin/sh -c #(nop)  ARG LAUNCHPAD_BUILD_ARCH     0B        
<missing>      3 weeks ago   /bin/sh -c #(nop)  ARG RELEASE                  0B        
```

### 1.2.

<details>
<summary>Outputs</summary>

```bash
platon@arch ~> docker save -o ubuntu_image.tar ubuntu:latest
platon@arch ~> ls -lh ubuntu_image.tar 
-rw------- 1 platon users 77M Mar  8 13:27 ubuntu_image.tar
platon@arch ~> docker rmi  ubuntu:latest 
Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container 5e07f8fca169 is using its referenced image bbdabce66f1b
platon@arch /t/tmp.2xkQ72ZtjI [1]> docker rm ubuntu_container 
ubuntu_container
platon@arch ~> docker rmi ubuntu:latest 
Untagged: ubuntu:latest
Untagged: ubuntu@sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Deleted: sha256:bbdabce66f1b7dde0c081a6b4536d837cd81dd322dd8c99edd68860baf3b2db3
Deleted: sha256:efafae78d70c98626c521c246827389128e7d7ea442db31bc433934647f0c791
```

</details>

**Tar file size comparison with image size**: The tar file size is 77M, which is a little bit smaller than the image size of 78.1M.

**Error message from the first removal attempt**: The error message shows that the image cannot be removed bcs there is a container that is using it.

**Analysis: Why does image removal fail when a container exists? Explain the dependency relationship**: Docker images and containers have a parent-child dependency: a container is a writable instance that references its image's read-only layers. Docker tracks this reference count and refuses to delete an image while any container (even a stopped one) still points to it. Removing the container first drops the reference, allowing the image to be deleted safely.

**Explanation: What is included in the exported tar file?**: Produces a tarred repository to the standard output stream. Contains all parent layers, and all tags + versions, or specified repo:tag, for each argument provided.

## 2.

### 2.1.

<details>
<summary>Outputs</summary>

```bash
platon@arch ~> docker run -d -p 80:80 --name nginx_container nginx
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
206356c42440: Pull complete
b47f187216b6: Pull complete
1ad233904a11: Pull complete
eedda9fd8786: Pull complete
35ff83c394d6: Pull complete
17d0911eaf62: Pull complete
df0b66c867e4: Pull complete
Digest: sha256:0236ee02dcbce00b9bd83e0f5fbc51069e7e1161bd59d99885b3ae1734f3392e
Status: Downloaded newer image for nginx:latest
d6921bf3772e3dff1672b8b568cb06e06e69145273e6a13ddd9c0fea9720722d
platon@arch ~> curl https://localhost
curl: (7) Failed to connect to localhost port 443 after 0 ms: Could not connect to server
platon@arch ~ [7]> curl http://localhost
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

<p><em>Thank you for using nginx!</em></p>
</body>
</html>
platon@arch ~> docker cp index.html nginx_container:/usr/share/nginx/html/
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/
platon@arch ~> curl http://localhost
<html>
  <head>
    <title> The best </title>
  </head>
  <body>
    <h1> website </h1>
  </body>
</html>
```

</details>

**Original Nginx welcome page**: The default `curl http://localhost` returned the standard nginx welcome page confirming the container is running and port 80 is mapped correctly. HTTPS (`curl https://localhost`) failed because nginx is not configured for TLS.

**Custom HTML content**:

```html
<html>
  <head>
    <title> The best </title>
  </head>
  <body>
    <h1> website </h1>
  </body>
</html>
```

The file was copied into the container with `docker cp` and `curl http://localhost` confirmed nginx is now serving the custom page.

### 2.2.

<details>
<summary>Outputs</summary>

```bash
platon@arch ~> docker commit nginx_container my_website:latest
sha256:2fadf5def02b2b1a3d1a6c624b261bd67d13dff6ce682ad2c5ff4cbd13c61f56
platon@arch ~> docker images my_website
IMAGE               ID             DISK USAGE   CONTENT SIZE   EXTRA
my_website:latest   2fadf5def02b        161MB             0B
platon@arch ~> docker rm -f nginx_container
nginx_container
platon@arch ~> docker run -d -p 80:80 --name my_website_container my_website:latest
b34c2f37b84d46023f63b49741b680389209e9a6f76b4743e2555f3432e28180
platon@arch ~> curl http://localhost
<html>
  <head>
    <title> The best </title>
  </head>
  <body>
    <h1> website </h1>
  </body>
</html>
platon@arch ~> docker diff my_website_container
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

</details>

**Analysis: Explain the diff output**: All entries are `C` (Changed) — these are files nginx modifies on every startup. The custom `index.html` doesn't appear because it was already committed into the image.

**Reflection: `docker commit` vs Dockerfile**: `docker commit` is fast and interactive but opaque — there's no record of what changed or why, making images hard to reproduce. A Dockerfile is explicit, version-controlled, and reproducible, which makes it the right choice for anything beyond quick local experiments.


## 3.

### 3.1.

<details>
<summary>Outputs</summary>

```bash
platon@arch ~> docker network create lab_network
66161eda62e302441548169591d670eb3e553de21cc25b496ad53904f102eeab
platon@arch ~> docker network ls
NETWORK ID     NAME          DRIVER    SCOPE
78f4e911dd05   bridge        bridge    local
87d136875d4b   host          host      local
66161eda62e3   lab_network   bridge    local
272e749c2d34   none          null      local
platon@arch ~> docker run -dit --network lab_network --name container1 alpine ash
Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
589002ba0eae: Pull complete
Digest: sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659
Status: Downloaded newer image for alpine:latest
f009574277c2ba812b2f36982fb4e6d85c25c68054dac5af80000ba622081562
platon@arch ~> docker run -dit --network lab_network --name container2 alpine ash
a91305a422737e4a345fbd2ce52e916e301181f4b25d4e711f99ecbec2502461
```

</details>

### 3.2.

<details>
<summary>Outputs</summary>

```bash
platon@arch ~> docker exec container1 ping -c 3 container2
PING container2 (172.17.0.3): 56 data bytes
64 bytes from 172.17.0.3: seq=0 ttl=64 time=0.081 ms
64 bytes from 172.17.0.3: seq=1 ttl=64 time=0.092 ms
64 bytes from 172.17.0.3: seq=2 ttl=64 time=0.101 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.081/0.091/0.101 ms
platon@arch ~> docker network inspect lab_network
[
    {
        "Name": "lab_network",
        "Id": "66161eda62e302441548169591d670eb3e553de21cc25b496ad53904f102eeab",
        "Created": "2026-03-08T15:11:25.590539912+03:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.17.0.0/16",
                    "Gateway": "172.17.0.1"
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
        "Options": {},
        "Labels": {},
        "Containers": {
            "a91305a422737e4a345fbd2ce52e916e301181f4b25d4e711f99ecbec2502461": {
                "Name": "container2",
                "EndpointID": "f1c44a51cc6d67ddff8055dd307f1500b73e7b1c6d59f35690b67fad858bac77",
                "MacAddress": "7a:8d:17:a6:9c:f6",
                "IPv4Address": "172.17.0.3/16",
                "IPv6Address": ""
            },
            "f009574277c2ba812b2f36982fb4e6d85c25c68054dac5af80000ba622081562": {
                "Name": "container1",
                "EndpointID": "e382a44966d0503a505e3b8bcfdc14d0e2b49499af05a110694930f5fcf476b6",
                "MacAddress": "0a:9a:35:2e:f2:ac",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            }
        }
    }
]
platon@arch ~> docker exec container1 nslookup container2
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:
Name:   container2
Address: 172.17.0.3
```

</details>

**Ping**: 0% packet loss, container1 reached container2 by name at `172.17.0.3`.

**Network inspect**: container1 — `172.17.0.2`, container2 — `172.17.0.3`, both on subnet `172.17.0.0/16`.

**DNS resolution**: `nslookup container2` returned `172.17.0.3` via Docker's embedded DNS at `127.0.0.11`.

**Analysis: How does Docker's internal DNS enable name-based communication?**: Docker runs an embedded DNS server at `127.0.0.11` inside each container on a user-defined network. It maps container names to their current IPs, so containers resolve each other by name without needing to know IPs in advance.

**Comparison: User-defined bridge vs default bridge**: The default bridge network has no DNS — containers can only reach each other by IP. User-defined networks add automatic name resolution, better isolation, and support for connecting/disconnecting containers at runtime.

## 4.

### 4.1.

<details>
<summary>Outputs</summary>

```bash
platon@arch ~> docker volume create app_data
app_data
platon@arch ~> docker volume ls
DRIVER    VOLUME NAME
local     app_data
platon@arch ~> docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
1b197e842931c2f373e2f244ad342c5d1fd3fe20c2adc137c30577aa79f4d72d
platon@arch ~> docker cp index.html web:/usr/share/nginx/html/
Successfully copied 2.05kB to web:/usr/share/nginx/html/
platon@arch ~> curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>
platon@arch ~> docker stop web && docker rm web
web
web
platon@arch ~> docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
bec444b950c71c9cc69591084c3f3d2928aade042d400d015c7858f99a56360f
platon@arch ~> curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>
```

</details>

**Volume creation**: `docker volume create app_data` creates a named volume managed by Docker, stored on the host at `/var/lib/docker/volumes/app_data/_data`.

**Persistence**: After copying `index.html` into the container (which wrote it to the volume), the original `web` container was stopped and removed. A new container `web_new` mounting the same `app_data` volume immediately served the same custom page — the data survived container deletion.

### 4.2.

<details>
<summary>Outputs</summary>

```bash
platon@arch ~> docker volume inspect app_data
[
    {
        "CreatedAt": "2026-03-08T15:19:59+03:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

</details>

**Volume inspect fields**: `Driver: local` means Docker manages storage on the host filesystem. `Mountpoint` is the actual host path where the volume data lives — this directory exists independently of any container. `Scope: local` means the volume is only available on this Docker host (not a distributed driver like NFS).

**Volumes vs bind mounts**: A bind mount maps a specific host path into a container — the user controls the location. A named volume is managed entirely by Docker: Docker picks the storage location, handles permissions, and the volume persists until explicitly deleted with `docker volume rm`. Volumes are portable across environments (no hardcoded host paths) and the recommended way to persist production data.

**Analysis: Why is data persistence important in containerized applications?**: Containers are ephemeral by design — when a container is removed, everything written to its writable layer is lost. Stateful applications (databases, uploaded files, application state) must survive container restarts and redeployments. Without persistent storage, every container replacement means data loss. Volumes decouple data from the container lifecycle so stateful workloads can run reliably in containerized environments.

**Comparison: Volumes vs bind mounts vs container storage**: Container storage (the writable layer) is ephemeral — it exists only while the container is alive and is the slowest option due to copy-on-write overhead. Use it only for truly temporary data. Bind mounts map a specific host path into a container — the user controls where data lives, making them ideal for development (e.g. mounting source code so edits are reflected instantly), but they are not portable because they rely on a hardcoded host path. Named volumes are managed entirely by Docker — Docker picks the storage location, handles permissions, and the volume persists until explicitly deleted. Volumes are portable, have no host-path coupling, and are the recommended choice for any production data that needs to survive container replacements.
