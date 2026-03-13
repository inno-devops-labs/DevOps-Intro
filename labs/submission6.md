# Task 1 — Container Lifecycle & Image Management

## 1.1 Basic Container Operations

### List Existing Containers

Command executed:

```bash
docker ps -a
```

Output:

```bash
CONTAINER ID   IMAGE                  COMMAND                  CREATED      STATUS                    PORTS     NAMES
7532fd271564   citusdata/citus:12.1   "docker-entrypoint.s…"   6 days ago   Exited (0) 6 days ago               citus-worker-1
888219b7165c   citusdata/citus:12.1   "docker-entrypoint.s…"   6 days ago   Exited (0) 6 days ago               citus-worker-2
1b833bddc24b   citusdata/citus:12.1   "docker-entrypoint.s…"   6 days ago   Exited (137) 6 days ago             citus-coordinator
c63856085e9f   mongo:6                "docker-entrypoint.s…"   8 days ago   Exited (137) 6 days ago             mongo2
eab47716bee8   mongo:6                "docker-entrypoint.s…"   8 days ago   Exited (137) 6 days ago             mongo1
c6db1f443af3   mongo:6                "docker-entrypoint.s…"   8 days ago   Exited (137) 6 days ago             mongo3
3fd47080e646   scylladb/scylla:5.4    "/docker-entrypoint.…"   8 days ago   Exited (0) 4 days ago               scylla2
c786eb5cc5af   scylladb/scylla:5.4    "/docker-entrypoint.…"   8 days ago   Exited (0) 4 days ago               scylla3
504e77bb1bd9   scylladb/scylla:5.4    "/docker-entrypoint.…"   8 days ago   Exited (137) 4 days ago             scylla1
4515f9d220af   neo4j:5                "tini -g -- /startup…"   9 days ago   Exited (0) 8 days ago               neo4j-lab
87b59cea317a   mongo:7                "docker-entrypoint.s…"   9 days ago   Exited (0) 8 days ago               mongodb-lab
56799e25512c   cassandra:4.1          "docker-entrypoint.s…"   9 days ago   Exited (143) 8 days ago             cassandra-lab
```

Analysis:

The command `docker ps -a` lists all containers on the system, including both running and stopped ones.  
From the output we can see several previously created containers based on images such as `mongo`, `citusdata/citus`, `scylladb/scylla`, `neo4j`, and `cassandra`.

Most containers are currently in the **Exited** state, which means they are not running but still exist in Docker's container storage. Containers remain in this state until they are explicitly removed with `docker rm`.

### Pull Ubuntu Image

Commands executed:

```bash
docker pull ubuntu:latest
docker images ubuntu
```

Output:

```bash
PS C:\Users\vlada> docker pull ubuntu:latest
latest: Pulling from library/ubuntu
01d7766a2e4a: Pull complete
Digest: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
```

```bash
PS C:\Users\vlada> docker images ubuntu
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    bbdabce66f1b   4 weeks ago   78.1MB
```

Analysis:

The command `docker pull ubuntu:latest` downloads the Ubuntu image from Docker Hub to the local Docker registry. Docker pulls the image layers and verifies them using a digest (SHA256).

The command `docker images ubuntu` lists locally available images related to Ubuntu. The output shows that the `ubuntu:latest` image is now stored locally with an image ID `bbdabce66f1b` and a size of **78.1 MB**.

### Run Interactive Container

Command executed:

```bash
docker run -it --name ubuntu_container ubuntu:latest
```

Commands executed inside the container:

```bash
cat /etc/os-release
ps aux
exit
```

Output of `cat /etc/os-release`:

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

Output of `ps aux`:

```bash
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.1  0.0   4588  3200 pts/0    Ss   13:29   0:00 /bin/bash
root        10  0.0  0.0   7888  4096 pts/0    R+   13:29   0:00 ps aux
```

Analysis:

The container started successfully in interactive mode from the `ubuntu:latest` image.  
The file `/etc/os-release` confirms that the container is running **Ubuntu 24.04.4 LTS**.

The `ps aux` output shows only a minimal process set inside the container. The main process with PID 1 is `/bin/bash`, which was launched by `docker run -it`. The second process is the `ps aux` command itself. This demonstrates that a container usually runs a small number of processes and is centered around its main process.

## 1.2 Export the Image

### Save Ubuntu Image to TAR Archive

Commands executed:

```bash
docker save -o ubuntu_image.tar ubuntu:latest
Get-Item .\ubuntu_image.tar | Select-Object Name,Length
```

Output:

```bash
PS C:\Users\vlada> docker save -o ubuntu_image.tar ubuntu:latest
```

```bash
PS C:\Users\vlada> Get-Item .\ubuntu_image.tar | Select-Object Name,Length

Name               Length
----               ------
ubuntu_image.tar 80654848
```

Analysis:

The command `docker save -o ubuntu_image.tar ubuntu:latest` exports the Docker image `ubuntu:latest` into a TAR archive file.

The file `ubuntu_image.tar` was successfully created. Its size is **80,654,848 bytes**, which confirms that the image was written to disk and can now be transferred or imported later with `docker load`.

Note:

In PowerShell, the Linux-style command `ls -lh ubuntu_image.tar` is not supported with the `-lh` flags, because `ls` is mapped to `Get-ChildItem`. Therefore, the file information was checked using:

```powershell
Get-Item .\ubuntu_image.tar | Select-Object Name,Length
```

### Remove Local Ubuntu Image

Commands executed:

```bash
docker rm ubuntu_container
docker rmi ubuntu:latest
docker images ubuntu
```

Output:

```bash
PS C:\Users\vlada> docker rm ubuntu_container
ubuntu_container
```

```bash
PS C:\Users\vlada> docker rmi ubuntu:latest
Untagged: ubuntu:latest
Untagged: ubuntu@sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Deleted: sha256:bbdabce66f1b7dde0c081a6b4536d837cd81dd322dd8c99edd68860baf3b2db3
Deleted: sha256:efafae78d70c98626c521c246827389128e7d7ea442db31bc433934647f0c791
```

```bash
PS C:\Users\vlada> docker images ubuntu
REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
```

Analysis:

Before deleting the image, the container `ubuntu_container` had to be removed because Docker does not allow deleting an image that is still referenced by an existing container.

The command `docker rmi ubuntu:latest` successfully removed the Ubuntu image from the local image store. The output shows that both the image tag and its layers were deleted.

The command `docker images ubuntu` returns an empty list, which confirms that the Ubuntu image is no longer available locally.

### Restore Ubuntu Image from TAR Archive

Commands executed:

```bash
docker load -i ubuntu_image.tar
docker images ubuntu
```

Output:

```bash
PS C:\Users\vlada> docker load -i ubuntu_image.tar
efafae78d70c: Loading layer [==================================================>]  80.64MB/80.64MB
Loaded image: ubuntu:latest
```

```bash
PS C:\Users\vlada> docker images ubuntu
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    bbdabce66f1b   4 weeks ago   78.1MB
```

Analysis:

The command `docker load -i ubuntu_image.tar` successfully restored the previously exported Ubuntu image from the TAR archive.

Docker reconstructed the image layers and registered the image locally again under the tag `ubuntu:latest`.

The command `docker images ubuntu` confirms that the image is available again with the same image ID `bbdabce66f1b` and size **78.1 MB**. This demonstrates that Docker images can be exported to a file and later restored without downloading them again from Docker Hub.

# Task 2 — Custom Image Creation & Analysis

## 2.1 Deploy and Customize Nginx

### Deploy Nginx Container

Commands executed:

```bash
docker run -d --name my_nginx -p 8080:80 nginx
docker ps
```

Output:

```bash
PS C:\Users\vlada> docker run -d --name my_nginx -p 8080:80 nginx
f6288ea884f99fb45807fe6d1785a520b313d83aa3d3fc0fb9ac8833d3fc0fb9ac8833fddd1da9
```

```bash
PS C:\Users\vlada> docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS         PORTS                  NAMES
f6288ea884f9   nginx     "/docker-entrypoint.…"   2 seconds ago   Up 2 seconds   0.0.0.0:8080->80/tcp   my_nginx
```

Browser verification:

The page at `http://localhost:8080` opened successfully and displayed the default **“Welcome to nginx!”** page.

Analysis:

The container was started in detached mode using the official `nginx` image.  
The option `-p 8080:80` maps port **8080** on the host to port **80** inside the container, which makes the web server accessible from the browser on the local machine.

The `docker ps` output confirms that the container is running and that port forwarding is active. The successful browser check proves that Nginx inside the container is serving content correctly.

### Create Custom HTML

Command executed:

```powershell
@"
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
"@ | Set-Content -Path .\index.html
```

Verification command:

```powershell
Get-Content .\index.html
```

Output:

```bash
PS C:\Users\vlada> Get-Content .\index.html
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

Analysis:

A custom `index.html` file was created on the host system.  
This file will be copied into the running Nginx container to replace the default welcome page.

The verification output confirms that the file contains the required HTML structure with the title **“The best”** and the heading **“website”**.

### Copy Custom Content into the Running Container

Commands executed:

```bash
docker cp .\index.html my_nginx:/usr/share/nginx/html/index.html
curl http://localhost:8080
```

Output:

```bash
PS C:\Users\vlada> docker cp .\index.html my_nginx:/usr/share/nginx/html/index.html
Successfully copied 2.05kB to my_nginx:/usr/share/nginx/html/index.html
```

```bash
PS C:\Users\vlada> curl http://localhost:8080


StatusCode        : 200
StatusDescription : OK
Content           : <html>
                    <head>
                    <title>The best</title>
                    </head>
                    <body>
                    <h1>website</h1>
                    </body>
                    </html>

RawContent        : HTTP/1.1 200 OK
                    Connection: keep-alive
                    Accept-Ranges: bytes
                    Content-Length: 87
                    Content-Type: text/html
                    Date: Fri, 13 Mar 2026 13:48:02 GMT
                    ETag: "69b41529-57"
                    Last-Modified: Fri, 13 Mar 2026 13...
Forms             : {}
Headers           : {[Connection, keep-alive], [Accept-Ranges, bytes], [Content-Length, 87], [Content-Type, text/html].
                    ..}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : System.__ComObject
RawContentLength  : 87
```

Analysis:

The file `index.html` was successfully copied from the host into the running container at `/usr/share/nginx/html/index.html`, which is the default directory used by Nginx to serve static web content.

The HTTP request to `http://localhost:8080` returned status code **200 OK** and the response body contains the custom HTML page. This confirms that the default Nginx page was replaced successfully and that the container is now serving the custom website content.

## 2.2 Create and Test Custom Image

### Commit Running Container to a New Image

Commands executed:

```bash
docker commit my_nginx my_website:latest
docker images my_website
```

Output:

```bash
PS C:\Users\vlada> docker commit my_nginx my_website:latest
sha256:08302588b4c0253fae7457b688d245e0e9b6b291a6784dda6f4f9602bcf042ea
```

```bash
PS C:\Users\vlada> docker images my_website
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
my_website   latest    08302588b4c0   2 seconds ago   192MB
```

Analysis:

The command `docker commit my_nginx my_website:latest` created a new image from the current filesystem state of the running container.

This new image includes the modified `index.html` file that replaced the default Nginx page. The command `docker images my_website` confirms that the new image was created successfully and stored locally under the name `my_website:latest`.

This demonstrates that `docker commit` can capture manual changes made inside a container and save them as a reusable image.

### Remove Original Container and Run from Custom Image

Commands executed:

```bash
docker rm -f my_nginx
docker run -d -p 8080:80 --name my_website_container my_website:latest
curl http://localhost:8080
```

Output:

```bash
PS C:\Users\vlada> docker rm -f my_nginx
my_nginx
```

```bash
PS C:\Users\vlada> docker run -d -p 8080:80 --name my_website_container my_website:latest
ba3027667a633f1eff97bff704d0fcd464c0294c4f4568c0881eca2827820d8a
```

```bash
PS C:\Users\vlada> curl http://localhost:8080


StatusCode        : 200
StatusDescription : OK
Content           : <html>
                    <head>
                    <title>The best</title>
                    </head>
                    <body>
                    <h1>website</h1>
                    </body>
                    </html>

RawContent        : HTTP/1.1 200 OK
                    Connection: keep-alive
                    Accept-Ranges: bytes
                    Content-Length: 87
                    Content-Type: text/html
                    Date: Fri, 13 Mar 2026 13:52:53 GMT
                    ETag: "69b41529-57"
                    Last-Modified: Fri, 13 Mar 2026 13...
Forms             : {}
Headers           : {[Connection, keep-alive], [Accept-Ranges, bytes], [Content-Length, 87], [Content-Type, text/html].
                    ..}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : System.__ComObject
RawContentLength  : 87
```

Analysis:

The original container `my_nginx` was removed using `docker rm -f`.  
A new container `my_website_container` was then started from the custom image `my_website:latest`.

The HTTP request to `http://localhost:8080` returned status code **200 OK** and the response body contains the custom HTML page. This confirms that the modified content was successfully preserved inside the new Docker image and is now served by the new container.

### Inspect Container Filesystem Changes

Command executed:

```bash
docker diff my_website_container
```

Output:

```bash
PS C:\Users\vlada> docker diff my_website_container
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

Explanation of diff symbols:

- **A** — Added file or directory
- **C** — Changed file or directory
- **D** — Deleted file or directory

Analysis:

The command `docker diff` shows changes in the container filesystem compared to the original image.

All listed entries are marked with **C**, which means the files or directories were modified after the container started. These changes are mainly related to runtime operations of the Nginx server, such as creation of the process PID file and updates to configuration-related directories.

Reflection: Docker Commit vs Dockerfile

The `docker commit` command is useful for quickly capturing the current state of a container and turning it into a reusable image. However, it has several drawbacks. The process is not transparent, not reproducible, and does not clearly document what changes were made.

In contrast, using a **Dockerfile** is considered best practice because it defines the image creation process declaratively. A Dockerfile makes builds reproducible, easier to version control, and easier for other developers to understand and maintain.

Therefore, while `docker commit` is convenient for experimentation or debugging, production images should normally be built using Dockerfiles.

# Task 3 — Container Networking & Service Discovery

## 3.1 Create Custom Network

### Create Bridge Network

Commands executed:

```bash
docker network create lab_network
docker network ls
```

Output:

```bash
PS C:\Users\vlada> docker network create lab_network
a785ef2ee84135da0ac71e73568777f5a93d103425b27061dbad906a0af527b7
```

```bash
PS C:\Users\vlada> docker network ls
NETWORK ID     NAME             DRIVER    SCOPE
48aa328513fa   bigdata_labnet   bridge    local
20e054abaf7c   bridge           bridge    local
4b1928a25d99   host             host      local
a785ef2ee841   lab_network      bridge    local
d95ab6192cac   none             null      local
```

Analysis:

The command `docker network create lab_network` successfully created a user-defined bridge network named `lab_network`.

The `docker network ls` output confirms that the new network now exists and uses the **bridge** driver. User-defined bridge networks allow containers to communicate with each other more easily and provide built-in DNS-based name resolution.

### Deploy Connected Containers

Commands executed:

```bash
docker run -dit --network lab_network --name container1 alpine ash
docker run -dit --network lab_network --name container2 alpine ash
docker ps
```

Output:

```bash
PS C:\Users\vlada> docker run -dit --network lab_network --name container1 alpine ash
Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
589002ba0eae: Pull complete
Digest: sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659
Status: Downloaded newer image for alpine:latest
e1bb5a5ca1f2aa9d77da41d9a57d51bf26d21275d224a89fb2863c1db33d18cd
```

```bash
PS C:\Users\vlada> docker run -dit --network lab_network --name container2 alpine ash
f1e385ddb3cf15abc3eedb319fece785fc9cb36b2a81bd3602b6d803abedc21c
```

```bash
PS C:\Users\vlada> docker ps
CONTAINER ID   IMAGE               COMMAND                  CREATED                  STATUS                  PORTS                  NAMES
f1e385ddb3cf   alpine              "ash"                    Less than a second ago   Up Less than a second                          container2
e1bb5a5ca1f2   alpine              "ash"                    1 second ago             Up Less than a second                          container1
ba3027667a63   my_website:latest   "/docker-entrypoint.…"   9 minutes ago            Up 9 minutes            0.0.0.0:8080->80/tcp   my_website_container
```

Analysis:

Two Alpine containers, `container1` and `container2`, were successfully started in detached interactive mode and attached to the user-defined bridge network `lab_network`.

Because the Alpine image was not present locally, Docker automatically downloaded it from Docker Hub before starting the first container.

The `docker ps` output confirms that both containers are running and available for network connectivity tests.

## 3.2 Test Connectivity and DNS

### Test Container-to-Container Communication

Command executed:

```bash
docker exec container1 ping -c 3 container2
```

Output:

```bash
PS C:\Users\vlada> docker exec container1 ping -c 3 container2
PING container2 (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=1.205 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.085 ms
64 bytes from 172.19.0.3: seq=2 ttl=64 time=0.207 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.085/0.499/1.205 ms
```

Analysis:

The ping test from `container1` to `container2` completed successfully.  
All three packets were transmitted and received with **0% packet loss**, which confirms that the containers can communicate with each other over the user-defined bridge network.

The hostname `container2` was resolved to the IP address `172.19.0.3`, showing that Docker's internal DNS is working correctly inside the custom network.

### Inspect Network Details

Command executed:

```bash
docker network inspect lab_network
```

Output:

```bash
PS C:\Users\vlada> docker network inspect lab_network
[
    {
        "Name": "lab_network",
        "Id": "a785ef2ee84135da0ac71e73568777f5a93d103425b27061dbad906a0af527b7",
        "Created": "2026-03-13T13:59:21.095169199Z",
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
            "e1bb5a5ca1f2aa9d77da41d9a57d51bf26d21275d224a89fb2863c1db33d18cd": {
                "Name": "container1",
                "EndpointID": "37e965672f03a3fc45cb281c94dae5d9ed561007b527976b811e00cf418f092e",
                "MacAddress": "f2:46:df:0e:7c:d3",
                "IPv4Address": "172.19.0.2/16",
                "IPv6Address": ""
            },
            "f1e385ddb3cf15abc3eedb319fece785fc9cb36b2a81bd3602b6d803abedc21c": {
                "Name": "container2",
                "EndpointID": "209c13cc260f56bae65ab0e84f6e97f4541851c60ff2541d2d643369c0535c8e",
                "MacAddress": "82:24:4a:a3:81:04",
                "IPv4Address": "172.19.0.3/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
```

Analysis:

The `docker network inspect lab_network` output shows the full configuration of the custom bridge network.

The network uses the subnet `172.19.0.0/16` with gateway `172.19.0.1`. Both containers are connected to this network and received their own IP addresses:
- `container1` → `172.19.0.2`
- `container2` → `172.19.0.3`

This confirms that Docker automatically assigns IP addresses to containers inside the same user-defined network and maintains network metadata for service discovery and communication.

### Test Docker Internal DNS Resolution

Command executed:

```bash
docker exec container1 nslookup container2
```

Output:

```bash
PS C:\Users\vlada> docker exec container1 nslookup container2
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:   container2
Address: 172.19.0.3
```

Analysis:

The command `nslookup container2` from inside `container1` successfully resolved the hostname `container2` to the IP address `172.19.0.3`.

The DNS server used inside the container is `127.0.0.11`, which is Docker's embedded internal DNS server. This server automatically resolves container names to their IP addresses within the same user-defined network.

Why internal DNS works here:

Docker provides automatic DNS-based service discovery for containers connected to the same **user-defined bridge network**. This means containers can communicate using container names instead of manually looking up IP addresses.

User-defined bridge vs default bridge:

A **user-defined bridge network** provides automatic DNS resolution, better service discovery, and easier isolation between groups of containers. Containers can refer to each other by name without additional configuration.

The **default bridge network** does not provide the same level of automatic DNS-based name resolution between containers. Communication there is less convenient and often requires legacy linking or manual IP-based access.

Therefore, user-defined bridge networks are preferred for multi-container applications.

# Task 4 — Volume Management and Data Persistence

## 4.1 Create and Attach Docker Volume

### Create Named Volume

Commands executed:

```bash
docker volume create lab_volume
docker volume ls
```

Output:

```bash
PS C:\Users\vlada> docker volume create lab_volume
lab_volume
```

```bash
PS C:\Users\vlada> docker volume ls
DRIVER    VOLUME NAME
local     0e9f80a4b65874ba6a6c00ab6ee6dc64f60d1d4054cab3824d8577130dddcdb6
local     0f49b27f56d6d497660595bcbdca1699d7297ce3e5530de3a9501e9a5c063fe2
local     3c40e8561dedb3f47b378a9b275923387322b4b276b9ef0bf3f83d2e3d50457e
local     4a93a512f436852a777be50a17b97d3e833fc053e2d9edec1ec81784a869cf16
local     4b1ee74bff2410c612dd696dadf83206e94e0b82c4a7ff40bcc171b95739ebbb
local     7ba8fea7656ccb6b3a55da4d1f729f02a2829fbdee8199bc67b7f968cc78fea9
local     8a616b66a5110d2163a38d6c62c05e19610e46c879e18b8d32d52720565b2a9a
local     9c5c5b1b382feed35212751bffa0f6bbd5f2669032e6dd7a6e50c3a85f942b8f
local     16a47560b778a5dbe404fd377b63ec0a11c508afd2190b9dcd035d76094c9104
local     35af4997c4c198b2ee9964028f32ca5bfa29d7b2cd2dcb8709c7d13388865b3f
local     56e4bb8b633c9926cbc524feef4f846acdeb4cdcdafd45a2fb087edf48655553
local     0206e8e892e3a7f7dc2eda2c6484d2249f36169fcbba22df52f908e716b0bf49
local     0798f211ed4cc382a907878daf09bfd0caf58100611ffe897d68302fa62fa394
local     855b0946b27fd70d4a25a63e8635ed9d2d78de1ce0f3461a5b30ec9cca2cf531
local     938c35a0b925fe5bb4cfc49db84f498fc86e1d743a08ddb26e225826003ec0cb
local     6981c5259b98a2ee075fd600d541cf282317d085ce9d7a60c5fb62fea2adbee9
local     7970e9ebcc00e90fa1c96f3d28afd1fdb0cf102d49b858d2306233f08d4e0149
local     30199dd4b9d7c0e9741ac405b1f4290c69165cafd844fb589adcc21f26d4f336
local     56169cf1f0718b893f2fd832ec05db37eb3c59d32b711d768dfe31fd44450e55
local     74458fe51e7104e18fcd6729bc86c46e357c25c4845f66745a35262311a4954e
local     31223598936ac8867a095f3226f4da6afc4da95b8f87800ad06221bfcf32ca6b
local     a20ca16e631f27f00f7fea02f470eed5b0d863ab331427e299446ff69241159f
local     a3737e0b48a1b5b717d1cec8a3dcb14c22850090fa0cece92a4a8ddff6f5f700
local     abd392905fd4b0ddac308abb7e3f499ee6b38e2a600284682eee3945fba450a0
local     b3df58adb746446ff0b75039d6f623fe6808b4e5af53dabe8ee38b0b56093f36
local     ce2b5b13707743761149adfde26b5c704a78cde0bab845c1bf6d396e1f94a899
local     da1c88878c5b3e6fc1b8abe4283e09c2f1e07607a6da388d7b3b6507474519f0
local     e7786f09e6e134c53107218b68bec4fae880a577f455b2b670b98b54e17262b3
local     ea79f9babe811cfa93549a4e3a2da85e61e91291a97880d613f19b5199af5fbd
local     f7af7e9e46e27acfcd1979e2b937329860abfe625eaa9846534aa45e75744dd2
local     f63dc252ea9b736bfe55a312dd6319510ce2a15249c09fe93d529bb378717490
local     f590ab4aa09ce75ed2653455b67820b8bf9ce6096f7f5d2f141f56cb4874e599
local     f28130e9b215d0d6a8a6fb28663ba86de045b49c9fb21cb5276ec81a8a3f8357
local     hw_3_grafana_data
local     hw_3_prometheus_data
local     lab_volume
```

Analysis:

The command `docker volume create lab_volume` successfully created a named Docker volume called `lab_volume`.

The `docker volume ls` output confirms that the volume now exists in the local Docker volume store. Named volumes are managed by Docker and are commonly used to persist data independently of the container lifecycle.

### Run Container with Attached Volume

Commands executed:

```bash
docker run -dit --name volume_container -v lab_volume:/data alpine ash
docker ps
```

Output:

```bash
PS C:\Users\vlada> docker run -dit --name volume_container -v lab_volume:/data alpine ash
b3601b7fa1cbb80e37890327505d60946b4a377f5cf7c31523ec69259836706a
```

```bash
PS C:\Users\vlada> docker ps
CONTAINER ID   IMAGE               COMMAND                  CREATED          STATUS          PORTS                  NAMES
b3601b7fa1cb   alpine              "ash"                    1 second ago     Up 1 second                            volume_container
f1e385ddb3cf   alpine              "ash"                    11 minutes ago   Up 11 minutes                          container2
e1bb5a5ca1f2   alpine              "ash"                    11 minutes ago   Up 11 minutes                          container1
ba3027667a63   my_website:latest   "/docker-entrypoint.…"   20 minutes ago   Up 20 minutes   0.0.0.0:8080->80/tcp   my_website_container
```

Analysis:

The container `volume_container` was started successfully from the Alpine image with the Docker volume `lab_volume` mounted at the path `/data`.

The option `-v lab_volume:/data` connects the named volume to the container directory `/data`. Any files written to this directory should persist even if the container is removed, because the data is stored in the Docker-managed volume rather than in the container filesystem itself.

### Write Data to the Volume

Commands executed:

```bash
docker exec volume_container sh -c "echo 'Hello from Docker Volume' > /data/hello.txt"
docker exec volume_container cat /data/hello.txt
```

Output:

```bash
PS C:\Users\vlada> docker exec volume_container sh -c "echo 'Hello from Docker Volume' > /data/hello.txt"
```

```bash
PS C:\Users\vlada> docker exec volume_container cat /data/hello.txt
Hello from Docker Volume
```

Analysis:

A file `hello.txt` was created inside the directory `/data`, which is mapped to the Docker volume `lab_volume`.

The successful output confirms that the file was written to the mounted volume and can be accessed from inside the container. Because `/data` is backed by a Docker volume, this file should remain available even if the container that created it is removed.

### Remove Container and Keep Volume Data

Commands executed:

```bash
docker rm -f volume_container
docker ps -a
```

Output:

```bash
PS C:\Users\vlada> docker rm -f volume_container
volume_container
```

```bash
PS C:\Users\vlada> docker ps -a
CONTAINER ID   IMAGE                  COMMAND                  CREATED          STATUS                    PORTS                  NAMES
f1e385ddb3cf   alpine                 "ash"                    13 minutes ago   Up 13 minutes                                    container2
e1bb5a5ca1f2   alpine                 "ash"                    13 minutes ago   Up 13 minutes                                    container1
ba3027667a63   my_website:latest      "/docker-entrypoint.…"   22 minutes ago   Up 22 minutes             0.0.0.0:8080->80/tcp   my_website_container
7532fd271564   citusdata/citus:12.1   "docker-entrypoint.s…"   6 days ago       Exited (0) 6 days ago                            citus-worker-1
888219b7165c   citusdata/citus:12.1   "docker-entrypoint.s…"   6 days ago       Exited (0) 6 days ago                            citus-worker-2
1b833bddc24b   citusdata/citus:12.1   "docker-entrypoint.s…"   6 days ago       Exited (137) 6 days ago                          citus-coordinator
c63856085e9f   mongo:6                "docker-entrypoint.s…"   8 days ago       Exited (137) 6 days ago                          mongo2
eab47716bee8   mongo:6                "docker-entrypoint.s…"   8 days ago       Exited (137) 6 days ago                          mongo1
c6db1f443af3   mongo:6                "docker-entrypoint.s…"   8 days ago       Exited (137) 6 days ago                          mongo3
3fd47080e646   scylladb/scylla:5.4    "/docker-entrypoint.…"   8 days ago       Exited (0) 4 days ago                            scylla2
c786eb5cc5af   scylladb/scylla:5.4    "/docker-entrypoint.…"   8 days ago       Exited (0) 4 days ago                            scylla3
504e77bb1bd9   scylladb/scylla:5.4    "/docker-entrypoint.…"   8 days ago       Exited (137) 4 days ago                          scylla1
4515f9d220af   neo4j:5                "tini -g -- /startup…"   9 days ago       Exited (0) 8 days ago                            neo4j-lab
87b59cea317a   mongo:7                "docker-entrypoint.s…"   9 days ago       Exited (0) 8 days ago                            mongodb-lab
56799e25512c   cassandra:4.1          "docker-entrypoint.s…"   9 days ago       Exited (143) 8 days ago                          cassandra-lab
```

Analysis:

The container `volume_container` was removed successfully.  
However, deleting a container does not automatically delete a named Docker volume attached to it.

The `docker ps -a` output confirms that `volume_container` no longer exists, while other containers remain unchanged. The data written to `lab_volume` should still be preserved and can be checked by mounting the same volume into a new container.

### Verify Data Persistence with a New Container

Commands executed:

```bash
docker run -dit --name volume_container_new -v lab_volume:/data alpine ash
docker exec volume_container_new cat /data/hello.txt
```

Output:

```bash
PS C:\Users\vlada> docker run -dit --name volume_container_new -v lab_volume:/data alpine ash
2fb1f25b6c796ab8cff65ec47311583bd3495e6703f829b7e806da655efa7d1d
```

```bash
PS C:\Users\vlada> docker exec volume_container_new cat /data/hello.txt
Hello from Docker Volume
```

Analysis:

A new container named `volume_container_new` was started with the same Docker volume `lab_volume` mounted at `/data`.

The file `hello.txt` created by the previous container is still present and contains the expected text: **Hello from Docker Volume**. This confirms that Docker volumes preserve data independently of container lifecycle.

Conclusion:

Docker volumes provide persistent storage that survives container deletion and recreation. This makes them the preferred mechanism for storing application data, databases, uploaded files, and any other important state that must not be lost when containers are replaced.