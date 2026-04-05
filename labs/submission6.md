

# Lab 6 — Container Fundamentals with Docker

## Task 1 — Container Lifecycle & Image Management (3 pts)

### docker ps -a 
docker pull ubuntu:latest
docker images ubuntu
docker run -it --name ubuntu_container ubuntu:latest


OUTPUT:


CONTAINER ID   IMAGE         COMMAND    CREATED          STATUS
     PORTS     NAMES
7230aae648f8   hello-world   "/hello"   21 seconds ago   Exited (0) 20 seconds a
go             blissful_bell
latest: Pulling from library/ubuntu
817807f3c64e: Pull complete
e4a1e8de092c: Download complete
Digest: sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
                                                            i Info →   U  In Use
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   186072bba1b2        119MB         31.7MB
root@a2dc6de9a098:/# cat /etc/os-release
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
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-poli
cy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo
root@a2dc6de9a098:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.1  0.0   4588  3712 pts/0    Ss   08:49   0:00 /bin/bash
root        10  0.0  0.0   7888  3968 pts/0    R+   08:49   0:00 ps aux
root@a2dc6de9a098:/# exit
exit



docker save -o ubuntu_image.tar ubuntu:latest ls -lh ubuntu_image.tar

docker rmi ubuntu:latest

docker rm ubuntu_container docker rmi ubuntu:latest


OUTPUT: 


-rw-r--r-- 1 PCWS 197121 31M Apr  5 11:50 ubuntu_image.tar
Error response from daemon: conflict: unable to delete ubuntu:latest (must be fo
rced) - container a2dc6de9a098 is using its referenced image 186072bba1b2
ubuntu_container
Untagged: ubuntu:latest
Deleted: sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c


### Why does image removal fail when a container exists?

Image removal fails because there is a container (a2dc6de9a098) that was created from the ubuntu:latest image. Docker maintains a reference count between containers and images. The container depends on the image's layers to function correctly. Deleting the image would break the container's ability to start or run. Docker prevents this to maintain system integrity and avoid orphaned containers that cannot function.

###What is included in the exported tar file?

The docker save command exports a complete image as a tar archive that contains all image layers as separate directories with their content, layer metadata in JSON configuration files, a manifest file listing all layers and their relationships, and the image configuration including settings like CMD, ENV, and ENTRYPOINT. This allows the image to be fully restored later with docker load


###Task 2 — Custom Image Creation & Analysis


 docker run -d -p 80:80 --name nginx_container nginx


Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
5e815e07e569: Pull complete
bb3d0aa29654: Pull complete
3189680c601f: Pull complete
587e3d84dbb5: Pull complete
ec781dee3f47: Pull complete
510ddf6557d6: Pull complete
cde7a05ae428: Pull complete
96a6cfe061e0: Download complete
669e0ab8e7fa: Download complete
Digest: sha256:7150b3a39203cb5bee612ff4a9d18774f8c7caf6399d6e8985e97e28eb751c18
Status: Downloaded newer image for nginx:latest
258ac9bb1b5574da1afb3c67d8141e9dfdd8e6f30312553ec431c748862a9d64


 curl http://localhost
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

 docker commit nginx_container my_website:latest
docker images my_website
sha256:519707d96fea06404161be085e398bf86874193fcf22d50df854bc426963f7a5
                                                            i Info →   U  In Use
IMAGE               ID             DISK USAGE   CONTENT SIZE   EXTRA
my_website:latest   519707d96fea        237MB         62.9MB


The custom image is larger than the original nginx image because it includes the current state of the container's filesystem, including runtime files and any modifications.



docker rm -f nginx_container
docker run -d -p 80:80 --name my_website_container my_website:latest
curl http://localhost
nginx_container
e4682695c6689370077b82ac7f89073810cac8a3386c9abaf94aa18b7eb27a44
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


docker diff my_website_container
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf





 docker network create lab_network
docker network ls
737c4613d05ea10cbbe448275361b963465625dff80e7f0cccc6ad25bdb5ffa0
NETWORK ID     NAME          DRIVER    SCOPE
2dd7ac39b745   bridge        bridge    local
e8fc0f129d49   host          host      local
737c4613d05e   lab_network   bridge    local
b1e5049524bb   none          null      local



 docker run -dit --network lab_network --name container1 alpine ash
docker run -dit --network lab_network --name container2 alpine ash


Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
589002ba0eae: Pull complete
caa817ad3aea: Download complete
9e595aac14e0: Download complete
Digest: sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659
Status: Downloaded newer image for alpine:latest
c35860a033f7b20196050b871b898f97e8edac0446c9f5ce9d029a9d7c59b724
6c79493f57067f7e30a39bb4e969bf517767eeadb4605c07fc6422e17626895d



##Analysis of docker diff output

docker diff shows file changes in a container (C = modified, A = added, D = deleted). In the Nginx example, C appears because config files and /run/nginx.pid were modified — no new files were added.

Docker commit vs Dockerfile

docker commit: good for quick experiments, but not reproducible, no history, hard to share.

Dockerfile: reproducible, versionable, automated — best for production, though slower for one-off tests.

Bottom line: Use commit for tinkering, Dockerfile for serious work.


###Task 3 — Container Networking & Service Discovery


docker exec container1 ping -c 3 container2


PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.173 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.183 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.084 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.084/0.146/0.183 ms


The ping command shows successful connectivity between container1 and container2 using the container name as the target


 docker network inspect lab_network
[
    {
        "Name": "lab_network",
        "Id": "737c4613d05ea10cbbe448275361b963465625dff80e7f0cccc6ad25bdb5ffa0"
,
        "Created": "2026-04-05T09:00:06.031609603Z",
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
            "6c79493f57067f7e30a39bb4e969bf517767eeadb4605c07fc6422e17626895d":
{
                "Name": "container2",
                "EndpointID": "e1956cd333f8f5199dbb0473fe3e267450b69799d753e513f
2e0e1b12fa3df55",
                "MacAddress": "36:01:8e:43:2a:35",
                "IPv4Address": "172.18.0.3/16",
                "IPv6Address": ""
            },
            "c35860a033f7b20196050b871b898f97e8edac0446c9f5ce9d029a9d7c59b724":
{
                "Name": "container1",
                "EndpointID": "fb85374c335d161356ec35fe82f22c890510a0f2135e2f7c6
d050bae62d7f040",
                "MacAddress": "b6:4d:d9:0e:9a:a1",
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



docker exec container1 nslookup container2
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:   container2
Address: 172.18.0.3


##How does Docker's internal DNS enable container-to-container communication?

Docker provides a built-in DNS server at the address 127.0.0.11 for all user-defined networks. When you create a container with a --name flag, Docker automatically registers that container name in its internal DNS. Other containers on the same network can then resolve that name to the container's current IP address. This is extremely powerful because container IP addresses are assigned dynamically and can change when containers restart. Without DNS, you would need to hardcode IP addresses or use links, which are now deprecated. With Docker's internal DNS, you can simply use the container name as a hostname, making service discovery automatic and reliable.



## User-defined bridge vs default bridge network

The default bridge network in Docker has significant limitations: it does not provide automatic DNS resolution between containers, requiring you to use the deprecated --link flag or manually find IP addresses. It also offers weaker isolation and does not allow containers to be connected or disconnected at runtime. User-defined bridge networks solve all these problems. They provide automatic DNS-based service discovery, better network isolation, and the ability to connect and disconnect containers dynamically without restarting them. They also support custom network configurations. For any real-world application, a user-defined bridge network is strongly recommended over the default bridge.


###Task 4 — Data Persistence with Volumes


docker volume create app_data
docker volume ls
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
echo '<html><body><h1>Persistent Data</h1></body></html>' > index2.html
docker cp index2.html web:/usr/share/nginx/html/index.html
curl http://localhost
docker stop web && docker rm web
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx

docker volume inspect app_data


OUTPUT:

app_data


DRIVER    VOLUME NAME
local     app_data


3515b2d1588d398dc5461a7d4329f9972d0069d79f25f898b7fcfd44cb83bc0e

Successfully copied 2.05kB to web:/usr/share/nginx/html/index.html

<html><body><h1>Persistent Data</h1></body></html>


[
    {
        "CreatedAt": "2026-04-05T09:01:33Z",
        "Driver": "local",
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Scope": "local"
    }
]



Why persistence matters
Containers are ephemeral — delete a container, lose its data. Docker volumes keep data alive across container lifecycles. Essential for databases, uploads, logs, configs.

Volumes vs Bind Mounts vs Container Storage

Container storage — default, temporary. Gone when container is removed. Only for caches/temp files.

Bind mounts — map host directory into container. Great for dev (live code edits), but host-dependent, less portable.

Volumes — Docker-managed, portable, backup-friendly, works same on any host. Best for production and databases.

Rule of thumb: Volumes for prod/data, bind mounts for dev, container storage for temp stuff.
