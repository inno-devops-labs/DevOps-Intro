# Lab 6 — Container Fundamentals with Docker

## Task 1 — Container Lifecycle & Image Management

### docker ps -a

```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

### docker images ubuntu

```
IMAGE           ID             DISK USAGE   CONTENT SIZE
ubuntu:latest   d1e2e92c075e        141MB         30.8MB
```

### OS Version inside container

```
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
```

### Running processes

```
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4300  3636 pts/0    Ss   18:03   0:00 /bin/bash
root        10  0.0  0.0   7632  3656 pts/0    R+   18:04   0:00 ps aux
```

### Exported image size

```
-rw-------  1 vozamhcak  staff    29M Mar 13 21:04 ubuntu_image.tar
```

### Error when trying to remove image

```
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container 8a2921a549bf is using its referenced image d1e2e92c075e
```

### Analysis

Docker does not allow deleting an image if a container created from that image still exists. The container depends on the image layers to run, so Docker prevents removal to avoid breaking the container. After deleting the container, the image can be removed successfully.

### What is inside the exported tar file?

The tar archive contains the Docker image layers, metadata, configuration files, and manifest information required to reconstruct the image later using `docker load`.

---

# Task 2 — Custom Image Creation & Analysis

### Default Nginx page

```
Welcome to nginx!
```

### Custom HTML content

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

### Verification with curl

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

### docker diff output

```
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

### Analysis of docker diff

* `C` means the file or directory was **changed**.
* These changes show runtime modifications made by Nginx when the container started.

### docker commit vs Dockerfile

**Advantages of docker commit**

* Quick and simple way to create a new image from a running container.
* Useful for experimentation or debugging.

**Disadvantages**

* Not reproducible.
* Hard to track changes.
* Not suitable for production workflows.

**Dockerfile advantages**

* Reproducible builds
* Version control
* Clear build instructions

---

# Task 3 — Container Networking & Service Discovery

### Ping between containers

```
PING container2 (172.18.0.3)
3 packets transmitted, 3 packets received, 0% packet loss
```

### Network inspect (important part)

```
container1 → 172.18.0.2
container2 → 172.18.0.3
```

### DNS resolution

```
Name: container2
Address: 172.18.0.3
```

### Analysis

Docker provides an internal DNS server for user-defined networks. This allows containers to communicate with each other using container names instead of IP addresses.

### Advantages of user-defined bridge networks

* Automatic DNS resolution
* Better isolation between applications
* Easier service discovery
* Improved network management

---

# Task 4 — Data Persistence with Volumes

### Custom HTML

```html
<html><body><h1>Persistent Data</h1></body></html>
```

### curl output before container removal

```
<html><body><h1>Persistent Data</h1></body></html>
```

### curl output after container recreation

```
<html><body><h1>Persistent Data</h1></body></html>
```

### Volume inspection

```
Mountpoint: /var/lib/docker/volumes/app_data/_data
Driver: local
```

### Analysis

Volumes store data outside the container filesystem. This allows data to persist even if containers are removed and recreated.

### Volumes vs Bind Mounts vs Container Storage

**Volumes**

* Managed by Docker
* Best performance
* Recommended for persistent data

**Bind mounts**

* Map directories from the host system
* Useful during development

**Container storage**

* Stored inside the container layer
* Data is lost when the container is removed

