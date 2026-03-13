# Lab 6 — Container Fundamentals with Docker

## Task 1 — Container Lifecycle & Image Management

### Existing containers and images

```
thallars@ASUS-TUF:~$ docker ps -a
CONTAINER ID   IMAGE                          COMMAND                  CREATED       STATUS                     PORTS     NAMES
498f2e2d4f42   fabook/iros:lidar-lab-v0.0.1   "/ros_entrypoint.sh …"   3 days ago    Exited (137) 2 days ago              lab_lidar-terminal-1
9136a0680860   fabook/iros:v0.0.1             "/opt/nvidia/nvidia_…"   4 weeks ago   Up 28 hours                          ros2_projects-terminal-1
d9c753867361   osrf/ros:humble-desktop-full   "/ros_entrypoint.sh …"   4 weeks ago   Exited (255) 4 weeks ago             ros2-humble
```

```
thallars@ASUS-TUF:~$ docker images
REPOSITORY    TAG                   IMAGE ID       CREATED        SIZE
fabook/iros   lidar-lab-v0.0.1      6364e3df68c9   3 days ago     5.7GB
ubuntu        latest                bbdabce66f1b   4 weeks ago    78.1MB
fabook/iros   v0.0.1                822b71059fb4   5 weeks ago    29.2GB
fabook/cv     mr-v0.0.1             d647a218a0cc   5 weeks ago    4.67GB
osrf/ros      jazzy-desktop-full    99fd0c13d5d2   5 months ago   4.57GB
osrf/ros      humble-desktop-full   8a2dc99bf30e   5 months ago   3.84GB
```

### Image size and layer count

Image size: 78.1MB
```
thallars@ASUS-TUF:~$ docker images ubuntu
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    bbdabce66f1b   4 weeks ago   78.1MB
```

Layer count: 1
```
"RootFS": {
    "Type": "layers",
    "Layers": [
        "sha256:efafae78d70c98626c521c246827389128e7d7ea442db31bc433934647f0c791"
    ]
}
```

### Tar file size comparison with image size

| `ubuntu_image.tar` | `ubuntu:latest` |
| ------------------ | --------------- |
| 80.7 MB            | 78.1MB          |

The exported tar file includes the complete Ubuntu image with all its layers, metadata, and the Docker configuration files needed to recreate the exact image. It contains every filesystem layer, the JSON metadata describing the image history and configuration, and the manifest file that ties everything together for loading back into Docker.

### Error message from the first removal attempt

```
thallars@ASUS-TUF:~/Downloads$ docker rmi ubuntu:latest
Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container 3d30d5aaba52 is using its referenced image bbdabce66f1b
```

Image removal fails because a running or existing container (3d30d5aaba52) has a dependency on that image—the container was created from it and needs the image's filesystem layers to function. One must stop and remove the dependent container first before being able to delete the image, unless using the force flag to override this safety mechanism.

## Task 2 — Custom Image Creation & Analysis

### Output of original Nginx welcome page

```
thallars@ASUS-TUF:~/Downloads$ curl http://localhost
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
```

### Custom HTML content and verification via curl

```
#index.html
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

```
thallars@ASUS-TUF:~/Downloads$ docker cp index.html nginx_container:/usr/share/nginx/html/
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/
thallars@ASUS-TUF:~/Downloads$ curl http://localhost
<html>
<head>
<title>The best</title>`docker commit` vs Dockerfile
</head>
<body>
<h1>website</h1>
</body>
</html>
```

### Output of `docker diff my_website_container`

```
thallars@ASUS-TUF:~/Downloads$ docker diff my_website_container
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

The `C` markers indicate modified files/directories, which include runtime files (`/run/nginx.pid` created when Nginx starts) and configuration files (`/etc/nginx/conf.d/default.conf` that was automatically generated). Notably, the custom `index.html` I added is not shown because it was committed to the image and is now part of the base filesystem, not a container-layer change.

### Reflection: What are the advantages and disadvantages of `docker commit` vs Dockerfile for image creation?

|  | Advantages | Disadvantages |
| - | - | - |
| Commit | Quick and simple for capturing a container's current state, useful for debugging or temporary snapshots without writing a Dockerfile | Not reproducible or version-controlled, hides the build process in a "black box," and can create unnecessarily large images by including temporary files and runtime artifacts
| Dockerfile | Provides clear documentation of build steps, enables version control, creates reproducible builds, and typically produces smaller, more optimized images | Requires more initial setup and Dockerfile syntax knowledge, and needs rebuilding for any change rather than modifying a running container

## Task 3 — Container Networking & Service Discovery

### Output of ping command

```
thallars@ASUS-TUF:~/Downloads$ docker exec container1 ping -c 3 container2
PING container2 (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.054 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.087 ms
64 bytes from 172.19.0.3: seq=2 ttl=64 time=0.103 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.054/0.081/0.103 ms
```

### Network inspection

```
thallars@ASUS-TUF:~/Downloads$ docker network inspect lab_network
[
    {
        "Name": "lab_network",
        "Id": "ae7f52a46de091bd6675860f82ece638edbd1a4789cadc05103f922e5fc08de0",
        "Created": "2026-03-13T19:14:22.933216166+03:00",
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
            "245d2ae47110a344ba865f19dc4fae60829a5d268d071f356194af3be9581a36": {
                "Name": "container1",
                "EndpointID": "d5446b72f45fac2a245b85c782172c96dcaa8e709449ebf3566ab73babc5b7fc",
                "MacAddress": "ba:17:98:10:a2:88",
                "IPv4Address": "172.19.0.2/16",
                "IPv6Address": ""
            },
            "6b2ea600f8242213b05a9090d64e85e07c2455f8fa38be4438b420fad8344b6c": {
                "Name": "container2",
                "EndpointID": "2b0ab7ad5f30be714f6cfd0717a35f083e3d76d3668840d39fe392ce26da5223",
                "MacAddress": "46:8d:05:80:0a:2a",
                "IPv4Address": "172.19.0.3/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
```

### DNS resolution

```
thallars@ASUS-TUF:~/Downloads$ docker exec container1 nslookup container2
Server:		127.0.0.11
Address:	127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:	container2
Address: 172.19.0.3
```

### Analysis: How does Docker's internal DNS enable container-to-container communication by name?

Docker's internal DNS enables container-to-container communication by name by automatically resolving container names to their IP addresses within the same network, allowing containers to ping or connect to each other using their container names as hostnames without needing to know their dynamic IP addresses. This embedded DNS server runs at 127.0.0.11 and eliminates the need for manual IP management or service discovery mechanisms when containers need to communicate.

### Comparison: What advantages does user-defined bridge networks provide over the default bridge network?

User-defined bridge networks provide automatic DNS resolution between containers (unlike the default bridge where containers can only communicate by IP), better isolation by grouping related containers together, and the ability to dynamically attach and detach containers without restarting. Additionally, user-defined networks offer configurable options like custom IP ranges and network drivers, while the default bridge requires legacy link flags for any form of name-based communication and applies the same firewall rules to all containers.

## Task 4 — Data Persistence with Volumes

### Custom HTML content

```
#index.html
<html><body><h1>Persistent Data</h1></body></html>
```

### Output of curl

```
thallars@ASUS-TUF:~/Downloads$ docker stop web && docker rm web
web
web
thallars@ASUS-TUF:~/Downloads$ docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
5f9910fa840fcd542cd4e04cbaa30d87a744f596df9ef249dd5899372786ca61
thallars@ASUS-TUF:~/Downloads$ curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>

```

### Volume inspection

```
thallars@ASUS-TUF:~/Downloads$ docker volume inspect app_data
[
    {
        "CreatedAt": "2026-03-13T19:21:12+03:00",
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

Data persistence ensures that critical data survives container restarts, recreations, or failures since containers are designed to be ephemeral and lose all internal data when removed. Without persistence, stateful applications like databases cannot maintain data across container lifecycles, making production deployments impossible.

### Comparison: Explain the differences between volumes, bind mounts, and container storage. When would you use each?

- Volumes are Docker-managed storage in `/var/lib/docker/volumes/` - best for production data, databases, and when you need backup capabilities or cross-container sharing

- Bind mounts directly map host files/folders into containers - ideal for development with live code reloading and providing host-specific configuration files

- Container storage is the temporary writable layer that dies with the container - suitable for cache files, temporary processing, and completely stateless applications