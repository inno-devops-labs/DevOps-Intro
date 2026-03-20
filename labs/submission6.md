# Lab 6 — Container Fundamentals with Docker

**Student:** Kamilya Shakirova
**Date:** 13-03-2026


---


## Task 1 — Container Lifecycle & Image Management

- [x] Output of `docker ps -a` and `docker images`
- [x] Image size and layer count
- [x] Tar file size comparison with image size
- [x] Error message from the first removal attempt
- [x] Analysis: Why does image removal fail when a container exists? Explain the dependency relationship.
- [x] Explanation: What is included in the exported tar file?


### 1.1 Basic Container Operations

1. **List Existing Containers:**

```sh
PS D:\Programs\DevOps-Intro>  docker ps -a
CONTAINER ID   IMAGE                        COMMAND                  CREATED        STATUS                      PORTS     NAMES
c4d6994f6e97   deployment-app               "streamlit run app.p…"   4 months ago   Exited (137) 4 months ago             titanic-app
b6709d77edf7   deployment-api               "uvicorn main:app --…"   4 months ago   Exited (137) 4 months ago             titanic-api
0be535c978c4   team-sync-frontend           "/docker-entrypoint.…"   8 months ago   Exited (137) 8 months ago             team-sync-frontend-1
ee5e286a2728   team-sync-backend-projects   "java -jar app.jar"      8 months ago   Exited (143) 8 months ago             team-sync-backend-projects-1
b73f87121514   team-sync-backend-auth       "java -jar app.jar"      8 months ago   Exited (137) 8 months ago             team-sync-backend-auth-1
adcd8f85d71c   team-sync-ml-search          "uvicorn main:app --…"   8 months ago   Exited (137) 8 months ago             team-sync-ml-search-1
9b0b54be5f2c   team-sync-ml-recsys          "uvicorn main:app --…"   8 months ago   Exited (137) 8 months ago             team-sync-ml-recsys-1
da8d44b56ee1   team-sync-backend-resume     "java -jar app.jar"      8 months ago   Exited (143) 8 months ago             team-sync-backend-resume-1
cf874007a1fb   team-sync-ml-embedder        "uvicorn main:app --…"   8 months ago   Exited (137) 8 months ago             team-sync-ml-embedder-1
fc32a0838299   qdrant/qdrant:v1.2.0         "./entrypoint.sh"        8 months ago   Exited (137) 8 months ago             qdrant
54b617dd0475   liquibase/liquibase:4.32.0   "/liquibase/docker-e…"   8 months ago   Exited (0) 8 months ago               team-sync-liquibase-1
f46f933ad117   dpage/pgadmin4:9.4.0         "/entrypoint.sh"         8 months ago   Exited (137) 8 months ago             team-sync-pgadmin-1
8d35bced6908   postgres:16                  "docker-entrypoint.s…"   8 months ago   Exited (137) 8 months ago             team-sync-postgres-1
165945fbb515   bitnami/keydb:6.3.4          "/opt/bitnami/script…"   8 months ago   Exited (137) 8 months ago             keydb
```

2. **Pull Ubuntu Image:**

```sh
PS D:\Programs\DevOps-Intro> docker pull ubuntu:latest
latest: Pulling from library/ubuntu
817807f3c64e: Pull complete
Digest: sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest

PS D:\Programs\DevOps-Intro> docker images ubuntu
REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
ubuntu       latest    186072bba1b2   3 weeks ago   117MB
```

3. **Run Interactive Container:**
  
```sh
PS D:\Programs\DevOps-Intro> docker run -it --name ubuntu_container ubuntu:latest

root@1396d259409c:/# cat /etc/os-release
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

root@1396d259409c:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4588  3520 pts/0    Ss   17:46   0:00 /bin/bash
root        10  0.0  0.0   7888  4000 pts/0    R+   17:47   0:00 ps aux

root@1396d259409c:/# exit
exit
```

### 1.2 Image Export and Dependency Analysis

1. **Export the Image:**

```sh
PS D:\Programs\DevOps-Intro> docker save -o ubuntu_image.tar ubuntu:latest

PS D:\Programs\DevOps-Intro> ls -lh ubuntu_image.tar
Get-ChildItem : Не удается найти параметр, соответствующий имени параметра "lh".
строка:1 знак:4
+ ls -lh ubuntu_image.tar
+    ~~~
    + CategoryInfo          : InvalidArgument: (:) [Get-ChildItem], ParameterBindingException
    + FullyQualifiedErrorId : NamedParameterNotFound,Microsoft.PowerShell.Commands.GetChildItemCommand

PS D:\Programs\DevOps-Intro> Get-Item .\ubuntu_image.tar | Select-Object Name,Length

Name               Length
----               ------
ubuntu_image.tar 29749760
```

2. **Attempt Image Removal:**

```sh
PS D:\Programs\DevOps-Intro> docker rmi ubuntu:latest
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container 1396d259409c is using its referenced image 186072bba1b2
```

3. **Remove Container and Retry:**

```sh
PS D:\Programs\DevOps-Intro> docker rm ubuntu_container
ubuntu_container

PS D:\Programs\DevOps-Intro> docker rmi ubuntu:latest
Untagged: ubuntu:latest
Deleted: sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c
```

### Analysis
#### Why does image removal fail when a container exists? Explain the dependency relationship.
Containers depend on images - the container's writable layer sits on top of the image's read-only layer. Docker prevents deletion because removing the image would orphan the container's filesystem, causing data loss. You must remove the container (docker rm ubuntu_container) before removing its image.

### Explanation
#### What is included in the exported tar file?
**docker save** creates a complete image archive containing:
- All filesystem layers (Ubuntu root filesystem)
- Image metadata (config, ENV, CMD)
- Layer manifests and JSON descriptors

The 28MB tar is a portable snapshot that preserves all dependencies for loading on any Docker host.


---

## Task 2 — Custom Image Creation & Analysis

- [x] Screenshot or output of original Nginx welcome page
- [x] Custom HTML content and verification via curl
- [x] Output of `docker diff my_website_container`
- [x] Analysis: Explain the diff output (A=Added, C=Changed, D=Deleted)
- [x] Reflection: What are the advantages and disadvantages of `docker commit` vs Dockerfile for image creation?

### 2.1 Deploy and Customize Nginx

1. **Deploy Nginx Container:**

```sh
PS D:\Programs\DevOps-Intro> docker run -d -p 80:80 --name nginx_container nginx
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
9baba07a35b6: Pull complete
f0b77348d9b0: Pull complete
980067d12da2: Pull complete
6b40784e4837: Pull complete
4174e33a2c9e: Pull complete
0289d65812c3: Pull complete
ec781dee3f47: Pull complete
Digest: sha256:dec7a90bd0973b076832dc56933fe876bc014929e14b4ec49923951405370112
Status: Downloaded newer image for nginx:latest
94cb3523d5b16aff79ad3f1020c4ba63a8a9425a12305d13f7347e0c1331c693

PS D:\Programs\DevOps-Intro> curl http://localhost

Предупреждение безопасности: риск выполнения сценария                                                                                                                       Invoke-WebRequest анализирует содержимое веб-страницы. При анализе страницы может выполняться код сценария на веб-странице.                                                       РЕКОМЕНДУЕМОЕ ДЕЙСТВИЕ:                                                                                                                                                     Используйте параметр -UseBasicParsing, чтобы предотвратить выполнение кода сценария.                                                                                  

      Продолжить?

[Y] Да - Y  [A] Да для всех - A  [N] Нет - N  [L] Нет для всех - L  [S] Приостановить - S  [?] Справка (значением по умолчанию является "N"): y


StatusCode        : 200
StatusDescription : OK
Content           : <!DOCTYPE html>
                    <html>
                    <head>
                    <title>Welcome to nginx!</title>
                    <style>
                    html { color-scheme: light dark; }
                    body { width: 35em; margin: 0 auto;
                    font-family: Tahoma, Verdana, Arial, sans-serif; }
                    </style...
RawContent        : HTTP/1.1 200 OK
                    Connection: keep-alive
                    Accept-Ranges: bytes
                    Content-Length: 896
                    Content-Type: text/html
                    Date: Fri, 20 Mar 2026 18:03:09 GMT
                    ETag: "69b038c3-380"
                    Last-Modified: Tue, 10 Mar 2026 ...
Forms             : {}
Headers           : {[Connection, keep-alive], [Accept-Ranges, bytes], [Content-Length, 896], [Content-Type, text/html]...}
Images            : {}
InputFields       : {}
Links             : {@{innerHTML=nginx.org; innerText=nginx.org; outerHTML=<A href="https://nginx.org/">nginx.org</A>; outerText=nginx.org; tagName=A; href=https://nginx.o
                    rg/}, @{innerHTML=community.nginx.org; innerText=community.nginx.org; outerHTML=<A href="https://community.nginx.org/">community.nginx.org</A>; outerTe 
                    xt=community.nginx.org; tagName=A; href=https://community.nginx.org/}, @{innerHTML=f5.com/nginx; innerText=f5.com/nginx; outerHTML=<A href="https://f5. 
                    com/nginx">f5.com/nginx</A>; outerText=f5.com/nginx; tagName=A; href=https://f5.com/nginx}}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 896
```

2. **Create Custom HTML:**

Created a file named `index.html` with the following content:

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

3. **Copy Custom Content:**

```sh
PS D:\Programs\DevOps-Intro> docker cp .\index.html my_website_container:/usr/share/nginx/html/
Successfully copied 2.05kB to my_website_container:/usr/share/nginx/html/

PS D:\Programs\DevOps-Intro> curl http://localhost 

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
                    Content-Length: 92
                    Content-Type: text/html
                    Date: Fri, 20 Mar 2026 18:37:10 GMT
                    ETag: "69bd8df5-5c"
                    Last-Modified: Fri, 20 Mar 2026 18...
Forms             : {}
Headers           : {[Connection, keep-alive], [Accept-Ranges, bytes], [Content-Length, 92], [Content-Type, text/html]...}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 92
```

### 2.2 Create and Test Custom Image

1. **Commit Container to Image:**

```sh
PS D:\Programs\DevOps-Intro> docker commit nginx_container my_website:latest      
sha256:5a7787f172e2cddba0b625cb5707dfbbf4426ce4c285d2b57c80229563903a6e

PS D:\Programs\DevOps-Intro> docker images my_website
REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
my_website   latest    5a7787f172e2   25 seconds ago   237MB
```

2. **Remove Original and Deploy from Custom Image:**

```sh
PS D:\Programs\DevOps-Intro> docker rm -f nginx_container
nginx_container

PS D:\Programs\DevOps-Intro> docker run -d -p 80:80 --name my_website_container my_website:latest
f5b04490d8c26035d93552d1ed0965c67f642b5d876087d8bcc8af52ef19d001

PS D:\Programs\DevOps-Intro> curl http://localhost

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
                    Content-Length: 92
                    Content-Type: text/html
                    Date: Fri, 20 Mar 2026 18:44:07 GMT
                    ETag: "69bd8df5-5c"
                    Last-Modified: Fri, 20 Mar 2026 18...
Forms             : {}
Headers           : {[Connection, keep-alive], [Accept-Ranges, bytes], [Content-Length, 92], [Content-Type, text/html]...}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 92
```

3. **Analyze Filesystem Changes:**

```sh
PS D:\Programs\DevOps-Intro> docker diff my_website_container
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
C /usr
C /usr/share
C /usr/share/nginx
C /usr/share/nginx/html
C /usr/share/nginx/html/index.html
```

<details>
<summary>🔍 Understanding docker diff output</summary>

- `A` = Added file or directory
- `C` = Changed file or directory
- `D` = Deleted file or directory

</details>


### Analysis
The docker diff output shows filesystem changes between container and image. In the example, all changed paths show the container layer modified nginx's default configuration and replaced the welcome page with custom content.

### Reflection
#### What are the advantages and disadvantages of `docker commit` vs Dockerfile for image creation?

Advantages of `docker commit`:
- Quick snapshots for debugging or experimentation
- Captures runtime state (installed packages, temp files)
- No syntax learning curve

Disadvantages of `docker commit`:
- **Non-reproducible**: Can't track changes; "black box" image
- **No version control**: Git can't diff binary images
- **Security risks**: Includes secrets, temp files, accidental changes
- **No audit trail**: Unknown what changed between commits

Advantages of Dockerfile:
- **Reproducible builds**: Same Dockerfile = same image
- **Version controllable**: Track changes in Git
- **Transparent**: Clear layer-by-layer instructions
- **CI/CD friendly**: Automated builds

Disadvantage of Dockerfile:
- Steeper initial learning curve

Dockerfiles ensure repeatable, auditable, and secure images - critical for GitOps workflows.


---

## Task 3 — Container Networking & Service Discovery

- [x] Output of ping command showing successful connectivity
- [x] Network inspection output showing both containers' IP addresses
- [x] DNS resolution output
- [x] Analysis: How does Docker's internal DNS enable container-to-container communication by name?
- [x] Comparison: What advantages does user-defined bridge networks provide over the default bridge network?

### 3.1 Create Custom Network

1. **Create Bridge Network:**

```sh
PS D:\Programs\DevOps-Intro> docker network create lab_network
ebe091eff42290b7cf64fa7decb1aee6a5cc2fc6f68ed86e506b93b2f4f061d7

PS D:\Programs\DevOps-Intro> docker network ls
NETWORK ID     NAME                         DRIVER    SCOPE
07a52c6a66ab   bridge                       bridge    local
52995ad43c8d   deployment_titanic-network   bridge    local
164c8cbfeefa   host                         host      local
ebe091eff422   lab_network                  bridge    local
9da791f399c9   none                         null      local
7ad479ac7bda   team-sync_default            bridge    local
```

2. **Deploy Connected Containers:**

```sh
PS D:\Programs\DevOps-Intro> docker run -dit --network lab_network --name container1 alpine ash
Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
589002ba0eae: Pull complete
Digest: sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659
Status: Downloaded newer image for alpine:latest
c2b5dd7ba496392e0483299cccec7676aa2dd34f8f9011308774c6e1984937b3

PS D:\Programs\DevOps-Intro> docker run -dit --network lab_network --name container2 alpine ash
31cfa3166d5583cbb1cea469f67f3c434087c4318d295692883335baba1829d3
```

### 3.2 Test Connectivity and DNS

1. **Test Container-to-Container Communication:**

```sh
PS D:\Programs\DevOps-Intro> docker exec container1 ping -c 3 container2
PING container2 (172.20.0.3): 56 data bytes
64 bytes from 172.20.0.3: seq=0 ttl=64 time=0.912 ms
64 bytes from 172.20.0.3: seq=1 ttl=64 time=0.229 ms
64 bytes from 172.20.0.3: seq=2 ttl=64 time=0.261 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.229/0.467/0.912 ms
```

2. **Inspect Network Details:**

```sh
PS D:\Programs\DevOps-Intro> docker network inspect lab_network
[
    {
        "Name": "lab_network",
        "Id": "ebe091eff42290b7cf64fa7decb1aee6a5cc2fc6f68ed86e506b93b2f4f061d7",
        "Created": "2026-03-20T18:51:43.520444591Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.20.0.0/16",
                    "Gateway": "172.20.0.1"
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
            "31cfa3166d5583cbb1cea469f67f3c434087c4318d295692883335baba1829d3": {
                "Name": "container2",
                "EndpointID": "c79c315446833d9f0f31c9fe8dd7cd2d6282071736f438613817ee504e9a8129",
                "MacAddress": "96:da:19:1d:60:b7",
                "IPv4Address": "172.20.0.3/16",
                "IPv6Address": ""
            },
            "c2b5dd7ba496392e0483299cccec7676aa2dd34f8f9011308774c6e1984937b3": {
                "Name": "container1",
                "EndpointID": "9b93f3e798f6d666dc5bfdee9ae5e4083459de211326dad51c2a09711473fa75",
                "MacAddress": "e6:f8:fc:95:89:21",
                "IPv4Address": "172.20.0.2/16",
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

3. **Check DNS Resolution:**

```sh
PS D:\Programs\DevOps-Intro> docker exec container1 nslookup container2
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:
Name:   container2
Address: 172.20.0.3

Non-authoritative answer:
```

### Analysis
#### How does Docker's internal DNS enable container-to-container communication by name?
Docker's embedded DNS server (127.0.0.11) automatically resolves container names to IP addresses within user-defined networks. When `container1` pings `container2`, Docker DNS returns `172.20.0.3` - no manual IP management or `--link` flags needed.

### Reflection
#### What advantages does user-defined bridge networks provide over the default bridge network?

**Default Bridge:**
- No automatic DNS resolution
- Requires deprecated `--link` for name resolution
- All containers can communicate (no isolation)

**User-Defined Bridge:**
- **Automatic DNS** for service discovery
- **Network isolation** - only containers in same network communicate
- **Dynamic updates** - DNS changes as containers start/stop

User-defined networks enable reliable, secure container communication by name - essential for microservices and distributed applications.


---

## Task 4 — Data Persistence with Volumes

**Objective:** Understand data persistence across container lifecycles using Docker volumes.


- [x] Custom HTML content used
- [x] Output of curl showing content persists after container recreation
- [x] Volume inspection output showing mount point
- [x] Analysis: Why is data persistence important in containerized applications?
- [x] Comparison: Explain the differences between volumes, bind mounts, and container storage. When would you use each?

### 4.1 Create and Use Volume

1. **Create Named Volume:**

```sh
PS D:\Programs\DevOps-Intro> docker volume create app_data
app_data

PS D:\Programs\DevOps-Intro> docker volume ls
DRIVER    VOLUME NAME
local     app_data
local     team-sync_keydb_data
local     team-sync_pgadmin_data
local     team-sync_pgdata
local     team-sync_qdrant_data
```

2. **Deploy Container with Volume:**

```sh
PS D:\Programs\DevOps-Intro> docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
b4e8cc754104fbd88e38896eae509c18f4e55ba9862a2881b2f1bb99f047092f
```

3. **Add Custom Content:**

Created a custom `index.html` file:

```html
<html><body><h1>Persistent Data</h1></body></html>
```

Copied to volume:

```sh
PS D:\Programs\DevOps-Intro> docker cp index.html web:/usr/share/nginx/html/ 
Successfully copied 2.05kB to web:/usr/share/nginx/html/

PS D:\Programs\DevOps-Intro> curl http://localhost

StatusCode        : 200
StatusDescription : OK
Content           : <html><body><h1>Persistent Data</h1></body></html>
RawContent        : HTTP/1.1 200 OK
                    Connection: keep-alive
                    Accept-Ranges: bytes
                    Content-Length: 50
                    Content-Type: text/html
                    Date: Fri, 20 Mar 2026 19:08:55 GMT
                    ETag: "69bd9a28-32"
                    Last-Modified: Fri, 20 Mar 2026 19...
Forms             : {}
Headers           : {[Connection, keep-alive], [Accept-Ranges, bytes], [Content-Length, 50], [Content-Type, text/html]...}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 50
```

### 4.2 Verify Persistence

1. **Destroy and Recreate Container:**

```sh
PS D:\Programs\DevOps-Intro> docker stop web                 
web
PS D:\Programs\DevOps-Intro> docker rm web                   
web

PS D:\Programs\DevOps-Intro> docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
9fb66a32a36548e8dd2324841b3f1f1e4d29ed80d6086163b2d8280458e335ab

PS D:\Programs\DevOps-Intro> curl http://localhost

StatusCode        : 200
StatusDescription : OK
Content           : <html><body><h1>Persistent Data</h1></body></html>
RawContent        : HTTP/1.1 200 OK
                    Connection: keep-alive
                    Accept-Ranges: bytes
                    Content-Length: 50
                    Content-Type: text/html
                    Date: Fri, 20 Mar 2026 19:11:07 GMT
                    ETag: "69bd9a28-32"
                    Last-Modified: Fri, 20 Mar 2026 19...
Forms             : {}
Headers           : {[Connection, keep-alive], [Accept-Ranges, bytes], [Content-Length, 50], [Content-Type, text/html]...}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 50
```

2. **Inspect Volume:**

```sh
PS D:\Programs\DevOps-Intro> docker volume inspect app_data
[
    {
        "CreatedAt": "2026-03-20T18:59:20Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```


### Analysis
#### Why is data persistence important in containerized applications?
Containers are ephemeral - when deleted, all data inside is lost. Without persistence, databases, user uploads, logs, and configuration vanish. The example shows `app_data` volume surviving container removal, preserving custom HTML content.

### Comparison
#### Explain the differences between volumes, bind mounts, and container storage. When would you use each?

| Type | Location | Best For |
|------|----------|---------|
| **Container Storage** | container layer | temporary/cache only (lost on delete) |
| **Volumes** | `/var/lib/docker/volumes/` | production databases, persistent app data |
| **Bind Mounts** | any host path | development, config files, live code reload |

Use Volumes for production data - Docker-managed, backup-friendly, and container-independent. Use Bind Mounts for development where you need host access. Avoid container storage for anything important.

