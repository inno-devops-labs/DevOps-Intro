# TASK 1

## 1. Output of docker ps -a and docker images

### docker ps -a

Command:

```bash id="q7v2p8"
sudo docker ps -a
```

Output:

```text id="m3x5k1"
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS   PORTS   NAMES
```

At this stage no containers remained because the previous ubuntu container was removed.

---

### docker images

Command:

```bash id="h8r4c6"
sudo docker images ubuntu
```

Output:

```text id="b5n9t3"
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    bbdabce66f1b   4 weeks ago   78.1MB
```

This confirms that the ubuntu image was successfully downloaded before removal.

---

## 2. Image size and layer count

### Image size

The ubuntu image size:

```text id="w2e6f4"
78.1 MB
```

---

### Layer count

Command:

```bash id="k1g7n5"
sudo docker history ubuntu:latest
```

Output shows five layers:

```text id="z9d3p2"
1. CMD ["/bin/bash"]
2. ADD file:...
3. LABEL ...
4. ARG LAUNCHPAD_BUILD_ARCH
5. ARG RELEASE
```

So the image contains **5 layers**.

---

## 3. Tar file size comparison with image size

### Export command

```bash id="p6f8m1"
sudo docker save -o ubuntu_image.tar ubuntu:latest
```

---

### File size

Command:

```bash id="r4j2v7"
ls -lh ubuntu_image.tar
```

Output:

```text id="t8s5n4"
77M ubuntu_image.tar
```

---

### Comparison

* Docker image size: **78.1 MB**
* Exported tar size: **77 MB**

The tar archive size is slightly smaller because metadata is stored efficiently during export.

---

## 4. Error message from the first removal attempt

Command:

```bash id="c3n7b9"
sudo docker rmi ubuntu:latest
```

Output:

```text id="y6u1m8"
Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container bb99524a576d is using its referenced image
```

---

## 5. Analysis: Why does image removal fail when a container exists?

Docker prevents image deletion if any container still depends on that image.

Dependency relationship:

* container uses image as its filesystem base
* image layers are required to preserve container integrity

Therefore Docker blocks deletion until the container is removed.

The issue was solved by removing the container first:

```bash id="v2l9q6"
sudo docker rm ubuntu_container
```

Then image removal succeeded.

---

## 6. Explanation: What is included in the exported tar file?

The exported tar file contains:

* all image layers
* image metadata
* manifest information
* configuration files

It does **not** contain running container state.

The tar archive allows the image to be transferred and later restored with:

```bash id="u7d4r1"
docker load
```

This makes docker save useful for backup and migration of images between systems.


# TASK 2

## 1. Screenshot or output of original Nginx welcome page

The nginx container was started with:

```bash id="m3k7d1"
sudo docker run -d -p 80:80 --name nginx_container nginx
```

Verification command:

```bash id="a7f9s2"
curl http://localhost
```

Output:

```html id="e8v2q5"
<title>Welcome to nginx!</title>
<h1>Welcome to nginx!</h1>
```

This confirms that nginx was successfully deployed and the default web page was available.

---

## 2. Custom HTML content and verification via curl

Custom file `index.html`:

```html id="k4n6u8"
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>Website</h1>
</body>
</html>
```

Copy into container:

```bash id="r2m5p7"
sudo docker cp index.html nginx_container:/usr/share/nginx/html/
```

Verification:

```bash id="b1w8z4"
curl http://localhost
```

Output:

```html id="h9c3x6"
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>Website</h1>
</body>
</html>
```

This confirms that nginx now serves the custom page.

---

## 3. Output of docker diff my_website_container

Command:

```bash id="d5j1l9"
sudo docker diff my_website_container
```

Output:

```text id="q8g2n4"
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

---

## 4. Analysis: Explain the diff output (A–Added, C–Changed, D–Deleted)

Docker diff compares the current filesystem state of the running container with the original image.

Symbol meanings:

* A — Added
* C — Changed
* D — Deleted

In this case only **C (Changed)** entries are present.

Explanation:

* `/etc/nginx/conf.d/default.conf` was accessed or modified by nginx during startup
* `/run/nginx.pid` was created when nginx started and stored its process ID

This shows that runtime services modify the container filesystem even if the main application content remains unchanged.

---

## 5. Reflection: Advantages and disadvantages of docker commit vs Dockerfile

### docker commit

Advantages:

* fast way to save a running container
* useful for experiments
* simple when testing manual changes

Disadvantages:

* changes are not reproducible
* build process is not documented
* difficult to maintain in production

### Dockerfile

Advantages:

* reproducible builds
* version control friendly
* clear description of build steps

Disadvantages:

* requires writing instructions manually
* slightly slower during development

For production systems Dockerfile is preferred because it guarantees reproducibility and maintainability.

---
# TASK 3
## 1. Output of ping command showing successful connectivity

Command:

```bash
sudo docker exec container1 ping -c 3 container2
```

Output:

```text
PING container2 (172.18.0.3): 56(84) bytes of data.
64 bytes from container2.lab_network (172.18.0.3): icmp_seq=1 ttl=64 time=0.145 ms
64 bytes from container2.lab_network (172.18.0.3): icmp_seq=2 ttl=64 time=0.163 ms
64 bytes from container2.lab_network (172.18.0.3): icmp_seq=3 ttl=64 time=0.113 ms

--- container2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2080ms
rtt min/avg/max/mdev = 0.113/0.140/0.163/0.020 ms
```

This confirms successful communication between `container1` and `container2` over the custom Docker bridge network.

---

## 2. Network inspection output showing both containers' IP addresses

Command:

```bash
sudo docker network inspect lab_network
```

Relevant output:

```text
"Subnet": "172.18.0.0/16",
"Gateway": "172.18.0.1"

"Name": "container1",
"IPv4Address": "172.18.0.2/16"

"Name": "container2",
"IPv4Address": "172.18.0.3/16"
```

This shows that both containers are connected to the same user-defined bridge network and received IP addresses from the same subnet.

---

## 3. DNS resolution output

Command:

```bash
sudo docker exec container1 nslookup container2
```

Output:

```text
Server:         127.0.0.11
Address:        127.0.0.11#53

Non-authoritative answer:
Name:   container2
Address: 172.18.0.3
```

This confirms that Docker internal DNS successfully resolves the container name `container2` into its IP address.

---

## 4. Analysis: How does Docker internal DNS enable container-to-container communication by name?

Docker provides an embedded DNS server for containers connected to the same user-defined network.

When `container1` requests `container2`, Docker DNS automatically resolves the hostname `container2` into IP address `172.18.0.3`.

This allows containers to communicate by name instead of manually specifying IP addresses, which simplifies service discovery.

---

## 5. Comparison: What advantages does user-defined bridge networks provide over the default bridge network?

User-defined bridge networks provide several advantages:

* automatic DNS-based name resolution
* easier communication between containers
* better service isolation
* simpler network management
* improved scalability for multi-container applications

The default bridge network does not provide equally convenient automatic name resolution for arbitrary containers.

# TASK 4
## 1. Custom HTML content used

The custom file `index.html` contained:

```html id="0t7m2k"
<html><body><h1>Persistent Data</h1></body></html>
```

The file was copied into the mounted volume using:

```bash id="4r8q1p"
sudo docker cp index.html web:/usr/share/nginx/html/
```

---

## 2. Output of curl showing content persists after container recreation

### First verification

Command:

```bash id="9v3n6c"
curl http://localhost
```

Output:

```html id="6j1f8x"
<html><body><h1>Persistent Data</h1></body></html>
```

---

### After container removal and recreation

Command:

```bash id="3p5d7w"
curl http://localhost
```

Output:

```html id="8m2q4s"
<html><body><h1>Persistent Data</h1></body></html>
```

This confirms that the data remained available after the original container was removed and a new container was created.

---

## 3. Volume inspection output showing mount point

Command:

```bash id="7k9c2t"
sudo docker volume inspect app_data
```

Output:

```text id="1n4v6b"
[
  {
    "Driver": "local",
    "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
    "Name": "app_data",
    "Scope": "local"
  }
]
```

This shows that Docker stores the volume data outside the container filesystem.

---

## 4. Analysis: Why is data persistence important in containerized applications?

Containers are ephemeral by design, which means that container files are lost when the container is removed.

Volumes solve this problem by storing data outside the container lifecycle.

This is important because:

* application data survives container recreation
* updates can be performed safely
* services remain stateful when needed

Without volumes, all user data would be lost when a container is deleted.

---

## 5. Comparison: Differences between volumes, bind mounts, and container storage

### Volumes

Volumes are managed by Docker and stored in Docker internal directories.

Advantages:

* easy to manage
* portable
* recommended for production

---

### Bind mounts

Bind mounts connect a container directly to a host directory.

Advantages:

* direct access to host files
* useful during development

Disadvantages:

* host filesystem dependency

---

### Container storage

Container internal storage exists only inside the container itself.

Disadvantage:

* data is deleted when the container is removed

---

### When to use each

* volumes → persistent production data
* bind mounts → development and local file editing
* container storage → temporary runtime files
