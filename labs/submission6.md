# Lab 6 — Container Fundamentals with Docker

## Task 1 — Container Lifecycle & Image Management

### 1.1: Basic Container Operations

**List Existing Containers:**

Command:

```bash
docker ps -a
```

Output:

```bash
CONTAINER ID   IMAGE                              COMMAND                  CREATED        STATUS                    PORTS     NAMES
52e0c39051e6   deployment-streamlit               "streamlit run strea…"   13 days ago    Exited (0) 13 days ago              streamlit_app
d4a514c5859c   deployment-fastapi                 "uvicorn app:app --h…"   13 days ago    Exited (0) 13 days ago              fastapi_service
cfea53ca891b   part2-backend                      "python3 /backend/ba…"   2 weeks ago    Exited (0) 2 weeks ago              part2-backend-1
cc5ca22649eb   part2-frontend                     "streamlit run /fron…"   2 weeks ago    Exited (0) 2 weeks ago              part2-frontend-1
4092a7b2e811   semitechnologies/weaviate:1.24.4   "/bin/weaviate --hos…"   3 months ago   Exited (0) 3 months ago             datasetpreparing-weaviate-1
```

**Pull Ubuntu Image:**

Command

```bash
docker pull ubuntu:latest
docker images ubuntu
```

Output

```bash
latest: Pulling from library/ubuntu
7bdf644cff2e: Pull complete 
Digest: sha256:728785b59223d755e3e5c5af178fab1be7031f3522c5ccd7a0b32b80d8248123
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
REPOSITORY   TAG       IMAGE ID       CREATED      SIZE
ubuntu       latest    728785b59223   7 days ago   139MB
```

**Run Interactive Container:**

Command

```bash
docker run -it --name ubuntu_container ubuntu:latest
```

**Inside the container exploration:**

Commands

```bash
cat /etc/os-release
ps aux
exit
```

Outputs

```bash
> PRETTY_NAME="Ubuntu 24.04.3 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.3 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo

> USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4296  3612 pts/0    Ss   19:01   0:00 /bin/bash
root        10  0.0  0.0   7628  3468 pts/0    R+   19:02   0:00 ps aux
```

### 1.2: Image Export and Dependency Analysis

**Export the Image:**

Commands

```bash
docker save -o ubuntu_image.tar ubuntu:latest
ls -lh ubuntu_image.tar
```

Output

```bash
-rw-------@ 1 rail  staff    28M Oct  7 22:05 ubuntu_image.tar
```

**Attempt Image Removal:**

Command

```bash
docker rmi ubuntu:latest
```

Output

```bash
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container 22290317e64e is using its referenced image 728785b59223
```

**Remove Container and Retry:**

Commands

```bash
docker rm ubuntu_container
docker rmi ubuntu:latest
```

Output

```bash
ubuntu_container
Untagged: ubuntu:latest
Deleted: sha256:728785b59223d755e3e5c5af178fab1be7031f3522c5ccd7a0b32b80d8248123
```

### Task 1 Analysis

### Output of docker ps -a and docker images, same as Error message from the first removal attempt, provided above

#### Image size and layer count

The Ubuntu image size is **139MB** as shown in the `docker images` output. The image was created 7 days ago and uses the latest tag. The pull output shows one layer being downloaded (7bdf644cff2e), indicating this is a single-layer image.

#### Tar file size comparison

The exported tar file (`ubuntu_image.tar`) is **28MB**, which is significantly smaller than the reported Docker image size of 139MB. This difference occurs because:

- Tar file contains compressed layers
- Docker's reported size includes uncompressed filesystem layers

#### Analysis: Why does image removal fail when a container exists?

Docker prevents image removal when containers (even stopped ones) depend on that image because:

- Containers maintain a reference to their base image
- Removing the image would break the container's ability to restart
- The image contains the filesystem layers that the container needs

#### Explanation: What is included in the exported tar file?

The exported tar file contains:

- All filesystem layers that make up the image
- Image metadata and configuration
- Layer manifests and checksums
- Repository and tag information
- The complete image structure needed to recreate the image on another system

The tar file is typically larger than the reported image size because it includes uncompressed layers and metadata overhead.

## Task 2 — Custom Image Creation & Analysis

### 2.1: Deploy and Customize Nginx

**Deploy Nginx Container:**

Commands:

```bash
docker run -d -p 80:80 --name nginx_container nginx
curl http://localhost
```

Output:

```bash
> Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
5f648e62e9ca: Pull complete 
bb2e7b5dc9bc: Pull complete 
f0838cc8bade: Pull complete 
08b278be6f74: Pull complete 
f4e51325a7cb: Pull complete 
4c5dff34614b: Pull complete 
e2a2ff429ed9: Pull complete 
Digest: sha256:8adbdcb969e2676478ee2c7ad333956f0c8e0e4c5a7463f4611d7a2e7a7ff5dc
Status: Downloaded newer image for nginx:latest
c8ae211a51e94edd5911cedd9abafa68c7594d9c5cdb812fb9c4728175e51a0f

> <!DOCTYPE html>
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

**Create Custom HTML:**

Created file `index.html` with content:

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

**Copy Custom Content:**

Commands:

```bash
docker cp index.html nginx_container:/usr/share/nginx/html/
curl http://localhost
```

Output:

```bash
> Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/
> <html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>%  
```

### 2.2: Create and Test Custom Image

**Commit Container to Image:**

Commands:

```bash
docker commit nginx_container my_website:latest
docker images my_website
```

Output:

```bash
> sha256:42f8d80c0d9216839d02b812853392bfd804e8acd4d79eb32082d92a55cd08cc
> REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
my_website   latest    42f8d80c0d92   10 seconds ago   281MB
```

**Remove Original and Deploy from Custom Image:**

Commands:

```bash
docker rm -f nginx_container
docker run -d -p 80:80 --name my_website_container my_website:latest
curl http://localhost
```

Output:

```bash
> nginx_container
> 9337c00f50349d9e6285839a2dc7ce5802469ea6274647f0f82484b00d5ef78c
> <html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>% 
```

**Analyze Filesystem Changes:**

Command:

```bash
docker diff my_website_container
```

Output:

```bash
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

### Task 2 Analysis

#### Screenshot or output of original Nginx welcome page

Provided above

#### Custom HTML content and verification

The custom `index.html` file contains a simple HTML structure with "The best" as the title and "website" as the main heading. After copying to the container and testing with curl, the output showed this custom content instead of the default Nginx welcome page. Output of `curl http://localhost` command provided above.

#### Output of docker diff analysis

Result of `docker diff my_website_container` also provided above.

#### Analysis: Explain the diff output (A=Added, C=Changed, D=Deleted)

All listed differences shows `C` predicate, indicating that this files/directories were changed.

#### Reflection: Advantages and disadvantages of docker commit vs Dockerfile

**Docker Commit Advantages:**

- Quick and easy for one-off customizations
- Captures exact current state of container
- Useful for debugging and experimentation
- No need to write Dockerfile syntax

**Docker Commit Disadvantages:**

- Not reproducible or version-controlled
- No documentation of what changes were made
- Creates larger images with unnecessary layers
- Not suitable for production workflows
- Difficult to maintain and update

**Dockerfile Advantages:**

- Reproducible and version-controlled
- Shows exactly what was done
- Optimized layer caching and smaller images
- Easy to modify and rebuild

**Dockerfile Disadvantages:**

- More time-consuming for simple changes
- Need to understand layer optimization

## Task 3 — Container Networking & Service Discovery

### 3.1: Create Custom Network

**Create Bridge Network:**

Commands:

```bash
docker network create lab_network
docker network ls
```

Output:

```bash
> 40d06cefd2ce2afbd8e561fde72791200c1821e090cc90c6c05fda946549333d
> NETWORK ID     NAME          DRIVER    SCOPE
17368f681773   bridge        bridge    local
07b957ec2fdf   host          host      local
40d06cefd2ce   lab_network   bridge    local
5b40e4ab87be   none          null      local
```

**Deploy Connected Containers:**

Commands:

```bash
docker run -dit --network lab_network --name container1 alpine ash
docker run -dit --network lab_network --name container2 alpine ash
```

Output:

```bash
> 7092eca639c548e268748297959877aa95907803606626e3d9eb664890dc9049 # id of cont1
> 52004a3a51a3730ac75ab83644aeb2547b4a32ef6e560ef106d72b82a12b7525 # id of cont2
```

### 3.2: Test Connectivity and DNS

**Test Container-to-Container Communication:**

Command:

```bash
docker exec container1 ping -c 3 container2
```

Output:

```bash
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.097 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.164 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.180 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.097/0.147/0.180 ms
```

**Inspect Network Details:**

Command:

```bash
docker network inspect lab_network
```

Output:

```bash
[
    {
        "Name": "lab_network",
        "Id": "40d06cefd2ce2afbd8e561fde72791200c1821e090cc90c6c05fda946549333d",
        "Created": "2025-10-07T19:34:56.133096421Z",
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
        "Containers": {
            "52004a3a51a3730ac75ab83644aeb2547b4a32ef6e560ef106d72b82a12b7525": {
                "Name": "container2",
                "EndpointID": "11bfc21aa8734d49a657515231467b412ff69fb9f276e8046b526245b2f468a8",
                "MacAddress": "76:1d:76:c6:f6:e3",
                "IPv4Address": "172.18.0.3/16",
                "IPv6Address": ""
            },
            "7092eca639c548e268748297959877aa95907803606626e3d9eb664890dc9049": {
                "Name": "container1",
                "EndpointID": "cc7d4412dabe917fbec8e36bfcc3c0ce11d63fea9370ed35b9ceea31873762cc",
                "MacAddress": "7e:73:6b:31:1b:c4",
                "IPv4Address": "172.18.0.2/16",
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

**Check DNS Resolution:**

Command:

```bash
docker exec container1 nslookup container2
```

Output:

```bash
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:   container2
Address: 172.18.0.3
```

### Task 3 Analysis

#### Output of ping command showing successful connectivity

Output provided above.
The ping command successfully connected container1 to container2:

- **Target**: container2 resolved to IP address 172.18.0.3
- **Response times**: 0.097ms, 0.164ms, 0.180ms (average: 0.147ms)
- **Success rate**: 100% (3 packets transmitted, 3 received, 0% packet loss)
- **Network performance**: Very low latency, indicating containers are on same host

#### Network inspection output showing both containers' IP addresses

Output provided above.

From the network inspection JSON output:

- **container1**: 172.18.0.2/16 (MAC: 7e:73:6b:31:1b:c4)
- **container2**: 172.18.0.3/16 (MAC: 76:1d:76:c6:f6:e3)
- **Network subnet**: 172.18.0.0/16
- **Gateway**: 172.18.0.1
- **Network ID**: 40d06cefd2ce2afbd8e561fde72791200c1821e090cc90c6c05fda946549333d

#### DNS resolution output

Output provided above.
The nslookup command showed:

- **DNS Server**: 127.0.0.11:53 (Docker's embedded DNS server)
- **Resolution**: container2 → 172.18.0.3
- **Response type**: Non-authoritative answer

#### Analysis: How does Docker's internal DNS enable container-to-container communication by name?

Docker's internal DNS service provides automatic service discovery within user-defined networks by:

- **Embedded DNS Server**: Docker runs an internal DNS server (typically at 127.0.0.11) within each container
- **Name Resolution**: Container names are automatically registered as DNS entries in the network
- **Dynamic Updates**: When containers join or leave the network, DNS records are updated automatically
- **Network Isolation**: DNS resolution is scoped to the specific network, preventing cross-network name conflicts
- **Backward Compatibility**: Works with standard networking tools and applications expecting DNS resolution

#### Comparison: What advantages does user-defined bridge networks provide over the default bridge network?

**User-Defined Bridge Network Advantages:**

1. **Automatic DNS Resolution**: Container names automatically resolve to IP addresses
2. **Better Isolation**: Network-level isolation between different applications
3. **Configurable**: Can specify subnet, IP range, and gateway
4. **Hot-pluggable**: Containers can be connected/disconnected without stopping
5. **Advanced Configuration**: Support for custom bridge settings and options

**Default Bridge Network Limitations:**

1. **No Automatic DNS**: Must use `--link` (deprecated) or IP addresses for communication
2. **Single Network**: All containers share the same network space
3. **Limited Isolation**: Less secure separation between containers
4. **Legacy Design**: Based on older Docker networking concepts
5. **Manual IP Management**: Requires manual tracking of container IP addresses

User-defined networks provide a more modern, scalable, and secure approach to container networking.

## Task 4 — Data Persistence with Volumes

### 4.1: Create and Use Volume

**Create Named Volume:**

Commands:

```bash
docker volume create app_data
docker volume ls
```

Output:

```bash
> app_data
> DRIVER    VOLUME NAME
local     app_data
local     datasetpreparing_weaviate_data
```

**Deploy Container with Volume:**

Command:

```bash
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
```

Output:

```bash
c4cb32981f0eb4daf908b07b2fb2ac33dc8bc4cdab43ee0df7228120e3c0a766
```

**Add Custom Content:**

Updated file `index.html` with content:

```html
<html><body><h1>Persistent Data</h1></body></html>
```

Commands:

```bash
docker cp index.html web:/usr/share/nginx/html/
curl http://localhost
```

Output:

```bash
> Successfully copied 2.05kB to web:/usr/share/nginx/html/
> <html><body><h1>Persistent Data</h1></body></html>%  
```

### 4.2: Verify Persistence

**Destroy and Recreate Container:**

Commands:

```bash
docker stop web && docker rm web
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
curl http://localhost
```

Output:

```bash
> web
> web
> efc0021e99cc479beb77de5fa3cdd336ec72cf21df1c52f21c9744332042bfd4
> <html><body><h1>Persistent Data</h1></body></html>%   
```

**Inspect Volume:**

Command:

```bash
docker volume inspect app_data
```

Output:

```bash
[
    {
        "CreatedAt": "2025-10-07T19:47:04Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

### Task 4 Analysis

#### Custom HTML content used

Provided above

#### Output of curl showing content persists after container recreation

Provided above

#### Volume inspection output showing mount point

Provided above

#### Analysis: Why is data persistence important in containerized applications?

Data persistence is crucial in containerized applications for several reasons:

1. **Stateful Applications**: Many applications need to maintain state (databases, user uploads, configuration files) that must survive container restarts
2. **Container Lifecycle Independence**: Containers are ephemeral by design - they can be stopped, removed, and recreated at any time
3. **Data Safety**: Without persistence, all data created inside a container is lost when the container is removed
4. **Scalability**: Enables horizontal scaling where multiple container instances can share the same persistent data
5. **Backup and Recovery**: Persistent volumes can be backed up and restored independently of containers
6. **Development Workflow**: Allows developers to update container images while preserving application data
7. **Production Reliability**: Critical for production systems where data loss is unacceptable

#### Comparison: Explain the differences between volumes, bind mounts, and container storage. When would you use each?

**Docker Volumes:**

- **Management**: Fully managed by Docker
- **Location**: Stored in Docker's internal directory structure
- **Portability**: Work across different Docker hosts and platforms
- **Performance**: Optimized for container workloads
- **Use Cases**:
  - Database storage
  - Application data that needs to persist
  - Sharing data between containers
  - Production deployments

**Bind Mounts:**

- **Management**: Direct mapping to host filesystem paths
- **Location**: Any directory on the host system
- **Portability**: Host-dependent (paths must exist on target host)
- **Performance**: Direct filesystem access (can be faster)
- **Use Cases**:
  - Development environments (live code editing)
  - Configuration files from host
  - Logs that need host access
  - Integration with host-based tools

**Container Storage:**

- **Management**: Part of container's writable layer
- **Location**: Inside container filesystem
- **Portability**: Lost when container is removed
- **Performance**: Varies by storage driver
- **Use Cases**:
  - Temporary files and caches
  - Application logs (if externally collected)
  - Stateless applications
  - Processing temporary data

**Usage:**

- **Use Volumes**: When you need persistent, portable data storage managed by Docker
- **Use Bind Mounts**: When you need direct host filesystem access or development workflows
- **Use Container Storage**: When data is temporary or the application is truly stateless
