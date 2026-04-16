# Lab 6 Submission

## Task 1 — Container Lifecycle & Image Management

### 1.1 Output
**Command: `docker ps -a`**
```text
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

**Command: `docker images ubuntu`**
```text
                                                                                                    i Info →   U  In Use
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   d1e2e92c075e        119MB         31.7MB
```

### 1.2 Analysis
**Image Size vs Tar Size:**
*   Image Size: 31.7MB
*   Tar File Size: 30,21875
*   Comparison: The tar file size is roughly comparable to the image size, containing all layers and metadata required to transport the image.

**Removal Error:**
```text
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container 53438dfb3e8e is using its referenced image d1e2e92c075e
```

**Why removal fails:**
The removal fails because the container `ubuntu_container` (even though stopped) still references the image layers. Docker prevents deleting an image that is actively used by a container to maintain filesystem integrity.

**Exported Tar Content:**
The exported tar file contains the complete filesystem layers of the image plus a manifest JSON file describing the configuration and how layers are assembled.

---

## Task 2 — Custom Image Creation & Analysis

### 2.1 Setup
**Original Nginx Welcome:**

```html
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

**Custom HTML Verification:**
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

### 2.2 Analysis
**Filesystem Changes (`docker diff`):**
```text
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

**Explanation of Diff:**
*   **A (Added):** Represents new files added to the container (e.g., our `index.html`).
*   **C (Changed):** Represents modified files (usually logs or PID files created at runtime).
*   **D (Deleted):** Represents files removed from the filesystem.

**Reflection: Commit vs Dockerfile:**
*   **Docker Commit:** Good for quick snapshots/prototyping. Bad for reproducibility and security (creates a "black box").
*   **Dockerfile:** The industry standard. Allows "Infrastructure as Code," version control, easy updates, and layer optimization.

---

## Task 3 — Container Networking & Service Discovery

### 3.1 & 3.2 Connectivity Results
**Ping Output (Container to Container):**
```text
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.230 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.101 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.095 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.095/0.142/0.230 ms
```

**Network Inspect:**
```text
        "Containers": {
            "38bb044267437217437f7dedd7cdcfacd4900af1b559d0d2e98b933cd794189a": {
                "Name": "container2",
                "EndpointID": "83f2f47944b59123b7baeed67c2314ab2589987eb2d251b1ac2dfa60f490f7ad",
                "MacAddress": "72:4a:56:91:a3:da",
                "IPv4Address": "172.18.0.3/16",
                "IPv6Address": ""
            },
            "666924cd8c72d330f11ba2e17104d81e299983af66d966b54f53dc3175faa357": {
                "Name": "container1",
                "EndpointID": "61edddd0226b5463f9b94bf65dcd3420f182d10670a5fa3973d46b1a2d890d0c",
                "MacAddress": "f6:9b:f3:e3:0e:54",
                "IPv4Address": "172.18.0.2/16",
                "IPv6Address": ""
            }
        }
```

**DNS Resolution (`nslookup`):**
```text
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:   container2
Address: 172.18.0.3
```

### 3.3 Analysis
**How Docker DNS works:**
Docker uses an embedded DNS server (`127.0.0.11`). On custom bridge networks, it automatically maps container names to their internal IP addresses, allowing service discovery by name.

**User-defined Bridge vs Default Bridge:**
User-defined bridges provide automatic DNS resolution (containers can ping by name) and better network isolation. The default bridge does not support DNS resolution by name out-of-the-box.

---

## Task 4 — Data Persistence with Volumes

### 4.1 & 4.2 Verification
**Custom HTML Content Used:**
```html
<html><body><h1>Persistent Data</h1></body></html>
```

**Persistence Check (after recreation):**
```text
PS C:\Users\User\Desktop> docker stop web
web
PS C:\Users\User\Desktop> docker rm web
web
PS C:\Users\User\Desktop> docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
cb3de2e1feb88347aedafaee38a7725622ffc647723be622855137a7df9489c3

PS C:\Users\User\Desktop> curl.exe http://localhost
<html><body><h1>Persistent Data</h1></body></html>
```

**Volume Inspection:**
```text
[
    {
        "CreatedAt": "2026-03-11T23:14:38Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

### 4.3 Analysis
**Importance of Persistence:**
Since container filesystems are ephemeral (destroyed when the container is removed), persistence is crucial for stateful applications like databases or user content storage to prevent data loss during updates or restarts.

**Storage Comparison:**
1.  **Volumes:** Managed by Docker (in `/var/lib/docker/volumes`). Best for persistent data and backups.
2.  **Bind Mounts:** Maps a host path to the container. Best for development environments.
3.  **Container Storage:** Ephemeral layer. Best for temporary files (tmp) that can be discarded.
``