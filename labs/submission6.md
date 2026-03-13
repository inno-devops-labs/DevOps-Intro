# Lab 6 Submission — Container Fundamentals with Docker

**Student:** Rodion Krainov

**Email:** [r.krainov@innopolis.university](mailto:r.krainov@innopolis.university)

**GitHub:** r3based

---

## Task 1 — Container Lifecycle & Image Management

### 1.1 Basic Container Operations

First, I checked the current state of containers on the host:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

Then I pulled the Ubuntu image:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker pull ubuntu:latest
latest: Pulling from library/ubuntu
01d7766a2e4a: Pull complete
Digest: sha256:d1e2e92c075e2ca139d51a140fff46f84315c0fdce203eab2807c7e495ecc5c6
Status: Downloaded newer image for ubuntu:latest
```

I verified the image locally:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker images ubuntu
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    bbdabce66f1b   4 weeks ago   78.1MB
```

I also inspected the image internals. The Ubuntu image had a size of **78.1 MB** and consisted of **one layer**:

```json
"RootFS": {
    "Type": "layers",
    "Layers": [
        "sha256:efafae78d70c98626c521d846827389128e7d7ea442db31bc433934647f1a945"
    ]
}
```

Next, I launched an interactive container session based on `ubuntu:latest`. Inside the container, I checked the operating system and running processes.

Observed results:

* **OS version:** Ubuntu 24.04.4 LTS (Noble Numbat)
* **Processes running:** only the shell session and the inspection command itself
* **PID 1:** `/bin/bash`

After exiting the session, the container appeared in the stopped state:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker ps -a
CONTAINER ID   IMAGE           COMMAND       CREATED         STATUS                     PORTS     NAMES
aa1e1cc149eb   ubuntu:latest   "/bin/bash"   2 minutes ago   Exited (0) 2 minutes ago             ubuntu_container
```

---

### 1.2 Image Export and Dependency Analysis

I exported the Ubuntu image to a tar archive:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker save -o ubuntu_image.tar ubuntu:latest
➜  DevOps-Intro git:(Feature/lab6) ls -lh ubuntu_image.tar
-rw-r--r-- 1 r3based r3based 80.7M Mar 13  ubuntu_image.tar
```

The resulting tar archive was **80.7 MB**, which is close to the reported image size of **78.1 MB**.
This is expected because the tar archive contains:

* all image filesystem layers,
* image configuration metadata,
* JSON manifests required to reconstruct the image with `docker load`.

When I tried to remove the image immediately, Docker rejected the operation:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker rmi ubuntu:latest
Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container aa1e1cc149eb is using its referenced image bbdabce66f1b
```

This happened because the stopped container still depended on the image. Docker protects image references as long as at least one container was created from that image.

After removing the container, the image could be deleted successfully.

#### Why does image removal fail when a container exists?

Image removal fails because a container keeps a dependency on its base image, even if the container is stopped. Docker prevents deleting that image to avoid breaking the container’s filesystem reference chain. The correct sequence is:

1. stop the container if needed,
2. remove the container,
3. remove the image.

#### What is included in the exported tar file?

The exported tar file contains the full portable representation of the image:

* filesystem layers,
* image history and configuration,
* manifest metadata.

In practice, it is a complete backup that can be transferred and later restored with `docker load`.

---

## Task 2 — Custom Image Creation & Analysis

### 2.1 Original Nginx Page

I started an Nginx container and checked the default page:

```bash
➜  DevOps-Intro git:(Feature/lab6) curl http://localhost
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
<h1>Welcome to nginx!</h1>
...
</html>
```

This confirmed that the container served the standard default Nginx welcome page.

---

### 2.2 Custom HTML Content

I created a custom `index.html` file with the following content:

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

Then I copied it into the running Nginx container:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker cp index.html nginx_container:/usr/share/nginx/html/
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/
```

Verification with `curl` showed that the page content changed successfully:

```bash
➜  DevOps-Intro git:(Feature/lab6) curl http://localhost
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

---

### 2.3 Creating a Custom Image

I preserved the modified container state by committing it into a new image:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker commit nginx_container my_website:latest
sha256:46c41202d89f...
```

The custom image size was approximately **161 MB**.

After recreating a container from `my_website:latest`, the custom page was still served, which confirmed that the change had been baked into the image.

---

### 2.4 `docker diff` Analysis

I used `docker diff` to inspect changes made to the container filesystem:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker diff my_website_container
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

#### Diff interpretation

The markers mean the following:

* `C` — changed object

These entries indicate runtime modifications performed during Nginx startup:

* `/run/nginx.pid` was created or updated for the running process,
* `/etc/nginx/conf.d/default.conf` and related directories were touched by configuration loading.

The custom HTML file is the meaningful content change from the user perspective; once committed into the image, it becomes part of the image filesystem itself.

---

### 2.5 `docker commit` vs Dockerfile

#### Advantages of `docker commit`

* very fast for experiments and prototyping,
* useful for saving the exact state of a running container,
* convenient during debugging or one-off manual modifications.

#### Disadvantages of `docker commit`

* not reproducible,
* no transparent build history,
* hard to version and review,
* may include unnecessary temporary files and runtime artifacts,
* does not follow infrastructure-as-code practices.

#### Advantages of a Dockerfile

* fully reproducible builds,
* version-controlled and easy to review,
* documents the build process explicitly,
* better suited for automation and CI/CD,
* usually leads to cleaner and more maintainable images.

#### Disadvantages of a Dockerfile

* requires more upfront preparation,
* less convenient for very quick manual experiments.

#### Conclusion

`docker commit` is acceptable for short-lived experimentation, but for real engineering workflows a **Dockerfile is the preferred approach** because it is reproducible, maintainable, and suitable for collaboration.

---

## Task 3 — Container Networking & Service Discovery

### 3.1 Creating a User-Defined Network

I created a dedicated bridge network:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker network create lab_network
350eec94bc17
```

Then I launched two Alpine containers attached to this network:

* `container1`
* `container2`

---

### 3.2 Connectivity Test

I verified connectivity from `container1` to `container2` by name:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker exec container1 ping -c 3 container2
PING container2 (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.054 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.087 ms
64 bytes from 172.19.0.3: seq=2 ttl=64 time=0.103 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.054/0.081/0.103 ms
```

This confirmed both network reachability and working name resolution.

---

### 3.3 Network Inspection

I inspected the created network:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker network inspect lab_network
[
  {
    "Name": "lab_network",
    "Driver": "bridge",
    "IPAM": {
      "Config": [
        {
          "Subnet": "172.19.0.0/16",
          "Gateway": "172.19.0.1"
        }
      ]
    },
    "Containers": {
      "...": {
        "Name": "container1",
        "IPv4Address": "172.19.0.2/16"
      },
      "...": {
        "Name": "container2",
        "IPv4Address": "172.19.0.3/16"
      }
    }
  }
]
```

Observed addressing:

* `container1` → `172.19.0.2/16`
* `container2` → `172.19.0.3/16`
* gateway → `172.19.0.1`

---

### 3.4 DNS Resolution

I checked Docker’s internal DNS from inside `container1`:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker exec container1 nslookup container2
Server:		127.0.0.11
Address:	127.0.0.11:53

Non-authoritative answer:
Name:	container2
Address: 172.19.0.3
```

#### How Docker internal DNS works

Docker provides an embedded DNS service at **127.0.0.11** on user-defined networks.
This service automatically resolves container names to their current IP addresses, which allows containers to communicate using stable names instead of hardcoded IPs.

That means applications can refer to peers as `container2`, `db`, `backend`, and so on, and Docker handles the mapping internally.

#### Advantages of a user-defined bridge network over the default bridge

1. automatic DNS-based service discovery by container name,
2. better isolation between groups of containers,
3. simpler application connectivity without manual IP management,
4. easier attachment of multiple containers to the same logical network,
5. cleaner and more production-like topology.

Compared to the default bridge network, user-defined networks are significantly more convenient for multi-container applications.

---

## Task 4 — Data Persistence with Volumes

### 4.1 Creating and Using a Volume

I created a Docker volume:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker volume create app_data
app_data
```

Then I prepared custom HTML content:

```html
<html><body><h1>Persistent Data</h1></body></html>
```

This content was placed into an Nginx container using the volume mounted at `/usr/share/nginx/html`.

---

### 4.2 Persistence Verification

After stopping and removing the original container, I started a new one with the same volume:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker stop web && docker rm web
web
web

➜  DevOps-Intro git:(Feature/lab6) docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
5f9910da840fcd542cd4e04cbaa30d87a744a545df9ef249dd5899372786ca61
```

I then checked the page:

```bash
➜  DevOps-Intro git:(Feature/lab6) curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>
```

The content was preserved, which proves that the data was stored in the volume rather than in the container’s ephemeral writable layer.

I also inspected the volume:

```bash
➜  DevOps-Intro git:(Feature/lab6) docker volume inspect app_data
[
    {
        "CreatedAt": "2026-03-13T19:21:12+03:00",
        "Driver": "local",
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Scope": "local"
    }
]
```

---

### 4.3 Why Data Persistence Matters

Persistence is essential because containers are designed to be ephemeral.
If data is stored only inside the container writable layer, it is lost when the container is deleted.

Persistent storage is required for:

* databases,
* uploaded files,
* application state,
* logs,
* configuration shared across recreations,
* backup and recovery scenarios.

Without persistence, stateful workloads cannot function reliably.

---

### 4.4 Volumes vs Bind Mounts vs Container Storage

| Storage Type      | Location                 | Persistence | Typical Use Case                                   |
| ----------------- | ------------------------ | ----------- | -------------------------------------------------- |
| Container storage | Container writable layer | Ephemeral   | Temporary runtime files, cache                     |
| Volume            | Docker-managed storage   | Persistent  | Production data, databases, shared app data        |
| Bind mount        | Host filesystem path     | Persistent  | Development, host config injection, live code sync |

#### When to use each

**Container storage**

* use for temporary files,
* suitable only for stateless workloads,
* data disappears with container removal.

**Volumes**

* best for production workloads,
* Docker-managed and portable within Docker workflows,
* ideal for databases, user uploads, and persistent application data.

**Bind mounts**

* best for development,
* useful when the container must read or modify files directly on the host,
* common for live code editing and host-side configuration injection.

---

## Reflection

This lab demonstrated the core Docker concepts behind container lifecycle, image handling, networking, and persistence.

The most important practical takeaways were:

* containers depend on images and cannot outlive their image references cleanly,
* `docker commit` is convenient but not a substitute for a Dockerfile,
* user-defined bridge networks provide built-in service discovery through Docker DNS,
* volumes are the correct mechanism for preserving data across container recreation.

Overall, the lab showed the difference between **ephemeral container state** and **persistent application data**, which is one of the most important concepts in containerized systems.
