# Task 1
albertshm@Mac DevOps-Intro % docker ps -a
docker pull ubuntu:latest
docker images ubuntu
docker run -it --name ubuntu_container ubuntu:latest
CONTAINER ID   IMAGE                  COMMAND                  CREATED      STATUS                    PORTS     NAMES
9ed482ad4168   scylladb/scylla:5.2    "/docker-entrypoint.…"   5 days ago   Exited (137) 4 days ago             scylla-node3
e40c6f02ed2f   scylladb/scylla:5.2    "/docker-entrypoint.…"   5 days ago   Exited (137) 4 days ago             scylla-node2
caae5c30ee62   scylladb/scylla:5.2    "/docker-entrypoint.…"   5 days ago   Exited (137) 4 days ago             scylla-node1
d0562eb54a73   citusdata/citus:11.1   "docker-entrypoint.s…"   5 days ago   Exited (0) 5 days ago               citus-worker2
ec3217558b6b   citusdata/citus:11.1   "docker-entrypoint.s…"   5 days ago   Exited (0) 5 days ago               citus-worker1
164f21acfe15   citusdata/citus:11.1   "docker-entrypoint.s…"   5 days ago   Exited (0) 5 days ago               citus-coordinator
latest: Pulling from library/ubuntu
66a4bbbfab88: Pull complete 
9c2a2ec78563: Download complete 
Digest: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
                                                                                                   i Info →   U  In Use
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   d1e2e92c075e        141MB         30.8MB        
root@75b5e6033d10:/# cat /etc/os-release
ps aux
exit
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
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4300  3628 pts/0    Ss   20:08   0:00 /bin/bash
root        10  0.0  0.0   7632  3652 pts/0    R+   20:08   0:00 ps aux
exit
albertshm@Mac DevOps-Intro % docker save -o ubuntu_image.tar ubuntu:latest
ls -lh ubuntu_image.tar
docker rmi ubuntu:latest
docker rm ubuntu_container
docker rmi ubuntu:latest
-rw-------@ 1 albertshm  staff    29M Mar 13 23:10 ubuntu_image.tar
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container 75b5e6033d10 is using its referenced image d1e2e92c075e
ubuntu_container
Untagged: ubuntu:latest
Deleted: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9


The image removal fails initially because Docker enforces dependency protection - any container, whether running or stopped, creates a reference to its base image. This prevents accidental deletion of images that are essential for existing containers to maintain their integrity and functionality. The exported tar file contains all filesystem layers, configuration metadata, environment variables, and the manifest that together form a complete portable snapshot of the Docker image.



# Task 2
albertshm@Mac DevOps-Intro % docker run -d -p 80:80 --name nginx_container nginx
curl http://localhost
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
a87363d30ab0: Pull complete 
3b66ab8c894c: Pull complete 
2e1e80a9149a: Pull complete 
fbeac1abb084: Pull complete 
d456cad1d0ff: Pull complete 
fca7a914ec95: Pull complete 
7e3a4af256ee: Pull complete 
91b7c54c9127: Download complete 
a50bc5888f62: Download complete 
Digest: sha256:bc45d248c4e1d1709321de61566eb2b64d4f0e32765239d66573666be7f13349
Status: Downloaded newer image for nginx:latest
ebd73eec846a7f229e8ec49970b11dc0fcb33876d03bb281ddc3849ba5c1c6b9
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
albertshm@Mac DevOps-Intro % docker cp index.html nginx_container:/usr/share/nginx/html/
curl http://localhost
lstat /Users/albertshm/DevOps-Intro/index.html: no such file or directory
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
albertshm@Mac DevOps-Intro % docker commit nginx_container my_website:latest
docker images my_website
docker rm -f nginx_container
docker run -d -p 80:80 --name my_website_container my_website:latest
curl http://localhost
docker diff my_website_container
sha256:ef92d0a2da6d508c40527aa4ba6dde052c888eb9a8bd5d5c5f0e10014610b736
                                                                                                   i Info →   U  In Use
IMAGE               ID             DISK USAGE   CONTENT SIZE   EXTRA
my_website:latest   ef92d0a2da6d        255MB         61.3MB        
nginx_container
57636268cdb9adb72dcec79a457a0d462d57485892fd813e1a6098bb5aa801a6
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
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
albertshm@Mac DevOps-Intro % 

The docker diff output shows filesystem changes with 'A' indicating new files created during runtime (like cache directories and PID files), 'C' showing modifications to existing files (like our custom index.html), and no 'D' deletions. While docker commit provides a quick way to snapshot a container's state for testing or debugging, Dockerfiles are superior for production as they provide reproducibility, version control, and clear documentation of how images are built.

# Task 3
albertshm@Mac DevOps-Intro % docker network create lab_network
docker network ls
docker run -dit --network lab_network --name container1 alpine ash
docker run -dit --network lab_network --name container2 alpine ash
525e6c6f058076d8822c7bc531b30da685b2af58717db8284e1fdd4d8e65e628
NETWORK ID     NAME          DRIVER    SCOPE
24b555110456   bridge        bridge    local
67789d429782   citus-net     bridge    local
16846cd97393   host          host      local
525e6c6f0580   lab_network   bridge    local
178b5c0b9a2e   none          null      local
697aa476f29f   scylla-net    bridge    local
Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
d8ad8cd72600: Pull complete 
cb94f19e6ea6: Download complete 
37093440b0e0: Download complete 
Digest: sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659
Status: Downloaded newer image for alpine:latest
a666f42630014090d20fdcf1347657eab32d16294e2aafc0338658df7e605114
85dffec99b2af0ecaf8457b29cc4f8332ff08379f3c22fd9214425a57e5ee0cc
albertshm@Mac DevOps-Intro % docker exec container1 ping -c 3 container2
docker network inspect lab_network
docker exec container1 nslookup container2
PING container2 (172.20.0.3): 56 data bytes
64 bytes from 172.20.0.3: seq=0 ttl=64 time=0.088 ms
64 bytes from 172.20.0.3: seq=1 ttl=64 time=0.099 ms
64 bytes from 172.20.0.3: seq=2 ttl=64 time=0.165 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.088/0.117/0.165 ms
[
    {
        "Name": "lab_network",
        "Id": "525e6c6f058076d8822c7bc531b30da685b2af58717db8284e1fdd4d8e65e628",
        "Created": "2026-03-13T20:18:40.66509309Z",
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
                    "IPRange": "",
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
        "Options": {
            "com.docker.network.enable_ipv4": "true",
            "com.docker.network.enable_ipv6": "false"
        },
        "Labels": {},
        "Containers": {
            "85dffec99b2af0ecaf8457b29cc4f8332ff08379f3c22fd9214425a57e5ee0cc": {
                "Name": "container2",
                "EndpointID": "154aeeee9e8b44f3a4e723afc4888e86719f2c82d62150fd4bc341d550d3f6ea",
                "MacAddress": "be:aa:17:34:56:63",
                "IPv4Address": "172.20.0.3/16",
                "IPv6Address": ""
            },
            "a666f42630014090d20fdcf1347657eab32d16294e2aafc0338658df7e605114": {
                "Name": "container1",
                "EndpointID": "e83246d5c0710fb0de359c7dc25f55a51965a2eede72a9ca78bec7b2c787e4e8",
                "MacAddress": "96:37:5e:fa:4e:24",
                "IPv4Address": "172.20.0.2/16",
                "IPv6Address": ""
            }
        },
        "Status": {
            "IPAM": {
                "Subnets": {
                    "172.20.0.0/16": {
                        "IPsInUse": 5,
                        "DynamicIPsAvailable": 65531
                    }
                }
            }
        }
    }
]
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:   container2
Address: 172.20.0.3

albertshm@Mac DevOps-Intro % 

Docker's internal DNS server at 127.0.0.11 automatically resolves container names to IP addresses within user-defined networks, enabling containers to communicate using service names instead of hardcoded IPs. User-defined bridge networks provide significant advantages over the default bridge including automatic DNS resolution, better isolation between application stacks, and the ability to attach/detach containers dynamically without restarting.

# Task 4
albertshm@Mac DevOps-Intro % docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx

8558fb402ec7275c133150a72c99779fa3ed51644be2d7c8a04d282d69d9798f
albertshm@Mac DevOps-Intro % docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS         PORTS                                 NAMES
8558fb402ec7   nginx     "/docker-entrypoint.…"   6 seconds ago   Up 6 seconds   0.0.0.0:80->80/tcp, [::]:80->80/tcp   web
85dffec99b2a   alpine    "ash"                    7 minutes ago   Up 7 minutes                                         container2
a666f4263001   alpine    "ash"                    7 minutes ago   Up 7 minutes                                         container1
albertshm@Mac DevOps-Intro % cat > index.html << 'EOF'
<html><body><h1>Persistent Data</h1></body></html>
EOF

albertshm@Mac DevOps-Intro % docker cp index.html web:/usr/share/nginx/html/

Successfully copied 2.05kB to web:/usr/share/nginx/html/
albertshm@Mac DevOps-Intro % curl http://localhost

<html><body><h1>Persistent Data</h1></body></html>
albertshm@Mac DevOps-Intro % docker stop web && docker rm web
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx

web
web
a59d5d9149e3bf69aefe31a40fac191e14db137e26abd1e6ccd6bc3cef02628c
albertshm@Mac DevOps-Intro % curl http://localhost

<html><body><h1>Persistent Data</h1></body></html>
albertshm@Mac DevOps-Intro % docker volume inspect app_data

[
    {
        "CreatedAt": "2026-03-13T20:19:45Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
albertshm@Mac DevOps-Intro % 

Data persistence is crucial in containerized applications because containers are ephemeral by design, and without volumes, all data would be lost during container restarts, updates, or failures, making stateful applications impossible to run reliably. Volumes are the preferred choice for production data as they're completely managed by Docker, while bind mounts are ideal for development providing direct host access, and container storage should only be used for temporary, non-critical files that can be safely discarded.