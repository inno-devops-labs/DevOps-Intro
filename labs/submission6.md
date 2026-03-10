# Lab 6 — Container Fundamentals with Docker

## Task 1 — Container Lifecycle & Image Management

### Output of `docker ps -a` and `docker images`
```sh
pixel@pixelbook:~$ docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

```sh
pixel@pixelbook:~$ docker images
                                                                                                                                                                        i Info →   U  In Use
IMAGE   ID             DISK USAGE   CONTENT SIZE   EXTRA
```

### Image size and layer count
Image size: 119MB disk usage, 31.7MB content size.
```sh
pixel@pixelbook:~$ docker images ubuntu
                                                                                                                                                                        i Info →   U  In Use
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   d1e2e92c075e        119MB         31.7MB
```

Layer count: 6 layers total, 1 layer with filesystem data.
```sh
pixel@pixelbook:~$ docker history ubuntu:latest
IMAGE          CREATED       CREATED BY                                      SIZE      COMMENT
d1e2e92c075e   3 weeks ago   /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>      3 weeks ago   /bin/sh -c #(nop) ADD file:1ae27d2ef43693611…   87.6MB
<missing>      3 weeks ago   /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      3 weeks ago   /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      3 weeks ago   /bin/sh -c #(nop)  ARG LAUNCHPAD_BUILD_ARCH     0B
<missing>      3 weeks ago   /bin/sh -c #(nop)  ARG RELEASE                  0B
```

### Tar file size comparison with image size
- Tar file (31 MB) ~= Docker content size (31.7 MB)
- Disk usage (119 MB) is larger because Docker stores uncompressed layers and overlay filesystem metadata.

### Error message from the first removal attempt
```sh
pixel@pixelbook:~$    docker rmi ubuntu:latest
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container cf9cdd5fed26 is using its referenced image d1e2e92c075e
```

### Analysis: Why does image removal fail when a container exists? Explain the dependency relationship
Image removal failed because a container was still referencing the image it was created from.
A Docker container is built on top of an image’s read-only layers with its own small writable layer. Even if the container is stopped, it still depends on the image to define its filesystem. Docker therefore prevents deleting an image that an existing container depends on to avoid breaking the container.

### Explanation: What is included in the exported tar file?
Docker exports the entire image package into a tar archive so it can be transferred and later restored using `docker load`.


## Task 2 — Custom Image Creation & Analysis

### Screenshot or output of original Nginx welcome page
```sh
pixel@pixelbook:~$ curl http://localhost
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

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

### Custom HTML content and verification via curl
```sh
pixel@pixelbook:~$ nano index.html
pixel@pixelbook:~$    docker cp index.html nginx_container:/usr/share/nginx/html/
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/
pixel@pixelbook:~$    curl http://localhost
   <html>
   <head>
   <title>The best</title>
   </head>
   <body>
   <h1>website</h1>
   </body>
   </html>
```

### Output of `docker diff my_website_container`
```sh
pixel@pixelbook:~$    docker diff my_website_container
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

### Analysis: Explain the diff output (A=Added, C=Changed, D=Deleted)
- /etc, /etc/nginx, /etc/nginx/conf.d – Marked changed because files inside them had metadata updates.
- /etc/nginx/conf.d/default.conf – Nginx configuration accessed/updated at runtime.
- /run – Runtime directory used by services.
- /run/nginx.pid – PID file created/updated when nginx starts.

### Reflection: What are the advantages and disadvantages of `docker commit` vs Dockerfile for image creation?
**docker commit**:
*Advantages:*
- Quick and easy snapshot of a running container
- Useful for experiments or debugging
*Disadvantages:*
- Not reproducible
- Hard to track or version-control changes
- May include unwanted files or temporary state

**Dockerfile**
*Advantages:*
- Reproducible and consistent builds
- Easy to version-control (e.g., Git)
- Good for automation and CI/CD
*Disadvantages:*
- Requires writing build instructions
- Slightly slower for quick experiments

`docker commit` is good for quick snapshots, while Dockerfiles are better for reproducible, maintainable image creation.


## Task 3 — Container Networking & Service Discovery

### Output of ping command showing successful connectivity
```sh
pixel@pixelbook:~$ docker exec container1 ping -c 3 container2
PING container2 (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.452 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.238 ms
64 bytes from 172.19.0.3: seq=2 ttl=64 time=0.206 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.206/0.298/0.452 ms
```

### Network inspection output showing both containers' IP addresses
```sh
pixel@pixelbook:~$ docker network inspect lab_network
[
    {
        "Name": "lab_network",
        "Id": "7bd11f8d901c0835c1bdeb65d50056e7fbbc0696758f9e21e4b346887236923d",
        "Created": "2026-03-10T14:04:26.291269933+03:00",
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
            "3c44fb4632b59e2e191a58f42e44faacc794f9d53a6aef6307fa021707bdde47": {
                "Name": "container1",
                "EndpointID": "6200abebf421ccd1dad47355dc5971af41f87abd2b5686027d8c9b119ef19a5e",
                "MacAddress": "46:de:63:cf:bf:70",
                "IPv4Address": "172.19.0.2/16",
                "IPv6Address": ""
            },
            "df938a715f513b3a24de286cbc984a43b0ffce9ecac871b6279f2ce337d5f4d6": {
                "Name": "container2",
                "EndpointID": "542befa8a0bdf255de0032c41fe8a71546b7c88a55f731f6d0a736da4784466a",
                "MacAddress": "b2:2b:6e:27:89:7f",
                "IPv4Address": "172.19.0.3/16",
                "IPv6Address": ""
            }
        },
        "Status": {
            "IPAM": {
                "Subnets": {
                    "172.19.0.0/16": {
                        "IPsInUse": 5,
                        "DynamicIPsAvailable": 65531
                    }
                }
            }
        }
    }
]
```

### DNS resolution output
```sh
pixel@pixelbook:~$ docker exec container1 nslookup container2
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:   container2
Address: 172.19.0.3
```

### Analysis: How does Docker's internal DNS enable container-to-container communication by name?
Docker has a built-in DNS server that runs inside each user-defined network. When a container starts, Docker automatically registers the container’s name and its internal IP address in this DNS system.

Containers on the same network use Docker’s internal DNS (usually at 127.0.0.11). When one container tries to connect to another using its name (for example db), the DNS server resolves that name to the container’s IP address.

This allows containers to communicate using names instead of IP addresses, and the mapping updates automatically if containers restart or change IPs.

### Comparison: What advantages does user-defined bridge networks provide over the default bridge network?
User-defined bridge networks provide several advantages over Docker’s default bridge network.

First, they include automatic DNS-based service discovery. Containers on a user-defined network can communicate using container names, while containers on the default bridge must use IP addresses unless links are manually configured.

Second, they offer better isolation. Only containers attached to the same user-defined network can communicate with each other, whereas the default bridge allows broader communication between containers.

Third, they support easier network management. Containers can be dynamically attached or detached from user-defined networks without restarting them.

Finally, user-defined networks allow custom configuration, such as specifying subnets, gateways, and network options, giving more control over container networking.


## Task 4 — Data Persistence with Volumes

### Custom HTML content used
```html
   <html><body><h1>Persistent Data</h1></body></html>
```

### Output of curl showing content persists after container recreation
```sh
pixel@pixelbook:~$    curl http://localhost
   <html><body><h1>Persistent Data</h1></body></html>
```

### Volume inspection output showing mount point
```sh
pixel@pixelbook:~$    docker volume inspect app_data
[
    {
        "CreatedAt": "2026-03-10T14:11:37+03:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

### Analysis: Why is data persistence important in containerized applications?
Data persistence is important in containerized applications because containers are ephemeral—their internal filesystem is lost when the container stops, restarts, or is replaced. Without persistence, any stored data would disappear during updates, scaling, or failures.
Using mechanisms like volumes in Docker allows data to be stored outside the container lifecycle.

### Comparison: Explain the differences between volumes, bind mounts, and container storage. When would you use each?
*Container storage:*
This is the container’s internal writable layer. It exists only while the container runs and is deleted when the container is removed. It’s used for temporary data or caches that don’t need to be saved.
*Volumes:*
Volumes are storage managed by Docker that exist outside the container. Data stays even if the container is deleted, and volumes can be shared between containers. They are best for persistent production data like databases.
*Bind mounts:*
Bind mounts connect a specific folder on the host machine to a folder inside the container. Changes appear on both sides immediately. They are mainly used in development when you want the container to access files directly from the host.

**Summary:**
Use container storage for temporary data, volumes for persistent application data, and bind mounts when you need direct access to host files (commonly in development).