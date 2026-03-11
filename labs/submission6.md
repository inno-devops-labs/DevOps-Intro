# Lab 6 Submission
## Task 1: Container Lifecycle & Image Management
#### Code output:
```
arinapetuhova@MacBook-Air-Arina ~ % docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
arinapetuhova@MacBook-Air-Arina ~ % docker pull ubuntu:latest
docker images ubuntu
latest: Pulling from library/ubuntu
66a4bbbfab88: Pull complete 
Digest: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    d1e2e92c075e   4 weeks ago   139MB
arinapetuhova@MacBook-Air-Arina ~ % docker run -it --name ubuntu_container ubuntu:latest
root@e7eb710e4e78:/# cat /etc/os-release
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
root@e7eb710e4e78:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4296  3612 pts/0    Ss   12:51   0:00 /bin/bash
root        10  0.0  0.0   7628  3532 pts/0    R+   12:52   0:00 ps aux
root@e7eb710e4e78:/# exit
exit
arinapetuhova@MacBook-Air-Arina ~ % docker save -o ubuntu_image.tar ubuntu:latest
ls -lh ubuntu_image.tar

-rw-------@ 1 arinapetuhova  staff    28M 11 марта 15:52 ubuntu_image.tar
arinapetuhova@MacBook-Air-Arina ~ % docker rmi ubuntu:latest
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container e7eb710e4e78 is using its referenced image d1e2e92c075e
arinapetuhova@MacBook-Air-Arina ~ % docker rm ubuntu_container
docker rmi ubuntu:latest
ubuntu_container
Untagged: ubuntu:latest
Deleted: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
```

#### Image size and layer count:
Image size: 139MB
Layer count: 1 layer

#### Tar file size comparison with image size:
The tar file size = 28MB is significantly smaller than the image size = 139MB because the tar file is compressed.

#### Error message analysis:
Container was still referencing the ubuntu:latest image, but to remove an image, Docker requires all dependent containers to be removed first. 

It happens because containers depend on images they were created from. As a safety mechanism, Docker prevents image deletion while its containers exist to avoid orphaned containers that can't be restarted, loss of container configuration/state, and potential data loss.

#### What is included in the exported tar file?
The `docker save` command exports a complete, portable archive of the Docker image containing all image layers, the complete filesystem (including all files, libraries, and binaries), image metadata (configuration, environment variables, ports), and JSON data with layer relationships and manifest information. This compressed tar file can be transferred to another system, loaded back into Docker using `docker load`, or used to recreate the exact same image. Docker automatically compresses the layers during export, making the archive efficient for storage and transfer.

## Task 2: Custom Image Creation & Analysis 
#### Code output (output of original Nginx welcome page, custom HTML content, and verification via curl):
```
arinapetuhova@MacBook-Air-Arina ~ % docker run -d -p 80:80 --name nginx_container nginx
curl http://localhost
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
a87363d30ab0: Pull complete 
d456cad1d0ff: Pull complete 
fbeac1abb084: Pull complete 
fca7a914ec95: Pull complete 
7e3a4af256ee: Pull complete 
3b66ab8c894c: Pull complete 
2e1e80a9149a: Pull complete 
Digest: sha256:bc45d248c4e1d1709321de61566eb2b64d4f0e32765239d66573666be7f13349
Status: Downloaded newer image for nginx:latest
d1271e43c760bc1adc5b54c2456681dbb5e07f32b867b91e0490082e6daa97c5
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
<p>If you see this page, nginx is successfully installed and working.
Further configuration is required for the web server, reverse proxy, 
API gateway, load balancer, content cache, or other features.</p>

<p>For online documentation and support please refer to
<a href="https://nginx.org/">nginx.org</a>.<br/>
To engage with the community please visit
<a href="https://community.nginx.org/">community.nginx.org</a>.<br/>
For enterprise grade support, professional services, additional 
security features and capabilities please refer to
<a href="https://f5.com/nginx">f5.com/nginx</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
arinapetuhova@MacBook-Air-Arina ~ % nano index.html 
arinapetuhova@MacBook-Air-Arina ~ % docker cp index.html nginx_container:/usr/share/nginx/html/
curl http://localhost
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>

arinapetuhova@MacBook-Air-Arina ~ % docker commit nginx_container my_website:latest
sha256:679643c1abd13a4a49d3dfc9e80c764136ed10e86ab155c520d13b8a3ef27e2c
arinapetuhova@MacBook-Air-Arina ~ % docker images my_website
REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
my_website   latest    679643c1abd1   16 seconds ago   255MB
arinapetuhova@MacBook-Air-Arina ~ % docker rm -f nginx_container
nginx_container
arinapetuhova@MacBook-Air-Arina ~ % docker run -d -p 80:80 --name my_website_container my_website:latest
a351439a820c2221792ef128d36192bc263dcf4f24e9faed6bbe80fa4d3595f5
arinapetuhova@MacBook-Air-Arina ~ % curl http://localhost
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

#### Output of `docker diff my_website_container`:
```
arinapetuhova@MacBook-Air-Arina ~ % docker diff my_website_container
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

#### Analysis of Docker Diff Output:
The docker diff output shows only changed files and directories, with no added or deleted entries. The changes cascade through the directory structure, starting from `/run` and `/etc` down to specific files. The key modifications are the creation of `/run/nginx.pid` (which stores the running process ID) and changes to `/etc/nginx/conf.d/default.conf` (the Nginx configuration file). These changes occur because when the container starts, Nginx creates its PID file and potentially modifies its default configuration. Notably, the custom `index.html` file doesn't appear in the diff because I modified it in the original container before committing, and the diff shows only changes made after the container started from the committed image.

#### Reflection:
Docker commit offers the advantage of quickly creating an image from a running container, which is useful for debugging, testing, or capturing a one-off state without writing a Dockerfile. However, it has significant disadvantages: it creates a "black box" image where the build process isn't documented, makes it difficult to recreate the image consistently, and typically results in larger image sizes since it includes all temporary files and history. Dockerfile approaches provide reproducibility, clear documentation of each step, smaller images through layer caching, and easier version control integration. The main disadvantage is the initial learning curve and the need to rebuild the image when making changes. For production environments, Dockerfiles are strongly preferred, while docker commit remains useful for quick experiments and emergency debugging of running containers.

## Task 3: Container Networking & Service Discovery 
#### Output of ping command:
```
arinapetuhova@MacBook-Air-Arina ~ % docker exec container1 ping -c 3 container2
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.157 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.234 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.249 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.157/0.213/0.249 ms
```

#### Network inspection output:
```
arinapetuhova@MacBook-Air-Arina ~ % docker network inspect lab_network
[
    {
        "Name": "lab_network",
        "Id": "87a819d2ac78421d45f162c264fa9008db45e731b9ceca6b0dee88853bff1adc",
        "Created": "2026-03-11T13:30:56.8214693Z",
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
            "66c785c8a4da27d3f0368bb6c508ee2e42e9334a2429ebbd2d7e626c66b8a8c7": {
                "Name": "container2",
                "EndpointID": "fd389e0f26450a6094577809036f8d85d41b147aad60f89c1c1550ecf739ca67",
                "MacAddress": "ea:fd:1a:0d:53:a3",
                "IPv4Address": "172.18.0.3/16",
                "IPv6Address": ""
            },
            "eb89be9745dcf0331851f43e8c1546cb6853dd4ab1d42e59774fa10fefde83f4": {
                "Name": "container1",
                "EndpointID": "e63cc851ae31a1d972cd16d6ce1407232fd6dc0fcf6a5f1e88538c1afe896d9c",
                "MacAddress": "da:9e:28:3e:38:1b",
                "IPv4Address": "172.18.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
```

#### DNS resolution output:
```
arinapetuhova@MacBook-Air-Arina ~ % docker exec container1 nslookup container2
Server:		127.0.0.11
Address:	127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:	container2
Address: 172.18.0.3
```

#### Analysis:
Docker's internal DNS server (running at `127.0.0.11` inside containers) automatically resolves container names to IP addresses on user-defined networks. As shown in the `nslookup` output, when container1 queries "container2", the DNS server returns the IP address 172.18.0.3, exactly matching the IPv4 address shown in the network inspection. This allows containers to communicate using friendly names rather than hard-to-remember IP addresses. The DNS resolution works because Docker maintains a real-time mapping of container names to their assigned IP addresses on each user-defined network, and automatically injects this DNS configuration into containers, as evidenced by the successful ping using the name "container2" rather than its IP address.

#### Comparison:
User-defined bridge networks provide the following advantages over the default bridge network:

 - Containers on a user-defined network can find each other by name automatically (like "container2"). On the default bridge, containers must use IP addresses to communicate, unless you use the old --link flag;
 - A user-defined network creates a private space where only containers you specifically add can talk to each other. On the default bridge, every container on your system can potentially connect unless you manually prevent it.
 - You can connect or disconnect containers from a user-defined network anytime without restarting them. Containers can also join multiple networks at once, allowing more flexible setups;
 - You can choose your own IP address range for the network, giving you more control over how IP addresses are assigned to containers.

## Task 4: Data Persistence with Volumes
#### Custom HTML content used (`index.html`):
```
<html><body><h1>Persistent Data</h1></body></html>
```

#### Output of curl showing content persists after container recreation:
```
arinapetuhova@MacBook-Air-Arina ~ % docker stop web && docker rm web
web
web
arinapetuhova@MacBook-Air-Arina ~ % docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
8b3234e768ffd76ddb49b173f48c76f3a984cdcbc089ca716949eea69906397f
arinapetuhova@MacBook-Air-Arina ~ % curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>
```

#### Volume inspection output:
```
arinapetuhova@MacBook-Air-Arina ~ % docker volume inspect app_data
[
    {
        "CreatedAt": "2026-03-11T13:43:42Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

#### Analysis: 
Data persistence is important because containers are temporary - they can be stopped, removed, or recreated at any time, and without persistence, all data inside them disappears forever. As shown above, even after completely removing the original container (`web`) and starting a new one (`web_new`), the custom HTML content remained accessible because it was stored in a volume. This matters for real applications where you can't afford to lose databases, user uploads, or configuration files every time you update or restart a container.

#### Comparison: 
Container storage is temporary and dies with the container (it's the default but unsuitable for important data). Volumes are managed by Docker (stored in `/var/lib/docker/volumes/`) and outlive containers, making them perfect for databases and application data that must survive container recreations. Bind mounts map any folder from your host computer into the container, ideal for development because you can edit files on your host and see changes immediately inside the container. Use volumes for production data you want Docker to manage, bind mounts for development and live code updates, and container storage only for temporary files that don't need to survive.