# 1

1.1:
```
docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```
```
docker images
REPOSITORY                                               TAG               IMAGE ID       CREATED         SIZE
postgres                                                 15                d743cd41504b   2 weeks ago     445MB
...(it's a big list, I've been using Docker for a while now)
```

1.2

```
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    bbdabce66f1b   4 weeks ago   78.1MB
```

1.3
77MB (tar) vs 78.1MB (image)

1.4 Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container 38b408c17591 is using its referenced image bbdabce66f1b

1.5 This error occurs because a container is a running or stopped instance that depends on the image's layers to exist, and Docker prevents image removal to avoid breaking the container's ability to restart or access its filesystem.

1.6 The exported tar file contains all the image layers, metadata, and configuration needed to recreate the exact image, essentially a complete snapshot of the image's filesystem.


# 2

2.1:

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

2.2

```
curl http://localhost
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

2.3

```
docker diff my_website_container
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

2.4 The configuration files in /etc show as "Changed" because Nginx automatically modifies its own config files and creates runtime settings when the container starts. The /run/nginx.pid file appears as "Changed" because it's dynamically created when the Nginx process runs to store the process ID, which changes each time the container starts.

2.5 Docker commit offers quick snapshots for testing but creates non-reproducible, opaque images, while Dockerfile provides version-controlled, automated, and documented builds that are essential for production and collaboration.

# 3

3.1
```
docker exec container1 ping -c 3 container2
PING container2 (172.22.0.2): 56 data bytes
64 bytes from 172.22.0.2: seq=0 ttl=64 time=0.175 ms
64 bytes from 172.22.0.2: seq=1 ttl=64 time=0.179 ms
64 bytes from 172.22.0.2: seq=2 ttl=64 time=0.165 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.165/0.173/0.179 ms
```

3.2
```
docker network inspect lab_network
[
    {
        "Name": "lab_network",
        "Id": "a5f7f43a8c165fadeaa2bfebb9474b1d2f75a1776f42bb849d67c0667c87ca26",
        "Created": "2026-03-13T16:02:10.103323733+03:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.22.0.0/16",
                    "Gateway": "172.22.0.1"
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
            "4fc70f9ba2556de1d7420a27c07bb2f32284d210c4a159dc695ad2510d31d1db": {
                "Name": "container2",
                "EndpointID": "03d54a1c35f19fd96665d65bd427f3de0c88c526c6f60c322a0290d24aced8cb",
                "MacAddress": "ba:4d:03:23:ba:2b",
                "IPv4Address": "172.22.0.2/16",
                "IPv6Address": ""
            },
            "bdd6aecbecfbd8cb4ff166d4a6acd90ff43262db54a5da215c5a7081cd7b5ce6": {
                "Name": "container1",
                "EndpointID": "eff56a2d8580ae70eca76e6cb9359f799c7ca070fef0401d408bf5a291c269bb",
                "MacAddress": "de:63:9a:1a:3d:00",
                "IPv4Address": "172.22.0.3/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
```

3.3
```
ocker exec container1 nslookup container2
Server:		127.0.0.11
Address:	127.0.0.11:53

Non-authoritative answer:
Name:	container2
Address: 172.22.0.2

Non-authoritative answer:
```

3.4 Docker's internal DNS server automatically resolves container names to their IP addresses when containers are on the same user-defined network, enabling reliable service discovery without hardcoding IPs.

3.5 User-defined bridge networks provide automatic DNS resolution between containers (allowing name-based communication), better isolation by grouping related containers, and the ability to dynamically attach/detach containers without restarting.

# 4

4.1

```
<html><body><h1>Persistent Data</h1></body></html>
```

4.2
```
curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>
```

4.3 
```
docker volume inspect app_data
[
    {
        "CreatedAt": "2026-03-13T16:07:50+03:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

4.4 Data persistence is important in containerized applications because containers are ephemeral by nature—when a container is removed, all its internal data is lost, making volumes essential for preserving databases, user uploads, logs, and configuration across container restarts, recreations, or updates.

4.5 Container storage (ephemeral) exists only as long as the container lives and is perfect for temporary/scratch data, bind mounts link a specific host directory into the container and are ideal for development with live code syncing, while volumes are completely managed by Docker, stored safely in its area, and provide the best persistence, portability, and performance for production data like databases.