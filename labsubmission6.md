# Lab 6 — Submission: Container Fundamentals with Docker

## Task 1 — Container Lifecycle & Image Management (3 pts)

### 1.1 Basic Container Operations

#### Output of `docker ps -a`

```
CONTAINER ID   IMAGE                              COMMAND                  CREATED        STATUS                        PORTS                    NAMES
07719cb8d228   bkimminich/juice-shop              "/nodejs/bin/node /j…"   3 weeks ago    Exited (255) 57 seconds ago   0.0.0.0:3000->3000/tcp   juice-shop
b8933707adc8   ubuntu:latest                      "sleep infinity"         7 weeks ago    Exited (137) 6 weeks ago                               ubuntu_container
fd7b35c74ee8   pmldl-assignment1-deployment-app   "streamlit run strea…"   2 months ago   Exited (0) 2 months ago                                web-app
bf035f3410f4   pmldl-assignment1-deployment-api   "uvicorn main:app --…"   2 months ago   Exited (137) 2 months ago                              model-api
```

#### Output of `docker images ubuntu`

```
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    c35e29c94501   6 weeks ago   117MB
```

#### Image Size and Layer Count

- **Image Size:** 117 MB
- **Layer Count:** 1 layer (as shown in docker images output)

### 1.2 Image Export and Dependency Analysis

#### Tar File Size

```
02.12.2025  14:34        29 742 592 ubuntuimage.tar
```

**Comparison:** The tar file size (29.7 MB) is smaller than the reported image size (117 MB) because the tar archive stores the compressed/layered representation of the image, which is more efficient than the expanded filesystem representation. Docker images are stored in layers and the tar format maintains this compression, whereas the displayed "SIZE" in `docker images` represents the uncompressed, expanded size of all layers combined.

#### Error Message from First Removal Attempt

```
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container d118332f3d15 is using its referenced image c35e29c94501
```

### Analysis

**Why does image removal fail when a container exists?**

Docker prevents image deletion when a container exists that depends on it because containers use the image's filesystem layers as their base. When you create a container from an image, the container holds a reference to that image's layers. If Docker allowed you to delete the image while a container depends on it, the container would become corrupted and unable to function properly. The container needs access to the image's layers for its operation, even if the container is stopped. This is a safety mechanism to ensure data integrity and prevent orphaned containers.

**What is included in the exported tar file?**

The exported tar file includes all the image layers, metadata, and configuration files needed to reconstruct the image. Specifically, it contains:
- All filesystem layers (each layer is a diff that stacks on top of previous layers)
- Image configuration files (JSON manifests describing the image structure)
- Repository information and tags
- Checksum information for layer verification

This makes the tar file a complete, portable representation of the Docker image that can be transferred to another system and imported with `docker load`.

---

## Task 2 — Custom Image Creation & Analysis (3 pts)

### 2.1 Deploy and Customize Nginx

#### Original Nginx Welcome Page

```
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

#### Custom HTML Content

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

#### Verification via curl (After Copying Custom Content)

```
<html><head><title>The best</title></head><body><h1>website</h1></body></html>
```

The custom HTML successfully replaced the default nginx welcome page, confirming that the file was correctly copied to the container's web root.

### 2.2 Create and Test Custom Image

#### Output of `docker images mywebsite`

```
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
mywebsite    latest    9134774b4543   8 seconds ago   225MB
```

#### Output of `docker diff mywebsitecontainer`

```
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

### Analysis

**Explain the diff output:**

- **A (Added):** No files were added in this container diff output.
- **C (Changed):** The changed files are:
  - `/etc` - configuration directory modified
  - `/etc/nginx` - nginx configuration directory changed
  - `/etc/nginx/conf.d` - nginx config sub-directory changed
  - `/etc/nginx/conf.d/default.conf` - nginx default configuration file was modified
  - `/run` - runtime directory changed
  - `/run/nginx.pid` - nginx process ID file was created/modified

These changes represent the runtime modifications made by nginx when it starts and serves the custom HTML file, as well as the process management files it creates.

- **D (Deleted):** No files were deleted.

### Reflection

**Advantages and disadvantages of `docker commit` vs Dockerfile:**

| Aspect | `docker commit` | Dockerfile |
|--------|-----------------|------------|
| **Advantages** | Quick and easy for testing; immediate capture of container state; good for prototyping | Reproducible builds; version control friendly; clear documentation of changes; can be shared easily; builds are consistent and cacheable |
| **Disadvantages** | Not reproducible; creates large images; difficult to track changes; no clear audit trail of what changed; poor for production | Requires writing and maintaining the Dockerfile; slower for quick prototyping; steeper learning curve |

**When to use each approach:**

Use `docker commit` when you need to quickly test configuration changes or create a one-off image for development. However, for production deployments, version-controlled code, and team collaboration, Dockerfile is always the better choice because it provides reproducibility, auditability, and maintainability. Dockerfiles are the industry standard practice because they make images transparent and allow other developers to understand and modify them.

---

## Task 3 — Container Networking & Service Discovery (2 pts)

### 3.1 Create Custom Network

#### Output of `docker network ls`

```
NETWORK ID     NAME                                   DRIVER    SCOPE
7f5d1a104405   bridge                                 bridge    local
85a14be6e1dd   host                                   host      local
f206d027d59e   labnetwork                             bridge    local
d45782c91fb9   none                                   null      local
70c2b786ae4f   pmldl-assignment1-deployment_default   bridge    local
```

### 3.2 Test Connectivity and DNS

#### Ping Command Output

```
PING container2 (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.195 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.127 ms
64 bytes from 172.19.0.3: seq=2 ttl=64 time=0.089 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.089/0.137/0.195 ms
```

The ping succeeded with 0% packet loss, demonstrating successful container-to-container communication.

#### Network Inspection Output

```json
[
    {
        "Name": "labnetwork",
        "Id": "f206d027d59e770acb45e415e78feb11caf12f9041928270b89eec0969fba0bf",
        "Created": "2025-12-02T11:39:46.393459392Z",
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
        "Containers": {
            "7a2b11b2853552ba91d85793f76a909408ac1d5a09093017e2fef796926d1eda": {
                "Name": "container2",
                "EndpointID": "613168235c738a6908d4ad408fba64f56cd860d52c47f22c22568bb2e114cd29",
                "MacAddress": "c2:4a:52:7d:f6:c1",
                "IPv4Address": "172.19.0.3/16",
                "IPv6Address": ""
            },
            "fcdaf9e835bfa273fad8f68d995acf62ff72ab9c2ce8fedee785fe0a69bb7a2e": {
                "Name": "container1",
                "EndpointID": "794ae6dd5e038a68b6b426364630e83538b05ac55dec5be1762920d37be92e23",
                "MacAddress": "e6:94:e7:c6:cf:1b",
                "IPv4Address": "172.19.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.enable_ipv4": "true",
            "com.docker.network.enable_ipv6": "false"
        },
        "Labels": {}
    }
]
```

#### DNS Resolution Output

```
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:   container2
Address: 172.19.0.3
```

The DNS resolution successfully resolved the container name "container2" to its IP address 172.19.0.3.

### Analysis

**How does Docker's internal DNS enable container-to-container communication by name?**

Docker includes an embedded DNS server that runs at 127.0.0.11:53 inside each container. When containers are connected to a user-defined bridge network like `labnetwork`, Docker automatically registers each container's name with this embedded DNS server. When one container tries to communicate with another by name (e.g., `ping container2`), the container's DNS resolver queries the embedded DNS server, which looks up the container name and returns its IP address on the shared network. This enables containers to discover and communicate with each other using memorable names instead of hardcoded IP addresses. The DNS resolution is dynamic, meaning when containers are added or removed, the DNS registry is automatically updated.

**Advantages of user-defined bridge networks over the default bridge network:**

User-defined bridge networks provide several key advantages:
1. **Automatic DNS resolution** - Container names are automatically resolvable within the network, unlike the default bridge where you must use the `--link` option or hardcode IP addresses.
2. **Better isolation** - Containers on different user-defined networks cannot communicate by default, providing network segmentation and improved security.
3. **Flexible attachment and detachment** - You can connect or disconnect containers from a network without stopping them.
4. **Custom network configuration** - You can set custom IPAM (IP Address Management) configurations.
5. **Better for multi-container applications** - Supports the common pattern where multiple containers form a coordinated application stack with clear network boundaries.

---

## Task 4 — Data Persistence with Volumes (2 pts)

### 4.1 Create and Use Volume

#### Output of `docker volume ls`

```
DRIVER    VOLUME NAME
local     appdata
```

#### Custom HTML Content

```html
<html><body><h1>Persistent Data</h1></body></html>
```

#### Output of curl (Before Container Destruction)

```
<html><body><h1>Persistent Data</h1></body></html>
```

The custom content was successfully served by the container.

### 4.2 Verify Persistence

#### Output of curl (After Container Recreation)

```
<html><body><h1>Persistent Data</h1></body></html>
```

The data persisted even after the container was stopped, removed, and recreated with the same volume attachment. This demonstrates that the volume data survives the container lifecycle.

#### Volume Inspection Output

```json
[
    {
        "CreatedAt": "2025-12-02T11:43:16Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/appdata/_data",
        "Name": "appdata",
        "Options": null,
        "Scope": "local"
    }
]
```

### Analysis

**Why is data persistence important in containerized applications?**

Data persistence is critical in containerized applications because containers are ephemeral by nature—they can be stopped, removed, and recreated at any time. Without persistent storage, all data created or modified within a container would be lost when the container is destroyed. This is essential for:
1. **Stateful applications** - Databases, message queues, and caching systems must retain their data across restarts.
2. **Configuration management** - Application settings and configurations need to survive container recreation.
3. **Business continuity** - Important data must not be lost during container updates, scaling, or failures.
4. **Multi-container coordination** - Multiple containers often need to share data via persistent volumes.

Volumes provide a mechanism to separate data lifecycle from container lifecycle, allowing applications to be scaled, updated, and recovered without data loss.

**Differences between volumes, bind mounts, and container storage:**

| Storage Type | Description | Use Case |
|--------------|-------------|----------|
| **Volumes** | Named, managed storage objects stored in Docker's storage directory (usually `/var/lib/docker/volumes`). Managed entirely by Docker with full lifecycle management. | Production applications, databases, shared data between containers. Volumes are the recommended approach for most use cases because Docker manages them completely. |
| **Bind Mounts** | Direct mapping of a host filesystem path to a container path. Depends on the host directory structure. Host filesystem is directly accessible to the container. | Development workflows (mounting source code), sharing files between host and container, configuration files from the host. Useful during development but less portable across different machines. |
| **Container Storage** | Ephemeral storage in the container's writable layer. Data is stored in the container and lost when the container is removed. Default storage mechanism for all containers. | Temporary files, logs, cache data, or any data that doesn't need to persist beyond the container lifecycle. |

**Trade-offs and best practices:**

- Use **volumes** for production data that must persist and for applications requiring high performance storage.
- Use **bind mounts** during development when you need live access to source code on your host machine.
- Use **container storage** only for temporary data that will be discarded with the container.
- Never rely on container storage for important data.
- Consider using named volumes for production to allow easy backup and migration.

