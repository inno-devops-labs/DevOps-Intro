# Lab 6 — Docker Fundamentals

## Task 1 — Container Lifecycle & Image Management

### Existing containers

```text
docker ps -a

CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

### Pull Ubuntu image

```text
docker pull ubuntu:latest
docker images ubuntu

REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    c35e29c94501   2 weeks ago   78.1MB
```

### Run Ubuntu container and inspect it

```text
docker run -it --name ubuntu_container ubuntu:latest
```

Inside the container:

```text
cat /etc/os-release

PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
UBUNTU_CODENAME=noble
```

```text
ps aux

USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4112  3328 pts/0    Ss   23:47   0:00 /bin/bash
root        15  0.0  0.0   8540  4352 pts/0    R+   23:47   0:00 ps aux
```

### Save image to tar archive

```text
docker save -o ubuntu_image.tar ubuntu:latest
ls -lh ubuntu_image.tar

-rw------- 1 andrey andrey 77M Mar 27 02:48 ubuntu_image.tar
```

### Attempt to remove image while container still exists

```text
docker rmi ubuntu:latest

Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container 0bdbca25355e is using its referenced image c35e29c94501bc21680f16e27d3d4769a04f34057d0b8d2ad278b5e4efea5f8d
```

### Remove container and then remove image

```text
docker rm ubuntu_container
docker rmi ubuntu:latest

ubuntu_container
Untagged: ubuntu:latest
Deleted: sha256:c35e29c94501bc21680f16e27d3d4769a04f34057d0b8d2ad278b5e4efea5f8d
```

### Analysis

The Ubuntu image size is **78.1 MB**, while the exported archive size is **77 MB**.  
Docker does not allow removing an image if an existing container still references it. This protects the consistency of container metadata and prevents breaking containers created from that image.  
The file `ubuntu_image.tar` stores the Docker image data in portable form, including image layers and metadata, so it can be transferred or loaded on another machine.

---

## Task 2 — Custom Image Creation & Analysis

### Run nginx and inspect the default page

```text
docker run -d -p 80:80 --name nginx_container nginx
curl http://localhost
```

Default page output:

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
<h1>Welcome to nginx!</h1>
...
</html>
```

### Custom HTML file

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

### Copy the new page into the container

```text
docker cp index.html nginx_container:/usr/share/nginx/html/
curl http://localhost
```

Updated page output:

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

### Commit the modified container into a new image

```text
docker commit nginx_container my_website:latest
docker images my_website

REPOSITORY   TAG       IMAGE ID       CREATED                  SIZE
my_website   latest    546b46f55510   Less than a second ago   161MB
```

### Remove old container and run new image

```text
docker rm -f nginx_container
docker run -d -p 80:80 --name my_website_container my_website:latest
curl http://localhost
```

Output:

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

### Inspect filesystem changes

```text
docker diff my_website_container

C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

### Analysis

The custom page was successfully embedded into a new image called `my_website:latest`.  
In `docker diff`, the letter `C` means **changed**. In general:
- `A` = added
- `C` = changed
- `D` = deleted

`docker commit` creates an image from the current state of a container, but it is not reproducible or easy to track in version control.  
A **Dockerfile** is usually better in real projects because it is declarative, repeatable, and easier to review, automate, and maintain.

---

## Task 3 — Container Networking & Service Discovery

### Create a user-defined bridge network

```text
docker network create lab_network
docker network ls

NETWORK ID     NAME          DRIVER    SCOPE
acde0a6bea4a   bridge        bridge    local
5efe57884f34   host          host      local
a977719bf87a   lab_network   bridge    local
8c5654fe4655   none          null      local
```

### Run two Alpine containers on that network

```text
docker run -dit --network lab_network --name container1 alpine ash
docker run -dit --network lab_network --name container2 alpine ash
```

### Verify connectivity between containers

```text
docker exec container1 ping -c 3 container2

PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=1.021 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.108 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.088 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.088/0.405/1.021 ms
```

### Inspect network details

```text
docker network inspect lab_network
```

Relevant part of the output:

```text
"Subnet": "172.18.0.0/16",
"Gateway": "172.18.0.1"

"Containers": {
    ...
    "Name": "container1",
    "IPv4Address": "172.18.0.2/16",
    ...
    "Name": "container2",
    "IPv4Address": "172.18.0.3/16"
}
```

### Verify Docker DNS name resolution

```text
docker exec container1 nslookup container2

Server:		127.0.0.11
Address:	127.0.0.11:53

Non-authoritative answer:
Name:	container2
Address: 172.18.0.3
```

### Analysis

The two containers can communicate over the custom bridge network by container name.  
Docker provides an internal DNS service for user-defined networks, so `container1` can resolve `container2` automatically.  
A user-defined bridge network is better than the default bridge because it provides built-in DNS-based service discovery and better isolation.

---

## Task 4 — Data Persistence with Volumes

### Create a named volume

```text
docker volume create app_data
docker volume ls

DRIVER    VOLUME NAME
local     app_data
```

### Start nginx with the volume mounted

```text
docker run -d -p 8080:80 -v app_data:/usr/share/nginx/html --name web nginx
curl http://localhost:8080
```

Initial output:

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
<h1>Welcome to nginx!</h1>
...
</html>
```

### Create a persistent HTML page

```html
<html><body><h1>Persistent Data</h1></body></html>
```

### Copy the file into the container and verify it

```text
docker cp index.html web:/usr/share/nginx/html/
curl http://localhost:8080
```

Output:

```html
<html><body><h1>Persistent Data</h1></body></html>
```

### Remove the container and start a new one with the same volume

```text
docker stop web
docker rm web
docker run -d -p 8080:80 -v app_data:/usr/share/nginx/html --name web_new nginx
sleep 3
curl http://localhost:8080
```

Output after recreation:

```html
<html><body><h1>Persistent Data</h1></body></html>
```

### Inspect the volume

```text
docker volume inspect app_data

[
    {
        "CreatedAt": "2026-03-27T02:57:31+03:00",
        "Driver": "local",
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Scope": "local"
    }
]
```

### Analysis

The HTML page remained available after deleting the first container and starting a new one with the same volume. This demonstrates persistent storage outside the container lifecycle.  

Docker volumes are useful for application data that must survive container recreation.  
Compared to other storage options:
- **Volumes** are managed by Docker and are recommended for persistent application data.
- **Bind mounts** map a host directory directly into a container.
- **Container storage** is ephemeral and is lost when the container is removed.
