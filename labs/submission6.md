# Task 1

## 1.1 Basic Container Operations

First I checked existing containers:

```
$ docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

No containers running. Then I pulled the Ubuntu image:

```
$ docker pull ubuntu:latest
latest: Pulling from library/ubuntu
66a4bbbfab88: Pull complete 
Digest: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Status: Downloaded newer image for ubuntu:latest

$ docker images ubuntu
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    d1e2e92c075e   4 weeks ago   139MB
```

The image is 139 MB and has 1 layer.

Then I ran an interactive container and explored it:

```
$ docker run -it --name ubuntu_container ubuntu:latest

root@aa53253b5836:/# cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian

root@aa53253b5836:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4296  3420 pts/0    Ss   08:45   0:00 /bin/bash
root        10  0.0  0.0   7628  3524 pts/0    R+   08:46   0:00 ps aux

root@aa53253b5836:/# exit
```

Only two processes were running: bash (PID 1) and ps itself.

## 1.2 Image Export and Dependency Analysis

I exported the image to a tar file:

```
$ docker save -o ubuntu_image.tar ubuntu:latest
$ ls -lh ubuntu_image.tar
-rw-------@ 1 chrnegor  staff    28M Mar 11 11:46 ubuntu_image.tar
```

The tar file is 28 MB while the image size reported by Docker is 139 MB. The tar is smaller because `docker save` compresses the layer data.

Then I tried to remove the image:

```
$ docker rmi ubuntu:latest
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container aa53253b5836 is using its referenced image d1e2e92c075e
```

Image removal failed because a container (`ubuntu_container`) still depends on it. Docker prevents deleting images that have containers referencing them, even stopped ones. This is because the container's filesystem is built on top of the image layers — removing the image would break the container.

After removing the container, the image was deleted successfully:

```
$ docker rm ubuntu_container
ubuntu_container

$ docker rmi ubuntu:latest
Untagged: ubuntu:latest
Deleted: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
```

The exported tar file contains the image layers, metadata (manifest.json), and config JSON. It can be used to load the image back with `docker load` on any machine without pulling from a registry.

# Task 2

## 2.1 Deploy and Customize Nginx

I ran the nginx container and checked the default page:

```
$ docker run -d -p 80:80 --name nginx_container nginx
489a5f3e181e7c7a20ad4d353af0c31f17b448d7299b43c7338ba0148ef5831a

$ curl http://localhost
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, nginx is successfully installed and working.
...
<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

Then I created a custom `index.html` and copied it into the container:

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

```
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

## 2.2 Create and Test Custom Image

I committed the container to a new image, removed the old one, and ran a new container from it:

```
$ docker commit nginx_container my_website:latest
sha256:be72f037eecf32e840c1bf6bc66827b535ad9c44a4556d4b54c95c7f8769fa60

$ docker images my_website
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
my_website   latest    be72f037eecf   4 seconds ago   255MB

$ docker rm -f nginx_container
nginx_container

$ docker run -d -p 80:80 --name my_website_container my_website:latest
735c74d639a47a8dc03eca6a2ebf9abb10bfdfe440398102ff799701cf1ec9c3

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

Custom page is served from the new container.

## docker diff Output

```
$ docker diff my_website_container
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

All entries are marked with `C` (Changed). There are no `A` (Added) or `D` (Deleted) paths. The diff compares the running container filesystem to the image layers. The changed paths are runtime state: nginx writes its pid file to `/run/nginx.pid` and may update config under `/etc/nginx`. So we see config and runtime dirs as changed, not the custom HTML we put in `/usr/share/nginx/html/` — that was already baked into the image by `docker commit`.

## Reflection: docker commit vs Dockerfile

**docker commit** — Fast and simple when you change something inside a running container and want to save it. No need to write a Dockerfile. Downside: no clear history of what changed, hard to reproduce, and you can accidentally include temporary or sensitive data. Image can get bloated.

**Dockerfile** — Reproducible and versioned. Each step is visible, layers are cached, and the build is documented. Better for teams and CI/CD. Disadvantage: you have to define every step in advance; quick one-off changes are more work. For production and repeatable builds, Dockerfile is the right choice; commit is useful for quick experiments or saving a debugging state.

# Task 3

## 3.1 Create Custom Network

```
$ docker network create lab_network
5ef7489cc44d0c2fdd3743f0fa149fd43ab933d50799eb022876fc265fb1eea8

$ docker network ls
NETWORK ID     NAME          DRIVER    SCOPE
905af6e6f153   bridge        bridge    local
5ab85e56769f   cda           bridge    local
cc416e7aa693   host          host      local
5ef7489cc44d   lab_network   bridge    local
d2f7d482697f   none          null      local
```

```
$ docker run -dit --network lab_network --name container1 alpine ash
b14310a776b9d9a5993b8860960eeb7315cce4c584014b2bb4a40c2eebd24994

$ docker run -dit --network lab_network --name container2 alpine ash
94ec92cb90b3599b16b1f761b24e1eaf2c10d4e24afcf55ce8d4305eea1e30c2
```

## 3.2 Connectivity and DNS

Ping from container1 to container2 by name:

```
$ docker exec container1 ping -c 3 container2
PING container2 (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.195 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.282 ms
64 bytes from 172.19.0.3: seq=2 ttl=64 time=0.137 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.137/0.204/0.282 ms
```

Network inspection (both containers and their IPs):

```
$ docker network inspect lab_network
[
    {
        "Name": "lab_network",
        "Id": "5ef7489cc44d0c2fdd3743f0fa149fd43ab933d50799eb022876fc265fb1eea8",
        "Created": "2026-03-11T10:55:03.670697338Z",
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
        "Containers": {
            "94ec92cb90b3599b16b1f761b24e1eaf2c10d4e24afcf55ce8d4305eea1e30c2": {
                "Name": "container2",
                "IPv4Address": "172.19.0.3/16"
            },
            "b14310a776b9d9a5993b8860960eeb7315cce4c584014b2bb4a40c2eebd24994": {
                "Name": "container1",
                "IPv4Address": "172.19.0.2/16"
            }
        }
    }
]
```

DNS resolution (Docker's embedded DNS at 127.0.0.11):

```
$ docker exec container1 nslookup container2
Server:		127.0.0.11
Address:	127.0.0.11:53

Name:	container2
Address: 172.19.0.3
```

**Analysis:** Docker runs an internal DNS server (127.0.0.11 inside the container) for user-defined networks. Containers on the same network resolve each other by name to the right IP, so you do not need to hardcode IPs.

**Comparison:** On the default bridge you only get resolution by IP unless you use `--link`. On a user-defined bridge like `lab_network`, DNS by container name works out of the box, isolation is better, and you can add or remove containers without recreating the network.

# Task 4

## 4.1 Create and Use Volume

```
$ docker volume create app_data
app_data

$ docker volume ls
DRIVER    VOLUME NAME
local     app_data
...
```

```
$ docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
652df7d06df84d4e65a0e90b9bb34409174aeacca4f360f9bf9d46c39bf1869e
```

Custom HTML used:

```html
<html><body><h1>Persistent Data</h1></body></html>
```

```
$ docker cp index.html web:/usr/share/nginx/html/
Successfully copied 2.05kB to web:/usr/share/nginx/html/

$ curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>
```

## 4.2 Verify Persistence

After removing the container and starting a new one with the same volume, the content is still there:

```
$ docker stop web && docker rm web
web
web

$ docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
dd4ad39a745ae54a059aee850810f1018676fed64a0987b3e6960f818f82447e

$ curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>
```

Volume inspection:

```
$ docker volume inspect app_data
[
    {
        "CreatedAt": "2026-03-11T10:56:14Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

**Analysis:** Containers are ephemeral — when you remove one, its writable layer is gone. If the app stores data only inside the container, that data is lost on `docker rm`. Volumes store data on the host (e.g. under `/var/lib/docker/volumes/`). So you can replace the container and attach the same volume; the data stays. That is important for databases, configs, uploads, or any state you need to keep across restarts or redeploys.

**Comparison:** Volumes are managed by Docker and survive container removal; use them for app data when you do not need a fixed host path. Bind mounts map a specific host path into the container; use them when you need to edit files from the host or reuse existing dirs. Container storage (writable layer) is the default place for changes inside the container and is lost when the container is removed; use only for temporary data.
