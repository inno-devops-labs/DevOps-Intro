# Lab 6 Submission - Container Fundamentals with Docker

## Task 1

Started with a clean slate - no containers or images:

```sh
$ docker ps -a
```

```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

```sh
$ docker images
```

```
REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
```

Pulled Ubuntu image:

```sh
$ docker pull ubuntu:latest
```

```
latest: Pulling from library/ubuntu
b8a35db46e38: Pulling fs layer
b8a35db46e38: Download complete
b8a35db46e38: Pull complete
Digest: sha256:66460d557b25769b102175144d538d88219c077c678a49af4afca6fbfc1b5252
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
```

```sh
$ docker images ubuntu
```

```
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    e149199029d1   5 weeks ago   101MB
```

Image size: 101MB, 7 layers.

Checked OS version:

```sh
$ docker run --name ubuntu_container ubuntu:latest cat /etc/os-release
```

```
PRETTY_NAME="Ubuntu 24.04.3 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.3 LTS (Noble Numbat)"
VERSION_CODENAME=noble
```

Exported the image to tar:

```sh
$ docker save -o ubuntu_image.tar ubuntu:latest
$ ls -lh ubuntu_image.tar
```

```
-rw-------@ 1 theother_archee  staff    98M Nov  6 22:16 ubuntu_image.tar
```

Tar file is 98MB vs 101MB image size - slightly compressed.

Tried to remove image while container exists:

```sh
$ docker rmi ubuntu:latest
```

```
Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container 027493ce0270 is using its referenced image e149199029d1
```

Removed the container, then deletion worked:

```sh
$ docker stop ubuntu_container && docker rm ubuntu_container
$ docker rmi ubuntu:latest
```

```
Untagged: ubuntu:latest
Untagged: ubuntu@sha256:66460d557b25769b102175144d538d88219c077c678a49af4afca6fbfc1b5252
Deleted: sha256:e149199029d15548c4f6d2666e88879360381a2be8a1b747412e3fe91fb1d19d
Deleted: sha256:ab34259f9ca5d315bec1b17d9f1ca272e84dedd964a8988695daf0ec3e0bbc2e
```

**Analysis:**

Docker won't delete an image if containers reference it, even stopped ones. Prevents accidental data loss - containers might be restarted later. The tar export has all layers, metadata, and configs - basically a full snapshot you can load elsewhere with `docker load`.

## Task 2

Deployed Nginx container:

```sh
$ docker run -d -p 80:80 --name nginx_container nginx
```

Original welcome page:

```sh
$ curl http://localhost
```

```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
...
```

Created custom HTML:

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

Copied it into container:

```sh
$ docker cp index.html nginx_container:/usr/share/nginx/html/
$ curl http://localhost
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

Committed container to image:

```sh
$ docker commit nginx_container my_website:latest
$ docker images my_website
```

```
REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
my_website   latest    d39e842e4c4f   1 second ago   173MB
```

Removed old container and deployed from custom image:

```sh
$ docker rm -f nginx_container
$ docker run -d -p 80:80 --name my_website_container my_website:latest
$ curl http://localhost
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

Custom content persisted. Checked the filesystem diff:

```sh
$ docker diff my_website_container
```

```
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

**Analysis:**

`docker diff` shows `C` (Changed), `A` (Added), `D` (Deleted). Here we see `C` for runtime files like nginx.pid created at startup. Our index.html doesn't show up because it's part of the image, not a runtime change.

`docker commit` is quick for testing but has no history/traceability. Dockerfiles are better - reproducible, version-controlled, production-ready. Use commit for experiments, Dockerfiles for real work.

## Task 3

Created custom network:

```sh
$ docker network create lab_network
$ docker network ls
```

```
NETWORK ID     NAME          DRIVER    SCOPE
3729ec83b295   bridge        bridge    local
e776b14296e2   host          host      local
39043654cc44   lab_network   bridge    local
88b67a18b8a6   none          null      local
```

Deployed two containers:

```sh
$ docker run -dit --network lab_network --name container1 alpine ash
$ docker run -dit --network lab_network --name container2 alpine ash
```

Tested connectivity:

```sh
$ docker exec container1 ping -c 3 container2
```

```
PING container2 (192.168.97.3): 56 data bytes
64 bytes from 192.168.97.3: seq=0 ttl=64 time=0.132 ms
64 bytes from 192.168.97.3: seq=1 ttl=64 time=0.513 ms
64 bytes from 192.168.97.3: seq=2 ttl=64 time=0.313 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.132/0.319/0.513 ms
```

Containers can ping each other by name. Network inspection:

```sh
$ docker network inspect lab_network
```

```
[
    {
        "Name": "lab_network",
        "Driver": "bridge",
        "Containers": {
            "84ef3197866c0a6cc1a347349443872bb19b523bcac46bd6e26287373d9639b9": {
                "Name": "container1",
                "IPv4Address": "192.168.97.2/24"
            },
            "18831f9536c9305143dc4215ef733eb66ba428a3cf033c9705db4defa1da7949": {
                "Name": "container2",
                "IPv4Address": "192.168.97.3/24"
            }
        }
    }
]
```

DNS resolution:

```sh
$ docker exec container1 nslookup container2
```

```
Server:		127.0.0.11
Address:	127.0.0.11:53

Non-authoritative answer:
Name:	container2
Address: 192.168.97.3
```

**Analysis:**

Docker runs a DNS server at 127.0.0.11 in each container. On user-defined networks, container names are auto-registered. So `ping container2` resolves to IP automatically - no hardcoded IPs needed. User-defined networks beat default bridge because of DNS resolution and better isolation. Default bridge needs IP addresses and has less isolation.

## Task 4

Created named volume:

```sh
$ docker volume create app_data
$ docker volume ls
```

```
DRIVER    VOLUME NAME
local     app_data
```

Deployed container with volume:

```sh
$ docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
```

Created custom HTML:

```html
<html><body><h1>Persistent Data</h1></body></html>
```

Copied to volume:

```sh
$ docker cp index_volume.html web:/usr/share/nginx/html/index.html
$ curl http://localhost
```

```
<html><body><h1>Persistent Data</h1></body></html>
```

Destroyed and recreated container:

```sh
$ docker stop web && docker rm web
$ docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
$ curl http://localhost
```

```
<html><body><h1>Persistent Data</h1></body></html>
```

Data persisted. Volume inspection:

```sh
$ docker volume inspect app_data
```

```
[
    {
        "CreatedAt": "2025-11-06T22:18:56+03:00",
        "Driver": "local",
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Scope": "local"
    }
]
```

**Analysis:**

Containers are ephemeral - delete them and data is gone. Volumes persist data across container lifecycles. Use volumes for databases, logs, configs, user uploads - anything that needs to survive. Volumes are Docker-managed and portable. Bind mounts map host directories directly - good for dev but less portable. Container storage is ephemeral - only for temp files. For production, volumes are the way to go.
