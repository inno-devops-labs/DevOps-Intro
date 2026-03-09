# Lab 6 — Container Fundamentals with Docker



## Task 1 — Container Lifecycle & Image Management

### List Existing Containers:

```bash
docker ps -a
```

```bash
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

### Pull Ubuntu Image:

```bash
docker pull ubuntu:latest
```

```bash
latest: Pulling from library/ubuntu
66a4bbbfab88: Pull complete 
9c2a2ec78563: Download complete 
Digest: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
```

---

```bash
docker images ubuntu
```

```bash
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   d1e2e92c075e        141MB         30.8MB
```

### Run Interactive Container:

```bash
docker run -it --name ubuntu_container ubuntu:latest
```

```bash
root@66e16b843422:/#
```

### OS version:

```bash
cat /etc/os-release
```

```bash
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
```

### List processes:

```bash
ps aux
```

```bash
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4300  3636 pts/0    Ss   08:28   0:00 /bin/bash
root        10  0.0  0.0   7632  3652 pts/0    R+   08:30   0:00 ps aux
```

---

```bash
exit
```

```bash
exit
```

### Export the Image:

```bash
docker save -o ubuntu_image.tar ubuntu:latest
ls -lh ubuntu_image.tar
```

```bash
-rw-------@ 1 miraladutska  staff    29M Mar  9 11:31 ubuntu_image.tar
```

### Attempt Image Removal:

```bash
docker rmi ubuntu:latest
```

```bash
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container 66e16b843422 is using its referenced image d1e2e92c075e
```

### Remove Container and Retry:

```bash
docker rm ubuntu_container
docker rmi ubuntu:latest
```

```bash
ubuntu_container
Untagged: ubuntu:latest
Deleted: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
```

### **Analysis:** 
Deleting an image fails while a container created from that image exists because the container stores a reference to the specific image ID as its read-only base layer.

### **Explanation:** 
The exported tar file created by the docker save command does not contain the container, but rather the image with all its layers and metadata.



## Task 2 — Custom Image Creation & Analysis

### Deploy Nginx Container:

```bash
docker run -d -p 80:80 --name nginx_container nginx
curl http://localhost
```

```bash
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
901e94f777d1: Pull complete 
2668e3434976: Pull complete 
c813174c999b: Pull complete 
e88d7844c33d: Pull complete 
3b66ab8c894c: Pull complete 
f2c05cdfb149: Pull complete 
4a89256e588a: Pull complete 
3c9c97ab7d80: Download complete 
35dee7ece046: Download complete 
Digest: sha256:0236ee02dcbce00b9bd83e0f5fbc51069e7e1161bd59d99885b3ae1734f3392e
Status: Downloaded newer image for nginx:latest
8e8e1134ae52854070abe17a89b283605b52bddcea0b1db3285dcfed9f9bf4e2

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

### Create Custom HTML:

```bash
nano index.html
```

```bash
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

### Copy Custom Content:

```bash
docker cp index.html nginx_container:/usr/share/nginx/html/
curl http://localhost
```

```bash
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

### Commit Container to Image:

```bash
docker commit nginx_container my_website:latest
docker images my_website
```

```bash
sha256:aa46c4968c64cb46200090c7dabe6185117fdfebc75c2c5e39d01394a12bc01b

IMAGE               ID             DISK USAGE   CONTENT SIZE   EXTRA
my_website:latest   aa46c4968c64        255MB         61.3MB
```

### Remove Original and Deploy from Custom Image:

```bash
docker rm -f nginx_container
docker run -d -p 80:80 --name my_website_container my_website:latest
curl http://localhost
```

```bash
nginx_container

223b1bf3c4142ab4846839b96fe5d0a386e35e057a7dcb4bf4395893f5d65916

<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

### Analyze Filesystem Changes:

```bash
docker diff my_website_container
```

```bash
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

### **Analysis:** 


- **A — Added:** A file or directory was added
- **C — Changed:** An existing file or directory was modified
- **D — Deleted** A file or directory was deleted

### **Reflection:** 

**Advantages of docker commit:**

- Fast and convenient for experimentation;
- Allows to save the current state of an already configured container;
- It is useful for debugging and prototyping.

**Disadvantages of docker commit:**

- Poorly reproducible: the exact history of which steps were performed is not visible;
- Difficult to maintain and update;
- It is difficult to use in a team and in CI/CD;
unnecessary or accidental changes may get into the image;
- It documents the build process worse.

**Advantages of Dockerfile:**

- The build is fully reproducible;
- All steps are explicitly described in the code;
- It is convenient to store in Git;
- Easier to automate, test, and maintain;
- It better matches the best practices of DevOps and production environments.

**Disadvantages of Dockerfile:**
- Requires more time for initial setup;
- It is less convenient for very quick one-time experiments.;
- It is necessary to describe the steps in advance, and not just “save the current state".



## Task 3 — Container Networking & Service Discovery

### Create Bridge Network:

```bash
docker network create lab_network
docker network ls
```

```bash
3afee910497e60b78a955b427cfcc134890fcd89aeb47163bb8463e84b49a71a

NETWORK ID     NAME          DRIVER    SCOPE
ed208f0c29f9   bridge        bridge    local
0b3fe1d513e8   host          host      local
3afee910497e   lab_network   bridge    local
9768eaaeedb2   none          null      local
```

### Deploy Connected Containers:

```bash
docker run -dit --network lab_network --name container1 alpine ash
docker run -dit --network lab_network --name container2 alpine ash
```

```bash
Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
d8ad8cd72600: Pull complete 
cb94f19e6ea6: Download complete 
37093440b0e0: Download complete 
Digest: sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659
Status: Downloaded newer image for alpine:latest
939e0686cc5f69c49ce8f004e59372dbecb0ecdcfcecd75162e4ce51c758e2c5
477459085d12e09ae5e24e88939103648afe160378dd069a7654c044f1d07fbf
```

### Test Container-to-Container Communication:

```bash
docker exec container1 ping -c 3 container2
```

```bash
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.897 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.098 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.248 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.098/0.414/0.897 ms
```

### Inspect Network Details:

```bash
docker network inspect lab_network
```

```bash
[
    {
        "Name": "lab_network",
        "Id": "3afee910497e60b78a955b427cfcc134890fcd89aeb47163bb8463e84b49a71a",
        "Created": "2026-03-09T08:58:02.114893928Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.18.0.0/16",
                    "Gateway": "172.18.0.1"
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
        "Options": {
            "com.docker.network.enable_ipv4": "true",
            "com.docker.network.enable_ipv6": "false"
        },
        "Labels": {},
        "Containers": {
            "477459085d12e09ae5e24e88939103648afe160378dd069a7654c044f1d07fbf": {
                "Name": "container2",
                "EndpointID": "c9887e3e810f83f080aa9477d4c78afd6ef5170225bc609f77741c89bffef0b7",
                "MacAddress": "7e:7f:ad:e0:7f:0e",
                "IPv4Address": "172.18.0.3/16",
                "IPv6Address": ""
            },
            "939e0686cc5f69c49ce8f004e59372dbecb0ecdcfcecd75162e4ce51c758e2c5": {
                "Name": "container1",
                "EndpointID": "371bcc76902119d3f7064bb885a2d149ecfb7006b6d12eea5bf1b6484f098d65",
                "MacAddress": "ca:61:86:ac:ed:ca",
                "IPv4Address": "172.18.0.2/16",
                "IPv6Address": ""
            }
        },
        "Status": {
            "IPAM": {
                "Subnets": {
                    "172.18.0.0/16": {
                        "IPsInUse": 5,
                        "DynamicIPsAvailable": 65531
                    }
                }
            }
        }
    }
]
```

### Inspect Network Details:

```bash
docker exec container1 nslookup container2
```

```bash
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:
Name:   container2
Address: 172.18.0.3

Non-authoritative answer:
```

**Analysis:** Docker has a built-in DNS server for user-defined networks. When a container connects to such a network, Docker automatically registers its name and IP address in this internal DNS system.

**Comparison:** 

- Embedded DNS containers can address each other by name.
- The best isolation is that the network is created separately for specific services.
- Automatic service discovery.
- Convenient management — can connect and disconnect containers from the network without rebuilding.



## Task 4 — Data Persistence with Volumes

### Create Named Volume:

```bash
docker volume create app_data
docker volume ls
```

```bash
app_data

DRIVER    VOLUME NAME
local     app_data
```

### Deploy Container with Volume:

```bash
docker run -d -p 90:90 -v app_data:/usr/share/nginx/html --name web nginx
```

```bash
7bc7bef68ddf88afca13aa2d8ff80a823263c087f51487e14cd51cacf6f22c4e
```

### Create a custom `index.html` file:

```bash
nano index.html
```

```bash
<html><body><h1>Persistent Data</h1></body></html>
```

### Copy to volume:

```bash
docker cp index.html web:/usr/share/nginx/html/
curl http://localhost
```

```bash
Successfully copied 2.05kB to web:/usr/share/nginx/html/

<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

### Destroy and Recreate Container:

```bash
docker stop web && docker rm web
docker run -d -p 90:90 -v app_data:/usr/share/nginx/html --name web_new nginx
curl http://localhost
```

```bash
web
web

71e42abbf4ccdbc371b15b96baafe715c5636e4f83b393972769e2e1da1f2bc8

<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

### Inspect Volume:

```bash
docker volume inspect app_data
```

```bash
[
    {
        "CreatedAt": "2026-03-09T09:05:07Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

**Analysis:** Data persistence is important in container applications because the container's file system is ephemeral. When a container is deleted, all data written to its writable layer disappears.

**Comparison:** 

1. Volumes
    - They are managed by Docker.
    - They are stored in a special Docker directory.
    - They are best suited for persistent data.
    - Portable and safer for production.

**When to use it**:
For persistent application data.

2. Bind mounts
    - Mount a specific host folder into a container.
    - Full access to the host file system.
    - They are often used in development.

**When to use it**:
Need to synchronize the code between the host and the container.

3. Container storage
    - Built-in temporary storage of the container.
    - It is deleted along with the container.
    - It is not intended for permanent data.

**When to use it**:
For temporary files, cache, or runtime data that does not need to be saved.
